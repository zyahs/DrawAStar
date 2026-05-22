//
//  JFRhythmSong.m
//

#import "JFRhythmSong.h"

#pragma mark - JFRhythmChart 难度抽稀

@implementation JFRhythmChart

+ (NSString *)nameOfDifficulty:(JFRhythmDifficulty)d {
    switch (d) {
        case JFRhythmDifficultyEasy:   return @"简单";
        case JFRhythmDifficultyMedium: return @"中等";
        case JFRhythmDifficultyHard:   return @"困难";
    }
    return @"中等";
}

+ (NSString *)keyOfDifficulty:(JFRhythmDifficulty)d {
    switch (d) {
        case JFRhythmDifficultyEasy:   return @"easy";
        case JFRhythmDifficultyMedium: return @"medium";
        case JFRhythmDifficultyHard:   return @"hard";
    }
    return @"medium";
}

+ (NSArray<JFRhythmBeat *> *)chartFromFull:(NSArray<JFRhythmBeat *> *)full
                                difficulty:(JFRhythmDifficulty)d {
    if (full.count == 0) return @[];

    NSTimeInterval minGap;
    double minStrength;
    NSInteger maxRun;
    switch (d) {
        case JFRhythmDifficultyEasy:   minGap = 0.36; minStrength = 0.40; maxRun = 2; break;
        case JFRhythmDifficultyMedium: minGap = 0.22; minStrength = 0.28; maxRun = 3; break;
        case JFRhythmDifficultyHard:   minGap = 0.15; minStrength = 0.15; maxRun = 4; break;
        default:                        minGap = 0.22; minStrength = 0.28; maxRun = 3; break;
    }

    // 1) 时间排序
    NSArray<JFRhythmBeat *> *sorted = [full sortedArrayUsingComparator:^NSComparisonResult(JFRhythmBeat *a, JFRhythmBeat *b) {
        if (a.time < b.time) return NSOrderedAscending;
        if (a.time > b.time) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    // 2) 间距+强度过滤,同时打散同 lane 连击
    NSMutableArray<JFRhythmBeat *> *out = [NSMutableArray array];
    NSTimeInterval lastTime = -1000;
    NSInteger lastLane = -1;
    NSInteger runCount = 0;
    NSInteger laneRotator = 0;
    for (JFRhythmBeat *b in sorted) {
        if (b.strength < minStrength) continue;
        if (b.time - lastTime < minGap) continue;
        NSInteger lane = b.lane;
        if (lane < 0) lane = 0;
        if (lane > 3) lane = 3;

        if (lane == lastLane && runCount >= maxRun) {
            // 同 lane 已经连续 maxRun 次 —— 强制换 lane
            laneRotator = (laneRotator + 1) % 4;
            if (laneRotator == lane) laneRotator = (laneRotator + 1) % 4;
            lane = laneRotator;
            runCount = 1;
        } else if (lane == lastLane) {
            runCount += 1;
        } else {
            runCount = 1;
        }

        JFRhythmBeat *nb = [JFRhythmBeat beatAt:b.time lane:lane strength:b.strength];
        [out addObject:nb];
        lastTime = b.time;
        lastLane = lane;
    }

    // 3) 简单/中等下:如果谱面密度仍然偏高(平均间距 < minGap),再做一遍稀疏
    if (out.count > 30) {
        NSTimeInterval span = out.lastObject.time - out.firstObject.time;
        if (span > 1) {
            double avgGap = span / (double)(out.count - 1);
            if (avgGap < minGap * 0.85) {
                NSMutableArray<JFRhythmBeat *> *fb = [NSMutableArray array];
                NSTimeInterval lt = -1000;
                NSInteger ll = -1;
                NSInteger rc = 0;
                NSInteger rot = 0;
                NSTimeInterval tightGap = minGap * 1.1;
                for (JFRhythmBeat *b in out) {
                    if (b.time - lt < tightGap) continue;
                    NSInteger lane = b.lane;
                    if (lane == ll && rc >= maxRun) {
                        rot = (rot + 1) % 4;
                        if (rot == lane) rot = (rot + 1) % 4;
                        lane = rot;
                        rc = 1;
                    } else if (lane == ll) {
                        rc += 1;
                    } else {
                        rc = 1;
                    }
                    [fb addObject:[JFRhythmBeat beatAt:b.time lane:lane strength:b.strength]];
                    lt = b.time;
                    ll = lane;
                }
                if (fb.count >= 8) return fb;
            }
        }
    }
    return out;
}

@end


@implementation JFRhythmBeat

+ (BOOL)supportsSecureCoding { return YES; }

+ (instancetype)beatAt:(NSTimeInterval)t lane:(NSInteger)lane strength:(double)s {
    JFRhythmBeat *b = [[self alloc] init];
    b.time = t;
    b.lane = lane;
    b.strength = s;
    return b;
}

- (instancetype)init {
    if ((self = [super init])) {
        _strength = 0.5;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)c {
    [c encodeDouble:_time     forKey:@"t"];
    [c encodeInteger:_lane    forKey:@"l"];
    [c encodeDouble:_strength forKey:@"s"];
}

- (instancetype)initWithCoder:(NSCoder *)c {
    if ((self = [super init])) {
        _time = [c decodeDoubleForKey:@"t"];
        _lane = [c decodeIntegerForKey:@"l"];
        _strength = [c decodeDoubleForKey:@"s"];
        if (_strength <= 0) _strength = 0.5;
    }
    return self;
}

@end


@implementation JFRhythmSong

+ (BOOL)supportsSecureCoding { return YES; }

- (NSURL *)audioURLInDocuments {
    if (self.kind != JFRhythmSongKindUserImport) return nil;
    if (!self.audioFileName.length) return nil;
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *dir = [docs stringByAppendingPathComponent:@"RhythmSongs"];
    return [NSURL fileURLWithPath:[dir stringByAppendingPathComponent:self.audioFileName]];
}

- (NSURL *)playableAudioURL {
    if (self.kind == JFRhythmSongKindUserImport) {
        return [self audioURLInDocuments];
    }
    if (!self.bundleAudioName.length) return nil;
    NSBundle *bundle = [NSBundle mainBundle];
    // bundleAudioName 现在存的是相对 bundle resourcePath 的相对路径(可带子目录)
    NSString *full = [bundle.resourcePath stringByAppendingPathComponent:self.bundleAudioName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:full]) {
        return [NSURL fileURLWithPath:full];
    }
    // 回退:把它当裸文件名,在常见位置找
    NSString *base = self.bundleAudioName.lastPathComponent.stringByDeletingPathExtension;
    NSString *ext  = self.bundleAudioName.pathExtension.length ? self.bundleAudioName.pathExtension : @"mp3";
    NSString *path = [bundle pathForResource:base ofType:ext inDirectory:@"Music"];
    if (!path) path = [bundle pathForResource:base ofType:ext];
    if (!path) return nil;
    return [NSURL fileURLWithPath:path];
}

- (void)encodeWithCoder:(NSCoder *)c {
    [c encodeInteger:_kind forKey:@"k"];
    [c encodeObject:_songId forKey:@"id"];
    [c encodeObject:_title forKey:@"t"];
    [c encodeObject:_artist forKey:@"a"];
    [c encodeObject:_audioFileName forKey:@"f"];
    [c encodeObject:_bundleAudioName forKey:@"bf"];
    [c encodeDouble:_duration forKey:@"d"];
    [c encodeDouble:_bpm forKey:@"b"];
    [c encodeObject:_chart forKey:@"c"];
    [c encodeObject:_fullChart forKey:@"fc"];
    [c encodeObject:_importedAt forKey:@"at"];
}

- (instancetype)initWithCoder:(NSCoder *)c {
    if ((self = [super init])) {
        _kind = [c decodeIntegerForKey:@"k"];
        _songId = [c decodeObjectOfClass:NSString.class forKey:@"id"];
        _title = [c decodeObjectOfClass:NSString.class forKey:@"t"];
        _artist = [c decodeObjectOfClass:NSString.class forKey:@"a"];
        _audioFileName = [c decodeObjectOfClass:NSString.class forKey:@"f"];
        _bundleAudioName = [c decodeObjectOfClass:NSString.class forKey:@"bf"];
        _duration = [c decodeDoubleForKey:@"d"];
        _bpm = [c decodeDoubleForKey:@"b"];
        NSSet *cls = [NSSet setWithObjects:NSArray.class, JFRhythmBeat.class, nil];
        _chart = [c decodeObjectOfClasses:cls forKey:@"c"];
        _fullChart = [c decodeObjectOfClasses:cls forKey:@"fc"];
        _importedAt = [c decodeObjectOfClass:NSDate.class forKey:@"at"];
    }
    return self;
}

@end
