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

    BOOL authoredChart = NO;
    for (JFRhythmBeat *beat in full) {
        if (beat.minimumDifficulty >= 0) {
            authoredChart = YES;
            break;
        }
    }

    if (authoredChart) {
        NSMutableArray<JFRhythmBeat *> *authored = [NSMutableArray array];
        for (JFRhythmBeat *beat in full) {
            NSInteger minimum = MAX(0, beat.minimumDifficulty);
            if (minimum > d) continue;
            JFRhythmBeat *copy = [JFRhythmBeat beatAt:beat.time
                                                lane:MAX(0, MIN(3, beat.lane))
                                            strength:beat.strength
                                                type:beat.type
                                            duration:beat.duration
                                             endLane:MAX(0, MIN(3, beat.endLane))];
            copy.minimumDifficulty = beat.minimumDifficulty;
            [authored addObject:copy];
        }
        return [authored sortedArrayUsingComparator:^NSComparisonResult(JFRhythmBeat *a, JFRhythmBeat *b) {
            if (a.time < b.time) return NSOrderedAscending;
            if (a.time > b.time) return NSOrderedDescending;
            if (a.lane < b.lane) return NSOrderedAscending;
            if (a.lane > b.lane) return NSOrderedDescending;
            return NSOrderedSame;
        }];
    }

    NSTimeInterval minGap;
    double minStrength;
    NSInteger maxRun;
    switch (d) {
        case JFRhythmDifficultyEasy:   minGap = 0.44; minStrength = 0.44; maxRun = 2; break;
        case JFRhythmDifficultyMedium: minGap = 0.30; minStrength = 0.32; maxRun = 2; break;
        case JFRhythmDifficultyHard:   minGap = 0.22; minStrength = 0.20; maxRun = 3; break;
        default:                        minGap = 0.30; minStrength = 0.32; maxRun = 2; break;
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
        BOOL actionNote = (b.type != JFRhythmBeatTypeTap);
        if (b.strength < minStrength && !actionNote) continue;
        if (!actionNote && b.time - lastTime < minGap) continue;
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
        nb.type = b.type;
        nb.duration = b.duration;
        nb.endLane = b.endLane;
        nb.minimumDifficulty = b.minimumDifficulty;
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
                    BOOL actionNote = (b.type != JFRhythmBeatTypeTap);
                    if (!actionNote && b.time - lt < tightGap) continue;
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
                    JFRhythmBeat *nb = [JFRhythmBeat beatAt:b.time lane:lane strength:b.strength];
                    nb.type = b.type;
                    nb.duration = b.duration;
                    nb.endLane = b.endLane;
                    nb.minimumDifficulty = b.minimumDifficulty;
                    [fb addObject:nb];
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
    return [self beatAt:t lane:lane strength:s type:JFRhythmBeatTypeTap duration:0 endLane:lane];
}

+ (instancetype)beatAt:(NSTimeInterval)t lane:(NSInteger)lane strength:(double)s type:(JFRhythmBeatType)type duration:(NSTimeInterval)duration endLane:(NSInteger)endLane {
    JFRhythmBeat *b = [[self alloc] init];
    b.time = t;
    b.lane = lane;
    b.strength = s;
    b.type = type;
    b.duration = MAX(0, duration);
    b.endLane = endLane;
    return b;
}

- (instancetype)init {
    if ((self = [super init])) {
        _strength = 0.5;
        _type = JFRhythmBeatTypeTap;
        _endLane = 0;
        _minimumDifficulty = -1;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)c {
    [c encodeDouble:_time     forKey:@"t"];
    [c encodeInteger:_lane    forKey:@"l"];
    [c encodeInteger:_endLane forKey:@"el"];
    [c encodeDouble:_duration forKey:@"du"];
    [c encodeDouble:_strength forKey:@"s"];
    [c encodeInteger:_type    forKey:@"ty"];
    [c encodeInteger:_minimumDifficulty forKey:@"md"];
}

- (instancetype)initWithCoder:(NSCoder *)c {
    if ((self = [super init])) {
        _time = [c decodeDoubleForKey:@"t"];
        _lane = [c decodeIntegerForKey:@"l"];
        _endLane = [c containsValueForKey:@"el"] ? [c decodeIntegerForKey:@"el"] : _lane;
        _duration = [c containsValueForKey:@"du"] ? [c decodeDoubleForKey:@"du"] : 0;
        _strength = [c decodeDoubleForKey:@"s"];
        _type = [c containsValueForKey:@"ty"] ? [c decodeIntegerForKey:@"ty"] : JFRhythmBeatTypeTap;
        _minimumDifficulty = [c containsValueForKey:@"md"] ? [c decodeIntegerForKey:@"md"] : -1;
        if (_strength <= 0) _strength = 0.5;
        if (_endLane < 0 || _endLane > 3) _endLane = _lane;
        if (_type < JFRhythmBeatTypeTap || _type > JFRhythmBeatTypeSlide) _type = JFRhythmBeatTypeTap;
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
    [c encodeBool:_tutorial forKey:@"tu"];
    [c encodeObject:_tutorialSteps forKey:@"ts"];
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
        _tutorial = [c containsValueForKey:@"tu"] ? [c decodeBoolForKey:@"tu"] : NO;
        NSSet *stepClasses = [NSSet setWithObjects:NSArray.class, NSDictionary.class, NSString.class, NSNumber.class, nil];
        _tutorialSteps = [c containsValueForKey:@"ts"] ? [c decodeObjectOfClasses:stepClasses forKey:@"ts"] : @[];
        if (!_tutorialSteps) _tutorialSteps = @[];
    }
    return self;
}

@end
