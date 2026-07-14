//
//  GestureBombViewController.m
//  JiFeng_UpApp
//

#import "GestureBombViewController.h"
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"
#import <math.h>

typedef NS_ENUM(NSInteger, JFGestureMode) {
    JFGestureModeParty = 0,
    JFGestureModeReaction,
};

@interface JFGestureCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *emojiLabel;
@property (nonatomic, strong) UIView *pulseRing;
- (void)configureWithEmoji:(NSString *)emoji highlighted:(BOOL)highlighted;
- (void)playHitAnimation:(BOOL)success;
@end

@implementation JFGestureCell

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.contentView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.09];
        self.contentView.layer.cornerRadius = 8;
        self.contentView.layer.cornerCurve = kCACornerCurveContinuous;
        self.contentView.layer.borderWidth = 1;
        self.contentView.layer.borderColor = [JFTheme cardBorder].CGColor;

        _pulseRing = [[UIView alloc] init];
        _pulseRing.userInteractionEnabled = NO;
        _pulseRing.layer.cornerRadius = 8;
        _pulseRing.layer.borderWidth = 3;
        _pulseRing.layer.borderColor = [JFTheme accent].CGColor;
        _pulseRing.alpha = 0;
        _pulseRing.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_pulseRing];

        _emojiLabel = [[UILabel alloc] init];
        _emojiLabel.textAlignment = NSTextAlignmentCenter;
        _emojiLabel.adjustsFontSizeToFitWidth = YES;
        _emojiLabel.minimumScaleFactor = 0.45;
        _emojiLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_emojiLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_pulseRing.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [_pulseRing.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_pulseRing.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_pulseRing.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
            [_emojiLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:5],
            [_emojiLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:5],
            [_emojiLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-5],
            [_emojiLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-5],
        ]];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.emojiLabel.font = [UIFont systemFontOfSize:MAX(30, MIN(70, MIN(self.bounds.size.width, self.bounds.size.height) * 0.56))];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.transform = CGAffineTransformIdentity;
    self.contentView.alpha = 1;
    [self.contentView.layer removeAllAnimations];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.transform = highlighted ? CGAffineTransformMakeScale(0.94, 0.94) : CGAffineTransformIdentity;
}

- (void)configureWithEmoji:(NSString *)emoji highlighted:(BOOL)highlighted {
    self.emojiLabel.text = emoji;
    self.pulseRing.alpha = highlighted ? 1 : 0;
    self.contentView.backgroundColor = highlighted
        ? [[JFTheme accent] colorWithAlphaComponent:0.2]
        : [[UIColor whiteColor] colorWithAlphaComponent:0.09];
    self.contentView.layer.shadowColor = highlighted ? [JFTheme accent].CGColor : UIColor.clearColor.CGColor;
    self.contentView.layer.shadowOpacity = highlighted ? 0.72 : 0;
    self.contentView.layer.shadowRadius = highlighted ? 14 : 0;
    self.contentView.layer.shadowOffset = CGSizeZero;
}

- (void)playHitAnimation:(BOOL)success {
    UIColor *color = success ? [JFTheme success] : [JFTheme danger];
    self.pulseRing.layer.borderColor = color.CGColor;
    self.pulseRing.alpha = 1;
    self.transform = CGAffineTransformMakeScale(success ? 0.86 : 0.94, success ? 0.86 : 0.94);
    [UIView animateWithDuration:0.22
                          delay:0
         usingSpringWithDamping:0.48
          initialSpringVelocity:0.8
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.transform = CGAffineTransformIdentity;
        self.pulseRing.transform = CGAffineTransformMakeScale(1.08, 1.08);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.18 animations:^{
            self.pulseRing.alpha = 0;
            self.pulseRing.transform = CGAffineTransformIdentity;
        }];
    }];
}

@end

@interface GestureBombViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UISegmentedControl *modeControl;
@property (nonatomic, strong) UIView *configBar;
@property (nonatomic, strong) UITextField *countField;
@property (nonatomic, strong) UIStepper *countStepper;
@property (nonatomic, strong) UIButton *regenerateButton;
@property (nonatomic, strong) UILabel *targetLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *startButton;

@property (nonatomic, copy) NSArray<NSString *> *gesturePool;
@property (nonatomic, strong) NSMutableArray<NSString *> *gestures;
@property (nonatomic, assign) NSInteger gestureCount;
@property (nonatomic, assign) NSInteger highlightedIndex;
@property (nonatomic, assign) NSInteger targetIndex;
@property (nonatomic, assign) NSInteger spinToken;
@property (nonatomic, assign) BOOL spinning;

@property (nonatomic, assign) BOOL reactionRunning;
@property (nonatomic, assign) NSInteger reactionScore;
@property (nonatomic, assign) NSInteger reactionCombo;
@property (nonatomic, assign) NSTimeInterval reactionEndTime;
@property (nonatomic, strong) NSTimer *reactionTimer;
@end

@implementation GestureBombViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"手势炸弹";
    self.gesturePool = @[@"✌️", @"🤟", @"🖖", @"✋", @"🤞", @"👍", @"👎", @"👊",
                         @"☝️", @"🤘", @"🤙", @"👌", @"🤌", @"👏", @"🙌", @"🫶"];
    self.gestureCount = 6;
    self.highlightedIndex = -1;
    self.targetIndex = -1;
    [self buildUI];
    [self regenerateGestures];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.spinToken += 1;
    self.spinning = NO;
    [self stopReactionAndReport:NO];
}

#pragma mark - UI

- (void)buildUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"手势炸弹";
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    self.modeControl = [[UISegmentedControl alloc] initWithItems:@[@"聚会抽取", @"30 秒反应"]];
    self.modeControl.selectedSegmentIndex = JFGestureModeParty;
    self.modeControl.selectedSegmentTintColor = [[JFTheme accent] colorWithAlphaComponent:0.86];
    [self.modeControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [JFTheme textPrimary],
                                               NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]}
                                    forState:UIControlStateNormal];
    [self.modeControl addTarget:self action:@selector(onModeChanged) forControlEvents:UIControlEventValueChanged];
    self.modeControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.modeControl];

    self.configBar = [[UIView alloc] init];
    self.configBar.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.075];
    self.configBar.layer.cornerRadius = 8;
    self.configBar.layer.borderWidth = 1;
    self.configBar.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.configBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.configBar];

    UILabel *countTitle = [[UILabel alloc] init];
    countTitle.text = @"手势数量";
    countTitle.textColor = [JFTheme textSecondary];
    countTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    countTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [self.configBar addSubview:countTitle];

    self.countField = [[UITextField alloc] init];
    self.countField.text = @"6";
    self.countField.keyboardType = UIKeyboardTypeNumberPad;
    self.countField.textAlignment = NSTextAlignmentCenter;
    self.countField.textColor = [JFTheme textPrimary];
    self.countField.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    self.countField.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.24];
    self.countField.layer.cornerRadius = 6;
    self.countField.layer.borderWidth = 1;
    self.countField.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.countField.delegate = self;
    self.countField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.configBar addSubview:self.countField];

    self.countStepper = [[UIStepper alloc] init];
    self.countStepper.minimumValue = 2;
    self.countStepper.maximumValue = self.gesturePool.count;
    self.countStepper.stepValue = 1;
    self.countStepper.value = self.gestureCount;
    self.countStepper.tintColor = [JFTheme textPrimary];
    [self.countStepper addTarget:self action:@selector(onStepperChanged) forControlEvents:UIControlEventValueChanged];
    self.countStepper.translatesAutoresizingMaskIntoConstraints = NO;
    [self.configBar addSubview:self.countStepper];

    self.regenerateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightBold];
    [self.regenerateButton setImage:[UIImage systemImageNamed:@"shuffle" withConfiguration:symbolConfig] forState:UIControlStateNormal];
    self.regenerateButton.tintColor = [JFTheme textPrimary];
    self.regenerateButton.backgroundColor = [[JFTheme brandPrimary] colorWithAlphaComponent:0.72];
    self.regenerateButton.layer.cornerRadius = 7;
    self.regenerateButton.accessibilityLabel = @"重新随机手势";
    [self.regenerateButton addTarget:self action:@selector(onRegenerate) forControlEvents:UIControlEventTouchUpInside];
    self.regenerateButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.configBar addSubview:self.regenerateButton];

    self.targetLabel = [[UILabel alloc] init];
    self.targetLabel.text = @"准备抽取";
    self.targetLabel.textColor = [JFTheme textPrimary];
    self.targetLabel.font = [UIFont systemFontOfSize:25 weight:UIFontWeightBlack];
    self.targetLabel.textAlignment = NSTextAlignmentCenter;
    self.targetLabel.adjustsFontSizeToFitWidth = YES;
    self.targetLabel.minimumScaleFactor = 0.7;
    self.targetLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.targetLabel];

    self.scoreLabel = [[UILabel alloc] init];
    self.scoreLabel.text = @"可选 6 个";
    self.scoreLabel.textColor = [JFTheme textSecondary];
    self.scoreLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    self.scoreLabel.textAlignment = NSTextAlignmentCenter;
    self.scoreLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scoreLabel];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"随机选出一个炸弹手势，聚会中做出它的人接受挑战";
    self.statusLabel.textColor = [JFTheme textSecondary];
    self.statusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 2;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 8;
    layout.minimumInteritemSpacing = 8;
    layout.sectionInset = UIEdgeInsetsMake(8, 8, 8, 8);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
    self.collectionView.layer.cornerRadius = 8;
    self.collectionView.layer.borderWidth = 1;
    self.collectionView.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.collectionView.clipsToBounds = YES;
    self.collectionView.scrollEnabled = NO;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.collectionView registerClass:JFGestureCell.class forCellWithReuseIdentifier:@"gesture"];
    [self.view addSubview:self.collectionView];

    self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.startButton.backgroundColor = [JFTheme brandPrimary];
    self.startButton.layer.cornerRadius = 8;
    self.startButton.layer.borderWidth = 1;
    self.startButton.layer.borderColor = [[JFTheme accent] colorWithAlphaComponent:0.52].CGColor;
    [self.startButton setTitle:@"随机炸弹" forState:UIControlStateNormal];
    [self.startButton setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    self.startButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    [self.startButton addTarget:self action:@selector(onStart) forControlEvents:UIControlEventTouchUpInside];
    self.startButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.startButton];

    UITapGestureRecognizer *dismissKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissCountKeyboard)];
    dismissKeyboard.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:dismissKeyboard];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:safe.leadingAnchor constant:64],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-64],

        [self.modeControl.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:12],
        [self.modeControl.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.modeControl.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.modeControl.heightAnchor constraintEqualToConstant:34],

        [self.configBar.topAnchor constraintEqualToAnchor:self.modeControl.bottomAnchor constant:9],
        [self.configBar.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.configBar.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.configBar.heightAnchor constraintEqualToConstant:50],

        [countTitle.leadingAnchor constraintEqualToAnchor:self.configBar.leadingAnchor constant:12],
        [countTitle.centerYAnchor constraintEqualToAnchor:self.configBar.centerYAnchor],
        [self.countField.leadingAnchor constraintEqualToAnchor:countTitle.trailingAnchor constant:9],
        [self.countField.centerYAnchor constraintEqualToAnchor:self.configBar.centerYAnchor],
        [self.countField.widthAnchor constraintEqualToConstant:46],
        [self.countField.heightAnchor constraintEqualToConstant:34],
        [self.countStepper.leadingAnchor constraintEqualToAnchor:self.countField.trailingAnchor constant:8],
        [self.countStepper.centerYAnchor constraintEqualToAnchor:self.configBar.centerYAnchor],
        [self.regenerateButton.trailingAnchor constraintEqualToAnchor:self.configBar.trailingAnchor constant:-8],
        [self.regenerateButton.centerYAnchor constraintEqualToAnchor:self.configBar.centerYAnchor],
        [self.regenerateButton.widthAnchor constraintEqualToConstant:36],
        [self.regenerateButton.heightAnchor constraintEqualToConstant:34],

        [self.targetLabel.topAnchor constraintEqualToAnchor:self.configBar.bottomAnchor constant:10],
        [self.targetLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.targetLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.targetLabel.heightAnchor constraintEqualToConstant:34],

        [self.scoreLabel.topAnchor constraintEqualToAnchor:self.targetLabel.bottomAnchor constant:2],
        [self.scoreLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.scoreLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.scoreLabel.heightAnchor constraintEqualToConstant:18],

        [self.statusLabel.topAnchor constraintEqualToAnchor:self.scoreLabel.bottomAnchor constant:3],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:18],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-18],

        [self.collectionView.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:8],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.startButton.topAnchor constant:-10],

        [self.startButton.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.startButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.startButton.heightAnchor constraintEqualToConstant:50],
        [self.startButton.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-14],
    ]];
}

- (void)dismissCountKeyboard {
    if ([self.countField isFirstResponder]) {
        [self applyCountFromField];
        [self.countField resignFirstResponder];
    }
}

#pragma mark - Configuration

- (void)onStepperChanged {
    if (self.reactionRunning || self.spinning) return;
    self.gestureCount = (NSInteger)self.countStepper.value;
    self.countField.text = [NSString stringWithFormat:@"%ld", (long)self.gestureCount];
    [self regenerateGestures];
}

- (void)onRegenerate {
    if (self.reactionRunning || self.spinning) return;
    [self applyCountFromField];
    [self regenerateGestures];
    [JFTheme hapticSelection];
}

- (void)applyCountFromField {
    NSInteger value = self.countField.text.integerValue;
    value = MAX(2, MIN((NSInteger)self.gesturePool.count, value));
    self.gestureCount = value;
    self.countField.text = [NSString stringWithFormat:@"%ld", (long)value];
    self.countStepper.value = value;
}

- (void)regenerateGestures {
    NSMutableArray<NSString *> *pool = self.gesturePool.mutableCopy;
    for (NSInteger idx = pool.count - 1; idx > 0; idx--) {
        NSInteger other = arc4random_uniform((uint32_t)(idx + 1));
        [pool exchangeObjectAtIndex:idx withObjectAtIndex:other];
    }
    self.gestures = [[pool subarrayWithRange:NSMakeRange(0, self.gestureCount)] mutableCopy];
    self.highlightedIndex = -1;
    self.targetIndex = -1;
    [self.collectionView reloadData];
    [self.collectionView.collectionViewLayout invalidateLayout];
    self.scoreLabel.text = [NSString stringWithFormat:@"可选 %ld 个", (long)self.gestureCount];
    if (self.modeControl.selectedSegmentIndex == JFGestureModeParty) self.targetLabel.text = @"准备抽取";
}

- (void)onModeChanged {
    [self stopReactionAndReport:NO];
    self.spinToken += 1;
    self.spinning = NO;
    self.highlightedIndex = -1;
    self.targetIndex = -1;
    BOOL reaction = self.modeControl.selectedSegmentIndex == JFGestureModeReaction;
    [self.startButton setTitle:reaction ? @"开始 30 秒" : @"随机炸弹" forState:UIControlStateNormal];
    self.targetLabel.text = reaction ? @"找到目标手势" : @"准备抽取";
    self.scoreLabel.text = reaction ? @"得分 0 · 连击 0 · 30.0s" : [NSString stringWithFormat:@"可选 %ld 个", (long)self.gestureCount];
    self.statusLabel.text = reaction ? @"根据上方目标，尽快在手势区中点中它" : @"随机选出一个炸弹手势，聚会中做出它的人接受挑战";
    self.startButton.enabled = YES;
    [self.collectionView reloadData];
    [JFTheme hapticSelection];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self applyCountFromField];
    [self regenerateGestures];
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (self.reactionRunning || self.spinning) return;
    [self applyCountFromField];
    [self regenerateGestures];
}

#pragma mark - Collection

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.gestures.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JFGestureCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"gesture" forIndexPath:indexPath];
    [cell configureWithEmoji:self.gestures[indexPath.item] highlighted:(indexPath.item == self.highlightedIndex)];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger count = MAX(1, self.gestures.count);
    CGFloat width = collectionView.bounds.size.width - 16;
    CGFloat height = collectionView.bounds.size.height - 16;
    CGFloat gap = 8;
    NSInteger bestColumns = 1;
    CGFloat bestSide = 0;
    for (NSInteger columns = 1; columns <= MIN(5, count); columns++) {
        NSInteger rows = (count + columns - 1) / columns;
        CGFloat cellWidth = (width - gap * (columns - 1)) / columns;
        CGFloat cellHeight = (height - gap * (rows - 1)) / rows;
        CGFloat side = MIN(cellWidth, cellHeight);
        if (side > bestSide) {
            bestSide = side;
            bestColumns = columns;
        }
    }
    NSInteger rows = (count + bestColumns - 1) / bestColumns;
    CGFloat cellWidth = floor((width - gap * (bestColumns - 1)) / bestColumns);
    CGFloat cellHeight = floor((height - gap * (rows - 1)) / rows);
    return CGSizeMake(MAX(44, cellWidth), MAX(44, cellHeight));
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    JFGestureCell *cell = (JFGestureCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (self.modeControl.selectedSegmentIndex == JFGestureModeReaction) {
        [self handleReactionTap:indexPath.item cell:cell];
        return;
    }
    if (self.targetIndex < 0 || self.spinning) {
        [cell playHitAnimation:YES];
        self.statusLabel.text = @"先点击“随机炸弹”选出本轮目标";
        return;
    }
    BOOL hitBomb = indexPath.item == self.targetIndex;
    [cell playHitAnimation:!hitBomb];
    self.statusLabel.text = hitBomb ? @"命中炸弹！这一轮接受挑战" : @"安全手势，继续观察其他玩家";
    [JFTheme hapticNotification:hitBomb ? UINotificationFeedbackTypeError : UINotificationFeedbackTypeSuccess];
}

#pragma mark - Party roulette

- (void)onStart {
    [self dismissCountKeyboard];
    if (self.modeControl.selectedSegmentIndex == JFGestureModeReaction) {
        [self startReaction];
    } else {
        [self startPartySpin];
    }
}

- (void)startPartySpin {
    if (self.spinning || self.gestures.count == 0) return;
    self.spinning = YES;
    self.startButton.enabled = NO;
    self.configBar.userInteractionEnabled = NO;
    self.targetIndex = -1;
    self.statusLabel.text = @"炸弹正在手势之间移动";
    self.targetLabel.text = @"随机中…";
    NSInteger token = ++self.spinToken;
    NSInteger totalSteps = MAX(20, self.gestures.count * 3);
    [self runSpinStep:0 total:totalSteps token:token];
}

- (void)runSpinStep:(NSInteger)step total:(NSInteger)total token:(NSInteger)token {
    if (token != self.spinToken || !self.spinning) return;
    NSInteger next = self.highlightedIndex;
    if (self.gestures.count > 1) {
        while (next == self.highlightedIndex) {
            next = arc4random_uniform((uint32_t)self.gestures.count);
        }
    } else {
        next = 0;
    }
    self.highlightedIndex = next;
    [self.collectionView reloadData];
    [JFTheme hapticSelection];

    if (step >= total - 1) {
        [self finishPartySpin];
        return;
    }
    CGFloat progress = (CGFloat)step / MAX(1, total - 1);
    NSTimeInterval delay = 0.045 + pow(progress, 3.0) * 0.20;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf runSpinStep:step + 1 total:total token:token];
    });
}

- (void)finishPartySpin {
    self.spinning = NO;
    self.targetIndex = self.highlightedIndex;
    self.startButton.enabled = YES;
    self.configBar.userInteractionEnabled = YES;
    NSString *target = self.gestures[self.targetIndex];
    self.targetLabel.text = [NSString stringWithFormat:@"炸弹 %@", target];
    self.scoreLabel.text = [NSString stringWithFormat:@"%ld 个手势中抽中第 %ld 个", (long)self.gestureCount, (long)self.targetIndex + 1];
    self.statusLabel.text = @"本轮做出这个手势的人接受挑战；也可轮流点击试探";
    JFGestureCell *cell = (JFGestureCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.targetIndex inSection:0]];
    [cell playHitAnimation:NO];
    [JFTheme hapticNotification:UINotificationFeedbackTypeWarning];
    [self reportGestureScore:10 win:YES duration:0 mode:@"聚会抽取"];
}

#pragma mark - Reaction

- (void)startReaction {
    if (self.reactionRunning) return;
    self.reactionRunning = YES;
    self.reactionScore = 0;
    self.reactionCombo = 0;
    self.reactionEndTime = NSDate.date.timeIntervalSince1970 + 30.0;
    self.modeControl.enabled = NO;
    self.configBar.userInteractionEnabled = NO;
    self.startButton.enabled = NO;
    [self.startButton setTitle:@"挑战中" forState:UIControlStateNormal];
    self.statusLabel.text = @"快！找到上方目标";
    [self chooseReactionTarget];
    self.reactionTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onReactionTick) userInfo:nil repeats:YES];
    [self onReactionTick];
}

- (void)chooseReactionTarget {
    NSInteger previous = self.targetIndex;
    if (self.gestures.count > 1) {
        do {
            self.targetIndex = arc4random_uniform((uint32_t)self.gestures.count);
        } while (self.targetIndex == previous);
    } else {
        self.targetIndex = 0;
    }
    self.highlightedIndex = -1;
    self.targetLabel.text = [NSString stringWithFormat:@"找到 %@", self.gestures[self.targetIndex]];
}

- (void)handleReactionTap:(NSInteger)index cell:(JFGestureCell *)cell {
    if (!self.reactionRunning) {
        self.statusLabel.text = @"点击“开始 30 秒”进入反应挑战";
        [cell playHitAnimation:YES];
        return;
    }
    BOOL correct = index == self.targetIndex;
    [cell playHitAnimation:correct];
    if (correct) {
        self.reactionCombo += 1;
        self.reactionScore += 10 + MIN(20, self.reactionCombo);
        self.statusLabel.text = [NSString stringWithFormat:@"命中 · 连击 %ld", (long)self.reactionCombo];
        [JFTheme hapticImpactLight];
        if (self.reactionCombo % 4 == 0) {
            for (NSInteger idx = self.gestures.count - 1; idx > 0; idx--) {
                NSInteger other = arc4random_uniform((uint32_t)(idx + 1));
                [self.gestures exchangeObjectAtIndex:idx withObjectAtIndex:other];
            }
            [self.collectionView reloadData];
        }
        [self chooseReactionTarget];
    } else {
        self.reactionCombo = 0;
        self.reactionScore = MAX(0, self.reactionScore - 3);
        self.statusLabel.text = @"点错了，连击清零";
        [JFTheme hapticNotification:UINotificationFeedbackTypeError];
    }
    [self updateReactionScoreWithRemaining:MAX(0, self.reactionEndTime - NSDate.date.timeIntervalSince1970)];
}

- (void)onReactionTick {
    NSTimeInterval remaining = self.reactionEndTime - NSDate.date.timeIntervalSince1970;
    if (remaining <= 0) {
        [self stopReactionAndReport:YES];
        return;
    }
    [self updateReactionScoreWithRemaining:remaining];
}

- (void)updateReactionScoreWithRemaining:(NSTimeInterval)remaining {
    self.scoreLabel.text = [NSString stringWithFormat:@"得分 %ld · 连击 %ld · %.1fs", (long)self.reactionScore, (long)self.reactionCombo, remaining];
}

- (void)stopReactionAndReport:(BOOL)report {
    if (!self.reactionRunning) return;
    self.reactionRunning = NO;
    [self.reactionTimer invalidate];
    self.reactionTimer = nil;
    self.modeControl.enabled = YES;
    self.configBar.userInteractionEnabled = YES;
    self.startButton.enabled = YES;
    [self.startButton setTitle:@"再来 30 秒" forState:UIControlStateNormal];
    self.targetLabel.text = @"挑战结束";
    self.statusLabel.text = [NSString stringWithFormat:@"最终得分 %ld", (long)self.reactionScore];
    if (report) {
        [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
        [self reportGestureScore:self.reactionScore win:(self.reactionScore >= 100) duration:30 mode:@"30 秒反应"];
    }
}

- (void)reportGestureScore:(NSInteger)score win:(BOOL)win duration:(NSTimeInterval)duration mode:(NSString *)mode {
    JFGameResult *result = [JFGameResult resultWithKind:JFGameKindGesture score:score win:win];
    result.duration = duration;
    result.difficulty = self.gestureCount;
    result.extra = @{@"mode": mode, @"gestureCount": @(self.gestureCount)};
    [[JFProfileStore shared] reportResult:result];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindGesture difficulty:self.gestureCount score:score win:win];
}

@end
