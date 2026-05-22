//
//  JFRhythmViewController.m
//
//  节奏点点 ——
//  · 顶部「歌单」按钮:列出「我的导入」+「内置预设节奏」,长按可删除导入歌
//  · 「导入音乐」从文件 App / iCloud 选音频,自动分析 BPM、生成谱面、本地化保存
//  · 「开始」/「暂停」/「继续」三态控制
//  · 真节拍下落:每个音符按它在歌中的"目标到达时间"反推位置,与音频/CADisplayLink 同步;
//    判定区(progress 0.4 ~ 1.25)内按下对应轨道键即命中
//  · 预设/导入都有真音频,统一用 AVAudioPlayer 播放,onset 分析在 JFRhythmAnalyzer 完成
//

#import "JFRhythmViewController.h"
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"
#import "JFRhythmSong.h"
#import "JFRhythmSongStore.h"
#import "JFRhythmAnalyzer.h"
#import <AVFoundation/AVFoundation.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

static const NSInteger kLanes = 4;
static NSString *const kBestKey = @"jf_rhythm_best";
static NSString *const kDiffKey = @"jf_rhythm_difficulty";

#pragma mark - 选歌列表

@class JFRhythmSongListVC;
@protocol JFRhythmSongListDelegate <NSObject>
- (void)songList:(JFRhythmSongListVC *)list didPickSong:(JFRhythmSong *)song;
- (void)songListDidRequestImport:(JFRhythmSongListVC *)list;
@end

@interface JFRhythmSongListVC : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) id<JFRhythmSongListDelegate> delegate;
@property (nonatomic, strong) UITableView *tableView;
@end

#pragma mark - 运行时音符

@interface JFRhythmRuntimeNote : NSObject
@property (nonatomic, assign) NSInteger lane;
@property (nonatomic, assign) NSTimeInterval targetTime;
@property (nonatomic, assign) double strength;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) BOOL hit;
@end
@implementation JFRhythmRuntimeNote @end

#pragma mark - 主页面

@interface JFRhythmViewController () <UIDocumentPickerDelegate, AVAudioPlayerDelegate, JFRhythmSongListDelegate>

// UI
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UILabel *comboLabel;
@property (nonatomic, strong) UILabel *bigComboLabel;   // 屏幕中央大字 combo
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *songLabel;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView  *track;
@property (nonatomic, strong) UIView  *judgeLine;
@property (nonatomic, strong) UIView  *judgeGlow;
@property (nonatomic, strong) NSArray<UIView *> *laneViews;
@property (nonatomic, strong) NSArray<UIButton *> *keyPads;
@property (nonatomic, strong) NSArray<UILabel *> *keyLabels;
@property (nonatomic, strong) UIButton *libraryButton;   // 选歌
@property (nonatomic, strong) UIButton *startButton;     // 开始/继续
@property (nonatomic, strong) UIButton *pauseButton;     // 暂停
@property (nonatomic, strong) UISegmentedControl *diffSeg; // 难度:简单/中等/困难
@property (nonatomic, strong) UILabel *bigGradeLabel;    // 屏幕中央大字 PERFECT/GREAT/GOOD

// 当前歌 + 运行时
@property (nonatomic, strong, nullable) JFRhythmSong *currentSong;
@property (nonatomic, strong, nullable) AVAudioPlayer *player;
@property (nonatomic, strong, nullable) NSURL *securedSongURL;   // 文件选择导入流程的安全作用域

@property (nonatomic, strong) NSMutableArray<JFRhythmRuntimeNote *> *notes;     // 已 spawn
@property (nonatomic, strong) NSMutableArray<JFRhythmBeat *> *pendingBeats;     // 待 spawn,头部最早
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) NSTimeInterval fallDuration;    // 屏顶 -> 判定线
@property (nonatomic, assign) NSTimeInterval pausedAt;        // 暂停时的歌曲时间

// 状态机
typedef NS_ENUM(NSInteger, JFRhythmState) {
    JFRhythmStateIdle = 0,
    JFRhythmStateAnalyzing,
    JFRhythmStatePlaying,
    JFRhythmStatePaused,
    JFRhythmStateFinished,
};
@property (nonatomic, assign) JFRhythmState state;

// 计分
@property (nonatomic, assign) NSInteger score;
@property (nonatomic, assign) NSInteger best;
@property (nonatomic, assign) NSInteger combo;
@property (nonatomic, assign) NSInteger maxCombo;

// 评级统计
@property (nonatomic, assign) NSInteger perfectCount;
@property (nonatomic, assign) NSInteger greatCount;
@property (nonatomic, assign) NSInteger goodCount;
@property (nonatomic, assign) NSInteger missCount;
@property (nonatomic, assign) NSInteger totalNotesAtStart;

// 难度
@property (nonatomic, assign) JFRhythmDifficulty difficulty;

@end

@implementation JFRhythmViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.best = [[NSUserDefaults standardUserDefaults] integerForKey:kBestKey];
    self.notes = [NSMutableArray array];
    self.pendingBeats = [NSMutableArray array];
    self.fallDuration = 1.9;
    self.state = JFRhythmStateIdle;

    NSInteger savedDiff = [[NSUserDefaults standardUserDefaults] integerForKey:kDiffKey];
    if (savedDiff < 0 || savedDiff > 2) savedDiff = JFRhythmDifficultyMedium;
    self.difficulty = (JFRhythmDifficulty)savedDiff;

    // 让 AVAudioPlayer 在静音键打开时也能出声
    NSError *sessErr = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                            mode:AVAudioSessionModeDefault
                                         options:0
                                           error:&sessErr];
    [[AVAudioSession sharedInstance] setActive:YES error:&sessErr];

    [self buildBackground];
    [self buildUI];
    [self syncButtonsForState];
    [self refreshSongLabel];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopAndCleanup];
}

// 鲜艳活泼的方块配色,随机选一种
- (UIColor *)randomNoteColor {
    static NSArray<UIColor *> *palette = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        palette = @[
            [UIColor colorWithRed:1.00 green:0.42 blue:0.55 alpha:1],   // 樱粉
            [UIColor colorWithRed:1.00 green:0.66 blue:0.30 alpha:1],   // 橙
            [UIColor colorWithRed:1.00 green:0.86 blue:0.36 alpha:1],   // 金
            [UIColor colorWithRed:0.36 green:0.85 blue:0.55 alpha:1],   // 嫩绿
            [UIColor colorWithRed:0.32 green:0.78 blue:0.95 alpha:1],   // 天蓝
            [UIColor colorWithRed:0.55 green:0.58 blue:1.00 alpha:1],   // 紫蓝
            [UIColor colorWithRed:0.86 green:0.45 blue:0.95 alpha:1],   // 紫
            [UIColor colorWithRed:0.30 green:0.95 blue:0.85 alpha:1],   // 青
        ];
    });
    return palette[arc4random_uniform((uint32_t)palette.count)];
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
    self.hintLabel.text = @"音符落到判定线时点对应键位 · 越准越多分";
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

    // 屏幕中央的大字 combo —— 命中时弹出,无命中保持淡出
    self.bigComboLabel = [[UILabel alloc] init];
    self.bigComboLabel.textAlignment = NSTextAlignmentCenter;
    self.bigComboLabel.userInteractionEnabled = NO;
    self.bigComboLabel.font = [UIFont systemFontOfSize:88 weight:UIFontWeightBlack];
    self.bigComboLabel.textColor = [UIColor whiteColor];
    self.bigComboLabel.alpha = 0;
    self.bigComboLabel.layer.shadowColor = [JFTheme accent].CGColor;
    self.bigComboLabel.layer.shadowOpacity = 0.9;
    self.bigComboLabel.layer.shadowRadius = 18;
    self.bigComboLabel.layer.shadowOffset = CGSizeZero;
    [self.track addSubview:self.bigComboLabel];

    // 评级大字 PERFECT/GREAT/GOOD —— 在 combo 字号下方一点,留出层级
    self.bigGradeLabel = [[UILabel alloc] init];
    self.bigGradeLabel.textAlignment = NSTextAlignmentCenter;
    self.bigGradeLabel.userInteractionEnabled = NO;
    self.bigGradeLabel.font = [UIFont systemFontOfSize:48 weight:UIFontWeightHeavy];
    self.bigGradeLabel.textColor = [UIColor whiteColor];
    self.bigGradeLabel.alpha = 0;
    self.bigGradeLabel.layer.shadowColor = [JFTheme accent].CGColor;
    self.bigGradeLabel.layer.shadowOpacity = 0.85;
    self.bigGradeLabel.layer.shadowRadius = 12;
    self.bigGradeLabel.layer.shadowOffset = CGSizeZero;
    [self.track addSubview:self.bigGradeLabel];

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

    self.libraryButton = [self secondaryButtonWithTitle:@"歌单" action:@selector(onOpenLibrary)];
    self.startButton   = [self primaryButtonWithTitle:@"开始" action:@selector(onStartOrResume)];
    self.pauseButton   = [self secondaryButtonWithTitle:@"暂停" action:@selector(onPause)];
    [self.view addSubview:self.libraryButton];
    [self.view addSubview:self.startButton];
    [self.view addSubview:self.pauseButton];

    // 难度选择
    self.diffSeg = [[UISegmentedControl alloc] initWithItems:@[@"简单", @"中等", @"困难"]];
    self.diffSeg.translatesAutoresizingMaskIntoConstraints = NO;
    self.diffSeg.selectedSegmentIndex = self.difficulty;
    self.diffSeg.selectedSegmentTintColor = [JFTheme accent];
    [self.diffSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [JFTheme textOnAccent]} forState:UIControlStateSelected];
    [self.diffSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [JFTheme textPrimary]} forState:UIControlStateNormal];
    [self.diffSeg addTarget:self action:@selector(onDifficultyChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.diffSeg];

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

        [self.diffSeg.topAnchor        constraintEqualToAnchor:self.hintLabel.bottomAnchor constant:JFSpacing8],
        [self.diffSeg.leadingAnchor    constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.diffSeg.trailingAnchor   constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [self.diffSeg.heightAnchor     constraintEqualToConstant:32],

        [self.track.topAnchor      constraintEqualToAnchor:self.diffSeg.bottomAnchor constant:JFSpacing8],
        [self.track.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing16],
        [self.track.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],

        [self.libraryButton.topAnchor     constraintEqualToAnchor:self.track.bottomAnchor constant:JFSpacing12],
        [self.libraryButton.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing16],
        [self.libraryButton.heightAnchor  constraintEqualToConstant:48],

        [self.startButton.topAnchor       constraintEqualToAnchor:self.track.bottomAnchor constant:JFSpacing12],
        [self.startButton.leadingAnchor   constraintEqualToAnchor:self.libraryButton.trailingAnchor constant:JFSpacing8],
        [self.startButton.heightAnchor    constraintEqualToConstant:48],

        [self.pauseButton.topAnchor       constraintEqualToAnchor:self.track.bottomAnchor constant:JFSpacing12],
        [self.pauseButton.leadingAnchor   constraintEqualToAnchor:self.startButton.trailingAnchor constant:JFSpacing8],
        [self.pauseButton.trailingAnchor  constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],
        [self.pauseButton.heightAnchor    constraintEqualToConstant:48],
        [self.pauseButton.widthAnchor     constraintEqualToAnchor:self.startButton.widthAnchor],
        [self.startButton.widthAnchor     constraintEqualToAnchor:self.libraryButton.widthAnchor],

        [self.libraryButton.bottomAnchor  constraintEqualToAnchor:safe.bottomAnchor constant:-JFSpacing16],
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
    // bigComboLabel:放在轨道中央偏上(避免遮判定线和落块下半段),宽与 track 同
    CGFloat comboH = 120;
    CGFloat comboY = (judgeY * 0.42) - comboH / 2;
    if (comboY < 8) comboY = 8;
    self.bigComboLabel.frame = CGRectMake(0, comboY, W, comboH);

    // bigGradeLabel:贴在 combo 下方,做"评级"位
    CGFloat gradeH = 60;
    CGFloat gradeY = comboY + comboH - 6;
    self.bigGradeLabel.frame = CGRectMake(0, gradeY, W, gradeH);
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
    if (self.currentSong.title.length) {
        self.songLabel.text = [NSString stringWithFormat:@"♪ %@", self.currentSong.title];
        if (self.state == JFRhythmStateIdle || self.state == JFRhythmStateFinished) {
            self.statusLabel.text = [NSString stringWithFormat:@"%@ · BPM %.0f · %.0fs · %@ %ld 拍",
                                      self.currentSong.kind == JFRhythmSongKindPreset ? @"内置经典" : @"已分析",
                                      self.currentSong.bpm,
                                      self.currentSong.duration,
                                      [JFRhythmChart nameOfDifficulty:self.difficulty],
                                      (long)self.currentSong.chart.count];
        }
    } else {
        self.songLabel.text = @"还没选曲目 —— 点击「歌单」挑一首";
        self.statusLabel.text = @"";
    }
}

- (void)syncButtonsForState {
    switch (self.state) {
        case JFRhythmStateIdle:
            self.libraryButton.enabled = YES;
            self.startButton.enabled = self.currentSong != nil;
            [self.startButton setTitle:@"开始" forState:UIControlStateNormal];
            self.pauseButton.enabled = NO;
            [self.pauseButton setTitle:@"暂停" forState:UIControlStateNormal];
            break;
        case JFRhythmStateAnalyzing:
            self.libraryButton.enabled = NO;
            self.startButton.enabled = NO;
            [self.startButton setTitle:@"分析中…" forState:UIControlStateNormal];
            self.pauseButton.enabled = NO;
            break;
        case JFRhythmStatePlaying:
            self.libraryButton.enabled = NO;
            self.startButton.enabled = NO;
            [self.startButton setTitle:@"游戏中" forState:UIControlStateNormal];
            self.pauseButton.enabled = YES;
            [self.pauseButton setTitle:@"暂停" forState:UIControlStateNormal];
            break;
        case JFRhythmStatePaused:
            self.libraryButton.enabled = NO;
            self.startButton.enabled = YES;
            [self.startButton setTitle:@"继续" forState:UIControlStateNormal];
            self.pauseButton.enabled = YES;
            [self.pauseButton setTitle:@"重新开始" forState:UIControlStateNormal];
            break;
        case JFRhythmStateFinished:
            self.libraryButton.enabled = YES;
            self.startButton.enabled = YES;
            [self.startButton setTitle:@"再来一次" forState:UIControlStateNormal];
            self.pauseButton.enabled = NO;
            break;
    }
    BOOL padsOn = (self.state == JFRhythmStatePlaying);
    for (UIButton *p in self.keyPads) p.enabled = padsOn;
}

#pragma mark - 选歌

- (void)onOpenLibrary {
    if (self.state == JFRhythmStateAnalyzing || self.state == JFRhythmStatePlaying) return;
    JFRhythmSongListVC *list = [[JFRhythmSongListVC alloc] init];
    list.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)songList:(JFRhythmSongListVC *)list didPickSong:(JFRhythmSong *)song {
    [list dismissViewControllerAnimated:YES completion:nil];
    [self loadSong:song];
}

- (void)songListDidRequestImport:(JFRhythmSongListVC *)list {
    [list dismissViewControllerAnimated:YES completion:^{
        [self presentDocumentPicker];
    }];
}

- (void)presentDocumentPicker {
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

#pragma mark - 装载/卸载歌

- (void)onDifficultyChanged:(UISegmentedControl *)seg {
    JFRhythmDifficulty d = (JFRhythmDifficulty)seg.selectedSegmentIndex;
    if (d == self.difficulty) return;
    self.difficulty = d;
    [[NSUserDefaults standardUserDefaults] setInteger:d forKey:kDiffKey];
    if (self.state == JFRhythmStatePlaying || self.state == JFRhythmStatePaused) {
        // 切难度需要重开
        [self stopAndCleanup];
        if (self.currentSong) [self loadSong:self.currentSong];
    } else {
        [self applyDifficultyToCurrent];
        [self refreshSongLabel];
    }
}

- (void)applyDifficultyToCurrent {
    if (!self.currentSong) return;
    NSArray<JFRhythmBeat *> *full = self.currentSong.fullChart;
    if (full.count == 0) full = self.currentSong.chart;
    if (full.count == 0) return;
    self.currentSong.chart = [JFRhythmChart chartFromFull:full difficulty:self.difficulty];
}

- (void)loadSong:(JFRhythmSong *)song {
    [self stopAndCleanup];
    self.currentSong = song;
    // 应用当前难度
    [self applyDifficultyToCurrent];
    self.state = JFRhythmStateIdle;
    self.score = 0; self.combo = 0; self.maxCombo = 0;
    self.perfectCount = self.greatCount = self.goodCount = self.missCount = 0;
    [self updateLabels];

    NSURL *url = [song playableAudioURL];
    if (url) {
        NSError *err = nil;
        AVAudioPlayer *p = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        if (p) {
            p.volume = 1.0;
            [p prepareToPlay];
            p.delegate = self;
            self.player = p;
            self.timeLabel.text = [NSString stringWithFormat:@"%.0fs", song.duration];
        } else {
            self.player = nil;
            self.statusLabel.text = [NSString stringWithFormat:@"音频读取失败:%@", err.localizedDescription ?: @"未知错误"];
        }
    } else {
        self.player = nil;
        self.timeLabel.text = [NSString stringWithFormat:@"%.0fs", song.duration];
        self.statusLabel.text = @"找不到这首歌的音频文件";
    }
    [self refreshSongLabel];
    [self syncButtonsForState];
}

#pragma mark - 文件导入回调

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *src = urls.firstObject;
    if (!src) return;

    BOOL secured = [src startAccessingSecurityScopedResource];
    NSURL *holder = secured ? src : nil;
    NSError *copyErr = nil;
    NSString *fileName = nil;
    NSURL *dst = [[JFRhythmSongStore shared] copyImportedAudioFromURL:src outFileName:&fileName error:&copyErr];
    if (holder) [holder stopAccessingSecurityScopedResource];
    if (!dst) {
        self.statusLabel.text = [NSString stringWithFormat:@"导入失败:%@", copyErr.localizedDescription ?: @"未知错误"];
        return;
    }

    NSString *displayTitle = src.lastPathComponent.stringByDeletingPathExtension;
    self.statusLabel.text = @"已保存,正在分析节奏…";
    self.state = JFRhythmStateAnalyzing;
    [self syncButtonsForState];

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *err = nil;
        AVAudioPlayer *p = [[AVAudioPlayer alloc] initWithContentsOfURL:dst error:&err];
        [p prepareToPlay];
        NSTimeInterval duration = p ? p.duration : 0;
        double bpm = 0;
        NSArray<JFRhythmBeat *> *chart = [JFRhythmAnalyzer analyzeURL:dst duration:duration outBPM:&bpm];

        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self_ = weakSelf;
            if (!self_) return;
            if (!p || err) {
                self_.statusLabel.text = [NSString stringWithFormat:@"无法读取这首歌:%@", err.localizedDescription ?: @"未知错误"];
                self_.state = JFRhythmStateIdle;
                [self_ syncButtonsForState];
                return;
            }
            JFRhythmSong *song = [[JFRhythmSong alloc] init];
            song.kind = JFRhythmSongKindUserImport;
            song.songId = [NSUUID UUID].UUIDString;
            song.title = displayTitle;
            song.artist = @"我导入的";
            song.audioFileName = fileName;
            song.duration = duration;
            song.bpm = bpm;
            song.fullChart = chart;
            song.chart = [JFRhythmChart chartFromFull:chart difficulty:self_.difficulty];
            song.importedAt = [NSDate date];
            [[JFRhythmSongStore shared] addUserSong:song];

            [self_ loadSong:song];
            self_.statusLabel.text = [NSString stringWithFormat:@"已添加到歌单 · BPM %.0f", bpm];
        });
    });
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller { }

#pragma mark - 游戏流程

- (void)onStartOrResume {
    if (self.state == JFRhythmStateIdle || self.state == JFRhythmStateFinished) {
        [self startFresh];
    } else if (self.state == JFRhythmStatePaused) {
        [self resume];
    }
}

- (void)onPause {
    if (self.state == JFRhythmStatePlaying) {
        [self pause];
    } else if (self.state == JFRhythmStatePaused) {
        // 在暂停态时,这个按钮变成"重新开始"
        [self stopAndCleanup];
        if (self.currentSong) [self loadSong:self.currentSong];
    }
}

- (void)startFresh {
    if (!self.currentSong || self.currentSong.chart.count == 0) {
        self.statusLabel.text = @"请先选择一首歌";
        return;
    }
    if (!self.player) {
        self.statusLabel.text = @"音频未就绪,试试重新选这首歌";
        return;
    }
    self.score = 0; self.combo = 0; self.maxCombo = 0;
    self.perfectCount = self.greatCount = self.goodCount = self.missCount = 0;
    self.totalNotesAtStart = self.currentSong.chart.count;
    self.bigComboLabel.alpha = 0;
    self.bigGradeLabel.alpha = 0;
    [self.notes removeAllObjects];
    self.pendingBeats = [self.currentSong.chart mutableCopy];
    [self.player setCurrentTime:0];
    [self.player play];
    self.state = JFRhythmStatePlaying;
    [self syncButtonsForState];
    [self updateLabels];
    self.statusLabel.text = @"";
    [self startLink];
}

- (void)pause {
    self.state = JFRhythmStatePaused;
    if (self.player.isPlaying) {
        self.pausedAt = self.player.currentTime;
        [self.player pause];
    }
    [self stopLink];
    [self syncButtonsForState];
    self.statusLabel.text = @"暂停 —— 点击「继续」回到游戏";
}

- (void)resume {
    if (self.state != JFRhythmStatePaused) return;
    if (self.player) {
        [self.player setCurrentTime:self.pausedAt];
        [self.player play];
    }
    self.state = JFRhythmStatePlaying;
    [self startLink];
    [self syncButtonsForState];
    self.statusLabel.text = @"";
}

- (void)stopAndCleanup {
    [self stopLink];
    if (self.player.isPlaying) [self.player pause];
    if (self.securedSongURL) {
        [self.securedSongURL stopAccessingSecurityScopedResource];
        self.securedSongURL = nil;
    }
    for (JFRhythmRuntimeNote *n in self.notes) [n.view removeFromSuperview];
    [self.notes removeAllObjects];
    [self.pendingBeats removeAllObjects];
}

- (void)finishSong {
    [self stopLink];
    if (self.player.isPlaying) [self.player stop];
    for (JFRhythmRuntimeNote *n in self.notes) [n.view removeFromSuperview];
    [self.notes removeAllObjects];
    self.state = JFRhythmStateFinished;
    [self syncButtonsForState];

    if (self.score > self.best) {
        self.best = self.score;
        [[NSUserDefaults standardUserDefaults] setInteger:self.best forKey:kBestKey];
    }
    NSInteger hits = self.perfectCount + self.greatCount + self.goodCount;
    NSInteger total = self.totalNotesAtStart > 0 ? self.totalNotesAtStart : (hits + self.missCount);
    JFGameResult *r = [JFGameResult resultWithKind:JFGameKindRhythm score:self.score win:YES];
    r.duration = self.currentSong.duration;
    r.difficulty = self.difficulty;
    r.extra = @{@"maxCombo": @(self.maxCombo),
                @"bpm": @(self.currentSong.bpm),
                @"song": self.currentSong.title ?: @"",
                @"difficulty": [JFRhythmChart keyOfDifficulty:self.difficulty],
                @"totalNotes": @(total),
                @"hits": @(hits),
                @"perfect": @(self.perfectCount),
                @"great": @(self.greatCount),
                @"good": @(self.goodCount),
                @"miss": @(self.missCount)};
    [[JFProfileStore shared] reportResult:r];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindRhythm difficulty:self.difficulty score:self.score win:(self.maxCombo >= 30)];
    self.statusLabel.text = [NSString stringWithFormat:@"本局结束 · Combo %ld · P/G/G %ld/%ld/%ld",
                             (long)self.maxCombo, (long)self.perfectCount, (long)self.greatCount, (long)self.goodCount];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (self.state != JFRhythmStatePlaying) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.state == JFRhythmStatePlaying) [self finishSong];
    });
}

#pragma mark - DisplayLink

- (void)startLink {
    if (self.link) return;
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(onTick)];
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopLink {
    [self.link invalidate];
    self.link = nil;
}

- (NSTimeInterval)currentSongTime {
    return self.player ? self.player.currentTime : 0;
}

- (void)onTick {
    if (self.state != JFRhythmStatePlaying) return;
    NSTimeInterval songTime = [self currentSongTime];
    NSTimeInterval remain = self.currentSong.duration - songTime;
    if (remain < 0) remain = 0;
    self.timeLabel.text = [NSString stringWithFormat:@"%.0fs", remain];

    // spawn 即将到来的拍点
    while (self.pendingBeats.count > 0) {
        JFRhythmBeat *b = self.pendingBeats.firstObject;
        if (b.time - songTime <= self.fallDuration) {
            JFRhythmRuntimeNote *n = [[JFRhythmRuntimeNote alloc] init];
            n.lane = b.lane;
            n.targetTime = b.time;
            n.strength = b.strength;
            n.color = [self randomNoteColor];
            UIView *v = [[UIView alloc] init];
            BOOL strong = b.strength >= 0.75;
            v.backgroundColor = n.color;
            v.layer.cornerRadius = 12;
            // 内描边 + 高光,质感更跳
            v.layer.borderWidth = 1.0;
            v.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.35].CGColor;
            v.layer.shadowColor = n.color.CGColor;
            v.layer.shadowOpacity = strong ? 0.95 : 0.7;
            v.layer.shadowRadius = strong ? 12 : 8;
            v.layer.shadowOffset = CGSizeZero;
            v.userInteractionEnabled = NO;
            n.view = v;
            [self.track addSubview:v];
            [self.notes addObject:n];
            [self.pendingBeats removeObjectAtIndex:0];
        } else {
            break;
        }
    }

    [self updateNotes:songTime];
}

- (void)updateNotes:(NSTimeInterval)songTime {
    CGFloat W = self.track.bounds.size.width;
    CGFloat lw = W / kLanes;
    CGFloat judgeY = [self judgeY];
    NSMutableArray *toRemove = [NSMutableArray array];
    for (JFRhythmRuntimeNote *n in self.notes) {
        if (n.hit) {
            [n.view removeFromSuperview];
            [toRemove addObject:n];
            continue;
        }
        NSTimeInterval delta = songTime - (n.targetTime - self.fallDuration);
        CGFloat progress = (CGFloat)(delta / self.fallDuration);
        if (progress > 1.35) {
            n.hit = YES;
            self.missCount += 1;
            [self animateMissAt:n];
            [toRemove addObject:n];
            if (self.combo > 0) {
                self.combo = 0;
                [self breakComboAnimation];
            }
            [self updateLabels];
            continue;
        }
        if (progress < -0.05) continue;
        CGFloat noteH = (n.strength >= 0.75) ? 46 : 36;
        CGFloat y = -noteH + (judgeY + noteH) * progress;
        n.view.frame = CGRectMake(n.lane * lw + 14, y, lw - 28, noteH);
    }
    [self.notes removeObjectsInArray:toRemove];
}

- (void)animateMissAt:(JFRhythmRuntimeNote *)n {
    UIView *v = n.view;
    [UIView animateWithDuration:0.25 animations:^{
        v.alpha = 0;
        v.transform = CGAffineTransformMakeScale(0.6, 0.6);
    } completion:^(BOOL finished) { [v removeFromSuperview]; }];
}

#pragma mark - 按键板

- (void)onPadDown:(UIButton *)b {
    NSInteger lane = b.tag;
    // 命中检测先做(瞬间响应),特效后做
    BOOL hit = NO;
    if (self.state == JFRhythmStatePlaying) hit = [self tryHitLane:lane];
    [self flashPad:b hit:hit];
}

- (void)onPadUp:(UIButton *)b {
    // 弹回原状态
    [UIView animateWithDuration:0.16 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:1.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
        b.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)flashPad:(UIButton *)b hit:(BOOL)hit {
    // 立刻按下:scale + 闪光圈,不等弹簧
    b.transform = CGAffineTransformMakeScale(0.9, 0.9);

    // 在 pad 上叠一层 ripple
    UIView *ripple = [[UIView alloc] initWithFrame:b.bounds];
    ripple.backgroundColor = hit ? [[JFTheme accent] colorWithAlphaComponent:0.55] : [[UIColor whiteColor] colorWithAlphaComponent:0.25];
    ripple.layer.cornerRadius = b.layer.cornerRadius;
    ripple.userInteractionEnabled = NO;
    [b addSubview:ripple];
    [UIView animateWithDuration:0.28 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        ripple.alpha = 0;
        ripple.transform = CGAffineTransformMakeScale(1.18, 1.18);
    } completion:^(BOOL finished) {
        [ripple removeFromSuperview];
    }];
}

- (BOOL)tryHitLane:(NSInteger)lane {
    JFRhythmRuntimeNote *best = nil;
    NSTimeInterval bestTimeDelta = CGFLOAT_MAX;
    NSTimeInterval songTime = [self currentSongTime];
    // 用"距离 targetTime 的时间差"而不是屏幕坐标做判定,更精确
    for (JFRhythmRuntimeNote *n in self.notes) {
        if (n.lane != lane || n.hit) continue;
        NSTimeInterval dt = fabs(songTime - n.targetTime);
        // 判定窗口:±0.32s,在窗口内取最近的那个
        if (dt > 0.32) continue;
        if (dt < bestTimeDelta) {
            bestTimeDelta = dt;
            best = n;
        }
    }
    if (!best) {
        // 没有可命中音符 —— 不立刻清 combo(避免提前按一下就破),而是轻微抖动 pad
        UIButton *pad = self.keyPads[lane];
        CAKeyframeAnimation *shake = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
        shake.values = @[@(-3), @(3), @(-2), @(2), @(0)];
        shake.duration = 0.16;
        [pad.layer addAnimation:shake forKey:@"jfPadShake"];
        return NO;
    }
    best.hit = YES;
    NSInteger pts;
    NSString *grade;
    UIColor *flashColor;
    // 时间差转为评级(更宽松)
    if (bestTimeDelta < 0.09)      { pts = 120; grade = @"PERFECT"; flashColor = [UIColor colorWithRed:1 green:0.85 blue:0.35 alpha:1]; self.perfectCount += 1; }
    else if (bestTimeDelta < 0.18) { pts = 80;  grade = @"GREAT";   flashColor = [JFTheme accent]; self.greatCount += 1; }
    else                            { pts = 40;  grade = @"GOOD";    flashColor = [UIColor colorWithWhite:1 alpha:0.9]; self.goodCount += 1; }
    self.score += pts + self.combo / 5;
    self.combo += 1;
    if (self.combo > self.maxCombo) self.maxCombo = self.combo;
    [self animateHit:best grade:grade color:flashColor];
    [self pulseJudgeLineWithColor:flashColor];
    [self animateComboPop];
    [self animateBigGrade:grade color:flashColor];
    [self updateLabels];
    return YES;
}

- (void)animateBigGrade:(NSString *)grade color:(UIColor *)color {
    UILabel *L = self.bigGradeLabel;
    L.text = grade;
    L.textColor = color;
    L.layer.shadowColor = color.CGColor;
    // 不同评级用不同字号:PERFECT 最大、GOOD 最小
    CGFloat fs = 56;
    if ([grade isEqualToString:@"PERFECT"]) fs = 64;
    else if ([grade isEqualToString:@"GREAT"]) fs = 56;
    else fs = 48;
    L.font = [UIFont systemFontOfSize:fs weight:UIFontWeightHeavy];

    [L.layer removeAllAnimations];
    L.alpha = 1.0;
    L.transform = CGAffineTransformMakeScale(1.6, 1.6);
    [UIView animateWithDuration:0.18 delay:0
         usingSpringWithDamping:0.45 initialSpringVelocity:1.8
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        L.transform = CGAffineTransformIdentity;
    } completion:nil];

    // PERFECT 时屏幕轻微抖一下,提升爽感
    if ([grade isEqualToString:@"PERFECT"]) {
        CAKeyframeAnimation *shake = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
        shake.values = @[@0, @(-4), @4, @(-3), @3, @(-1.5), @0];
        shake.duration = 0.22;
        [self.track.layer addAnimation:shake forKey:@"jfTrackShake"];
    }

    // 0.45s 后淡出
    NSString *snap = grade;
    NSInteger snapStamp = self.perfectCount + self.greatCount + self.goodCount;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![L.text isEqualToString:snap]) return;
        if ((self.perfectCount + self.greatCount + self.goodCount) != snapStamp) return;
        [UIView animateWithDuration:0.4 animations:^{
            L.alpha = 0;
        }];
    });
}

- (void)animateHit:(JFRhythmRuntimeNote *)n grade:(NSString *)grade color:(UIColor *)color {
    UIView *v = n.view;
    CGRect frame = v.frame;
    CGFloat centerX = CGRectGetMidX(frame);
    CGFloat judgeY = [self judgeY];
    UIColor *noteColor = n.color ?: color;

    // 主方块爆开
    [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        v.alpha = 0;
        v.transform = CGAffineTransformMakeScale(1.8, 1.8);
    } completion:^(BOOL finished) { [v removeFromSuperview]; }];

    // 双层光环
    for (NSInteger i = 0; i < 2; i++) {
        UIView *ring = [[UIView alloc] initWithFrame:CGRectMake(centerX - 24, judgeY - 24, 48, 48)];
        ring.backgroundColor = [UIColor clearColor];
        ring.layer.borderWidth = (i == 0) ? 3 : 1.5;
        ring.layer.borderColor = (i == 0 ? color : noteColor).CGColor;
        ring.layer.cornerRadius = 24;
        ring.userInteractionEnabled = NO;
        [self.track addSubview:ring];
        CGFloat scale = (i == 0) ? 2.6 : 3.4;
        NSTimeInterval delay = (i == 0) ? 0 : 0.06;
        [UIView animateWithDuration:0.5 delay:delay options:UIViewAnimationOptionCurveEaseOut animations:^{
            ring.transform = CGAffineTransformMakeScale(scale, scale);
            ring.alpha = 0;
        } completion:^(BOOL finished) { [ring removeFromSuperview]; }];
    }

    // 8 颗粒子四散
    NSInteger particleCount = 8;
    for (NSInteger i = 0; i < particleCount; i++) {
        UIView *p = [[UIView alloc] initWithFrame:CGRectMake(centerX - 4, judgeY - 4, 8, 8)];
        p.backgroundColor = (i % 2 == 0) ? noteColor : color;
        p.layer.cornerRadius = 4;
        p.userInteractionEnabled = NO;
        [self.track addSubview:p];
        CGFloat angle = (CGFloat)i / particleCount * (CGFloat)M_PI * 2.0 + ((CGFloat)arc4random_uniform(40) / 100.0);
        CGFloat dist = 50 + arc4random_uniform(40);
        CGFloat dx = cosf(angle) * dist;
        CGFloat dy = sinf(angle) * dist - 20; // 略往上飘
        [UIView animateWithDuration:0.55 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            p.transform = CGAffineTransformMakeTranslation(dx, dy);
            p.alpha = 0;
        } completion:^(BOOL finished) { [p removeFromSuperview]; }];
    }

    // 评级文字飘
    UILabel *gl = [[UILabel alloc] init];
    gl.text = grade;
    gl.textColor = color;
    gl.font = [UIFont systemFontOfSize:20 weight:UIFontWeightHeavy];
    gl.textAlignment = NSTextAlignmentCenter;
    gl.userInteractionEnabled = NO;
    gl.frame = CGRectMake(centerX - 60, judgeY - 40, 120, 26);
    gl.alpha = 0;
    gl.transform = CGAffineTransformMakeScale(0.6, 0.6);
    [self.track addSubview:gl];
    [UIView animateWithDuration:0.12 animations:^{
        gl.alpha = 1;
        gl.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 delay:0.08 options:UIViewAnimationOptionCurveEaseOut animations:^{
            gl.transform = CGAffineTransformMakeTranslation(0, -42);
            gl.alpha = 0;
        } completion:^(BOOL fin) { [gl removeFromSuperview]; }];
    }];
}

- (void)pulseJudgeLineWithColor:(UIColor *)color {
    UIColor *origLine = [JFTheme accent];
    self.judgeLine.backgroundColor = color;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.judgeLine.backgroundColor = origLine;
    } completion:nil];

    self.judgeGlow.alpha = 1;
    self.judgeGlow.backgroundColor = [color colorWithAlphaComponent:0.4];
    [UIView animateWithDuration:0.45 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.judgeGlow.backgroundColor = [[JFTheme accent] colorWithAlphaComponent:0.18];
        self.judgeGlow.alpha = 1;
    } completion:nil];
}

- (void)breakComboAnimation {
    UILabel *L = self.bigComboLabel;
    if (L.alpha <= 0.01) return;
    [UIView animateWithDuration:0.35 animations:^{
        L.transform = CGAffineTransformMakeScale(0.7, 0.7);
        L.alpha = 0;
    } completion:^(BOOL finished) {
        L.transform = CGAffineTransformIdentity;
    }];
}

- (void)animateComboPop {
    // 顶部 badge 小弹一下
    self.comboLabel.transform = CGAffineTransformMakeScale(1.0, 1.0);
    [UIView animateWithDuration:0.12 animations:^{
        self.comboLabel.transform = CGAffineTransformMakeScale(1.18, 1.18);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.18 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.comboLabel.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];

    // 中央大字:combo >= 2 才显示,数字越大越炸
    if (self.combo < 2) {
        [UIView animateWithDuration:0.25 animations:^{
            self.bigComboLabel.alpha = 0;
        }];
        return;
    }
    UILabel *L = self.bigComboLabel;
    L.text = [NSString stringWithFormat:@"%ld", (long)self.combo];
    // 颜色随 combo 升级
    UIColor *color;
    CGFloat fontSize;
    if (self.combo >= 50)      { color = [UIColor colorWithRed:1 green:0.4 blue:0.55 alpha:1]; fontSize = 132; }
    else if (self.combo >= 20) { color = [UIColor colorWithRed:1 green:0.78 blue:0.36 alpha:1]; fontSize = 116; }
    else if (self.combo >= 10) { color = [UIColor colorWithRed:0.36 green:0.85 blue:0.55 alpha:1]; fontSize = 100; }
    else                        { color = [UIColor whiteColor]; fontSize = 88; }
    L.textColor = color;
    L.layer.shadowColor = color.CGColor;
    L.font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightBlack];

    // 弹出 + 淡入 + 抖动:scale 1.4 -> 1.0 -> 1.05(spring)
    [L.layer removeAllAnimations];
    L.alpha = 1.0;
    L.transform = CGAffineTransformMakeScale(1.45, 1.45);
    [UIView animateWithDuration:0.18 delay:0
         usingSpringWithDamping:0.45 initialSpringVelocity:1.6
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        L.transform = CGAffineTransformIdentity;
    } completion:nil];

    // 失败保险:0.9s 后还在显示就慢慢淡出(下次命中会再点亮)
    NSInteger snapshotCombo = self.combo;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.combo != snapshotCombo) return;   // 期间又有命中,交给后续动画
        [UIView animateWithDuration:0.6 animations:^{
            self.bigComboLabel.alpha = 0.35;
        }];
    });
}

- (void)updateLabels {
    self.scoreLabel.text = [NSString stringWithFormat:@"%ld", (long)self.score];
    self.comboLabel.text = [NSString stringWithFormat:@"Combo %ld", (long)self.combo];
}

@end


#pragma mark - 选歌列表实现

@implementation JFRhythmSongListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"歌单";
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [JFTheme backgroundPrimary];
    [self.view addSubview:self.tableView];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAdd)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(onClose)];
}

- (void)onAdd {
    [self.delegate songListDidRequestImport:self];
}

- (void)onClose {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSArray<JFRhythmSong *> *)userSongs   { return [JFRhythmSongStore.shared userSongs]; }
- (NSArray<JFRhythmSong *> *)presetSongs { return [JFRhythmSongStore.shared presetSongs]; }

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 2; }

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return (s == 0) ? MAX(1, self.userSongs.count) : self.presetSongs.count;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
    return (s == 0) ? @"我导入的" : @"内置经典节奏";
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    static NSString *CID = @"songcell";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CID];
        cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
        cell.textLabel.textColor = [JFTheme textPrimary];
        cell.detailTextLabel.textColor = [JFTheme textSecondary];
    }
    if (ip.section == 0) {
        if (self.userSongs.count == 0) {
            cell.textLabel.text = @"还没导入歌曲";
            cell.detailTextLabel.text = @"点右上角 + 从「文件」中选一首";
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            JFRhythmSong *song = self.userSongs[ip.row];
            cell.textLabel.text = song.title;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"BPM %.0f · %.0fs · 长按删除", song.bpm, song.duration];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    } else {
        JFRhythmSong *song = self.presetSongs[ip.row];
        cell.textLabel.text = song.title;
        cell.detailTextLabel.text = song.artist;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    JFRhythmSong *song = nil;
    if (ip.section == 0) {
        if (self.userSongs.count == 0) return;
        song = self.userSongs[ip.row];
    } else {
        song = self.presetSongs[ip.row];
    }
    [self.delegate songList:self didPickSong:song];
}

- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip {
    return ip.section == 0 && self.userSongs.count > 0;
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)ip {
    if (style != UITableViewCellEditingStyleDelete) return;
    JFRhythmSong *song = self.userSongs[ip.row];
    [[JFRhythmSongStore shared] removeUserSong:song];
    [tv reloadData];
}

@end
