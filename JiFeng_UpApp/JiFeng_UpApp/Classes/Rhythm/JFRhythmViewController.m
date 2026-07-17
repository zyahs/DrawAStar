//
//  JFRhythmViewController.m
//
//  节奏大师 ——
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
static const NSTimeInterval kHitEarlyWindow = 0.20;
static const NSTimeInterval kHitLateWindow = 0.24;
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

#pragma mark - 多指输入面

@class JFRhythmInputView;
@protocol JFRhythmInputViewDelegate <NSObject>
- (void)rhythmInputView:(JFRhythmInputView *)view didPressLane:(NSInteger)lane;
- (void)rhythmInputView:(JFRhythmInputView *)view didMoveFromLane:(NSInteger)fromLane toLane:(NSInteger)toLane;
- (void)rhythmInputView:(JFRhythmInputView *)view didReleaseLane:(NSInteger)lane;
@end

@interface JFRhythmInputView : UIView
@property (nonatomic, weak) id<JFRhythmInputViewDelegate> delegate;
@property (nonatomic, strong) NSMapTable<UITouch *, NSNumber *> *laneByTouch;
@end

@implementation JFRhythmInputView

- (instancetype)init {
    if ((self = [super init])) {
        self.backgroundColor = UIColor.clearColor;
        self.multipleTouchEnabled = YES;
        self.exclusiveTouch = NO;
        _laneByTouch = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}

- (NSInteger)laneForTouch:(UITouch *)touch {
    CGFloat width = self.bounds.size.width;
    if (width <= 0) return NSNotFound;
    CGFloat x = [touch locationInView:self].x;
    NSInteger lane = (NSInteger)floor((x / width) * kLanes);
    return MAX(0, MIN(kLanes - 1, lane));
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    for (UITouch *touch in touches) {
        NSInteger lane = [self laneForTouch:touch];
        if (lane == NSNotFound) continue;
        [self.laneByTouch setObject:@(lane) forKey:touch];
        [self.delegate rhythmInputView:self didPressLane:lane];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    for (UITouch *touch in touches) {
        NSNumber *oldValue = [self.laneByTouch objectForKey:touch];
        if (!oldValue) continue;
        NSInteger oldLane = oldValue.integerValue;
        NSInteger newLane = [self laneForTouch:touch];
        if (newLane == NSNotFound || newLane == oldLane) continue;
        [self.laneByTouch setObject:@(newLane) forKey:touch];
        [self.delegate rhythmInputView:self didMoveFromLane:oldLane toLane:newLane];
    }
}

- (void)finishTouches:(NSSet<UITouch *> *)touches {
    for (UITouch *touch in touches) {
        NSNumber *laneValue = [self.laneByTouch objectForKey:touch];
        if (laneValue) [self.delegate rhythmInputView:self didReleaseLane:laneValue.integerValue];
        [self.laneByTouch removeObjectForKey:touch];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self finishTouches:touches];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self finishTouches:touches];
}

@end

#pragma mark - 音符视图

@interface JFRhythmNoteView : UIView
@property (nonatomic, assign) JFRhythmBeatType noteType;
@property (nonatomic, assign) NSInteger direction;
@property (nonatomic, strong) UIColor *noteColor;
@property (nonatomic, strong) CAShapeLayer *guideLayer;
@property (nonatomic, strong) CAGradientLayer *flowLayer;
@property (nonatomic, strong) CAShapeLayer *bodyLayer;
@property (nonatomic, strong) CAShapeLayer *accentLayer;
- (instancetype)initWithType:(JFRhythmBeatType)type color:(UIColor *)color direction:(NSInteger)direction;
- (void)setActionActive:(BOOL)active;
@end

@implementation JFRhythmNoteView

- (instancetype)initWithType:(JFRhythmBeatType)type color:(UIColor *)color direction:(NSInteger)direction {
    if ((self = [super init])) {
        _noteType = type;
        _noteColor = color;
        _direction = direction >= 0 ? 1 : -1;
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;
        self.layer.shadowColor = color.CGColor;
        self.layer.shadowOpacity = 0.76;
        self.layer.shadowRadius = 11;
        self.layer.shadowOffset = CGSizeZero;

        _guideLayer = [CAShapeLayer layer];
        _guideLayer.fillColor = UIColor.clearColor.CGColor;
        _guideLayer.lineCap = kCALineCapRound;
        [self.layer addSublayer:_guideLayer];

        _flowLayer = [CAGradientLayer layer];
        _flowLayer.opacity = type == JFRhythmBeatTypeTap ? 0 : 0.48;
        [self.layer addSublayer:_flowLayer];

        _bodyLayer = [CAShapeLayer layer];
        _bodyLayer.lineJoin = kCALineJoinRound;
        [self.layer addSublayer:_bodyLayer];

        _accentLayer = [CAShapeLayer layer];
        _accentLayer.fillColor = UIColor.clearColor.CGColor;
        _accentLayer.strokeColor = [[UIColor whiteColor] colorWithAlphaComponent:0.76].CGColor;
        _accentLayer.lineCap = kCALineCapRound;
        _accentLayer.lineJoin = kCALineJoinRound;
        [self.layer addSublayer:_accentLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    if (width <= 0 || height <= 0) return;

    self.guideLayer.frame = self.bounds;
    self.bodyLayer.frame = self.bounds;
    self.accentLayer.frame = self.bounds;
    self.bodyLayer.fillColor = self.noteColor.CGColor;
    self.bodyLayer.strokeColor = [[UIColor whiteColor] colorWithAlphaComponent:0.40].CGColor;
    self.bodyLayer.lineWidth = 1.2;
    self.guideLayer.strokeColor = [self.noteColor colorWithAlphaComponent:0.54].CGColor;

    if (self.noteType == JFRhythmBeatTypeTap) {
        CGRect body = CGRectInset(self.bounds, 2, 2);
        UIBezierPath *shape = [UIBezierPath bezierPathWithRoundedRect:body cornerRadius:MIN(10, CGRectGetHeight(body) * 0.28)];
        self.bodyLayer.path = shape.CGPath;
        UIBezierPath *shine = [UIBezierPath bezierPath];
        [shine moveToPoint:CGPointMake(CGRectGetMinX(body) + 10, CGRectGetMinY(body) + 6)];
        [shine addLineToPoint:CGPointMake(CGRectGetMaxX(body) - 10, CGRectGetMinY(body) + 6)];
        self.accentLayer.path = shine.CGPath;
        self.accentLayer.lineWidth = 2;
        self.guideLayer.path = nil;
        self.flowLayer.hidden = YES;
        return;
    }

    self.flowLayer.hidden = NO;
    if (self.noteType == JFRhythmBeatTypeHold) {
        CGFloat headHeight = MAX(30, MIN(44, width * 0.42));
        CGFloat beamWidth = MAX(13, MIN(30, width * 0.24));
        CGFloat centerX = width * 0.5;
        CGFloat headTop = MAX(0, height - headHeight);

        UIBezierPath *rail = [UIBezierPath bezierPath];
        [rail moveToPoint:CGPointMake(centerX, 8)];
        [rail addLineToPoint:CGPointMake(centerX, headTop + headHeight * 0.46)];
        self.guideLayer.path = rail.CGPath;
        self.guideLayer.lineWidth = beamWidth;
        self.guideLayer.shadowColor = self.noteColor.CGColor;
        self.guideLayer.shadowOpacity = 0.85;
        self.guideLayer.shadowRadius = 9;

        UIBezierPath *body = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(2, headTop, width - 4, headHeight - 2) cornerRadius:10];
        CGFloat capSize = beamWidth + 8;
        [body appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(centerX - capSize * 0.5, 2, capSize, capSize)]];
        self.bodyLayer.path = body.CGPath;

        UIBezierPath *laser = [UIBezierPath bezierPath];
        [laser moveToPoint:CGPointMake(centerX, 9)];
        [laser addLineToPoint:CGPointMake(centerX, headTop + headHeight * 0.44)];
        self.accentLayer.path = laser.CGPath;
        self.accentLayer.lineWidth = MAX(3, beamWidth * 0.22);
        self.accentLayer.lineDashPattern = @[@7, @9];

        self.flowLayer.frame = CGRectMake(centerX - beamWidth * 0.5, 4, beamWidth, MAX(4, headTop + headHeight * 0.45));
        self.flowLayer.cornerRadius = beamWidth * 0.5;
        self.flowLayer.startPoint = CGPointMake(0.5, 1);
        self.flowLayer.endPoint = CGPointMake(0.5, 0);
    } else {
        CGFloat centerY = height * 0.5;
        CGFloat radius = MAX(12, MIN(height * 0.40, 22));
        CGFloat startX = self.direction > 0 ? radius + 3 : width - radius - 3;
        CGFloat endX = self.direction > 0 ? width - radius - 3 : radius + 3;

        UIBezierPath *rail = [UIBezierPath bezierPath];
        [rail moveToPoint:CGPointMake(startX, centerY)];
        [rail addLineToPoint:CGPointMake(endX, centerY)];
        self.guideLayer.path = rail.CGPath;
        self.guideLayer.lineWidth = MAX(10, height * 0.30);

        UIBezierPath *body = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(startX - radius, centerY - radius, radius * 2, radius * 2)];
        [body appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(endX - radius, centerY - radius, radius * 2, radius * 2)]];
        self.bodyLayer.path = body.CGPath;

        UIBezierPath *arrows = [UIBezierPath bezierPath];
        [arrows moveToPoint:CGPointMake(startX, centerY)];
        [arrows addLineToPoint:CGPointMake(endX, centerY)];
        CGFloat sign = self.direction > 0 ? 1 : -1;
        for (NSInteger i = 1; i <= 3; i++) {
            CGFloat x = startX + (endX - startX) * (i / 4.0);
            [arrows moveToPoint:CGPointMake(x - sign * 6, centerY - 6)];
            [arrows addLineToPoint:CGPointMake(x, centerY)];
            [arrows addLineToPoint:CGPointMake(x - sign * 6, centerY + 6)];
        }
        self.accentLayer.path = arrows.CGPath;
        self.accentLayer.lineWidth = 2.5;
        self.accentLayer.lineDashPattern = @[@8, @7];

        CGFloat left = MIN(startX, endX);
        self.flowLayer.frame = CGRectMake(left, centerY - 7, fabs(endX - startX), 14);
        self.flowLayer.cornerRadius = 7;
        self.flowLayer.startPoint = self.direction > 0 ? CGPointMake(0, 0.5) : CGPointMake(1, 0.5);
        self.flowLayer.endPoint = self.direction > 0 ? CGPointMake(1, 0.5) : CGPointMake(0, 0.5);
    }

    self.flowLayer.colors = @[
        (__bridge id)[UIColor clearColor].CGColor,
        (__bridge id)[self.noteColor colorWithAlphaComponent:0.48].CGColor,
        (__bridge id)[UIColor colorWithWhite:1 alpha:0.92].CGColor,
        (__bridge id)[self.noteColor colorWithAlphaComponent:0.82].CGColor,
        (__bridge id)[UIColor clearColor].CGColor,
    ];
    self.flowLayer.locations = @[@0, @0.26, @0.50, @0.74, @1];
}

- (void)setActionActive:(BOOL)active {
    [self.flowLayer removeAnimationForKey:@"jfFlow"];
    [self.accentLayer removeAnimationForKey:@"jfDash"];
    [self.bodyLayer removeAnimationForKey:@"jfHeadPulse"];
    self.flowLayer.opacity = active ? 1.0 : 0.48;
    self.layer.shadowOpacity = active ? 1.0 : 0.76;
    self.layer.shadowRadius = active ? 22 : 11;
    if (!active) return;

    CABasicAnimation *flow = [CABasicAnimation animationWithKeyPath:@"locations"];
    flow.fromValue = @[@(-0.45), @(-0.20), @0.02, @0.24, @0.48];
    flow.toValue = @[@0.52, @0.76, @0.98, @1.20, @1.45];
    flow.duration = self.noteType == JFRhythmBeatTypeHold ? 0.42 : 0.30;
    flow.repeatCount = HUGE_VALF;
    [self.flowLayer addAnimation:flow forKey:@"jfFlow"];

    CABasicAnimation *dash = [CABasicAnimation animationWithKeyPath:@"lineDashPhase"];
    dash.fromValue = @0;
    dash.toValue = @(self.direction * -32);
    dash.duration = 0.38;
    dash.repeatCount = HUGE_VALF;
    [self.accentLayer addAnimation:dash forKey:@"jfDash"];

    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
    pulse.fromValue = @0.72;
    pulse.toValue = @1.0;
    pulse.duration = 0.22;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [self.bodyLayer addAnimation:pulse forKey:@"jfHeadPulse"];
}

@end

#pragma mark - 运行时音符

@interface JFRhythmRuntimeNote : NSObject
@property (nonatomic, assign) NSInteger lane;
@property (nonatomic, assign) NSInteger endLane;
@property (nonatomic, assign) NSTimeInterval targetTime;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) double strength;
@property (nonatomic, assign) JFRhythmBeatType type;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) BOOL hit;
@property (nonatomic, assign) BOOL holding;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) NSTimeInterval startGradeDelta;
@end
@implementation JFRhythmRuntimeNote @end

#pragma mark - 主页面

@interface JFRhythmViewController () <UIDocumentPickerDelegate, AVAudioPlayerDelegate, JFRhythmSongListDelegate, JFRhythmInputViewDelegate>

// UI
@property (nonatomic, strong) UIView *setupView;
@property (nonatomic, strong) UIView *setupPanel;
@property (nonatomic, strong) UIView *setupVisualView;
@property (nonatomic, strong) NSArray<UIView *> *setupWaveBars;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *eyebrowLabel;
@property (nonatomic, strong) UILabel *bestLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UILabel *comboLabel;
@property (nonatomic, strong) UILabel *bigComboLabel;   // 屏幕中央大字 combo
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *songLabel;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIStackView *hudStack;
@property (nonatomic, strong) UIView *gameInfoView;
@property (nonatomic, strong) UILabel *gameSongLabel;
@property (nonatomic, strong) UIView *progressTrackView;
@property (nonatomic, strong) UIView *progressFillView;
@property (nonatomic, strong) UIView  *track;
@property (nonatomic, strong) UIView  *judgeLine;
@property (nonatomic, strong) UIView  *judgeGlow;
@property (nonatomic, strong) NSArray<UIView *> *laneViews;
@property (nonatomic, strong) NSArray<UIView *> *laneBeamViews;
@property (nonatomic, strong) NSArray<UIButton *> *keyPads;
@property (nonatomic, strong) NSArray<UILabel *> *keyLabels;
@property (nonatomic, strong) NSArray<UIColor *> *laneColors;
@property (nonatomic, strong) JFRhythmInputView *inputView;
@property (nonatomic, strong) UIButton *libraryButton;   // 选歌
@property (nonatomic, strong) UIButton *startButton;     // 开始/继续
@property (nonatomic, strong) UIButton *pauseButton;     // 暂停
@property (nonatomic, strong) UISegmentedControl *diffSeg; // 难度:简单/中等/困难
@property (nonatomic, strong) UIView *pauseOverlay;
@property (nonatomic, strong) UIView *pausePanel;
@property (nonatomic, strong) UILabel *pauseSongLabel;
@property (nonatomic, strong) UISegmentedControl *pauseDiffSeg;
@property (nonatomic, strong) UILabel *bigGradeLabel;    // 屏幕中央大字 PERFECT/GREAT/GOOD
@property (nonatomic, strong) UIView *tutorialCoachView;
@property (nonatomic, strong) UIImageView *tutorialIconView;
@property (nonatomic, strong) UILabel *tutorialStepLabel;
@property (nonatomic, strong) UILabel *tutorialTitleLabel;
@property (nonatomic, strong) UILabel *tutorialDetailLabel;
@property (nonatomic, strong) NSArray<UIImageView *> *tutorialLaneGuides;
@property (nonatomic, strong) CAGradientLayer *backgroundGradient;
@property (nonatomic, strong) CAGradientLayer *trackGradient;
@property (nonatomic, assign) BOOL shouldRestorePortraitOnExit;

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
@property (nonatomic, assign) NSInteger tutorialStepIndex;
@property (nonatomic, assign) NSTimeInterval tutorialFeedbackUntil;
@property (nonatomic, copy) NSString *tutorialFeedbackText;

@end

@implementation JFRhythmViewController

#pragma mark - 屏幕方向

- (BOOL)shouldAutorotate { return YES; }

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self jf_requestLandscape];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    BOOL exiting = self.isMovingFromParentViewController || self.isBeingDismissed || self.navigationController.isBeingDismissed;
    if (exiting) [self stopAndCleanup];
    self.shouldRestorePortraitOnExit = exiting;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!self.shouldRestorePortraitOnExit) return;
    self.shouldRestorePortraitOnExit = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self jf_requestPortraitAfterExit];
    });
}

- (void)jf_requestLandscape {
    if (@available(iOS 16.0, *)) {
        UIWindowScene *scene = nil;
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]] && s.activationState == UISceneActivationStateForegroundActive) {
                scene = (UIWindowScene *)s;
                break;
            }
        }
        if (scene) {
            UIWindowSceneGeometryPreferencesIOS *pref =
                [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:UIInterfaceOrientationMaskLandscape];
            [scene requestGeometryUpdateWithPreferences:pref errorHandler:^(NSError * _Nonnull error) {
                NSLog(@"[Rhythm] request landscape failed: %@", error);
            }];
        }
        [self setNeedsUpdateOfSupportedInterfaceOrientations];
    } else {
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeRight) forKey:@"orientation"];
        [UIViewController attemptRotationToDeviceOrientation];
    }
}

- (void)jf_requestPortraitAfterExit {
    if (@available(iOS 16.0, *)) {
        [self.navigationController setNeedsUpdateOfSupportedInterfaceOrientations];
        UIWindowScene *scene = nil;
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]] && s.activationState == UISceneActivationStateForegroundActive) {
                scene = (UIWindowScene *)s;
                break;
            }
        }
        if (scene) {
            UIWindowSceneGeometryPreferencesIOS *pref =
                [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:UIInterfaceOrientationMaskPortrait];
            [scene requestGeometryUpdateWithPreferences:pref errorHandler:^(NSError * _Nonnull error) { }];
        }
    } else {
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
        [UIViewController attemptRotationToDeviceOrientation];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.jfSuppressBackButton = YES;
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.best = [[NSUserDefaults standardUserDefaults] integerForKey:kBestKey];
    self.notes = [NSMutableArray array];
    self.pendingBeats = [NSMutableArray array];
    self.fallDuration = 1.85;
    self.state = JFRhythmStateIdle;
    self.tutorialStepIndex = NSNotFound;

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
    JFRhythmSong *tutorial = nil;
    for (JFRhythmSong *song in JFRhythmSongStore.shared.presetSongs) {
        if (song.isTutorial) { tutorial = song; break; }
    }
    if (tutorial) {
        [self loadSong:tutorial];
    } else {
        [self syncButtonsForState];
        [self refreshSongLabel];
    }
}

- (BOOL)jf_prefersThemedBackground {
    return NO;
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
    self.backgroundGradient = [CAGradientLayer layer];
    self.backgroundGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:0.015 green:0.018 blue:0.035 alpha:1].CGColor,
        (__bridge id)[[JFTheme brandPrimary] colorWithAlphaComponent:0.42].CGColor,
        (__bridge id)[[JFTheme accent] colorWithAlphaComponent:0.20].CGColor,
        (__bridge id)[UIColor colorWithRed:0.008 green:0.012 blue:0.026 alpha:1].CGColor
    ];
    self.backgroundGradient.locations = @[@0, @0.42, @0.72, @1];
    self.backgroundGradient.startPoint = CGPointMake(0.05, 0.08);
    self.backgroundGradient.endPoint = CGPointMake(0.96, 0.92);
    [self.view.layer addSublayer:self.backgroundGradient];

    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.24];
    overlay.userInteractionEnabled = NO;
    [self.view addSubview:overlay];
}

- (void)buildUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    self.track = [[UIView alloc] init];
    self.track.translatesAutoresizingMaskIntoConstraints = NO;
    self.track.backgroundColor = [UIColor colorWithWhite:0 alpha:0.18];
    self.track.clipsToBounds = YES;
    [self.view addSubview:self.track];

    self.trackGradient = [CAGradientLayer layer];
    self.trackGradient.colors = @[
        (__bridge id)[UIColor colorWithWhite:1 alpha:0.055].CGColor,
        (__bridge id)[UIColor colorWithRed:0.018 green:0.025 blue:0.055 alpha:0.86].CGColor,
        (__bridge id)[UIColor colorWithRed:0.004 green:0.006 blue:0.018 alpha:0.98].CGColor
    ];
    self.trackGradient.locations = @[@0, @0.38, @1];
    self.trackGradient.startPoint = CGPointMake(0.5, 0);
    self.trackGradient.endPoint = CGPointMake(0.5, 1);
    [self.track.layer addSublayer:self.trackGradient];

    self.judgeGlow = [[UIView alloc] init];
    self.judgeGlow.backgroundColor = [[JFTheme accent] colorWithAlphaComponent:0.18];
    self.judgeGlow.userInteractionEnabled = NO;
    [self.track addSubview:self.judgeGlow];

    self.judgeLine = [[UIView alloc] init];
    self.judgeLine.backgroundColor = [JFTheme accent];
    self.judgeLine.userInteractionEnabled = NO;
    [self.track addSubview:self.judgeLine];

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
    NSMutableArray *beams = [NSMutableArray array];
    NSMutableArray *pads  = [NSMutableArray array];
    NSMutableArray *kls   = [NSMutableArray array];
    NSMutableArray *tutorialGuides = [NSMutableArray array];
    NSArray<UIColor *>  *keyColors = @[
        [UIColor colorWithRed:1.00 green:0.34 blue:0.48 alpha:1],
        [UIColor colorWithRed:1.00 green:0.76 blue:0.25 alpha:1],
        [UIColor colorWithRed:0.18 green:0.80 blue:0.98 alpha:1],
        [UIColor colorWithRed:0.34 green:0.92 blue:0.62 alpha:1],
    ];
    self.laneColors = keyColors;
    for (NSInteger i = 0; i < kLanes; i++) {
        UIView *lane = [[UIView alloc] init];
        lane.userInteractionEnabled = NO;
        lane.backgroundColor = (i % 2 == 0) ? [UIColor colorWithWhite:1 alpha:0.032] : [UIColor colorWithWhite:1 alpha:0.012];
        [self.track addSubview:lane];
        [lanes addObject:lane];

        UIView *beam = [[UIView alloc] init];
        beam.userInteractionEnabled = NO;
        beam.backgroundColor = [keyColors[i] colorWithAlphaComponent:0.24];
        beam.layer.cornerRadius = 1;
        beam.layer.shadowColor = keyColors[i].CGColor;
        beam.layer.shadowOpacity = 0.30;
        beam.layer.shadowRadius = 5;
        beam.layer.shadowOffset = CGSizeZero;
        [self.track addSubview:beam];
        [beams addObject:beam];

        UIButton *pad = [UIButton buttonWithType:UIButtonTypeCustom];
        pad.tag = i;
        pad.userInteractionEnabled = NO;
        pad.backgroundColor = [keyColors[i] colorWithAlphaComponent:0.12];
        pad.layer.cornerRadius = 8;
        pad.layer.cornerCurve = kCACornerCurveContinuous;
        pad.layer.borderWidth = 1.0;
        pad.layer.borderColor = [keyColors[i] colorWithAlphaComponent:0.56].CGColor;
        pad.layer.shadowColor = keyColors[i].CGColor;
        pad.layer.shadowOpacity = 0.32;
        pad.layer.shadowRadius = 9;
        pad.layer.shadowOffset = CGSizeZero;
        [self.track addSubview:pad];
        [pads addObject:pad];

        UILabel *kl = [[UILabel alloc] init];
        kl.backgroundColor = keyColors[i];
        kl.layer.cornerRadius = 1.5;
        kl.layer.shadowColor = keyColors[i].CGColor;
        kl.layer.shadowOpacity = 0.75;
        kl.layer.shadowRadius = 5;
        kl.userInteractionEnabled = NO;
        [self.track addSubview:kl];
        [kls addObject:kl];

        UIImageSymbolConfiguration *guideConfig = [UIImageSymbolConfiguration configurationWithPointSize:13 weight:UIImageSymbolWeightBlack];
        UIImageView *guide = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"arrowtriangle.down.fill" withConfiguration:guideConfig]];
        guide.contentMode = UIViewContentModeCenter;
        guide.tintColor = keyColors[i];
        guide.backgroundColor = [UIColor colorWithWhite:0.02 alpha:0.86];
        guide.layer.cornerRadius = 7;
        guide.layer.borderWidth = 1;
        guide.layer.borderColor = [keyColors[i] colorWithAlphaComponent:0.85].CGColor;
        guide.layer.shadowColor = keyColors[i].CGColor;
        guide.layer.shadowOpacity = 0.74;
        guide.layer.shadowRadius = 8;
        guide.layer.shadowOffset = CGSizeZero;
        guide.userInteractionEnabled = NO;
        guide.hidden = YES;
        CABasicAnimation *guidePulse = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
        guidePulse.fromValue = @(-2);
        guidePulse.toValue = @(3);
        guidePulse.duration = 0.38;
        guidePulse.autoreverses = YES;
        guidePulse.repeatCount = HUGE_VALF;
        [guide.layer addAnimation:guidePulse forKey:@"jfTutorialGuidePulse"];
        [self.track addSubview:guide];
        [tutorialGuides addObject:guide];
    }
    self.laneViews = lanes;
    self.laneBeamViews = beams;
    self.keyPads = pads;
    self.keyLabels = kls;
    self.tutorialLaneGuides = tutorialGuides;
    self.view.multipleTouchEnabled = YES;
    self.track.multipleTouchEnabled = YES;

    self.inputView = [[JFRhythmInputView alloc] init];
    self.inputView.delegate = self;
    [self.track addSubview:self.inputView];

    self.scoreLabel = [self badgeLabel];
    self.comboLabel = [self badgeLabel];
    self.scoreLabel.text = @"SCORE  000000";
    self.comboLabel.text = @"COMBO  0";
    self.hudStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.scoreLabel, self.comboLabel]];
    self.hudStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.hudStack.axis = UILayoutConstraintAxisHorizontal;
    self.hudStack.spacing = 16;
    self.hudStack.distribution = UIStackViewDistributionFillEqually;
    [self.view addSubview:self.hudStack];

    self.gameInfoView = [[UIView alloc] init];
    self.gameInfoView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.gameInfoView];

    self.gameSongLabel = [[UILabel alloc] init];
    self.gameSongLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.gameSongLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.82];
    self.gameSongLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    self.gameSongLabel.textAlignment = NSTextAlignmentCenter;
    self.gameSongLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self.gameInfoView addSubview:self.gameSongLabel];

    self.timeLabel = [self badgeLabel];
    self.timeLabel.text = @"00:00";
    self.timeLabel.textAlignment = NSTextAlignmentRight;
    [self.gameInfoView addSubview:self.timeLabel];

    self.progressTrackView = [[UIView alloc] init];
    self.progressTrackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressTrackView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.14];
    self.progressTrackView.layer.cornerRadius = 1.5;
    self.progressTrackView.clipsToBounds = YES;
    [self.gameInfoView addSubview:self.progressTrackView];

    self.progressFillView = [[UIView alloc] initWithFrame:CGRectZero];
    self.progressFillView.backgroundColor = [JFTheme accent];
    self.progressFillView.layer.cornerRadius = 1.5;
    [self.progressTrackView addSubview:self.progressFillView];

    self.pauseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.pauseButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.pauseButton.tintColor = [UIColor whiteColor];
    self.pauseButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.09];
    self.pauseButton.layer.cornerRadius = 8;
    self.pauseButton.layer.cornerCurve = kCACornerCurveContinuous;
    self.pauseButton.layer.borderWidth = 1;
    self.pauseButton.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16].CGColor;
    UIImageSymbolConfiguration *pauseCfg = [UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold];
    [self.pauseButton setImage:[UIImage systemImageNamed:@"pause.fill" withConfiguration:pauseCfg] forState:UIControlStateNormal];
    [self.pauseButton addTarget:self action:@selector(onPause) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.pauseButton];

    self.tutorialCoachView = [[UIView alloc] init];
    self.tutorialCoachView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tutorialCoachView.backgroundColor = [UIColor colorWithRed:0.025 green:0.032 blue:0.055 alpha:0.94];
    self.tutorialCoachView.layer.cornerRadius = 8;
    self.tutorialCoachView.layer.cornerCurve = kCACornerCurveContinuous;
    self.tutorialCoachView.layer.borderWidth = 1;
    self.tutorialCoachView.layer.borderColor = [[JFTheme accent] colorWithAlphaComponent:0.58].CGColor;
    self.tutorialCoachView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.tutorialCoachView.layer.shadowOpacity = 0.42;
    self.tutorialCoachView.layer.shadowRadius = 14;
    self.tutorialCoachView.layer.shadowOffset = CGSizeMake(0, 7);
    self.tutorialCoachView.userInteractionEnabled = NO;
    self.tutorialCoachView.hidden = YES;
    [self.view addSubview:self.tutorialCoachView];

    UIImageSymbolConfiguration *coachIconConfig = [UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightBold];
    self.tutorialIconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"sparkles" withConfiguration:coachIconConfig]];
    self.tutorialIconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tutorialIconView.contentMode = UIViewContentModeCenter;
    self.tutorialIconView.tintColor = [JFTheme accent];
    self.tutorialIconView.backgroundColor = [[JFTheme accent] colorWithAlphaComponent:0.13];
    self.tutorialIconView.layer.cornerRadius = 8;
    [self.tutorialCoachView addSubview:self.tutorialIconView];

    self.tutorialStepLabel = [[UILabel alloc] init];
    self.tutorialStepLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.tutorialStepLabel.textColor = [JFTheme accent];
    self.tutorialStepLabel.font = [UIFont monospacedDigitSystemFontOfSize:9.5 weight:UIFontWeightBold];
    [self.tutorialCoachView addSubview:self.tutorialStepLabel];

    self.tutorialTitleLabel = [[UILabel alloc] init];
    self.tutorialTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.tutorialTitleLabel.textColor = [UIColor whiteColor];
    self.tutorialTitleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [self.tutorialCoachView addSubview:self.tutorialTitleLabel];

    self.tutorialDetailLabel = [[UILabel alloc] init];
    self.tutorialDetailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.tutorialDetailLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.64];
    self.tutorialDetailLabel.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightMedium];
    self.tutorialDetailLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.tutorialCoachView addSubview:self.tutorialDetailLabel];

    self.setupView = [[UIView alloc] init];
    self.setupView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.setupView];

    self.backButton = [JFTheme backButtonWithTarget:self action:@selector(onBack)];
    [self.setupView addSubview:self.backButton];

    self.eyebrowLabel = [[UILabel alloc] init];
    self.eyebrowLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.eyebrowLabel.text = @"RHYTHM DRIVE";
    self.eyebrowLabel.textColor = [JFTheme accent];
    self.eyebrowLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBlack];
    [self.setupView addSubview:self.eyebrowLabel];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"节奏大师";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBlack];
    [self.setupView addSubview:self.titleLabel];

    self.setupVisualView = [[UIView alloc] init];
    self.setupVisualView.translatesAutoresizingMaskIntoConstraints = NO;
    self.setupVisualView.clipsToBounds = YES;
    [self.setupView addSubview:self.setupVisualView];

    NSMutableArray<UIView *> *waveBars = [NSMutableArray array];
    for (NSInteger i = 0; i < 14; i++) {
        UIView *bar = [[UIView alloc] init];
        UIColor *barColor = keyColors[i % keyColors.count];
        bar.backgroundColor = [barColor colorWithAlphaComponent:0.80];
        bar.layer.cornerRadius = 2;
        bar.layer.anchorPoint = CGPointMake(0.5, 1.0);
        bar.layer.shadowColor = barColor.CGColor;
        bar.layer.shadowOpacity = 0.65;
        bar.layer.shadowRadius = 7;
        [self.setupVisualView addSubview:bar];
        [waveBars addObject:bar];
    }
    self.setupWaveBars = waveBars;

    self.bestLabel = [[UILabel alloc] init];
    self.bestLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.bestLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.78];
    self.bestLabel.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightSemibold];
    self.bestLabel.text = [NSString stringWithFormat:@"BEST  %06ld", (long)self.best];
    [self.setupVisualView addSubview:self.bestLabel];

    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.hintLabel.text = @"点按 / 长按 / 滑动";
    self.hintLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.48];
    self.hintLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [self.setupVisualView addSubview:self.hintLabel];

    self.setupPanel = [[UIView alloc] init];
    self.setupPanel.translatesAutoresizingMaskIntoConstraints = NO;
    self.setupPanel.backgroundColor = [UIColor colorWithWhite:0.035 alpha:0.76];
    self.setupPanel.layer.cornerRadius = 8;
    self.setupPanel.layer.cornerCurve = kCACornerCurveContinuous;
    self.setupPanel.layer.borderWidth = 1;
    self.setupPanel.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.13].CGColor;
    self.setupPanel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.setupPanel.layer.shadowOpacity = 0.34;
    self.setupPanel.layer.shadowRadius = 18;
    self.setupPanel.layer.shadowOffset = CGSizeMake(0, 10);
    [self.setupView addSubview:self.setupPanel];

    UILabel *currentTrackLabel = [[UILabel alloc] init];
    currentTrackLabel.translatesAutoresizingMaskIntoConstraints = NO;
    currentTrackLabel.text = @"当前曲目";
    currentTrackLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.48];
    currentTrackLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    [self.setupPanel addSubview:currentTrackLabel];

    self.songLabel = [[UILabel alloc] init];
    self.songLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.songLabel.textColor = [UIColor whiteColor];
    self.songLabel.font = [UIFont systemFontOfSize:21 weight:UIFontWeightBold];
    self.songLabel.numberOfLines = 2;
    self.songLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.setupPanel addSubview:self.songLabel];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.textColor = [JFTheme accent];
    self.statusLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.statusLabel.numberOfLines = 2;
    [self.setupPanel addSubview:self.statusLabel];

    UIView *panelSeparator = [[UIView alloc] init];
    panelSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    panelSeparator.backgroundColor = [UIColor colorWithWhite:1 alpha:0.10];
    [self.setupPanel addSubview:panelSeparator];

    UILabel *difficultyLabel = [[UILabel alloc] init];
    difficultyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    difficultyLabel.text = @"难度";
    difficultyLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.55];
    difficultyLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    [self.setupPanel addSubview:difficultyLabel];

    self.diffSeg = [[UISegmentedControl alloc] initWithItems:@[@"简单", @"中等", @"困难"]];
    self.diffSeg.translatesAutoresizingMaskIntoConstraints = NO;
    self.diffSeg.selectedSegmentIndex = self.difficulty;
    self.diffSeg.selectedSegmentTintColor = [JFTheme accent];
    self.diffSeg.backgroundColor = [UIColor colorWithWhite:1 alpha:0.07];
    [self.diffSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [JFTheme textOnAccent]} forState:UIControlStateSelected];
    [self.diffSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.72]} forState:UIControlStateNormal];
    [self.diffSeg addTarget:self action:@selector(onDifficultyChanged:) forControlEvents:UIControlEventValueChanged];
    [self.setupPanel addSubview:self.diffSeg];

    self.libraryButton = [self secondaryButtonWithTitle:@"选曲" action:@selector(onOpenLibrary)];
    self.startButton = [self primaryButtonWithTitle:@"开始" action:@selector(onStartOrResume)];
    [self.libraryButton setImage:[UIImage systemImageNamed:@"music.note.list"] forState:UIControlStateNormal];
    [self.startButton setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal];
    self.libraryButton.tintColor = [UIColor whiteColor];
    self.startButton.tintColor = [UIColor colorWithWhite:0.04 alpha:1];
    UIStackView *setupActions = [[UIStackView alloc] initWithArrangedSubviews:@[self.libraryButton, self.startButton]];
    setupActions.translatesAutoresizingMaskIntoConstraints = NO;
    setupActions.axis = UILayoutConstraintAxisHorizontal;
    setupActions.spacing = 10;
    setupActions.distribution = UIStackViewDistributionFillEqually;
    [self.setupPanel addSubview:setupActions];

    NSLayoutConstraint *panelWidth = [self.setupPanel.widthAnchor constraintEqualToAnchor:self.setupView.widthAnchor multiplier:0.40];
    panelWidth.priority = UILayoutPriorityDefaultHigh;
    NSLayoutConstraint *tutorialFixedWidth = [self.tutorialCoachView.widthAnchor constraintEqualToConstant:430];
    tutorialFixedWidth.priority = 999;
    NSLayoutConstraint *tutorialAvailableWidth = [self.tutorialCoachView.widthAnchor constraintEqualToAnchor:safe.widthAnchor constant:-24];
    tutorialAvailableWidth.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [self.track.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [self.track.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [self.track.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [self.track.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],

        [self.hudStack.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [self.hudStack.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.hudStack.widthAnchor constraintEqualToConstant:246],
        [self.hudStack.heightAnchor constraintEqualToConstant:38],

        [self.pauseButton.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10],
        [self.pauseButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.pauseButton.widthAnchor constraintEqualToConstant:44],
        [self.pauseButton.heightAnchor constraintEqualToConstant:44],

        [self.tutorialCoachView.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [self.tutorialCoachView.topAnchor constraintEqualToAnchor:safe.topAnchor constant:58],
        tutorialFixedWidth,
        tutorialAvailableWidth,
        [self.tutorialCoachView.heightAnchor constraintEqualToConstant:72],
        [self.tutorialCoachView.leadingAnchor constraintGreaterThanOrEqualToAnchor:safe.leadingAnchor constant:12],
        [self.tutorialCoachView.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-12],
        [self.tutorialIconView.leadingAnchor constraintEqualToAnchor:self.tutorialCoachView.leadingAnchor constant:12],
        [self.tutorialIconView.centerYAnchor constraintEqualToAnchor:self.tutorialCoachView.centerYAnchor],
        [self.tutorialIconView.widthAnchor constraintEqualToConstant:40],
        [self.tutorialIconView.heightAnchor constraintEqualToConstant:40],
        [self.tutorialStepLabel.leadingAnchor constraintEqualToAnchor:self.tutorialIconView.trailingAnchor constant:12],
        [self.tutorialStepLabel.trailingAnchor constraintEqualToAnchor:self.tutorialCoachView.trailingAnchor constant:-12],
        [self.tutorialStepLabel.topAnchor constraintEqualToAnchor:self.tutorialCoachView.topAnchor constant:8],
        [self.tutorialTitleLabel.leadingAnchor constraintEqualToAnchor:self.tutorialStepLabel.leadingAnchor],
        [self.tutorialTitleLabel.trailingAnchor constraintEqualToAnchor:self.tutorialStepLabel.trailingAnchor],
        [self.tutorialTitleLabel.topAnchor constraintEqualToAnchor:self.tutorialStepLabel.bottomAnchor constant:1],
        [self.tutorialDetailLabel.leadingAnchor constraintEqualToAnchor:self.tutorialStepLabel.leadingAnchor],
        [self.tutorialDetailLabel.trailingAnchor constraintEqualToAnchor:self.tutorialStepLabel.trailingAnchor],
        [self.tutorialDetailLabel.topAnchor constraintEqualToAnchor:self.tutorialTitleLabel.bottomAnchor],
        [self.tutorialDetailLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.tutorialCoachView.bottomAnchor constant:-7],

        [self.gameInfoView.leadingAnchor constraintEqualToAnchor:self.hudStack.trailingAnchor constant:18],
        [self.gameInfoView.trailingAnchor constraintEqualToAnchor:self.pauseButton.leadingAnchor constant:-18],
        [self.gameInfoView.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10],
        [self.gameInfoView.heightAnchor constraintEqualToConstant:44],

        [self.gameSongLabel.leadingAnchor constraintEqualToAnchor:self.gameInfoView.leadingAnchor],
        [self.gameSongLabel.trailingAnchor constraintEqualToAnchor:self.timeLabel.leadingAnchor constant:-8],
        [self.gameSongLabel.topAnchor constraintEqualToAnchor:self.gameInfoView.topAnchor],
        [self.gameSongLabel.heightAnchor constraintEqualToConstant:22],
        [self.timeLabel.trailingAnchor constraintEqualToAnchor:self.gameInfoView.trailingAnchor],
        [self.timeLabel.centerYAnchor constraintEqualToAnchor:self.gameSongLabel.centerYAnchor],
        [self.timeLabel.widthAnchor constraintEqualToConstant:52],
        [self.progressTrackView.leadingAnchor constraintEqualToAnchor:self.gameInfoView.leadingAnchor],
        [self.progressTrackView.trailingAnchor constraintEqualToAnchor:self.gameInfoView.trailingAnchor],
        [self.progressTrackView.topAnchor constraintEqualToAnchor:self.gameSongLabel.bottomAnchor constant:5],
        [self.progressTrackView.heightAnchor constraintEqualToConstant:3],

        [self.setupView.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [self.setupView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [self.setupView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [self.setupView.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],

        [self.backButton.leadingAnchor constraintEqualToAnchor:self.setupView.leadingAnchor constant:14],
        [self.backButton.topAnchor constraintEqualToAnchor:self.setupView.topAnchor constant:12],
        [self.backButton.widthAnchor constraintEqualToConstant:42],
        [self.backButton.heightAnchor constraintEqualToConstant:42],

        [self.eyebrowLabel.leadingAnchor constraintEqualToAnchor:self.backButton.trailingAnchor constant:16],
        [self.eyebrowLabel.topAnchor constraintEqualToAnchor:self.setupView.topAnchor constant:13],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.eyebrowLabel.leadingAnchor],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.eyebrowLabel.bottomAnchor constant:1],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.setupPanel.leadingAnchor constant:-24],

        [self.setupVisualView.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.setupVisualView.trailingAnchor constraintEqualToAnchor:self.setupPanel.leadingAnchor constant:-28],
        [self.setupVisualView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:12],
        [self.setupVisualView.bottomAnchor constraintEqualToAnchor:self.setupView.bottomAnchor constant:-20],
        [self.bestLabel.leadingAnchor constraintEqualToAnchor:self.setupVisualView.leadingAnchor],
        [self.bestLabel.topAnchor constraintEqualToAnchor:self.setupVisualView.topAnchor],
        [self.hintLabel.leadingAnchor constraintEqualToAnchor:self.setupVisualView.leadingAnchor],
        [self.hintLabel.bottomAnchor constraintEqualToAnchor:self.setupVisualView.bottomAnchor],

        [self.setupPanel.trailingAnchor constraintEqualToAnchor:self.setupView.trailingAnchor constant:-20],
        [self.setupPanel.topAnchor constraintEqualToAnchor:self.setupView.topAnchor constant:16],
        [self.setupPanel.bottomAnchor constraintEqualToAnchor:self.setupView.bottomAnchor constant:-16],
        panelWidth,
        [self.setupPanel.widthAnchor constraintGreaterThanOrEqualToConstant:250],
        [self.setupPanel.widthAnchor constraintLessThanOrEqualToConstant:340],

        [currentTrackLabel.leadingAnchor constraintEqualToAnchor:self.setupPanel.leadingAnchor constant:18],
        [currentTrackLabel.trailingAnchor constraintEqualToAnchor:self.setupPanel.trailingAnchor constant:-18],
        [currentTrackLabel.topAnchor constraintEqualToAnchor:self.setupPanel.topAnchor constant:16],
        [self.songLabel.leadingAnchor constraintEqualToAnchor:currentTrackLabel.leadingAnchor],
        [self.songLabel.trailingAnchor constraintEqualToAnchor:currentTrackLabel.trailingAnchor],
        [self.songLabel.topAnchor constraintEqualToAnchor:currentTrackLabel.bottomAnchor constant:4],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:currentTrackLabel.leadingAnchor],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:currentTrackLabel.trailingAnchor],
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.songLabel.bottomAnchor constant:4],

        [panelSeparator.leadingAnchor constraintEqualToAnchor:currentTrackLabel.leadingAnchor],
        [panelSeparator.trailingAnchor constraintEqualToAnchor:currentTrackLabel.trailingAnchor],
        [panelSeparator.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:10],
        [panelSeparator.heightAnchor constraintEqualToConstant:1],
        [difficultyLabel.leadingAnchor constraintEqualToAnchor:currentTrackLabel.leadingAnchor],
        [difficultyLabel.topAnchor constraintEqualToAnchor:panelSeparator.bottomAnchor constant:10],
        [self.diffSeg.leadingAnchor constraintEqualToAnchor:currentTrackLabel.leadingAnchor],
        [self.diffSeg.trailingAnchor constraintEqualToAnchor:currentTrackLabel.trailingAnchor],
        [self.diffSeg.topAnchor constraintEqualToAnchor:difficultyLabel.bottomAnchor constant:5],
        [self.diffSeg.heightAnchor constraintEqualToConstant:36],

        [setupActions.leadingAnchor constraintEqualToAnchor:currentTrackLabel.leadingAnchor],
        [setupActions.trailingAnchor constraintEqualToAnchor:currentTrackLabel.trailingAnchor],
        [setupActions.bottomAnchor constraintEqualToAnchor:self.setupPanel.bottomAnchor constant:-16],
        [setupActions.heightAnchor constraintEqualToConstant:50],
        [setupActions.topAnchor constraintGreaterThanOrEqualToAnchor:self.diffSeg.bottomAnchor constant:10],
    ]];

    [self buildPauseOverlay];
    [self startSetupWaveAnimation];
}

- (void)buildPauseOverlay {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    self.pauseOverlay = [[UIView alloc] init];
    self.pauseOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    self.pauseOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.70];
    self.pauseOverlay.hidden = YES;
    [self.view addSubview:self.pauseOverlay];

    self.pausePanel = [[UIView alloc] init];
    self.pausePanel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pausePanel.backgroundColor = [UIColor colorWithRed:0.035 green:0.045 blue:0.075 alpha:0.96];
    self.pausePanel.layer.cornerRadius = 8;
    self.pausePanel.layer.cornerCurve = kCACornerCurveContinuous;
    self.pausePanel.layer.borderWidth = 1;
    self.pausePanel.layer.borderColor = [[JFTheme accent] colorWithAlphaComponent:0.34].CGColor;
    self.pausePanel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.pausePanel.layer.shadowOpacity = 0.55;
    self.pausePanel.layer.shadowRadius = 24;
    self.pausePanel.layer.shadowOffset = CGSizeMake(0, 12);
    [self.pauseOverlay addSubview:self.pausePanel];

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"已暂停";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont systemFontOfSize:25 weight:UIFontWeightBlack];
    [self.pausePanel addSubview:title];

    self.pauseSongLabel = [[UILabel alloc] init];
    self.pauseSongLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pauseSongLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.58];
    self.pauseSongLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.pauseSongLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self.pausePanel addSubview:self.pauseSongLabel];

    UILabel *difficulty = [[UILabel alloc] init];
    difficulty.translatesAutoresizingMaskIntoConstraints = NO;
    difficulty.text = @"重新开始时使用的难度";
    difficulty.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.45];
    difficulty.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    [self.pausePanel addSubview:difficulty];

    self.pauseDiffSeg = [[UISegmentedControl alloc] initWithItems:@[@"简单", @"中等", @"困难"]];
    self.pauseDiffSeg.translatesAutoresizingMaskIntoConstraints = NO;
    self.pauseDiffSeg.selectedSegmentIndex = self.difficulty;
    self.pauseDiffSeg.selectedSegmentTintColor = [JFTheme accent];
    self.pauseDiffSeg.backgroundColor = [UIColor colorWithWhite:1 alpha:0.07];
    [self.pauseDiffSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    [self.pauseDiffSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.68]} forState:UIControlStateNormal];
    [self.pauseDiffSeg addTarget:self action:@selector(onPauseDifficultyChanged:) forControlEvents:UIControlEventValueChanged];
    [self.pausePanel addSubview:self.pauseDiffSeg];

    UIButton *resumeButton = [self primaryButtonWithTitle:@"继续游戏" action:@selector(onResumeFromPause)];
    [resumeButton setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal];
    resumeButton.tintColor = [UIColor colorWithWhite:0.04 alpha:1];
    [self.pausePanel addSubview:resumeButton];

    UIButton *restartButton = [self secondaryButtonWithTitle:@"重开" action:@selector(onRestartFromPause)];
    UIButton *songButton = [self secondaryButtonWithTitle:@"换歌" action:@selector(onChooseSongFromPause)];
    UIButton *exitButton = [self secondaryButtonWithTitle:@"结束" action:@selector(onExitToSetup)];
    [restartButton setImage:[UIImage systemImageNamed:@"arrow.counterclockwise"] forState:UIControlStateNormal];
    [songButton setImage:[UIImage systemImageNamed:@"music.note.list"] forState:UIControlStateNormal];
    [exitButton setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    for (UIButton *button in @[restartButton, songButton, exitButton]) {
        button.tintColor = [UIColor whiteColor];
    }
    UIStackView *actions = [[UIStackView alloc] initWithArrangedSubviews:@[restartButton, songButton, exitButton]];
    actions.translatesAutoresizingMaskIntoConstraints = NO;
    actions.axis = UILayoutConstraintAxisHorizontal;
    actions.spacing = 8;
    actions.distribution = UIStackViewDistributionFillEqually;
    [self.pausePanel addSubview:actions];

    NSLayoutConstraint *panelWidth = [self.pausePanel.widthAnchor constraintEqualToConstant:420];
    panelWidth.priority = UILayoutPriorityRequired - 1;
    [NSLayoutConstraint activateConstraints:@[
        [self.pauseOverlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.pauseOverlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.pauseOverlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.pauseOverlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.pausePanel.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [self.pausePanel.centerYAnchor constraintEqualToAnchor:safe.centerYAnchor],
        panelWidth,
        [self.pausePanel.widthAnchor constraintLessThanOrEqualToAnchor:safe.widthAnchor constant:-32],
        [self.pausePanel.heightAnchor constraintEqualToConstant:252],

        [title.leadingAnchor constraintEqualToAnchor:self.pausePanel.leadingAnchor constant:20],
        [title.topAnchor constraintEqualToAnchor:self.pausePanel.topAnchor constant:16],
        [self.pauseSongLabel.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [self.pauseSongLabel.trailingAnchor constraintEqualToAnchor:self.pausePanel.trailingAnchor constant:-20],
        [self.pauseSongLabel.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:1],

        [difficulty.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [difficulty.topAnchor constraintEqualToAnchor:self.pauseSongLabel.bottomAnchor constant:9],
        [self.pauseDiffSeg.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [self.pauseDiffSeg.trailingAnchor constraintEqualToAnchor:self.pausePanel.trailingAnchor constant:-20],
        [self.pauseDiffSeg.topAnchor constraintEqualToAnchor:difficulty.bottomAnchor constant:4],
        [self.pauseDiffSeg.heightAnchor constraintEqualToConstant:34],

        [resumeButton.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [resumeButton.trailingAnchor constraintEqualToAnchor:self.pauseDiffSeg.trailingAnchor],
        [resumeButton.topAnchor constraintEqualToAnchor:self.pauseDiffSeg.bottomAnchor constant:12],
        [resumeButton.heightAnchor constraintEqualToConstant:46],

        [actions.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [actions.trailingAnchor constraintEqualToAnchor:self.pauseDiffSeg.trailingAnchor],
        [actions.topAnchor constraintEqualToAnchor:resumeButton.bottomAnchor constant:8],
        [actions.heightAnchor constraintEqualToConstant:40],
        [actions.bottomAnchor constraintLessThanOrEqualToAnchor:self.pausePanel.bottomAnchor constant:-12],
    ]];
}

- (void)startSetupWaveAnimation {
    [self.setupWaveBars enumerateObjectsUsingBlock:^(UIView *bar, NSUInteger idx, BOOL *stop) {
        CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
        pulse.fromValue = @(0.58 + (idx % 3) * 0.08);
        pulse.toValue = @1.0;
        pulse.duration = 0.52 + (idx % 5) * 0.08;
        pulse.beginTime = CACurrentMediaTime() + idx * 0.035;
        pulse.autoreverses = YES;
        pulse.repeatCount = HUGE_VALF;
        pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [bar.layer addAnimation:pulse forKey:@"jfSetupWave"];
    }];
}

- (CGFloat)padHeight {
    CGFloat height = self.track.bounds.size.height;
    return MAX(64, MIN(82, height * 0.22));
}

- (CGFloat)padPadding { return 3; }

- (CGFloat)judgeY {
    CGFloat H = self.track.bounds.size.height;
    return H - [self padHeight] - 5;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.backgroundGradient.frame = self.view.bounds;
    CGFloat W = self.track.bounds.size.width;
    CGFloat H = self.track.bounds.size.height;
    if (W <= 0 || H <= 0) return;
    self.trackGradient.frame = self.track.bounds;
    CGFloat lw = W / kLanes;
    CGFloat padH = [self padHeight];
    CGFloat padTop = H - padH;
    CGFloat judgeY = [self judgeY];
    for (NSInteger i = 0; i < kLanes; i++) {
        self.laneViews[i].frame = CGRectMake(i * lw, 0, lw, judgeY);
        UIView *beam = self.laneBeamViews[i];
        CGFloat beamW = 2;
        beam.frame = CGRectMake(i * lw + (lw - beamW) / 2.0, 58, beamW, MAX(20, judgeY - 84));
        UIButton *pad = self.keyPads[i];
        pad.frame = CGRectMake(i * lw + [self padPadding], padTop + 5, lw - 2 * [self padPadding], padH - 8);
        UILabel *kl = self.keyLabels[i];
        kl.frame = CGRectMake(CGRectGetMinX(pad.frame) + 12, CGRectGetMinY(pad.frame), MAX(8, CGRectGetWidth(pad.frame) - 24), 3);
        UIImageView *guide = self.tutorialLaneGuides[i];
        guide.frame = CGRectMake(i * lw + (lw - 30) * 0.5, padTop - 34, 30, 28);
    }
    self.inputView.frame = CGRectMake(0, padTop, W, padH);
    self.judgeLine.frame = CGRectMake(0, judgeY, W, 2);
    self.judgeGlow.frame = CGRectMake(0, judgeY - 28, W, 30);

    CGFloat comboH = MIN(112, judgeY * 0.34);
    CGFloat comboY = (judgeY * 0.43) - comboH / 2;
    if (comboY < 8) comboY = 8;
    if (self.currentSong.isTutorial) {
        CGFloat tutorialTop = 138;
        CGFloat room = MAX(78, judgeY - tutorialTop - 8);
        comboH = MIN(comboH, MAX(50, room * 0.58));
        comboY = tutorialTop;
    }
    self.bigComboLabel.frame = CGRectMake(0, comboY, W, comboH);

    CGFloat gradeH = MIN(56, judgeY * 0.19);
    CGFloat gradeY = comboY + comboH - 6;
    if (self.currentSong.isTutorial) {
        gradeH = MIN(gradeH, 38);
        gradeY = MIN(gradeY, judgeY - gradeH - 4);
    }
    self.bigGradeLabel.frame = CGRectMake(0, gradeY, W, gradeH);

    CGFloat visualW = self.setupVisualView.bounds.size.width;
    CGFloat visualH = self.setupVisualView.bounds.size.height;
    if (visualW > 0 && visualH > 0 && self.setupWaveBars.count > 0) {
        CGFloat gap = 6;
        CGFloat barW = MIN(18, (visualW - gap * (self.setupWaveBars.count - 1)) / self.setupWaveBars.count);
        CGFloat totalW = barW * self.setupWaveBars.count + gap * (self.setupWaveBars.count - 1);
        CGFloat startX = MAX(0, (visualW - totalW) * 0.5);
        CGFloat baseY = MAX(54, visualH - 34);
        NSArray<NSNumber *> *levels = @[@0.24, @0.48, @0.78, @0.44, @0.92, @0.60, @0.34,
                                        @0.72, @0.98, @0.50, @0.82, @0.38, @0.66, @0.28];
        CGFloat availableH = MAX(36, baseY - 34);
        [self.setupWaveBars enumerateObjectsUsingBlock:^(UIView *bar, NSUInteger idx, BOOL *stop) {
            CGFloat barH = MAX(18, availableH * levels[idx].doubleValue);
            bar.frame = CGRectMake(startX + idx * (barW + gap), baseY - barH, barW, barH);
        }];
    }

    CGFloat duration = self.currentSong.duration;
    CGFloat progress = duration > 0 ? MIN(1, MAX(0, self.player.currentTime / duration)) : 0;
    self.progressFillView.frame = CGRectMake(0, 0, self.progressTrackView.bounds.size.width * progress, self.progressTrackView.bounds.size.height);
}

- (UILabel *)badgeLabel {
    UILabel *l = [[UILabel alloc] init];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    l.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
    l.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightBold];
    l.textAlignment = NSTextAlignmentLeft;
    l.adjustsFontSizeToFitWidth = YES;
    l.minimumScaleFactor = 0.78;
    return l;
}

- (UIButton *)primaryButtonWithTitle:(NSString *)t action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = [JFTheme accent];
    b.layer.cornerRadius = 8;
    b.layer.cornerCurve = kCACornerCurveContinuous;
    b.layer.shadowColor = [JFTheme accent].CGColor;
    b.layer.shadowOpacity = 0.34;
    b.layer.shadowRadius = 10;
    b.layer.shadowOffset = CGSizeZero;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:[UIColor colorWithWhite:0.04 alpha:1] forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBlack];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (UIButton *)secondaryButtonWithTitle:(NSString *)t action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.075];
    b.layer.cornerRadius = 8;
    b.layer.cornerCurve = kCACornerCurveContinuous;
    b.layer.borderWidth = 1.0;
    b.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.14].CGColor;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (NSString *)formattedTime:(NSTimeInterval)time {
    NSInteger totalSeconds = MAX(0, (NSInteger)ceil(time));
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)(totalSeconds / 60), (long)(totalSeconds % 60)];
}

- (void)refreshSongLabel {
    if (self.currentSong.title.length) {
        self.songLabel.text = self.currentSong.title;
        self.gameSongLabel.text = self.currentSong.title;
        self.pauseSongLabel.text = self.currentSong.title;
        if (self.state == JFRhythmStateIdle || self.state == JFRhythmStateFinished) {
            if (self.currentSong.isTutorial) {
                self.statusLabel.text = [NSString stringWithFormat:@"新手教学  ·  约 1 分钟  ·  %ld 拍  ·  可重复练习",
                                         (long)self.currentSong.chart.count];
            } else {
                self.statusLabel.text = [NSString stringWithFormat:@"%@  ·  %.0f BPM  ·  %@  ·  %ld 拍",
                                         self.currentSong.kind == JFRhythmSongKindPreset ? @"内置经典" : @"已分析",
                                         self.currentSong.bpm,
                                         [JFRhythmChart nameOfDifficulty:self.difficulty],
                                         (long)self.currentSong.chart.count];
            }
        }
    } else {
        self.songLabel.text = @"选择一首歌开始";
        self.gameSongLabel.text = @"节奏大师";
        self.pauseSongLabel.text = @"节奏大师";
        self.statusLabel.text = @"支持内置曲目和本地音频";
    }
    self.bestLabel.text = [NSString stringWithFormat:@"BEST  %06ld", (long)self.best];
}

- (void)syncButtonsForState {
    BOOL playing = (self.state == JFRhythmStatePlaying);
    BOOL gameVisible = (self.state == JFRhythmStatePlaying || self.state == JFRhythmStatePaused);
    BOOL setupVisible = !gameVisible;
    [self setSetupVisible:setupVisible animated:(self.view.window != nil)];
    self.pauseButton.hidden = !gameVisible;
    self.hudStack.hidden = !gameVisible;
    self.gameInfoView.hidden = !gameVisible;
    BOOL showTutorial = playing && self.currentSong.isTutorial;
    self.tutorialCoachView.hidden = !showTutorial;
    if (!showTutorial) {
        for (UIImageView *guide in self.tutorialLaneGuides) guide.hidden = YES;
    }
    if (setupVisible) [self hidePauseOverlayAnimated:NO];
    switch (self.state) {
        case JFRhythmStateIdle:
            self.libraryButton.enabled = YES;
            self.startButton.enabled = self.currentSong != nil;
            [self.startButton setTitle:self.currentSong.isTutorial ? @"开始训练" : @"开始" forState:UIControlStateNormal];
            self.pauseButton.enabled = NO;
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
            break;
        case JFRhythmStatePaused:
            self.libraryButton.enabled = YES;
            self.startButton.enabled = YES;
            [self.startButton setTitle:@"继续" forState:UIControlStateNormal];
            self.pauseButton.enabled = YES;
            break;
        case JFRhythmStateFinished:
            self.libraryButton.enabled = YES;
            self.startButton.enabled = YES;
            [self.startButton setTitle:self.currentSong.isTutorial ? @"再练一次" : @"再来一次" forState:UIControlStateNormal];
            self.pauseButton.enabled = NO;
            break;
    }
    self.inputView.userInteractionEnabled = playing;
}

- (void)setSetupVisible:(BOOL)visible animated:(BOOL)animated {
    BOOL alreadyVisible = !self.setupView.hidden && self.setupView.alpha > 0.99;
    BOOL alreadyInGame = self.setupView.hidden && !self.track.hidden;
    if ((visible && alreadyVisible) || (!visible && alreadyInGame)) {
        self.track.hidden = visible;
        self.track.alpha = visible ? 0 : 1;
        return;
    }

    NSTimeInterval duration = animated ? 0.28 : 0;
    if (visible) {
        self.setupView.hidden = NO;
        self.setupView.alpha = animated ? 0 : 1;
        self.setupView.transform = animated ? CGAffineTransformMakeTranslation(18, 0) : CGAffineTransformIdentity;
        self.track.hidden = NO;
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.setupView.alpha = 1;
            self.setupView.transform = CGAffineTransformIdentity;
            self.track.alpha = 0;
        } completion:^(__unused BOOL finished) {
            self.track.hidden = YES;
        }];
    } else {
        self.track.hidden = NO;
        self.track.alpha = animated ? 0 : 1;
        self.setupView.hidden = NO;
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.track.alpha = 1;
            self.setupView.alpha = 0;
            self.setupView.transform = CGAffineTransformMakeTranslation(-18, 0);
        } completion:^(__unused BOOL finished) {
            self.setupView.hidden = YES;
            self.setupView.transform = CGAffineTransformIdentity;
        }];
    }
}

#pragma mark - 新手训练提示

- (void)resetTutorialUI {
    self.tutorialStepIndex = NSNotFound;
    self.tutorialFeedbackUntil = 0;
    self.tutorialFeedbackText = @"";
    self.tutorialCoachView.hidden = YES;
    self.tutorialCoachView.alpha = 1;
    self.tutorialCoachView.transform = CGAffineTransformIdentity;
    self.tutorialCoachView.layer.borderColor = [[JFTheme accent] colorWithAlphaComponent:0.58].CGColor;
    for (UIImageView *guide in self.tutorialLaneGuides) guide.hidden = YES;
}

- (void)showTutorialFeedback:(NSString *)text {
    if (!self.currentSong.isTutorial || text.length == 0) return;
    self.tutorialFeedbackText = text;
    self.tutorialFeedbackUntil = [self currentSongTime] + 0.72;
}

- (void)updateTutorialLaneGuidesAtTime:(NSTimeInterval)songTime {
    for (UIImageView *guide in self.tutorialLaneGuides) guide.hidden = YES;
    if (!self.currentSong.isTutorial || self.state != JFRhythmStatePlaying) return;

    // 已经按住的动作优先指向当前应保持/应滑到的轨道。
    for (JFRhythmRuntimeNote *note in self.notes) {
        if (!note.started || !note.holding || note.hit) continue;
        NSInteger lane = note.type == JFRhythmBeatTypeSlide ? note.endLane : note.lane;
        if (lane >= 0 && lane < self.tutorialLaneGuides.count) {
            UIImageView *guide = self.tutorialLaneGuides[lane];
            guide.hidden = NO;
            [self.track bringSubviewToFront:guide];
        }
        return;
    }

    NSTimeInterval nextTime = DBL_MAX;
    for (JFRhythmRuntimeNote *note in self.notes) {
        if (note.hit) continue;
        NSTimeInterval delta = note.targetTime - songTime;
        if (delta < -kHitLateWindow || delta > 1.12) continue;
        nextTime = MIN(nextTime, note.targetTime);
    }
    if (nextTime == DBL_MAX) return;

    for (JFRhythmRuntimeNote *note in self.notes) {
        if (note.hit || fabs(note.targetTime - nextTime) > 0.012) continue;
        if (note.lane < 0 || note.lane >= self.tutorialLaneGuides.count) continue;
        UIImageView *guide = self.tutorialLaneGuides[note.lane];
        guide.hidden = NO;
        [self.track bringSubviewToFront:guide];
    }
}

- (void)updateTutorialAtTime:(NSTimeInterval)songTime {
    NSArray<NSDictionary *> *steps = self.currentSong.tutorialSteps;
    if (!self.currentSong.isTutorial || steps.count == 0 || self.state != JFRhythmStatePlaying) {
        self.tutorialCoachView.hidden = YES;
        [self updateTutorialLaneGuidesAtTime:songTime];
        return;
    }

    NSInteger stepIndex = NSNotFound;
    for (NSInteger i = 0; i < steps.count; i++) {
        NSDictionary *candidate = steps[i];
        if (songTime >= [candidate[@"from"] doubleValue] && songTime < [candidate[@"to"] doubleValue]) {
            stepIndex = i;
            break;
        }
    }
    if (stepIndex == NSNotFound) stepIndex = MIN((NSInteger)steps.count - 1, MAX(0, self.tutorialStepIndex));
    NSDictionary *step = steps[stepIndex];
    self.tutorialCoachView.hidden = NO;

    if (stepIndex != self.tutorialStepIndex) {
        self.tutorialStepIndex = stepIndex;
        void (^updates)(void) = ^{
            self.tutorialStepLabel.text = [NSString stringWithFormat:@"新手训练  %ld / %ld", (long)stepIndex + 1, (long)steps.count];
            self.tutorialTitleLabel.text = step[@"title"];
            NSString *iconName = [step[@"icon"] isKindOfClass:NSString.class] ? step[@"icon"] : @"sparkles";
            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightBold];
            self.tutorialIconView.image = [UIImage systemImageNamed:iconName withConfiguration:config] ?: [UIImage systemImageNamed:@"sparkles" withConfiguration:config];
        };
        if (self.tutorialCoachView.window) {
            [UIView transitionWithView:self.tutorialCoachView duration:0.22 options:UIViewAnimationOptionTransitionCrossDissolve animations:updates completion:nil];
        } else {
            updates();
        }
    }

    BOOL showingFeedback = songTime < self.tutorialFeedbackUntil && self.tutorialFeedbackText.length > 0;
    NSString *detail = showingFeedback ? self.tutorialFeedbackText : step[@"detail"];
    if (![self.tutorialDetailLabel.text isEqualToString:detail]) self.tutorialDetailLabel.text = detail;
    UIColor *borderColor = showingFeedback
        ? [[UIColor colorWithRed:0.34 green:0.92 blue:0.62 alpha:1] colorWithAlphaComponent:0.82]
        : [[JFTheme accent] colorWithAlphaComponent:0.58];
    self.tutorialCoachView.layer.borderColor = borderColor.CGColor;
    [self updateTutorialLaneGuidesAtTime:songTime];
}

#pragma mark - 选歌

- (void)onBack {
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

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
    NSArray<UTType *> *types = @[ UTTypeAudio, UTTypeMP3, UTTypeMPEG4Audio, UTTypeWAV, UTTypeAIFF ];
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:types asCopy:YES];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - 装载/卸载歌

- (void)onDifficultyChanged:(UISegmentedControl *)seg {
    if (self.currentSong.isTutorial) {
        seg.selectedSegmentIndex = self.difficulty;
        return;
    }
    JFRhythmDifficulty d = (JFRhythmDifficulty)seg.selectedSegmentIndex;
    self.diffSeg.selectedSegmentIndex = d;
    self.pauseDiffSeg.selectedSegmentIndex = d;
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
    JFRhythmDifficulty effectiveDifficulty = self.currentSong.isTutorial ? JFRhythmDifficultyEasy : self.difficulty;
    self.currentSong.chart = [JFRhythmChart chartFromFull:full difficulty:effectiveDifficulty];
}

- (void)loadSong:(JFRhythmSong *)song {
    [self stopAndCleanup];
    self.currentSong = song;
    self.fallDuration = song.isTutorial ? 2.25 : 1.85;
    self.diffSeg.enabled = !song.isTutorial;
    self.pauseDiffSeg.enabled = !song.isTutorial;
    NSInteger displayedDifficulty = song.isTutorial ? JFRhythmDifficultyEasy : self.difficulty;
    self.diffSeg.selectedSegmentIndex = displayedDifficulty;
    self.pauseDiffSeg.selectedSegmentIndex = displayedDifficulty;
    [self resetTutorialUI];
    [self.view setNeedsLayout];
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
            self.timeLabel.text = [self formattedTime:song.duration];
        } else {
            self.player = nil;
            self.statusLabel.text = [NSString stringWithFormat:@"音频读取失败:%@", err.localizedDescription ?: @"未知错误"];
        }
    } else {
        self.player = nil;
        self.timeLabel.text = [self formattedTime:song.duration];
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
        [self showPauseMenu];
    } else if (self.state == JFRhythmStatePaused) {
        [self showPauseMenu];
    }
}

- (void)showPauseMenu {
    if (self.state != JFRhythmStatePaused || !self.pauseOverlay.hidden) return;
    self.pauseSongLabel.text = self.currentSong.title ?: @"节奏大师";
    self.pauseDiffSeg.selectedSegmentIndex = self.currentSong.isTutorial ? JFRhythmDifficultyEasy : self.difficulty;
    self.pauseOverlay.hidden = NO;
    self.pauseOverlay.alpha = 0;
    self.pausePanel.transform = CGAffineTransformMakeScale(0.94, 0.94);
    [UIView animateWithDuration:0.24 delay:0 usingSpringWithDamping:0.88 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.pauseOverlay.alpha = 1;
        self.pausePanel.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)hidePauseOverlayAnimated:(BOOL)animated {
    if (self.pauseOverlay.hidden) return;
    NSTimeInterval duration = animated ? 0.18 : 0;
    [UIView animateWithDuration:duration animations:^{
        self.pauseOverlay.alpha = 0;
        self.pausePanel.transform = CGAffineTransformMakeScale(0.97, 0.97);
    } completion:^(__unused BOOL finished) {
        self.pauseOverlay.hidden = YES;
        self.pauseOverlay.alpha = 1;
        self.pausePanel.transform = CGAffineTransformIdentity;
    }];
}

- (void)onResumeFromPause {
    [self resume];
}

- (void)onRestartFromPause {
    [self hidePauseOverlayAnimated:NO];
    [self stopAndCleanup];
    [self.player setCurrentTime:0];
    [self startFresh];
}

- (void)onChooseSongFromPause {
    [self hidePauseOverlayAnimated:YES];
    [self onOpenLibrary];
}

- (void)onExitToSetup {
    [self hidePauseOverlayAnimated:NO];
    [self stopAndCleanup];
    [self.player stop];
    [self.player prepareToPlay];
    self.state = JFRhythmStateIdle;
    [self refreshSongLabel];
    [self syncButtonsForState];
}

- (void)onPauseDifficultyChanged:(UISegmentedControl *)seg {
    [self hidePauseOverlayAnimated:NO];
    self.diffSeg.selectedSegmentIndex = seg.selectedSegmentIndex;
    [self onDifficultyChanged:self.diffSeg];
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
    [self resetTutorialUI];
    [self.notes removeAllObjects];
    self.pendingBeats = [self.currentSong.chart mutableCopy];
    [self.player setCurrentTime:0];
    [self.player play];
    self.state = JFRhythmStatePlaying;
    [self syncButtonsForState];
    [self updateTutorialAtTime:0];
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
    [self hidePauseOverlayAnimated:YES];
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
    for (NSInteger i = 0; i < self.keyPads.count; i++) [self setPadLane:i active:NO color:nil];
    [self resetTutorialUI];
}

- (void)finishSong {
    [self stopLink];
    if (self.player.isPlaying) [self.player stop];
    for (JFRhythmRuntimeNote *n in self.notes) [n.view removeFromSuperview];
    [self.notes removeAllObjects];
    self.state = JFRhythmStateFinished;
    [self syncButtonsForState];

    BOOL tutorial = self.currentSong.isTutorial;
    if (!tutorial && self.score > self.best) {
        self.best = self.score;
        [[NSUserDefaults standardUserDefaults] setInteger:self.best forKey:kBestKey];
        self.bestLabel.text = [NSString stringWithFormat:@"BEST  %06ld", (long)self.best];
    }
    NSInteger hits = self.perfectCount + self.greatCount + self.goodCount;
    NSInteger total = self.totalNotesAtStart > 0 ? self.totalNotesAtStart : (hits + self.missCount);
    if (tutorial) {
        NSInteger accuracy = total > 0 ? (NSInteger)llround((double)hits / total * 100.0) : 0;
        self.statusLabel.text = [NSString stringWithFormat:@"训练完成 · 命中 %ld/%ld（%ld%%）· 点击「再练一次」可重复挑战",
                                 (long)hits, (long)total, (long)accuracy];
        return;
    }
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
    self.timeLabel.text = [self formattedTime:remain];
    CGFloat progress = self.currentSong.duration > 0 ? MIN(1, MAX(0, songTime / self.currentSong.duration)) : 0;
    self.progressFillView.frame = CGRectMake(0, 0, self.progressTrackView.bounds.size.width * progress, self.progressTrackView.bounds.size.height);

    // spawn 即将到来的拍点
    while (self.pendingBeats.count > 0) {
        JFRhythmBeat *b = self.pendingBeats.firstObject;
        if (b.time - songTime <= self.fallDuration) {
            JFRhythmRuntimeNote *n = [[JFRhythmRuntimeNote alloc] init];
            n.lane = b.lane;
            n.endLane = b.endLane;
            n.targetTime = b.time;
            n.duration = b.duration;
            n.strength = b.strength;
            n.type = b.type;
            n.color = [self randomNoteColor];
            NSInteger direction = b.endLane >= b.lane ? 1 : -1;
            JFRhythmNoteView *v = [[JFRhythmNoteView alloc] initWithType:b.type color:n.color direction:direction];
            v.alpha = 0;
            v.transform = CGAffineTransformMakeScale(0.86, 0.86);
            n.view = v;
            [self.track addSubview:v];
            [UIView animateWithDuration:0.16 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                v.alpha = 1;
                v.transform = CGAffineTransformIdentity;
            } completion:nil];
            [self.notes addObject:n];
            [self.pendingBeats removeObjectAtIndex:0];
        } else {
            break;
        }
    }

    [self updateNotes:songTime];
    [self updateTutorialAtTime:songTime];
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
        NSTimeInterval endTime = n.targetTime + ((n.type == JFRhythmBeatTypeTap) ? 0 : n.duration);
        if (n.type == JFRhythmBeatTypeHold && n.started && n.holding && songTime >= endTime - 0.04) {
            n.hit = YES;
            [toRemove addObject:n];
            [self completeActionNote:n gradeDelta:MAX(n.startGradeDelta, fabs(songTime - endTime))];
            continue;
        }
        if (songTime - endTime > kHitLateWindow) {
            n.hit = YES;
            if (n.started) [self stopHeldVisualsForNote:n];
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
        CGFloat noteH = (n.strength >= 0.75) ? 52 : 42;
        CGFloat holdH = (n.type == JFRhythmBeatTypeHold) ? MAX(54, (CGFloat)(n.duration / self.fallDuration) * judgeY) : 0;
        CGFloat y = -noteH + (judgeY + noteH) * progress;
        CGFloat inset = MAX(12, lw * 0.18);
        if (n.type == JFRhythmBeatTypeSlide) {
            NSInteger minLane = MIN(n.lane, n.endLane);
            NSInteger maxLane = MAX(n.lane, n.endLane);
            CGFloat x = minLane * lw + inset;
            CGFloat w = (maxLane - minLane + 1) * lw - inset * 2;
            CGFloat slideY = (n.started && songTime >= n.targetTime) ? judgeY : y;
            n.view.frame = CGRectMake(x, slideY, w, noteH);
        } else if (n.type == JFRhythmBeatTypeHold) {
            if (n.started && songTime >= n.targetTime) {
                CGFloat remaining = n.duration > 0 ? MAX(0, MIN(1, (endTime - songTime) / n.duration)) : 0;
                CGFloat remainingTail = holdH * remaining;
                n.view.frame = CGRectMake(n.lane * lw + inset, judgeY - remainingTail, lw - inset * 2, noteH + remainingTail);
            } else {
                n.view.frame = CGRectMake(n.lane * lw + inset, y - holdH, lw - inset * 2, noteH + holdH);
            }
        } else {
            n.view.frame = CGRectMake(n.lane * lw + inset, y, lw - inset * 2, noteH);
        }
    }
    [self.notes removeObjectsInArray:toRemove];
}

- (void)animateMissAt:(JFRhythmRuntimeNote *)n {
    [self showTutorialFeedback:@"没关系，跟住下一颗音符就好"];
    UIView *v = n.view;
    [UIView animateWithDuration:0.25 animations:^{
        v.alpha = 0;
        v.transform = CGAffineTransformMakeScale(0.6, 0.6);
    } completion:^(BOOL finished) { [v removeFromSuperview]; }];
}

#pragma mark - 按键板

- (void)rhythmInputView:(JFRhythmInputView *)view didPressLane:(NSInteger)lane {
    if (lane < 0 || lane >= self.keyPads.count) return;
    UIButton *pad = self.keyPads[lane];
    BOOL hit = NO;
    if (self.state == JFRhythmStatePlaying) hit = [self tryHitLane:lane];
    [self flashPad:pad hit:hit];
}

- (void)rhythmInputView:(JFRhythmInputView *)view didMoveFromLane:(NSInteger)fromLane toLane:(NSInteger)toLane {
    if (self.state != JFRhythmStatePlaying) return;
    [self tryReleaseHoldLane:fromLane];
    BOOL completedSlide = [self tryCompleteSlideToLane:toLane];
    if (fromLane >= 0 && fromLane < self.keyPads.count) {
        self.keyPads[fromLane].transform = CGAffineTransformIdentity;
    }
    if (completedSlide && toLane >= 0 && toLane < self.keyPads.count) {
        [self flashPad:self.keyPads[toLane] hit:YES];
    }
}

- (void)rhythmInputView:(JFRhythmInputView *)view didReleaseLane:(NSInteger)lane {
    if (self.state == JFRhythmStatePlaying) [self tryReleaseHoldLane:lane];
    if (lane < 0 || lane >= self.keyPads.count) return;
    UIButton *pad = self.keyPads[lane];
    [UIView animateWithDuration:0.16 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:1.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
        pad.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)flashPad:(UIButton *)b hit:(BOOL)hit {
    b.transform = CGAffineTransformMakeScale(0.96, 0.96);

    UIColor *laneColor = (b.tag < self.laneColors.count) ? self.laneColors[b.tag] : [JFTheme accent];
    UIView *ripple = [[UIView alloc] initWithFrame:b.bounds];
    ripple.backgroundColor = hit ? [laneColor colorWithAlphaComponent:0.52] : [[UIColor whiteColor] colorWithAlphaComponent:0.16];
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

- (BOOL)tryCompleteSlideToLane:(NSInteger)lane {
    NSTimeInterval songTime = [self currentSongTime];
    for (JFRhythmRuntimeNote *n in [self.notes copy]) {
        if (n.type != JFRhythmBeatTypeSlide || !n.started || !n.holding || n.hit) continue;
        if (n.endLane != lane) continue;
        if (songTime > n.targetTime + MAX(0.65, n.duration) + kHitLateWindow) continue;
        n.hit = YES;
        n.holding = NO;
        [self.notes removeObject:n];
        [self completeActionNote:n gradeDelta:n.startGradeDelta];
        return YES;
    }
    return NO;
}

- (BOOL)tryHitLane:(NSInteger)lane {
    if ([self tryCompleteSlideToLane:lane]) return YES;
    NSTimeInterval songTime = [self currentSongTime];

    JFRhythmRuntimeNote *best = nil;
    NSTimeInterval bestDelta = CGFLOAT_MAX;
    NSTimeInterval bestAbsDelta = CGFLOAT_MAX;
    // 节奏游戏优先消费当前轨道最早的可判音符,避免后一个音符抢走前一个的点击
    for (JFRhythmRuntimeNote *n in self.notes) {
        if (n.lane != lane || n.hit) continue;
        NSTimeInterval delta = songTime - n.targetTime;
        if (delta < -kHitEarlyWindow) {
            continue;
        }
        if (delta > kHitLateWindow) {
            continue;
        }
        NSTimeInterval absDelta = fabs(delta);
        if (!best ||
            n.targetTime < best.targetTime ||
            (fabs(n.targetTime - best.targetTime) < 0.001 && absDelta < bestAbsDelta)) {
            best = n;
            bestDelta = delta;
            bestAbsDelta = absDelta;
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
    if (best.type == JFRhythmBeatTypeHold || best.type == JFRhythmBeatTypeSlide) {
        best.hit = NO;
        best.started = YES;
        best.holding = YES;
        best.startGradeDelta = fabs(bestDelta);
        [self startActionNote:best lane:lane];
        return YES;
    }
    [self.notes removeObject:best];
    [self completeTapNote:best lane:lane gradeDelta:fabs(bestDelta)];
    return YES;
}

- (void)completeTapNote:(JFRhythmRuntimeNote *)best lane:(NSInteger)lane gradeDelta:(NSTimeInterval)gradeDelta {
    NSInteger pts;
    NSString *grade;
    UIColor *flashColor;
    // 时间差转为评级;连续音符时窗口保留容错,但不让上一颗拖太久
    if (gradeDelta < 0.075)      { pts = 120; grade = @"PERFECT"; flashColor = [UIColor colorWithRed:1 green:0.85 blue:0.35 alpha:1]; self.perfectCount += 1; }
    else if (gradeDelta < 0.15) { pts = 80;  grade = @"GREAT";   flashColor = [JFTheme accent]; self.greatCount += 1; }
    else                            { pts = 40;  grade = @"GOOD";    flashColor = [UIColor colorWithWhite:1 alpha:0.9]; self.goodCount += 1; }
    self.score += pts + self.combo / 5;
    self.combo += 1;
    if (self.combo > self.maxCombo) self.maxCombo = self.combo;
    UIImpactFeedbackStyle style = [grade isEqualToString:@"PERFECT"] ? UIImpactFeedbackStyleHeavy : UIImpactFeedbackStyleMedium;
    UIImpactFeedbackGenerator *impact = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
    [impact impactOccurred];
    [self flashLaneAtIndex:lane color:flashColor perfect:[grade isEqualToString:@"PERFECT"]];
    [self animateHit:best grade:grade color:flashColor];
    [self pulseJudgeLineWithColor:flashColor];
    [self animateComboPop];
    [self animateBigGrade:grade color:flashColor];
    [self showTutorialFeedback:@"很好，点按命中，继续看下一颗"];
    [self updateLabels];
}

- (void)startActionNote:(JFRhythmRuntimeNote *)note lane:(NSInteger)lane {
    UIColor *color = note.color ?: [JFTheme accent];
    note.view.alpha = 1.0;
    [self startHeldVisualsForNote:note lane:lane];
    UIImpactFeedbackGenerator *impact = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [impact impactOccurred];
    [self flashLaneAtIndex:lane color:color perfect:NO];
}

- (void)completeActionNote:(JFRhythmRuntimeNote *)note gradeDelta:(NSTimeInterval)gradeDelta {
    NSInteger lane = note.type == JFRhythmBeatTypeSlide ? note.endLane : note.lane;
    [self stopHeldVisualsForNote:note];
    NSString *grade;
    NSInteger pts;
    UIColor *flashColor;
    if (gradeDelta < 0.09)      { pts = 160; grade = @"PERFECT"; flashColor = [UIColor colorWithRed:1 green:0.85 blue:0.35 alpha:1]; self.perfectCount += 1; }
    else if (gradeDelta < 0.18) { pts = 110; grade = @"GREAT";   flashColor = [JFTheme accent]; self.greatCount += 1; }
    else                        { pts = 70;  grade = @"GOOD";    flashColor = [UIColor colorWithWhite:1 alpha:0.9]; self.goodCount += 1; }
    self.score += pts + self.combo / 4;
    self.combo += 1;
    if (self.combo > self.maxCombo) self.maxCombo = self.combo;
    UIImpactFeedbackGenerator *impact = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    [impact impactOccurred];
    [self flashLaneAtIndex:lane color:flashColor perfect:[grade isEqualToString:@"PERFECT"]];
    [self animateHit:note grade:grade color:flashColor];
    [self pulseJudgeLineWithColor:flashColor];
    [self animateComboPop];
    [self animateBigGrade:grade color:flashColor];
    [self showTutorialFeedback:note.type == JFRhythmBeatTypeSlide ? @"滑动完成，方向和时机都对了" : @"长按完成，记得按到长条尾端"];
    [self updateLabels];
}

- (void)tryReleaseHoldLane:(NSInteger)lane {
    NSTimeInterval songTime = [self currentSongTime];
    for (JFRhythmRuntimeNote *n in [self.notes copy]) {
        if (n.type != JFRhythmBeatTypeHold || !n.started || !n.holding || n.lane != lane || n.hit) continue;
        NSTimeInterval endTime = n.targetTime + n.duration;
        NSTimeInterval delta = songTime - endTime;
        n.holding = NO;
        if (delta >= -kHitEarlyWindow && delta <= kHitLateWindow) {
            n.hit = YES;
            [self.notes removeObject:n];
            [self completeActionNote:n gradeDelta:MAX(n.startGradeDelta, fabs(delta))];
        } else if (delta < -kHitEarlyWindow) {
            n.hit = YES;
            [self stopHeldVisualsForNote:n];
            self.missCount += 1;
            if (self.combo > 0) {
                self.combo = 0;
                [self breakComboAnimation];
            }
            [self.notes removeObject:n];
            [self animateMissAt:n];
            [self updateLabels];
        }
        return;
    }
}

- (void)startHeldVisualsForNote:(JFRhythmRuntimeNote *)note lane:(NSInteger)lane {
    UIColor *color = note.color ?: [JFTheme accent];
    if ([note.view isKindOfClass:JFRhythmNoteView.class]) {
        [(JFRhythmNoteView *)note.view setActionActive:YES];
    }
    [self setPadLane:lane active:YES color:color];
    if (note.type == JFRhythmBeatTypeSlide && note.endLane != lane) {
        [self setPadLane:note.endLane active:YES color:color];
    }
}

- (void)stopHeldVisualsForNote:(JFRhythmRuntimeNote *)note {
    if ([note.view isKindOfClass:JFRhythmNoteView.class]) {
        [(JFRhythmNoteView *)note.view setActionActive:NO];
    }
    [self setPadLane:note.lane active:NO color:nil];
    if (note.endLane != note.lane) [self setPadLane:note.endLane active:NO color:nil];
}

- (void)setPadLane:(NSInteger)lane active:(BOOL)active color:(UIColor *)color {
    if (lane < 0 || lane >= self.keyPads.count) return;
    UIButton *pad = self.keyPads[lane];
    UIView *beam = lane < self.laneBeamViews.count ? self.laneBeamViews[lane] : nil;
    UIColor *laneColor = color ?: ((lane < self.laneColors.count) ? self.laneColors[lane] : [JFTheme accent]);
    pad.layer.borderColor = [laneColor colorWithAlphaComponent:active ? 1.0 : 0.56].CGColor;
    pad.layer.shadowOpacity = active ? 0.82 : 0.32;
    pad.layer.shadowRadius = active ? 21 : 9;
    pad.backgroundColor = [laneColor colorWithAlphaComponent:active ? 0.25 : 0.12];
    beam.backgroundColor = [laneColor colorWithAlphaComponent:active ? 0.88 : 0.24];
    beam.layer.shadowOpacity = active ? 0.92 : 0.30;
    beam.layer.shadowRadius = active ? 14 : 5;
    if (active) {
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"shadowRadius"];
        a.fromValue = @10;
        a.toValue = @23;
        a.duration = 0.32;
        a.autoreverses = YES;
        a.repeatCount = HUGE_VALF;
        [pad.layer addAnimation:a forKey:@"jfPadHoldGlow"];
        CABasicAnimation *beamPulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
        beamPulse.fromValue = @0.42;
        beamPulse.toValue = @1.0;
        beamPulse.duration = 0.24;
        beamPulse.autoreverses = YES;
        beamPulse.repeatCount = HUGE_VALF;
        [beam.layer addAnimation:beamPulse forKey:@"jfLaneLaser"];
    } else {
        [pad.layer removeAnimationForKey:@"jfPadHoldGlow"];
        [beam.layer removeAnimationForKey:@"jfLaneLaser"];
    }
}

- (void)flashLaneAtIndex:(NSInteger)lane color:(UIColor *)color perfect:(BOOL)perfect {
    if (lane < 0 || lane >= self.laneViews.count) return;
    UIView *laneView = self.laneViews[lane];
    UIView *flash = [[UIView alloc] initWithFrame:laneView.frame];
    flash.backgroundColor = [color colorWithAlphaComponent:perfect ? 0.36 : 0.24];
    flash.userInteractionEnabled = NO;
    flash.alpha = 0;
    [self.track insertSubview:flash aboveSubview:laneView];
    [UIView animateWithDuration:0.06 animations:^{
        flash.alpha = 1;
    } completion:^(__unused BOOL finished) {
        [UIView animateWithDuration:0.28 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            flash.alpha = 0;
        } completion:^(__unused BOOL fin) {
            [flash removeFromSuperview];
        }];
    }];
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
    self.scoreLabel.text = [NSString stringWithFormat:@"SCORE  %06ld", (long)self.score];
    self.comboLabel.text = [NSString stringWithFormat:@"COMBO  %ld", (long)self.combo];
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
    return (s == 0) ? @"我导入的" : @"新手训练与内置曲目";
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
    cell.imageView.image = nil;
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
        if (song.isTutorial) {
            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightBold];
            cell.imageView.image = [UIImage systemImageNamed:@"graduationcap.fill" withConfiguration:config];
            cell.imageView.tintColor = [JFTheme accent];
            cell.detailTextLabel.text = @"约 1 分钟 · 带实时提示 · 可重复练习";
        } else {
            cell.detailTextLabel.text = song.artist;
        }
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
