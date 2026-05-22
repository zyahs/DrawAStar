//
//  JFRhythmViewController.m
//
//  节奏点点 —— 4 列下落点击 + 底部固定按键板。支持从「文件」/iCloud 导入
//  自己喜欢的音乐(mp3 / m4a / wav / aac / flac),导入后离线分析估算 BPM,
//  按节拍均匀生成谱面;游戏开始时与 AVAudioPlayer 同步播放。
//
//  判定放宽:落到判定区(progress 0.4 ~ 1.25)的音符,按下对应轨道键即命中,
//  按距离判定线的远近给三档分数(PERFECT / GREAT / GOOD)。
//

#import "JFRhythmViewController.h"
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"
#import <AVFoundation/AVFoundation.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

static const NSInteger kLanes = 4;
static NSString *const kBestKey = @"jf_rhythm_best";

#pragma mark - 谱面 / 音符模型

@interface JFRhythmBeat : NSObject
@property (nonatomic, assign) NSTimeInterval time;     // 该音符到达判定线的歌曲时间(秒)
@property (nonatomic, assign) NSInteger lane;          // 0..3
@end
@implementation JFRhythmBeat @end

@interface JFRhythmNote : NSObject
@property (nonatomic, assign) NSInteger lane;
@property (nonatomic, assign) NSTimeInterval targetTime;   // 应到达判定线的歌曲时间
@property (nonatomic, strong) UIView *view;
@property (nonatomic, assign) BOOL hit;
@property (nonatomic, assign) BOOL spawned;
@end
@implementation JFRhythmNote @end

@interface JFRhythmViewController () <UIDocumentPickerDelegate, AVAudioPlayerDelegate>

// UI
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UILabel *comboLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *songLabel;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UILabel *statusLabel;     // 分析状态
@property (nonatomic, strong) UIView  *track;
@property (nonatomic, strong) UIView  *judgeLine;
@property (nonatomic, strong) UIView  *judgeGlow;
@property (nonatomic, strong) NSArray<UIView *> *laneViews;
@property (nonatomic, strong) NSArray<UIButton *> *keyPads;
@property (nonatomic, strong) NSArray<UILabel *> *keyLabels;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *pickButton;     // 选择音乐

// 音频 + 谱面
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, copy)   NSString *songTitle;
@property (nonatomic, assign) NSTimeInterval songDuration;
@property (nonatomic, assign) double bpm;
@property (nonatomic, strong) NSArray<JFRhythmBeat *> *chart;
@property (nonatomic, strong) NSURL *securedSongURL;    // 用于 stop 时 stopAccessingSecurityScopedResource

// 运行时
@property (nonatomic, strong) NSMutableArray<JFRhythmNote *> *notes;     // 已 spawn 的
@property (nonatomic, strong) NSMutableArray<JFRhythmBeat *> *pendingBeats; // 等待 spawn 的(头部最早)
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) NSTimeInterval fallDuration;   // 从屏顶到判定线的下落用时

@property (nonatomic, assign) NSInteger score;
@property (nonatomic, assign) NSInteger best;
@property (nonatomic, assign) NSInteger combo;
@property (nonatomic, assign) NSInteger maxCombo;
@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) BOOL analyzing;

@end

@implementation JFRhythmViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.best = [[NSUserDefaults standardUserDefaults] integerForKey:kBestKey];
    self.notes = [NSMutableArray array];
    self.pendingBeats = [NSMutableArray array];
    self.fallDuration = 1.6;

    [self buildBackground];
    [self buildUI];
    [self refreshSongLabel];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopAndCleanup];
}

#pragma mark - UI

- (void)buildBackground {
    self.bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"3333"]];
    self.bgImageView.frame = self.view.bounds;
    self.bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.bgImageView];

    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65];
    [self.view addSubview:overlay];
}

- (void)buildUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"节奏点点";
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    [self.view addSubview:self.titleLabel];

    self.timeLabel  = [self badgeLabel]; self.timeLabel.text  = @"--";
    self.scoreLabel = [self badgeLabel]; self.scoreLabel.text = @"0";
    self.comboLabel = [self badgeLabel]; self.comboLabel.text = @"Combo 0";

    UIStackView *bs = [[UIStackView alloc] initWithArrangedSubviews:@[self.timeLabel, self.scoreLabel, self.comboLabel]];
    bs.translatesAutoresizingMaskIntoConstraints = NO;
    bs.axis = UILayoutConstraintAxisHorizontal;
    bs.spacing = JFSpacing8;
    bs.distribution = UIStackViewDistributionFillEqually;
    [self.view addSubview:bs];

    self.songLabel = [[UILabel alloc] init];
    self.songLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.songLabel.textColor = [JFTheme textPrimary];
    self.songLabel.font = [JFTheme fontHeadline];
    self.songLabel.textAlignment = NSTextAlignmentCenter;
    self.songLabel.numberOfLines = 1;
    [self.view addSubview:self.songLabel];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.textColor = [JFTheme accent];
    self.statusLabel.font = [JFTheme fontBody];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    [self.view addSubview:self.statusLabel];

    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.hintLabel.text = @"音符落到下方按键时,点击对应键位即可命中";
    self.hintLabel.textColor = [JFTheme textSecondary];
    self.hintLabel.font = [JFTheme fontBody];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.numberOfLines = 0;
    [self.view addSubview:self.hintLabel];

    self.track = [[UIView alloc] init];
    self.track.translatesAutoresizingMaskIntoConstraints = NO;
    self.track.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    self.track.layer.cornerRadius = JFRadiusMedium;
    self.track.layer.borderWidth = 0.5;
    self.track.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.track.clipsToBounds = YES;
    [self.view addSubview:self.track];

    self.judgeGlow = [[UIView alloc] init];
    self.judgeGlow.backgroundColor = [[JFTheme accent] colorWithAlphaComponent:0.18];
    self.judgeGlow.userInteractionEnabled = NO;
    [self.track addSubview:self.judgeGlow];

    self.judgeLine = [[UIView alloc] init];
    self.judgeLine.backgroundColor = [JFTheme accent];
    self.judgeLine.userInteractionEnabled = NO;
    [self.track addSubview:self.judgeLine];

    NSMutableArray *lanes = [NSMutableArray array];
    NSMutableArray *pads  = [NSMutableArray array];
    NSMutableArray *kls   = [NSMutableArray array];
    NSArray<NSString *> *keyTitles = @[@"A", @"S", @"K", @"L"];
    NSArray<UIColor *>  *keyColors = @[
        [UIColor colorWithRed:0.97 green:0.45 blue:0.55 alpha:1],
        [UIColor colorWithRed:0.99 green:0.78 blue:0.36 alpha:1],
        [UIColor colorWithRed:0.32 green:0.78 blue:0.95 alpha:1],
        [UIColor colorWithRed:0.55 green:0.86 blue:0.55 alpha:1],
    ];
    for (NSInteger i = 0; i < kLanes; i++) {
        UIView *lane = [[UIView alloc] init];
        lane.userInteractionEnabled = NO;
        lane.backgroundColor = (i % 2 == 0) ? [UIColor colorWithWhite:1 alpha:0.04] : [UIColor colorWithWhite:1 alpha:0.02];
        [self.track addSubview:lane];
        [lanes addObject:lane];

        UIButton *pad = [UIButton buttonWithType:UIButtonTypeCustom];
        pad.tag = i;
        pad.backgroundColor = [keyColors[i] colorWithAlphaComponent:0.18];
        pad.layer.cornerRadius = 12;
        pad.layer.borderWidth = 1.5;
        pad.layer.borderColor = [keyColors[i] colorWithAlphaComponent:0.85].CGColor;
        [pad addTarget:self action:@selector(onPadDown:) forControlEvents:UIControlEventTouchDown];
        [pad addTarget:self action:@selector(onPadUp:)   forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        [self.track addSubview:pad];
        [pads addObject:pad];

        UILabel *kl = [[UILabel alloc] init];
        kl.text = keyTitles[i];
        kl.textColor = [UIColor colorWithWhite:1 alpha:0.95];
        kl.font = [UIFont systemFontOfSize:26 weight:UIFontWeightHeavy];
        kl.textAlignment = NSTextAlignmentCenter;
        kl.userInteractionEnabled = NO;
        [self.track addSubview:kl];
        [kls addObject:kl];
    }
    self.laneViews = lanes;
    self.keyPads = pads;
    self.keyLabels = kls;

    self.pickButton  = [self secondaryButtonWithTitle:@"导入音乐" action:@selector(onPickSong)];
    self.startButton = [self primaryButtonWithTitle:@"开始" action:@selector(onStart)];
    [self.view addSubview:self.pickButton];
    [self.view addSubview:self.startButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:JFSpacing12],
        [self.titleLabel.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],

        [bs.topAnchor      constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:JFSpacing12],
        [bs.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [bs.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [bs.heightAnchor   constraintEqualToConstant:32],

        [self.songLabel.topAnchor      constraintEqualToAnchor:bs.bottomAnchor constant:JFSpacing12],
        [self.songLabel.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.songLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],

        [self.statusLabel.topAnchor      constraintEqualToAnchor:self.songLabel.bottomAnchor constant:JFSpacing4],
        [self.statusLabel.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],

        [self.hintLabel.topAnchor      constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:JFSpacing4],
        [self.hintLabel.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.hintLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],

        [self.track.topAnchor      constraintEqualToAnchor:self.hintLabel.bottomAnchor constant:JFSpacing8],
        [self.track.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing16],
        [self.track.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],

        [self.pickButton.topAnchor      constraintEqualToAnchor:self.track.bottomAnchor constant:JFSpacing12],
        [self.pickButton.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.pickButton.heightAnchor   constraintEqualToConstant:48],

        [self.startButton.topAnchor      constraintEqualToAnchor:self.track.bottomAnchor constant:JFSpacing12],
        [self.startButton.leadingAnchor  constraintEqualToAnchor:self.pickButton.trailingAnchor constant:JFSpacing12],
        [self.startButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [self.startButton.heightAnchor   constraintEqualToConstant:48],
        [self.pickButton.widthAnchor     constraintEqualToAnchor:self.startButton.widthAnchor],

        [self.startButton.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor constant:-JFSpacing16],
    ]];
}

- (CGFloat)padHeight  { return 88; }
- (CGFloat)padPadding { return 8; }
- (CGFloat)judgeY {
    CGFloat H = self.track.bounds.size.height;
    return H - [self padHeight] + 14;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.track.bounds.size.width;
    CGFloat H = self.track.bounds.size.height;
    if (W <= 0 || H <= 0) return;
    CGFloat lw = W / kLanes;
    CGFloat padH = [self padHeight];
    CGFloat padTop = H - padH;
    CGFloat judgeY = [self judgeY];
    for (NSInteger i = 0; i < kLanes; i++) {
        self.laneViews[i].frame = CGRectMake(i * lw, 0, lw, padTop);
        UIButton *pad = self.keyPads[i];
        pad.frame = CGRectMake(i * lw + [self padPadding], padTop + 2, lw - 2 * [self padPadding], padH - 4);
        UILabel *kl = self.keyLabels[i];
        kl.frame = pad.frame;
    }
    self.judgeLine.frame = CGRectMake(0, judgeY, W, 3);
    self.judgeGlow.frame = CGRectMake(0, judgeY - 36, W, 36);
}

- (UILabel *)badgeLabel {
    UILabel *l = [[UILabel alloc] init];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    l.textColor = [JFTheme textPrimary];
    l.font = [JFTheme fontHeadline];
    l.textAlignment = NSTextAlignmentCenter;
    l.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    l.layer.cornerRadius = JFRadiusMedium;
    l.layer.borderWidth = 0.5;
    l.layer.borderColor = [JFTheme cardBorder].CGColor;
    l.clipsToBounds = YES;
    return l;
}

- (UIButton *)primaryButtonWithTitle:(NSString *)t action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = [JFTheme brandPrimary];
    b.layer.cornerRadius = JFRadiusMedium;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textOnAccent] forState:UIControlStateNormal];
    b.titleLabel.font = [JFTheme fontHeadline];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (UIButton *)secondaryButtonWithTitle:(NSString *)t action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    b.layer.cornerRadius = JFRadiusMedium;
    b.layer.borderWidth = 0.5;
    b.layer.borderColor = [JFTheme cardBorder].CGColor;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    b.titleLabel.font = [JFTheme fontHeadline];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)refreshSongLabel {
    if (self.songTitle.length) {
        self.songLabel.text = [NSString stringWithFormat:@"♪ %@", self.songTitle];
    } else {
        self.songLabel.text = @"还没选音乐 —— 点击「导入音乐」开始";
    }
}

#pragma mark - 选音乐 / 分析

- (void)onPickSong {
    if (self.running || self.analyzing) return;
    UIDocumentPickerViewController *picker;
    if (@available(iOS 14.0, *)) {
        NSArray<UTType *> *types = @[ UTTypeAudio, UTTypeMP3, UTTypeMPEG4Audio, UTTypeWAV, UTTypeAIFF ];
        picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:types asCopy:YES];
    } else {
        picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.audio"] inMode:UIDocumentPickerModeImport];
    }
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;

    BOOL secured = [url startAccessingSecurityScopedResource];
    self.securedSongURL = secured ? url : nil;

    self.songTitle = url.lastPathComponent.stringByDeletingPathExtension;
    [self refreshSongLabel];
    self.statusLabel.text = @"正在分析节奏…";
    self.analyzing = YES;
    self.startButton.enabled = NO;

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *err = nil;
        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        [player prepareToPlay];

        // 估算 BPM + 生成谱面
        double bpm = 0;
        NSTimeInterval duration = player ? player.duration : 0;
        NSArray<JFRhythmBeat *> *chart = [weakSelf analyzeChartFromURL:url duration:duration outBPM:&bpm];

        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self_ = weakSelf;
            if (!self_) return;
            self_.analyzing = NO;
            if (!player || err) {
                self_.statusLabel.text = [NSString stringWithFormat:@"无法读取这首歌:%@", err.localizedDescription ?: @"未知错误"];
                return;
            }
            self_.player = player;
            self_.player.delegate = self_;
            self_.player.volume = 1.0;
            self_.songDuration = duration;
            self_.bpm = bpm;
            self_.chart = chart;
            self_.statusLabel.text = [NSString stringWithFormat:@"BPM ≈ %.0f · %ld 个节拍 · 时长 %.0fs",
                                      bpm, (long)chart.count, duration];
            self_.startButton.enabled = YES;
        });
    });
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller { }

#pragma mark - 谱面生成

/// 通过 AVAudioFile 离线读取 PCM 数据,做简易 onset 自相关估算 BPM,然后按节拍均匀生谱。
/// 这里采用"低成本估算":分块计算 RMS,差分得到能量上升;用一组候选 BPM 做能量节拍模板的相关,选最大者。
- (NSArray<JFRhythmBeat *> *)analyzeChartFromURL:(NSURL *)url duration:(NSTimeInterval)duration outBPM:(double *)outBPM {
    NSError *err = nil;
    AVAudioFile *file = [[AVAudioFile alloc] initForReading:url error:&err];
    if (!file || err) {
        if (outBPM) *outBPM = 100;
        return [self fallbackChartWithDuration:duration bpm:100];
    }
    AVAudioFormat *processingFormat = file.processingFormat;
    AVAudioFrameCount totalFrames = (AVAudioFrameCount)file.length;
    if (totalFrames == 0 || processingFormat.sampleRate <= 0) {
        if (outBPM) *outBPM = 100;
        return [self fallbackChartWithDuration:duration bpm:100];
    }

    double sampleRate = processingFormat.sampleRate;
    NSUInteger channels = processingFormat.channelCount;

    // 为避免占用太多内存,分块读取并同时计算每个 hop 的 RMS。
    const NSUInteger hopSize = (NSUInteger)(sampleRate * 0.020);   // 20 ms 一帧 -> 50 fps
    const NSUInteger chunkFrames = MIN((NSUInteger)totalFrames, (NSUInteger)(sampleRate * 5.0)); // 一次最多读 5 秒
    AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:processingFormat frameCapacity:(AVAudioFrameCount)chunkFrames];
    if (!buffer) {
        if (outBPM) *outBPM = 100;
        return [self fallbackChartWithDuration:duration bpm:100];
    }

    NSMutableArray<NSNumber *> *envelope = [NSMutableArray array];
    NSUInteger sampleCarry = 0;
    double accSquare = 0;
    NSUInteger framesRead = 0;

    while (framesRead < totalFrames) {
        AVAudioFrameCount want = (AVAudioFrameCount)MIN(chunkFrames, totalFrames - framesRead);
        buffer.frameLength = 0;
        @try {
            BOOL ok = [file readIntoBuffer:buffer frameCount:want error:&err];
            if (!ok || err) break;
        } @catch (NSException *e) {
            break;
        }
        AVAudioFrameCount got = buffer.frameLength;
        if (got == 0) break;

        // 取 float channel data 求平方和
        float **chanData = buffer.floatChannelData;
        if (!chanData) break;
        for (AVAudioFrameCount i = 0; i < got; i++) {
            float s = 0;
            for (NSUInteger c = 0; c < channels; c++) s += chanData[c][i];
            s /= MAX(1u, (unsigned)channels);
            accSquare += (double)(s * s);
            sampleCarry++;
            if (sampleCarry >= hopSize) {
                double rms = sqrt(accSquare / sampleCarry);
                [envelope addObject:@(rms)];
                accSquare = 0;
                sampleCarry = 0;
            }
        }
        framesRead += got;
        if (got < want) break;
    }
    if (envelope.count < 32) {
        if (outBPM) *outBPM = 100;
        return [self fallbackChartWithDuration:duration bpm:100];
    }

    // 一阶差分(只保留能量上升部分)作为简单的 onset 强度
    NSMutableArray<NSNumber *> *onset = [NSMutableArray arrayWithCapacity:envelope.count];
    [onset addObject:@(0)];
    for (NSUInteger i = 1; i < envelope.count; i++) {
        double d = [envelope[i] doubleValue] - [envelope[i - 1] doubleValue];
        if (d < 0) d = 0;
        [onset addObject:@(d)];
    }

    // 用一组候选 BPM 做"加权和"评分,选分数最高者。每帧 = 0.020s -> framesPerBeat = 60 / bpm / 0.020
    double bestScore = -1;
    double bestBPM   = 100;
    for (double bpm = 70; bpm <= 180; bpm += 1.0) {
        double framesPerBeat = 60.0 / bpm / 0.020;
        if (framesPerBeat < 4) continue;
        // 累加每个候选节拍位置上的 onset 能量;尝试 16 个相位,取相位最大值
        double bestPhaseSum = 0;
        for (NSInteger phase = 0; phase < (NSInteger)framesPerBeat; phase += MAX(1, (NSInteger)(framesPerBeat / 16))) {
            double sum = 0;
            for (double f = phase; f < envelope.count; f += framesPerBeat) {
                NSInteger idx = (NSInteger)f;
                if (idx >= 0 && idx < (NSInteger)onset.count) sum += [onset[idx] doubleValue];
            }
            if (sum > bestPhaseSum) bestPhaseSum = sum;
        }
        // 略微抑制非常高/非常低的 BPM
        double penalty = 1.0;
        if (bpm < 80 || bpm > 160) penalty = 0.92;
        double score = bestPhaseSum * penalty;
        if (score > bestScore) {
            bestScore = score;
            bestBPM = bpm;
        }
    }
    if (outBPM) *outBPM = bestBPM;

    // 找到最佳相位(beat 起点)
    double framesPerBeat = 60.0 / bestBPM / 0.020;
    NSInteger bestPhase = 0;
    double bestPhaseSum = -1;
    for (NSInteger phase = 0; phase < (NSInteger)framesPerBeat; phase++) {
        double sum = 0;
        for (double f = phase; f < envelope.count; f += framesPerBeat) {
            NSInteger idx = (NSInteger)f;
            if (idx >= 0 && idx < (NSInteger)onset.count) sum += [onset[idx] doubleValue];
        }
        if (sum > bestPhaseSum) { bestPhaseSum = sum; bestPhase = phase; }
    }

    // 等距生谱:1/4 拍间隔(节奏点点)以及随机分配轨道,但相邻不重轨。
    double secPerBeat = 60.0 / bestBPM;
    double step = secPerBeat / 2.0;            // 八分音符密度
    NSTimeInterval startTime = bestPhase * 0.020;
    NSMutableArray<JFRhythmBeat *> *chart = [NSMutableArray array];
    NSInteger lastLane = -1;
    NSInteger seed = (NSInteger)(framesPerBeat * 31 + envelope.count);
    NSInteger r = seed;
    for (NSTimeInterval t = startTime; t < duration - 0.6; t += step) {
        if (t < 0.5) continue;   // 给玩家一点准备时间
        // 简易 PRNG —— 让分布稳定但不千篇一律
        r = (r * 1103515245 + 12345) & 0x7FFFFFFF;
        NSInteger lane = r % kLanes;
        if (lane == lastLane) lane = (lane + 1) % kLanes;
        lastLane = lane;
        JFRhythmBeat *b = [[JFRhythmBeat alloc] init];
        b.time = t;
        b.lane = lane;
        [chart addObject:b];
    }
    if (chart.count == 0) {
        return [self fallbackChartWithDuration:duration bpm:bestBPM];
    }
    return chart;
}

- (NSArray<JFRhythmBeat *> *)fallbackChartWithDuration:(NSTimeInterval)duration bpm:(double)bpm {
    if (duration <= 0) duration = 60;
    double step = 60.0 / MAX(60.0, bpm) / 2.0;
    NSMutableArray<JFRhythmBeat *> *chart = [NSMutableArray array];
    NSInteger lastLane = -1;
    NSInteger r = 0xC0FFEE;
    for (NSTimeInterval t = 1.0; t < duration - 0.6; t += step) {
        r = (r * 1103515245 + 12345) & 0x7FFFFFFF;
        NSInteger lane = r % kLanes;
        if (lane == lastLane) lane = (lane + 1) % kLanes;
        lastLane = lane;
        JFRhythmBeat *b = [[JFRhythmBeat alloc] init];
        b.time = t;
        b.lane = lane;
        [chart addObject:b];
    }
    return chart;
}

#pragma mark - 游戏流程

- (void)onStart {
    if (self.running || self.analyzing) return;
    if (!self.player || !self.chart.count) {
        self.statusLabel.text = @"先导入一首音乐再开始吧 ♪";
        return;
    }
    self.running = YES;
    self.score = 0;
    self.combo = 0;
    self.maxCombo = 0;
    [self.notes removeAllObjects];
    self.pendingBeats = [self.chart mutableCopy];
    self.startButton.enabled = NO;
    self.pickButton.enabled = NO;
    [self.startButton setTitle:@"游戏中..." forState:UIControlStateNormal];
    [self updateLabels];

    [self.player setCurrentTime:0];
    [self.player play];

    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(onTick)];
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopAndCleanup {
    [self stopRunning];
    if (self.player.isPlaying) [self.player stop];
    if (self.securedSongURL) {
        [self.securedSongURL stopAccessingSecurityScopedResource];
        self.securedSongURL = nil;
    }
}

- (void)stopRunning {
    if (!self.running) return;
    self.running = NO;
    [self.link invalidate];
    self.link = nil;
    for (JFRhythmNote *n in self.notes) [n.view removeFromSuperview];
    [self.notes removeAllObjects];
    self.pickButton.enabled = YES;
    self.startButton.enabled = YES;
    [self.startButton setTitle:@"再来一次" forState:UIControlStateNormal];

    if (self.score > self.best) {
        self.best = self.score;
        [[NSUserDefaults standardUserDefaults] setInteger:self.best forKey:kBestKey];
    }
    JFGameResult *r = [JFGameResult resultWithKind:JFGameKindRhythm score:self.score win:YES];
    r.duration = self.songDuration;
    r.extra = @{@"maxCombo": @(self.maxCombo),
                @"bpm": @(self.bpm),
                @"song": self.songTitle ?: @""};
    [[JFProfileStore shared] reportResult:r];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindRhythm difficulty:0 score:self.score win:(self.maxCombo >= 30)];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (!self.running) return;
    // 让画面再走 1 秒让最后的音符消化完
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self stopRunning];
    });
}

#pragma mark - 主循环

- (void)onTick {
    if (!self.running) return;
    NSTimeInterval songTime = self.player.currentTime;
    NSTimeInterval remain = self.songDuration - songTime;
    if (remain < 0) remain = 0;
    self.timeLabel.text = [NSString stringWithFormat:@"%.0fs", remain];

    // spawn 即将到来的 beat:在到达判定线前 fallDuration 秒生成
    while (self.pendingBeats.count > 0) {
        JFRhythmBeat *b = self.pendingBeats.firstObject;
        if (b.time - songTime <= self.fallDuration) {
            JFRhythmNote *n = [[JFRhythmNote alloc] init];
            n.lane = b.lane;
            n.targetTime = b.time;
            UIView *v = [[UIView alloc] init];
            v.backgroundColor = [JFTheme brandPrimary];
            v.layer.cornerRadius = 10;
            v.layer.shadowColor = [JFTheme accent].CGColor;
            v.layer.shadowOpacity = 0.7;
            v.layer.shadowRadius = 8;
            v.layer.shadowOffset = CGSizeZero;
            v.userInteractionEnabled = NO;
            n.view = v;
            n.spawned = YES;
            [self.track addSubview:v];
            [self.notes addObject:n];
            [self.pendingBeats removeObjectAtIndex:0];
        } else {
            break;
        }
    }

    [self updateNotes:songTime];

    if (!self.player.isPlaying && self.pendingBeats.count == 0 && self.notes.count == 0) {
        [self stopRunning];
    }
}

- (void)updateNotes:(NSTimeInterval)songTime {
    CGFloat W = self.track.bounds.size.width;
    CGFloat lw = W / kLanes;
    CGFloat judgeY = [self judgeY];
    NSMutableArray *toRemove = [NSMutableArray array];

    for (JFRhythmNote *n in self.notes) {
        if (n.hit) {
            [n.view removeFromSuperview];
            [toRemove addObject:n];
            continue;
        }
        // progress: 0 = 在屏顶,1 = 到达判定线
        NSTimeInterval delta = songTime - (n.targetTime - self.fallDuration);
        CGFloat progress = (CGFloat)(delta / self.fallDuration);
        // 漏过判定线 0.35 秒以上 -> miss
        if (progress > 1.35) {
            n.hit = YES;
            [self animateMissAt:n];
            [toRemove addObject:n];
            self.combo = 0;
            [self updateLabels];
            continue;
        }
        if (progress < -0.05) {
            // 还没到该出现的时候(理论上不会触发,因为 onTick 控制 spawn)
            continue;
        }
        CGFloat noteH = 40;
        CGFloat y = -noteH + (judgeY + noteH) * progress;
        n.view.frame = CGRectMake(n.lane * lw + 14, y, lw - 28, noteH);
    }
    [self.notes removeObjectsInArray:toRemove];
}

- (void)animateMissAt:(JFRhythmNote *)n {
    UIView *v = n.view;
    [UIView animateWithDuration:0.25 animations:^{
        v.alpha = 0;
        v.transform = CGAffineTransformMakeScale(0.6, 0.6);
    } completion:^(BOOL finished) { [v removeFromSuperview]; }];
}

#pragma mark - 按键板交互

- (void)onPadDown:(UIButton *)b {
    NSInteger lane = b.tag;
    [self animatePadDown:b];
    if (!self.running) return;
    [self tryHitLane:lane];
}

- (void)onPadUp:(UIButton *)b {
    [self animatePadUp:b];
}

- (void)animatePadDown:(UIButton *)b {
    [UIView animateWithDuration:0.06 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        b.transform = CGAffineTransformMakeScale(0.92, 0.92);
        b.backgroundColor = [b.backgroundColor colorWithAlphaComponent:0.45];
    } completion:nil];
}

- (void)animatePadUp:(UIButton *)b {
    [UIView animateWithDuration:0.18 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.7 options:UIViewAnimationOptionCurveEaseOut animations:^{
        b.transform = CGAffineTransformIdentity;
        b.backgroundColor = [b.backgroundColor colorWithAlphaComponent:0.18];
    } completion:nil];
}

- (void)tryHitLane:(NSInteger)lane {
    JFRhythmNote *best = nil;
    CGFloat bestDist = CGFLOAT_MAX;
    NSTimeInterval songTime = self.player.currentTime;
    CGFloat judgeY = [self judgeY];
    for (JFRhythmNote *n in self.notes) {
        if (n.lane != lane || n.hit) continue;
        NSTimeInterval delta = songTime - (n.targetTime - self.fallDuration);
        CGFloat progress = (CGFloat)(delta / self.fallDuration);
        if (progress < 0.4 || progress > 1.25) continue;
        CGFloat noteCenterY = -20 + (judgeY + 40) * progress + 20;
        CGFloat d = fabs(noteCenterY - judgeY);
        if (d < bestDist) {
            bestDist = d;
            best = n;
        }
    }
    if (best) {
        best.hit = YES;
        NSInteger pts;
        NSString *grade;
        UIColor *flashColor;
        if (bestDist < 30)      { pts = 120; grade = @"PERFECT"; flashColor = [UIColor colorWithRed:1 green:0.84 blue:0.32 alpha:1]; }
        else if (bestDist < 80) { pts = 80;  grade = @"GREAT";   flashColor = [JFTheme accent]; }
        else                    { pts = 40;  grade = @"GOOD";    flashColor = [UIColor colorWithWhite:1 alpha:0.85]; }
        self.score += pts + self.combo / 5;
        self.combo += 1;
        if (self.combo > self.maxCombo) self.maxCombo = self.combo;
        [JFTheme hapticImpactLight];
        [self animateHit:best grade:grade color:flashColor];
        [self animateComboPop];
        [self updateLabels];
    } else {
        if (self.combo > 0) {
            self.combo = 0;
            [self updateLabels];
        }
        UIButton *pad = self.keyPads[lane];
        CAKeyframeAnimation *shake = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
        shake.values = @[@(-4), @(4), @(-3), @(3), @(0)];
        shake.duration = 0.18;
        [pad.layer addAnimation:shake forKey:@"jfPadShake"];
    }
}

- (void)animateHit:(JFRhythmNote *)n grade:(NSString *)grade color:(UIColor *)color {
    UIView *v = n.view;
    CGRect frame = v.frame;
    CGFloat centerX = CGRectGetMidX(frame);
    CGFloat judgeY = [self judgeY];

    [UIView animateWithDuration:0.28 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        v.alpha = 0;
        v.transform = CGAffineTransformMakeScale(1.6, 1.6);
    } completion:^(BOOL finished) {
        [v removeFromSuperview];
    }];

    UIView *ring = [[UIView alloc] initWithFrame:CGRectMake(centerX - 22, judgeY - 22, 44, 44)];
    ring.backgroundColor = [UIColor clearColor];
    ring.layer.borderWidth = 3;
    ring.layer.borderColor = color.CGColor;
    ring.layer.cornerRadius = 22;
    ring.userInteractionEnabled = NO;
    [self.track addSubview:ring];
    [UIView animateWithDuration:0.45 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        ring.transform = CGAffineTransformMakeScale(2.8, 2.8);
        ring.alpha = 0;
    } completion:^(BOOL finished) { [ring removeFromSuperview]; }];

    UILabel *gl = [[UILabel alloc] init];
    gl.text = grade;
    gl.textColor = color;
    gl.font = [UIFont systemFontOfSize:18 weight:UIFontWeightHeavy];
    gl.textAlignment = NSTextAlignmentCenter;
    gl.userInteractionEnabled = NO;
    gl.frame = CGRectMake(centerX - 60, judgeY - 36, 120, 24);
    [self.track addSubview:gl];
    [UIView animateWithDuration:0.55 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        gl.transform = CGAffineTransformMakeTranslation(0, -38);
        gl.alpha = 0;
    } completion:^(BOOL finished) { [gl removeFromSuperview]; }];
}

- (void)animateComboPop {
    self.comboLabel.transform = CGAffineTransformMakeScale(1.0, 1.0);
    [UIView animateWithDuration:0.12 animations:^{
        self.comboLabel.transform = CGAffineTransformMakeScale(1.18, 1.18);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.18 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.comboLabel.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}

- (void)updateLabels {
    self.scoreLabel.text = [NSString stringWithFormat:@"%ld", (long)self.score];
    self.comboLabel.text = [NSString stringWithFormat:@"Combo %ld", (long)self.combo];
}

@end
