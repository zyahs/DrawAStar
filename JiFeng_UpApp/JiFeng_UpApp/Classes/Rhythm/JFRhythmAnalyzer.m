//
//  JFRhythmAnalyzer.m
//

#import "JFRhythmAnalyzer.h"
#import <AVFoundation/AVFoundation.h>

static const NSInteger kLanes = 4;
static const double    kHopSec = 0.011609;       // 约 86 fps,512 / 44100
static const double    kMinNoteGap = 0.085;       // 同轨最小间隔
static const double    kGlobalMinGap = 0.060;     // 任意轨最小间隔

@implementation JFRhythmAnalyzer

#pragma mark - 一阶 IIR 双工(low/high pass)

// 单极一阶 lowpass:y[n] = a*x[n] + (1-a)*y[n-1],a = 1 - exp(-2π fc / fs)
static inline double lpCoeff(double fc, double fs) {
    return 1.0 - exp(-2.0 * M_PI * fc / fs);
}

#pragma mark - 主入口

+ (NSArray<JFRhythmBeat *> *)analyzeURL:(NSURL *)url
                               duration:(NSTimeInterval)duration
                                 outBPM:(double *)outBPM {
    NSError *err = nil;
    AVAudioFile *file = [[AVAudioFile alloc] initForReading:url error:&err];
    if (!file || err) {
        if (outBPM) *outBPM = 110;
        return @[];
    }
    AVAudioFormat *fmt = file.processingFormat;
    AVAudioFrameCount totalFrames = (AVAudioFrameCount)file.length;
    if (totalFrames == 0 || fmt.sampleRate <= 0) {
        if (outBPM) *outBPM = 110;
        return @[];
    }

    double sr = fmt.sampleRate;
    NSUInteger channels = fmt.channelCount;
    NSUInteger hopSize = MAX(1u, (NSUInteger)(sr * kHopSec));
    NSUInteger chunkFrames = (NSUInteger)MIN((double)totalFrames, sr * 5.0);
    AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:fmt frameCapacity:(AVAudioFrameCount)chunkFrames];
    if (!buffer) {
        if (outBPM) *outBPM = 110;
        return @[];
    }

    // 4 个频段:低 (~120Hz) / 中低 (~120-500Hz) / 中高 (~500-2k) / 高 (>2k)
    const double aLow1  = lpCoeff(120.0, sr);
    const double aLow2  = lpCoeff(500.0, sr);
    const double aLow3  = lpCoeff(2000.0, sr);

    double yLP1 = 0, yLP2 = 0, yLP3 = 0;

    NSMutableArray<NSNumber *> *band0 = [NSMutableArray array];   // <120
    NSMutableArray<NSNumber *> *band1 = [NSMutableArray array];   // 120-500
    NSMutableArray<NSNumber *> *band2 = [NSMutableArray array];   // 500-2k
    NSMutableArray<NSNumber *> *band3 = [NSMutableArray array];   // >2k

    NSUInteger sampleCarry = 0;
    double sq0 = 0, sq1 = 0, sq2 = 0, sq3 = 0;
    NSUInteger framesRead = 0;

    while (framesRead < totalFrames) {
        AVAudioFrameCount want = (AVAudioFrameCount)MIN(chunkFrames, totalFrames - framesRead);
        buffer.frameLength = 0;
        @try {
            BOOL ok = [file readIntoBuffer:buffer frameCount:want error:&err];
            if (!ok || err) break;
        } @catch (__unused NSException *e) { break; }
        AVAudioFrameCount got = buffer.frameLength;
        if (got == 0) break;
        float **chan = buffer.floatChannelData;
        if (!chan) break;
        for (AVAudioFrameCount i = 0; i < got; i++) {
            double s = 0;
            for (NSUInteger c = 0; c < channels; c++) s += chan[c][i];
            s /= MAX(1u, (unsigned)channels);

            // 三层 LP 分频
            yLP1 += aLow1 * (s - yLP1);     // <120
            yLP2 += aLow2 * (s - yLP2);     // <500
            yLP3 += aLow3 * (s - yLP3);     // <2000

            double b0 = yLP1;
            double b1 = yLP2 - yLP1;
            double b2 = yLP3 - yLP2;
            double b3 = s     - yLP3;

            sq0 += b0 * b0;
            sq1 += b1 * b1;
            sq2 += b2 * b2;
            sq3 += b3 * b3;
            sampleCarry++;

            if (sampleCarry >= hopSize) {
                [band0 addObject:@(sqrt(sq0 / sampleCarry))];
                [band1 addObject:@(sqrt(sq1 / sampleCarry))];
                [band2 addObject:@(sqrt(sq2 / sampleCarry))];
                [band3 addObject:@(sqrt(sq3 / sampleCarry))];
                sq0 = sq1 = sq2 = sq3 = 0;
                sampleCarry = 0;
            }
        }
        framesRead += got;
        if (got < want) break;
    }

    NSUInteger N = band0.count;
    if (N < 64) {
        if (outBPM) *outBPM = 110;
        return @[];
    }

    // === 半波正差分(onset 流)===
    double *o0 = calloc(N, sizeof(double));
    double *o1 = calloc(N, sizeof(double));
    double *o2 = calloc(N, sizeof(double));
    double *o3 = calloc(N, sizeof(double));
    double *oAll = calloc(N, sizeof(double));
    double *bandE0 = calloc(N, sizeof(double));
    double *bandE1 = calloc(N, sizeof(double));
    double *bandE2 = calloc(N, sizeof(double));
    double *bandE3 = calloc(N, sizeof(double));
    for (NSUInteger i = 0; i < N; i++) {
        bandE0[i] = [band0[i] doubleValue];
        bandE1[i] = [band1[i] doubleValue];
        bandE2[i] = [band2[i] doubleValue];
        bandE3[i] = [band3[i] doubleValue];
    }
    for (NSUInteger i = 1; i < N; i++) {
        double d0 = MAX(0, bandE0[i] - bandE0[i - 1]);
        double d1 = MAX(0, bandE1[i] - bandE1[i - 1]);
        double d2 = MAX(0, bandE2[i] - bandE2[i - 1]);
        double d3 = MAX(0, bandE3[i] - bandE3[i - 1]);
        o0[i] = d0; o1[i] = d1; o2[i] = d2; o3[i] = d3;
        // 总 onset 加权:鼓底 1.4,中低 1.0,中高 0.9,高 0.8
        oAll[i] = d0 * 1.4 + d1 * 1.0 + d2 * 0.9 + d3 * 0.8;
    }

    // === BPM 估算(可选,不影响 onset 选取)===
    double bestScore = -1, bestBPM = 110;
    for (double bpm = 60; bpm <= 200; bpm += 1.0) {
        double framesPerBeat = 60.0 / bpm / kHopSec;
        if (framesPerBeat < 4) continue;
        // 每首歌只取一组相位扫描以加速
        double maxSum = 0;
        NSInteger steps = MAX(1, (NSInteger)(framesPerBeat / 12));
        for (NSInteger phase = 0; phase < (NSInteger)framesPerBeat; phase += steps) {
            double sum = 0;
            for (double f = phase; f < N; f += framesPerBeat) {
                NSInteger idx = (NSInteger)f;
                if (idx < (NSInteger)N) sum += oAll[idx];
            }
            if (sum > maxSum) maxSum = sum;
        }
        double penalty = (bpm < 80 || bpm > 170) ? 0.92 : 1.0;
        double score = maxSum * penalty;
        if (score > bestScore) { bestScore = score; bestBPM = bpm; }
    }
    if (outBPM) *outBPM = bestBPM;

    // === 自适应阈值 peak picking ===
    // 对 oAll 做局部极大 + 局部均值 * k 阈值
    NSInteger window = MAX(3, (NSInteger)(0.045 / kHopSec));         // 极大值半径 ~45ms
    NSInteger longWindow = MAX(20, (NSInteger)(0.6 / kHopSec));      // 阈值参考窗口 600ms
    NSMutableArray<JFRhythmBeat *> *raw = [NSMutableArray array];
    NSInteger lastFrameByLane[4] = { -1000, -1000, -1000, -1000 };
    NSInteger lastFrameAny = -1000;

    for (NSInteger i = 1; i < (NSInteger)N - 1; i++) {
        double t = i * kHopSec;
        if (t < 1.5) continue;
        if (t > duration - 0.4) break;

        double v = oAll[i];
        if (v <= 0) continue;

        // 局部极大
        BOOL isPeak = YES;
        for (NSInteger k = -window; k <= window; k++) {
            NSInteger j = i + k;
            if (j < 0 || j >= (NSInteger)N || j == i) continue;
            if (oAll[j] > v) { isPeak = NO; break; }
        }
        if (!isPeak) continue;

        // 阈值参考窗口
        NSInteger lo = MAX(0, i - longWindow);
        NSInteger hi = MIN((NSInteger)N - 1, i + longWindow / 4);  // 偏前(过去)
        double mean = 0; NSInteger cnt = 0;
        for (NSInteger j = lo; j <= hi; j++) { mean += oAll[j]; cnt++; }
        mean = (cnt > 0) ? mean / cnt : 0;
        double threshold = mean * 1.5 + 1e-5;
        if (v < threshold) continue;

        // 全局最小间隔
        if (i - lastFrameAny < (NSInteger)(kGlobalMinGap / kHopSec)) continue;

        // 选轨道:看哪个频段相对自身均值"突出"得最厉害
        // 用 (band onset / band 长期均值) 排序
        double rel0 = o0[i] / (avgOver(bandE0, N, lo, hi) + 1e-6);
        double rel1 = o1[i] / (avgOver(bandE1, N, lo, hi) + 1e-6);
        double rel2 = o2[i] / (avgOver(bandE2, N, lo, hi) + 1e-6);
        double rel3 = o3[i] / (avgOver(bandE3, N, lo, hi) + 1e-6);
        double rels[4] = { rel0, rel1, rel2, rel3 };

        // 主 lane = max
        NSInteger lane = 0;
        double maxRel = rels[0];
        for (NSInteger l = 1; l < 4; l++) {
            if (rels[l] > maxRel) { maxRel = rels[l]; lane = l; }
        }
        // 同轨刚刚响过 -> 退到次大轨
        if (i - lastFrameByLane[lane] < (NSInteger)(kMinNoteGap / kHopSec)) {
            // 找次大
            NSInteger second = -1; double secRel = -1;
            for (NSInteger l = 0; l < 4; l++) {
                if (l == lane) continue;
                if (rels[l] > secRel && (i - lastFrameByLane[l] >= (NSInteger)(kMinNoteGap / kHopSec))) {
                    secRel = rels[l]; second = l;
                }
            }
            if (second >= 0) lane = second;
        }

        // strength:相对自身长期均值的倍数,归一到 0..1
        double meanLong = mean;
        double strength = MIN(1.0, MAX(0.25, (v - meanLong) / (meanLong * 4.0 + 1e-6) + 0.45));

        [raw addObject:[JFRhythmBeat beatAt:t lane:lane strength:strength]];
        lastFrameByLane[lane] = i;
        lastFrameAny = i;
    }

    free(o0); free(o1); free(o2); free(o3); free(oAll);
    free(bandE0); free(bandE1); free(bandE2); free(bandE3);

    return [raw copy];
}

static inline double avgOver(double *arr, NSUInteger N, NSInteger lo, NSInteger hi) {
    if (lo < 0) lo = 0;
    if (hi >= (NSInteger)N) hi = (NSInteger)N - 1;
    if (hi <= lo) return 0;
    double s = 0;
    for (NSInteger j = lo; j <= hi; j++) s += arr[j];
    return s / (hi - lo + 1);
}

@end
