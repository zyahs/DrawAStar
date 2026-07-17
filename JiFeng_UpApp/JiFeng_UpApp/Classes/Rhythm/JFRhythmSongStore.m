//
//  JFRhythmSongStore.m
//

#import "JFRhythmSongStore.h"
#import "JFRhythmAnalyzer.h"
#import <AVFoundation/AVFoundation.h>

static NSString *const kArchiveName = @"jf_rhythm_library.archive";
static NSString *const kAudioDirName = @"RhythmSongs";
static NSString *const kPresetCacheName = @"jf_rhythm_preset_cache.archive";
static NSString *const kPresetChartVersion = @"chart-v10-repeatable-tutorial";
static NSString *const kChartSchema = @"jifeng-rhythm-chart-v1";

static NSDictionary<NSString *, NSDictionary *> *JFLoadBundledChartManifests(NSBundle *bundle) {
    NSMutableOrderedSet<NSString *> *paths = [NSMutableOrderedSet orderedSet];
    [paths addObjectsFromArray:[bundle pathsForResourcesOfType:@"json" inDirectory:nil] ?: @[]];

    NSString *chartDirectory = [bundle.resourcePath stringByAppendingPathComponent:@"Music/Charts"];
    for (NSString *fileName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:chartDirectory error:nil] ?: @[]) {
        if (![fileName.pathExtension.lowercaseString isEqualToString:@"json"]) continue;
        [paths addObject:[chartDirectory stringByAppendingPathComponent:fileName]];
    }

    NSMutableDictionary<NSString *, NSDictionary *> *manifests = [NSMutableDictionary dictionary];
    for (NSString *path in paths) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (!data) continue;
        NSDictionary *manifest = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (![manifest isKindOfClass:NSDictionary.class]) continue;
        if (![manifest[@"schema"] isEqual:kChartSchema]) continue;
        NSString *audio = [manifest[@"audio"] isKindOfClass:NSString.class] ? manifest[@"audio"] : nil;
        if (!audio.length) continue;
        manifests[audio.lastPathComponent.lowercaseString] = manifest;
    }
    return manifests;
}

static NSArray<JFRhythmBeat *> *JFBeatsFromManifest(NSDictionary *manifest, NSTimeInterval songDuration) {
    NSArray *rawNotes = [manifest[@"notes"] isKindOfClass:NSArray.class] ? manifest[@"notes"] : @[];
    NSMutableArray<JFRhythmBeat *> *beats = [NSMutableArray arrayWithCapacity:rawNotes.count];
    for (NSDictionary *raw in rawNotes) {
        if (![raw isKindOfClass:NSDictionary.class]) continue;
        NSTimeInterval time = [raw[@"t"] doubleValue];
        NSTimeInterval duration = MAX(0, [raw[@"duration"] doubleValue]);
        if (time < 0.2 || time + duration > songDuration - 0.15) continue;
        NSInteger lane = MAX(0, MIN(3, [raw[@"lane"] integerValue]));
        NSInteger endLane = raw[@"endLane"] ? MAX(0, MIN(3, [raw[@"endLane"] integerValue])) : lane;
        NSString *typeName = [raw[@"type"] isKindOfClass:NSString.class] ? raw[@"type"] : @"tap";
        JFRhythmBeatType type = JFRhythmBeatTypeTap;
        if ([typeName isEqualToString:@"hold"]) type = JFRhythmBeatTypeHold;
        else if ([typeName isEqualToString:@"slide"]) type = JFRhythmBeatTypeSlide;
        if (type != JFRhythmBeatTypeTap && duration < 0.18) continue;
        double strength = raw[@"strength"] ? MAX(0.25, MIN(1.0, [raw[@"strength"] doubleValue])) : 0.72;
        JFRhythmBeat *beat = [JFRhythmBeat beatAt:time lane:lane strength:strength type:type duration:duration endLane:endLane];
        beat.minimumDifficulty = MAX(0, MIN(2, [raw[@"level"] integerValue]));
        [beats addObject:beat];
    }
    return [beats sortedArrayUsingComparator:^NSComparisonResult(JFRhythmBeat *a, JFRhythmBeat *b) {
        if (a.time < b.time) return NSOrderedAscending;
        if (a.time > b.time) return NSOrderedDescending;
        if (a.lane < b.lane) return NSOrderedAscending;
        if (a.lane > b.lane) return NSOrderedDescending;
        return NSOrderedSame;
    }];
}

static NSArray<NSDictionary *> *JFTutorialStepsFromManifest(NSDictionary *manifest, NSTimeInterval songDuration) {
    NSArray *rawSteps = [manifest[@"tutorialSteps"] isKindOfClass:NSArray.class] ? manifest[@"tutorialSteps"] : @[];
    NSMutableArray<NSDictionary *> *steps = [NSMutableArray arrayWithCapacity:rawSteps.count];
    for (NSDictionary *raw in rawSteps) {
        if (![raw isKindOfClass:NSDictionary.class]) continue;
        NSTimeInterval from = MAX(0, [raw[@"from"] doubleValue]);
        NSTimeInterval to = MIN(songDuration, [raw[@"to"] doubleValue]);
        NSString *title = [raw[@"title"] isKindOfClass:NSString.class] ? raw[@"title"] : @"跟随节奏";
        NSString *detail = [raw[@"detail"] isKindOfClass:NSString.class] ? raw[@"detail"] : @"看准判定线完成动作";
        NSString *icon = [raw[@"icon"] isKindOfClass:NSString.class] ? raw[@"icon"] : @"sparkles";
        if (to <= from || title.length == 0 || detail.length == 0) continue;
        [steps addObject:@{ @"from": @(from), @"to": @(to), @"title": title, @"detail": detail, @"icon": icon }];
    }
    return [steps sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[@"from"] compare:b[@"from"]];
    }];
}

@interface JFRhythmSongStore ()
@property (nonatomic, strong) NSMutableArray<JFRhythmSong *> *userSongsInternal;
@property (nonatomic, strong) NSArray<JFRhythmSong *> *presetSongsInternal;
@end

@implementation JFRhythmSongStore

+ (instancetype)shared {
    static JFRhythmSongStore *s = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[self alloc] init]; });
    return s;
}

- (instancetype)init {
    if ((self = [super init])) {
        [self ensureAudioDir];
        [self loadFromDisk];
        _presetSongsInternal = [self buildPresets];
    }
    return self;
}

#pragma mark - 路径

- (NSString *)libraryDir {
    NSString *p = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    return p;
}

- (NSString *)archivePath {
    return [self.libraryDir stringByAppendingPathComponent:kArchiveName];
}

- (NSString *)audioDir {
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [docs stringByAppendingPathComponent:kAudioDirName];
}

- (void)ensureAudioDir {
    NSString *dir = [self audioDir];
    if (![NSFileManager.defaultManager fileExistsAtPath:dir]) {
        [NSFileManager.defaultManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark - 持久化

- (void)loadFromDisk {
    self.userSongsInternal = [NSMutableArray array];
    NSData *data = [NSData dataWithContentsOfFile:[self archivePath]];
    if (!data) return;
    NSError *err = nil;
    NSSet *cls = [NSSet setWithObjects:NSArray.class, NSDictionary.class, JFRhythmSong.class, JFRhythmBeat.class, NSDate.class, NSString.class, NSNumber.class, nil];
    NSArray *arr = [NSKeyedUnarchiver unarchivedObjectOfClasses:cls fromData:data error:&err];
    if ([arr isKindOfClass:NSArray.class]) {
        for (id obj in arr) if ([obj isKindOfClass:JFRhythmSong.class]) [self.userSongsInternal addObject:obj];
    }
}

- (void)saveToDisk {
    NSError *err = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.userSongsInternal requiringSecureCoding:YES error:&err];
    if (data) {
        [data writeToFile:[self archivePath] atomically:YES];
    }
}

#pragma mark - 公共 API

- (NSArray<JFRhythmSong *> *)allSongs {
    NSMutableArray *all = [NSMutableArray arrayWithArray:self.presetSongsInternal];
    NSArray *us = [self userSongs];
    [all addObjectsFromArray:us];
    return [all copy];
}

- (NSArray<JFRhythmSong *> *)userSongs {
    return [self.userSongsInternal sortedArrayUsingComparator:^NSComparisonResult(JFRhythmSong *a, JFRhythmSong *b) {
        NSDate *da = a.importedAt ?: NSDate.distantPast;
        NSDate *db = b.importedAt ?: NSDate.distantPast;
        return [db compare:da];
    }];
}

- (NSArray<JFRhythmSong *> *)presetSongs { return self.presetSongsInternal; }

- (nullable NSURL *)copyImportedAudioFromURL:(NSURL *)src
                                 outFileName:(NSString * _Nullable * _Nullable)outName
                                       error:(NSError * _Nullable * _Nullable)error {
    [self ensureAudioDir];
    NSString *ext = src.pathExtension.length ? src.pathExtension : @"audio";
    NSString *uuid = [NSUUID UUID].UUIDString;
    NSString *fileName = [NSString stringWithFormat:@"%@.%@", uuid, ext];
    NSString *dst = [[self audioDir] stringByAppendingPathComponent:fileName];
    NSURL *dstURL = [NSURL fileURLWithPath:dst];
    NSError *err = nil;
    // 用 copyItemAtURL —— 调用方负责 securityScoped
    BOOL ok = [NSFileManager.defaultManager copyItemAtURL:src toURL:dstURL error:&err];
    if (!ok) {
        if (error) *error = err;
        return nil;
    }
    if (outName) *outName = fileName;
    return dstURL;
}

- (void)addUserSong:(JFRhythmSong *)song {
    if (!song) return;
    [self.userSongsInternal addObject:song];
    [self saveToDisk];
}

- (void)removeUserSong:(JFRhythmSong *)song {
    if (!song) return;
    NSString *path = song.audioURLInDocuments.path;
    if (path.length) [NSFileManager.defaultManager removeItemAtPath:path error:nil];
    [self.userSongsInternal removeObject:song];
    [self saveToDisk];
}

#pragma mark - 内置预设节奏(从 bundle Music/ 读真音频)

- (NSString *)presetCachePath {
    return [self.libraryDir stringByAppendingPathComponent:kPresetCacheName];
}

- (NSDictionary<NSString *, JFRhythmSong *> *)loadPresetCache {
    NSData *data = [NSData dataWithContentsOfFile:[self presetCachePath]];
    if (!data) return @{};
    NSError *err = nil;
    NSSet *cls = [NSSet setWithObjects:NSDictionary.class, NSArray.class, JFRhythmSong.class, JFRhythmBeat.class, NSDate.class, NSString.class, NSNumber.class, nil];
    NSDictionary *d = [NSKeyedUnarchiver unarchivedObjectOfClasses:cls fromData:data error:&err];
    return [d isKindOfClass:NSDictionary.class] ? d : @{};
}

- (void)savePresetCache:(NSDictionary<NSString *, JFRhythmSong *> *)cache {
    NSError *err = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cache requiringSecureCoding:YES error:&err];
    if (data) [data writeToFile:[self presetCachePath] atomically:YES];
}

- (NSArray<JFRhythmSong *> *)buildPresets {
    // 多途径找音频文件:
    // 1. resourcePath/Music 子目录(老式分组)
    // 2. resourcePath 根(Xcode 16 同步分组打平时)
    // 3. NSBundle pathsForResourcesOfType: 全 bundle 扫描兜底
    NSArray *exts = @[@"mp3", @"m4a", @"wav", @"aac", @"aif", @"aiff", @"caf"];
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *resDir = bundle.resourcePath;
    NSFileManager *fm = [NSFileManager defaultManager];

    NSMutableArray<NSDictionary *> *found = [NSMutableArray array];
    NSMutableSet<NSString *> *seenAbs = [NSMutableSet set];

    void (^addIfAudio)(NSString *, NSString *) = ^(NSString *rel, NSString *abs) {
        if (!abs.length || [seenAbs containsObject:abs]) return;
        if (![exts containsObject:abs.pathExtension.lowercaseString]) return;
        // 至少 8KB,排除空 caf 等占位文件
        NSDictionary *a = [fm attributesOfItemAtPath:abs error:nil];
        unsigned long long sz = [a[NSFileSize] unsignedLongLongValue];
        if (sz < 8 * 1024) return;
        [seenAbs addObject:abs];
        [found addObject:@{@"rel": rel, @"abs": abs}];
    };

    // 路径 1:resourcePath/Music
    NSString *musicSub = [resDir stringByAppendingPathComponent:@"Music"];
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:musicSub isDirectory:&isDir] && isDir) {
        for (NSString *fn in [fm contentsOfDirectoryAtPath:musicSub error:nil]) {
            addIfAudio([@"Music" stringByAppendingPathComponent:fn],
                       [musicSub stringByAppendingPathComponent:fn]);
        }
    }

    // 路径 2:resourcePath 根
    for (NSString *fn in [fm contentsOfDirectoryAtPath:resDir error:nil] ?: @[]) {
        addIfAudio(fn, [resDir stringByAppendingPathComponent:fn]);
    }

    // 路径 3:全 bundle 扫描(兜底)
    for (NSString *ext in exts) {
        NSArray<NSString *> *all = [bundle pathsForResourcesOfType:ext inDirectory:nil];
        for (NSString *abs in all) {
            NSString *rel = abs;
            if ([abs hasPrefix:resDir]) {
                rel = [abs substringFromIndex:resDir.length];
                if ([rel hasPrefix:@"/"]) rel = [rel substringFromIndex:1];
            }
            addIfAudio(rel, abs);
        }
    }

    NSDictionary<NSString *, NSDictionary *> *manifests = JFLoadBundledChartManifests(bundle);
    NSMutableDictionary<NSString *, JFRhythmSong *> *cache = [[self loadPresetCache] mutableCopy] ?: [NSMutableDictionary dictionary];
    NSMutableArray<JFRhythmSong *> *out = [NSMutableArray array];
    BOOL cacheChanged = NO;

    for (NSDictionary *item in found) {
        NSString *rel = item[@"rel"];
        NSString *abs = item[@"abs"];
        NSURL *url = [NSURL fileURLWithPath:abs];
        NSString *fn = abs.lastPathComponent;
        NSDictionary *manifest = manifests[fn.lowercaseString];
        BOOL tutorial = [manifest[@"tutorial"] boolValue];

        NSString *display = fn.stringByDeletingPathExtension;
        NSRange hashR = [display rangeOfString:@"#"];
        if (hashR.location != NSNotFound) display = [display substringToIndex:hashR.location];

        NSString *title = display;
        NSString *artist = @"";
        NSRange dashR = [display rangeOfString:@"-"];
        if (dashR.location != NSNotFound) {
            title  = [[display substringToIndex:dashR.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            artist = [[display substringFromIndex:dashR.location + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        if ([manifest[@"title"] isKindOfClass:NSString.class] && [manifest[@"title"] length] > 0) title = manifest[@"title"];
        if ([manifest[@"artist"] isKindOfClass:NSString.class] && [manifest[@"artist"] length] > 0) artist = manifest[@"artist"];

        NSString *manifestId = [manifest[@"id"] isKindOfClass:NSString.class] ? manifest[@"id"] : nil;
        NSString *songId = manifestId.length ? manifestId : [@"preset_" stringByAppendingString:fn];

        NSDictionary *attr = [fm attributesOfItemAtPath:abs error:nil];
        NSString *fingerprint = [NSString stringWithFormat:@"%@:%@:%@",
                                 attr[NSFileSize] ?: @"0",
                                 [attr[NSFileModificationDate] description] ?: @"",
                                 fn];
        NSString *revision = manifest[@"revision"] ? [manifest[@"revision"] description] : @"auto";
        NSString *cacheKey = [NSString stringWithFormat:@"%@|%@|%@|%@", kPresetChartVersion, revision, songId, fingerprint];

        JFRhythmSong *cached = cache[cacheKey];
        if (cached && (cached.fullChart.count > 0 || cached.chart.count > 0)) {
            cached.bundleAudioName = rel;
            cached.title = title;
            cached.artist = tutorial ? @"新手教学 · 可重复练习" : (artist.length ? artist : @"内置经典");
            cached.tutorial = tutorial;
            cached.tutorialSteps = tutorial ? JFTutorialStepsFromManifest(manifest, cached.duration) : @[];
            // 老缓存可能没 fullChart —— 兜底用 chart 当 fullChart
            if (cached.fullChart.count == 0 && cached.chart.count > 0) {
                cached.fullChart = cached.chart;
            }
            [out addObject:cached];
            continue;
        }

        AVAudioPlayer *p = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        NSTimeInterval duration = p.duration;
        if (duration <= 0) duration = 60;
        double bpm = [manifest[@"bpm"] doubleValue];
        NSArray<JFRhythmBeat *> *full = manifest ? JFBeatsFromManifest(manifest, duration) : nil;
        BOOL authoredChart = (full.count > 0);
        if (!authoredChart) {
            full = [JFRhythmAnalyzer analyzeURL:url duration:duration outBPM:&bpm];
        }

        JFRhythmSong *s = [[JFRhythmSong alloc] init];
        s.kind = JFRhythmSongKindPreset;
        s.songId = songId;
        s.title = title;
        s.artist = authoredChart ? (artist.length ? [NSString stringWithFormat:@"%@ · 手工谱", artist] : @"手工谱")
                                 : (artist.length ? artist : @"内置经典");
        s.bundleAudioName = rel;
        s.duration = duration;
        s.bpm = bpm > 0 ? bpm : 110;
        s.fullChart = full;
        s.chart = [JFRhythmChart chartFromFull:full difficulty:JFRhythmDifficultyMedium];
        s.tutorial = tutorial;
        s.tutorialSteps = tutorial ? JFTutorialStepsFromManifest(manifest, duration) : @[];
        if (tutorial) s.artist = @"新手教学 · 可重复练习";
        [out addObject:s];

        if (full.count > 0) {
            cache[cacheKey] = s;
            cacheChanged = YES;
        }
    }
    if (cacheChanged) [self savePresetCache:cache];

    // 清单中的 order 决定内置曲目顺序;没有清单的音频放在末尾。
    [out sortUsingComparator:^NSComparisonResult(JFRhythmSong *a, JFRhythmSong *b) {
        NSDictionary *ma = manifests[a.bundleAudioName.lastPathComponent.lowercaseString];
        NSDictionary *mb = manifests[b.bundleAudioName.lastPathComponent.lowercaseString];
        NSInteger oa = ma[@"order"] ? [ma[@"order"] integerValue] : NSIntegerMax;
        NSInteger ob = mb[@"order"] ? [mb[@"order"] integerValue] : NSIntegerMax;
        if (oa < ob) return NSOrderedAscending;
        if (oa > ob) return NSOrderedDescending;
        return [a.title localizedCompare:b.title];
    }];
    return out;
}

@end
