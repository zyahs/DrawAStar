//
//  FiveQiVc.m
//  漫天都是小星星的说
//
//  五子棋 —— 强制横屏。棋盘按可用高度撑到最大,左侧贴近返回按钮,右侧放控制按钮。
//

#import "FiveQiVc.h"
#import "CheckerboardView.h"
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"

@interface FiveQiVc ()

@property (nonatomic, strong) CheckerboardView *boardView;
@property (nonatomic, strong) UIButton         *undoButton;     // 悔棋
@property (nonatomic, strong) UIButton         *restartButton;  // 新游戏
@property (nonatomic, strong) UILabel          *titleLabel;
@property (nonatomic, assign) BOOL             shouldRestorePortraitOnExit;

@end

@implementation FiveQiVc

#pragma mark - 屏幕方向(强制横屏)

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
                NSLog(@"[FiveQi] request landscape failed: %@", error);
            }];
        }
        [self setNeedsUpdateOfSupportedInterfaceOrientations];
    } else {
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeRight) forKey:@"orientation"];
        [UIViewController attemptRotationToDeviceOrientation];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.shouldRestorePortraitOnExit = self.isMovingFromParentViewController || self.isBeingDismissed || self.navigationController.isBeingDismissed;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!self.shouldRestorePortraitOnExit) return;
    self.shouldRestorePortraitOnExit = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self jf_requestPortraitAfterExit];
    });
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

    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.18];
    [self.view addSubview:overlay];

    [self setupUI];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(onFiveDidFinish:)
                                                  name:@"JFFiveInRowDidFinishNotification"
                                                object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onFiveDidFinish:(NSNotification *)note {
    JFGameResult *r = [JFGameResult resultWithKind:JFGameKindFiveInRow score:100 win:YES];
    [[JFProfileStore shared] reportResult:r];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindFiveInRow difficulty:0 score:100 win:YES];
}

- (void)setupUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    // 标题(左上,与返回按钮并排)
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"五子棋";
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];

    // 棋盘 —— 横屏下铺成更宽的长方形,内部网格按宽高分别撑满。
    self.boardView = [[CheckerboardView alloc] initWithFrame:CGRectZero];
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.boardView.backgroundColor = [UIColor colorWithRed:240/255.0 green:215/255.0 blue:155/255.0 alpha:0.95];
    self.boardView.layer.cornerRadius = JFRadiusMedium;
    self.boardView.layer.cornerCurve  = kCACornerCurveContinuous;
    self.boardView.clipsToBounds = YES;
    [self.view addSubview:self.boardView];

    // 控制按钮 —— 横屏右侧竖排
    self.undoButton    = [self primaryButtonWithTitle:@"悔棋"   action:@selector(onUndo)];
    self.restartButton = [self primaryButtonWithTitle:@"新游戏" action:@selector(onRestart)];

    UIStackView *btnStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.restartButton, self.undoButton]];
    btnStack.translatesAutoresizingMaskIntoConstraints = NO;
    btnStack.axis = UILayoutConstraintAxisVertical;
    btnStack.spacing = JFSpacing12;
    btnStack.distribution = UIStackViewDistributionFillEqually;
    [self.view addSubview:btnStack];

    [NSLayoutConstraint activateConstraints:@[
        // 标题:顶部居中
        [self.titleLabel.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:JFSpacing8],
        [self.titleLabel.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],

        // 棋盘:横向铺满左侧主区域,不再强制正方形。
        [self.boardView.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:JFSpacing8 + 36],
        [self.boardView.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor constant:-JFSpacing12],
        [self.boardView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing16],
        [self.boardView.trailingAnchor constraintEqualToAnchor:btnStack.leadingAnchor constant:-JFSpacing16],

        // 按钮组:右侧竖排
        [btnStack.trailingAnchor   constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],
        [btnStack.centerYAnchor    constraintEqualToAnchor:self.view.centerYAnchor],
        [btnStack.widthAnchor      constraintEqualToConstant:120],
        [btnStack.heightAnchor     constraintEqualToConstant:48 * 2 + JFSpacing12],
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // CheckerboardView 内部会基于 bounds 重画,触发刷新
    [self.boardView setNeedsDisplay];
}

- (UIButton *)primaryButtonWithTitle:(NSString *)title action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = [JFTheme brandPrimary];
    b.layer.cornerRadius = JFRadiusMedium;
    b.layer.cornerCurve  = kCACornerCurveContinuous;
    b.titleLabel.font = [JFTheme fontHeadline];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textOnAccent] forState:UIControlStateNormal];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

#pragma mark - Actions

- (void)onUndo {
    [JFTheme hapticImpactLight];
    [self.boardView backOneStep:nil];
}

- (void)onRestart {
    [JFTheme hapticImpactMedium];
    [self.boardView newGame];
}

@end
