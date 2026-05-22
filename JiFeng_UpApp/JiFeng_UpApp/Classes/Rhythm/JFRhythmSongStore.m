//
//  JFRhythmSongStore.m
//

#import "JFRhythmSongStore.h"
#import "JFRhythmAnalyzer.h"
#import <AVFoundation/AVFoundation.h>

static NSString *const kArchiveName = @"jf_rhythm_library.archive";
static NSString *const kAudioDirName = @"RhythmSongs";
static NSString *const kPresetCacheName = @"jf_rhythm_preset_cache.archive";

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
    NSSet *cls = [NSSet setWithObjects:NSArray.class, JFRhythmSong.class, JFRhythmBeat.class, NSDate.class, NSString.class, nil];
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

- (NSURL *)copyImportedAudioFromURL:(NSURL *)src outFileName:(NSString **)outName error:(NSError **)error {
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

    NSMutableDictionary<NSString *, JFRhythmSong *> *cache = [[self loadPresetCache] mutableCopy] ?: [NSMutableDictionary dictionary];
    NSMutableArray<JFRhythmSong *> *out = [NSMutableArray array];
    BOOL cacheChanged = NO;

    for (NSDictionary *item in found) {
        NSString *rel = item[@"rel"];
        NSString *abs = item[@"abs"];
        NSURL *url = [NSURL fileURLWithPath:abs];
        NSString *fn = abs.lastPathComponent;

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

        NSString *songId = [@"preset_" stringByAppendingString:fn];

        NSDictionary *attr = [fm attributesOfItemAtPath:abs error:nil];
        NSString *fingerprint = [NSString stringWithFormat:@"%@:%@:%@",
                                 attr[NSFileSize] ?: @"0",
                                 [attr[NSFileModificationDate] description] ?: @"",
                                 fn];
        NSString *cacheKey = [NSString stringWithFormat:@"%@|%@", songId, fingerprint];

        JFRhythmSong *cached = cache[cacheKey];
        if (cached && (cached.fullChart.count > 0 || cached.chart.count > 0)) {
            cached.bundleAudioName = rel;
            cached.title = title;
            cached.artist = artist.length ? artist : @"内置经典";
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
        double bpm = 0;
        NSArray<JFRhythmBeat *> *full = [JFRhythmAnalyzer analyzeURL:url duration:duration outBPM:&bpm];

        JFRhythmSong *s = [[JFRhythmSong alloc] init];
        s.kind = JFRhythmSongKindPreset;
        s.songId = songId;
        s.title = title;
        s.artist = artist.length ? artist : @"内置经典";
        s.bundleAudioName = rel;
        s.duration = duration;
        s.bpm = bpm > 0 ? bpm : 110;
        s.fullChart = full;
        s.chart = [JFRhythmChart chartFromFull:full difficulty:JFRhythmDifficultyMedium];
        [out addObject:s];

        if (full.count > 0) {
            cache[cacheKey] = s;
            cacheChanged = YES;
        }
    }
    if (cacheChanged) [self savePresetCache:cache];

    // 按标题稳定排序
    [out sortUsingComparator:^NSComparisonResult(JFRhythmSong *a, JFRhythmSong *b) {
        return [a.title localizedCompare:b.title];
    }];
    return out;
}

@end
