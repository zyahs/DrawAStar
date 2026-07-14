//
//  JFPuzzleViewController.m
//  JiFeng_UpApp
//

#import "JFPuzzleViewController.h"
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"

typedef NS_ENUM(NSInteger, JFPuzzleDifficulty) {
    JFPuzzleDifficultyEasy   = 3,  // 3x3
    JFPuzzleDifficultyMedium = 4,  // 4x4
    JFPuzzleDifficultyHard   = 5,  // 5x5
};

#pragma mark - 拼图块视图

@interface JFPuzzlePiece : UIImageView
@property (nonatomic, assign) NSInteger correctIndex;  // 正确位置 (row*N + col)
@property (nonatomic, assign) NSInteger currentIndex;  // 当前位置
@property (nonatomic, assign) CGRect    homeFrame;     // 自己的目标 frame
@end

@implementation JFPuzzlePiece
@end

#pragma mark - VC

@interface JFPuzzleViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

// 配置
@property (nonatomic, assign) JFPuzzleDifficulty difficulty;
@property (nonatomic, strong, nullable) UIImage *sourceImage;

// UI
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel     *titleLabel;
@property (nonatomic, strong) UILabel     *statusLabel;
@property (nonatomic, strong) UISegmentedControl *difficultyControl;
@property (nonatomic, strong) UIButton    *pickButton;
@property (nonatomic, strong) UIButton    *shuffleButton;
@property (nonatomic, strong) UIView      *boardView;
@property (nonatomic, strong) UIImageView *previewImageView; // 完成后展示原图

// 拼图状态
@property (nonatomic, strong) NSMutableArray<JFPuzzlePiece *> *pieces;
@property (nonatomic, weak)   JFPuzzlePiece *draggingPiece;
@property (nonatomic, assign) CGPoint draggingTouchOffset;

@property (nonatomic, assign) NSInteger moves;

@end

@implementation JFPuzzleViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.difficulty = JFPuzzleDifficultyEasy;
    self.pieces = [NSMutableArray array];

    [self buildBackground];
    [self buildUI];
}

- (void)buildBackground {
    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.24];
    [self.view addSubview:overlay];
}

- (void)buildUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"拼图";
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    [self.view addSubview:self.titleLabel];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"先选一张相册照片,然后选难度";
    self.statusLabel.textColor = [JFTheme textSecondary];
    self.statusLabel.font = [JFTheme fontBody];
    self.statusLabel.numberOfLines = 0;
    [self.view addSubview:self.statusLabel];

    // 难度
    self.difficultyControl = [[UISegmentedControl alloc] initWithItems:@[@"低 3×3", @"中 4×4", @"高 5×5"]];
    self.difficultyControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.difficultyControl.selectedSegmentIndex = 0;
    self.difficultyControl.selectedSegmentTintColor = [JFTheme brandPrimary];
    [self.difficultyControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [JFTheme textPrimary]} forState:UIControlStateNormal];
    [self.difficultyControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [JFTheme textOnAccent]} forState:UIControlStateSelected];
    [self.difficultyControl addTarget:self action:@selector(onDifficultyChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.difficultyControl];

    // 棋盘容器
    self.boardView = [[UIView alloc] init];
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.boardView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.30];
    self.boardView.layer.cornerRadius = JFRadiusMedium;
    self.boardView.layer.cornerCurve  = kCACornerCurveContinuous;
    self.boardView.layer.borderWidth  = 0.5;
    self.boardView.layer.borderColor  = [JFTheme cardBorder].CGColor;
    self.boardView.clipsToBounds = YES;
    [self.view addSubview:self.boardView];

    // 操作按钮
    self.pickButton    = [self primaryButtonWithTitle:@"选照片"  action:@selector(onPickPhoto)];
    self.shuffleButton = [self ghostButtonWithTitle:@"重新打乱" action:@selector(onShuffleAgain)];
    self.shuffleButton.enabled = NO;
    self.shuffleButton.alpha = 0.5;

    UIStackView *btnStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.pickButton, self.shuffleButton]];
    btnStack.translatesAutoresizingMaskIntoConstraints = NO;
    btnStack.axis = UILayoutConstraintAxisHorizontal;
    btnStack.spacing = JFSpacing12;
    btnStack.distribution = UIStackViewDistributionFillEqually;
    [self.view addSubview:btnStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:JFSpacing12],
        [self.titleLabel.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],

        [self.statusLabel.topAnchor      constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:JFSpacing4],
        [self.statusLabel.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],

        [self.difficultyControl.topAnchor      constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:JFSpacing16],
        [self.difficultyControl.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.difficultyControl.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [self.difficultyControl.heightAnchor   constraintEqualToConstant:36],

        [self.boardView.topAnchor      constraintEqualToAnchor:self.difficultyControl.bottomAnchor constant:JFSpacing16],
        [self.boardView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing16],
        [self.boardView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],
        [self.boardView.widthAnchor    constraintEqualToAnchor:self.boardView.heightAnchor],

        [btnStack.topAnchor      constraintEqualToAnchor:self.boardView.bottomAnchor constant:JFSpacing16],
        [btnStack.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [btnStack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [btnStack.heightAnchor   constraintEqualToConstant:48],
        [btnStack.bottomAnchor   constraintLessThanOrEqualToAnchor:safe.bottomAnchor constant:-JFSpacing16],
    ]];
}

#pragma mark - 按钮工厂

- (UIButton *)primaryButtonWithTitle:(NSString *)t action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = [JFTheme brandPrimary];
    b.layer.cornerRadius = JFRadiusMedium;
    b.layer.cornerCurve = kCACornerCurveContinuous;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textOnAccent] forState:UIControlStateNormal];
    b.titleLabel.font = [JFTheme fontHeadline];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (UIButton *)ghostButtonWithTitle:(NSString *)t action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
    b.layer.cornerRadius = JFRadiusMedium;
    b.layer.cornerCurve = kCACornerCurveContinuous;
    b.layer.borderWidth = 1;
    b.layer.borderColor = [JFTheme cardBorder].CGColor;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    b.titleLabel.font = [JFTheme fontHeadline];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

#pragma mark - Actions

- (void)onDifficultyChanged:(UISegmentedControl *)sender {
    NSArray<NSNumber *> *map = @[@(JFPuzzleDifficultyEasy), @(JFPuzzleDifficultyMedium), @(JFPuzzleDifficultyHard)];
    self.difficulty = (JFPuzzleDifficulty)map[sender.selectedSegmentIndex].integerValue;
    if (self.sourceImage) {
        [self buildPuzzleWithImage:self.sourceImage];
    }
}

- (void)onPickPhoto {
    [JFTheme hapticImpactMedium];
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.statusLabel.text = @"无法访问相册";
        return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.allowsEditing = YES;   // 让用户裁成方形,简化拼图比例
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)onShuffleAgain {
    if (!self.sourceImage) return;
    [JFTheme hapticImpactMedium];
    [self buildPuzzleWithImage:self.sourceImage];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    UIImage *img = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        if (img) {
            self.sourceImage = [self squareCroppedImage:img];
            [self buildPuzzleWithImage:self.sourceImage];
            self.shuffleButton.enabled = YES;
            self.shuffleButton.alpha = 1.0;
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 拼图核心

/// 把图裁成正方形,以中间为基准,边长 = min(W,H)
- (UIImage *)squareCroppedImage:(UIImage *)img {
    CGFloat w = img.size.width, h = img.size.height;
    CGFloat side = MIN(w, h);
    CGFloat x = (w - side) / 2.0;
    CGFloat y = (h - side) / 2.0;
    CGRect cropRect = CGRectMake(x * img.scale, y * img.scale, side * img.scale, side * img.scale);
    CGImageRef cg = CGImageCreateWithImageInRect(img.CGImage, cropRect);
    UIImage *result = [UIImage imageWithCGImage:cg scale:img.scale orientation:img.imageOrientation];
    CGImageRelease(cg);
    return result;
}

- (void)buildPuzzleWithImage:(UIImage *)image {
    // 清掉旧块
    for (UIView *v in [self.boardView.subviews copy]) [v removeFromSuperview];
    [self.pieces removeAllObjects];
    self.moves = 0;

    [self.view layoutIfNeeded];
    CGSize boardSize = self.boardView.bounds.size;
    if (boardSize.width <= 0) {
        // 还没布局完,稍后重试
        dispatch_async(dispatch_get_main_queue(), ^{
            [self buildPuzzleWithImage:image];
        });
        return;
    }

    NSInteger N = (NSInteger)self.difficulty;
    CGFloat tileSize = floor(boardSize.width / N);
    CGFloat usedSize = tileSize * N;

    // 把原图绘制成正方形 usedSize x usedSize 的位图,再切片
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(usedSize, usedSize), NO, [UIScreen mainScreen].scale);
    [image drawInRect:CGRectMake(0, 0, usedSize, usedSize)];
    UIImage *normalized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // 生成 N*N 块的目标位置 + 切片
    NSMutableArray<JFPuzzlePiece *> *pieces = [NSMutableArray array];
    for (NSInteger r = 0; r < N; r++) {
        for (NSInteger c = 0; c < N; c++) {
            CGRect cropRect = CGRectMake(c * tileSize * normalized.scale,
                                         r * tileSize * normalized.scale,
                                         tileSize * normalized.scale,
                                         tileSize * normalized.scale);
            CGImageRef cg = CGImageCreateWithImageInRect(normalized.CGImage, cropRect);
            UIImage *tileImg = [UIImage imageWithCGImage:cg scale:normalized.scale orientation:UIImageOrientationUp];
            CGImageRelease(cg);

            JFPuzzlePiece *p = [[JFPuzzlePiece alloc] initWithImage:tileImg];
            p.userInteractionEnabled = YES;
            p.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.20].CGColor;
            p.layer.borderWidth = 0.5;
            p.layer.cornerRadius = 2;
            p.clipsToBounds = YES;
            p.correctIndex = r * N + c;
            p.homeFrame = CGRectMake(c * tileSize, r * tileSize, tileSize, tileSize);
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPiecePan:)];
            [p addGestureRecognizer:pan];
            [pieces addObject:p];
        }
    }

    // 洗牌:把 pieces[i].currentIndex 设为打乱后的位置
    NSMutableArray<NSNumber *> *order = [NSMutableArray array];
    for (NSInteger i = 0; i < N * N; i++) [order addObject:@(i)];
    for (NSInteger i = order.count - 1; i > 0; i--) {
        NSInteger j = arc4random_uniform((uint32_t)(i + 1));
        [order exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    // 防止洗成原序
    BOOL isIdentity = YES;
    for (NSInteger i = 0; i < order.count; i++) if (order[i].integerValue != i) { isIdentity = NO; break; }
    if (isIdentity && order.count >= 2) {
        [order exchangeObjectAtIndex:0 withObjectAtIndex:1];
    }

    for (NSInteger i = 0; i < pieces.count; i++) {
        JFPuzzlePiece *p = pieces[i];
        NSInteger pos = order[i].integerValue;
        p.currentIndex = pos;
        NSInteger r = pos / N, c = pos % N;
        p.frame = CGRectMake(c * tileSize, r * tileSize, tileSize, tileSize);
        [self.boardView addSubview:p];
    }
    [self.pieces addObjectsFromArray:pieces];

    self.statusLabel.text = [NSString stringWithFormat:@"难度 %ld×%ld · 拖动方块拼回原图", (long)N, (long)N];
}

#pragma mark - 拖拽

- (void)onPiecePan:(UIPanGestureRecognizer *)pan {
    JFPuzzlePiece *p = (JFPuzzlePiece *)pan.view;
    CGPoint loc = [pan locationInView:self.boardView];
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            self.draggingPiece = p;
            self.draggingTouchOffset = CGPointMake(loc.x - p.center.x, loc.y - p.center.y);
            [self.boardView bringSubviewToFront:p];
            [UIView animateWithDuration:0.12 animations:^{
                p.transform = CGAffineTransformMakeScale(1.06, 1.06);
                p.alpha = 0.92;
            }];
            [JFTheme hapticSelection];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            p.center = CGPointMake(loc.x - self.draggingTouchOffset.x,
                                   loc.y - self.draggingTouchOffset.y);
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            [self dropPiece:p atPoint:loc];
            break;
        }
        default: break;
    }
}

- (void)dropPiece:(JFPuzzlePiece *)p atPoint:(CGPoint)loc {
    NSInteger N = (NSInteger)self.difficulty;
    CGFloat tileSize = floor(self.boardView.bounds.size.width / N);
    NSInteger col = MAX(0, MIN(N - 1, (NSInteger)floor(loc.x / tileSize)));
    NSInteger row = MAX(0, MIN(N - 1, (NSInteger)floor(loc.y / tileSize)));
    NSInteger targetIndex = row * N + col;

    // 找当前在那个槽位的方块
    JFPuzzlePiece *occupant = nil;
    for (JFPuzzlePiece *other in self.pieces) {
        if (other != p && other.currentIndex == targetIndex) { occupant = other; break; }
    }

    NSInteger fromIndex = p.currentIndex;

    [UIView animateWithDuration:0.22 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseOut animations:^{
        p.transform = CGAffineTransformIdentity;
        p.alpha = 1.0;
        p.frame = CGRectMake(col * tileSize, row * tileSize, tileSize, tileSize);
        if (occupant) {
            NSInteger r = fromIndex / N, c = fromIndex % N;
            occupant.frame = CGRectMake(c * tileSize, r * tileSize, tileSize, tileSize);
        }
    } completion:nil];

    if (occupant) occupant.currentIndex = fromIndex;
    p.currentIndex = targetIndex;

    self.moves += 1;
    [self checkWin];
}

- (void)checkWin {
    BOOL allOK = YES;
    for (JFPuzzlePiece *p in self.pieces) {
        if (p.currentIndex != p.correctIndex) { allOK = NO; break; }
    }
    if (allOK) {
        [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
        self.statusLabel.text = [NSString stringWithFormat:@"完成!共 %ld 步", (long)self.moves];
        // 拼图完成动效:轻微缩放呼吸 + 边框淡出
        for (JFPuzzlePiece *p in self.pieces) {
            [UIView animateWithDuration:0.6 animations:^{
                p.layer.borderColor = [UIColor clearColor].CGColor;
            }];
        }
        [UIView animateWithDuration:0.35 animations:^{
            self.boardView.transform = CGAffineTransformMakeScale(1.04, 1.04);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.35 animations:^{
                self.boardView.transform = CGAffineTransformIdentity;
            }];
        }];

        // 上报 Profile / Daily
        NSInteger n = (NSInteger)self.difficulty;
        NSInteger diffIdx = (n == 3) ? 0 : (n == 4 ? 1 : 2);
        NSInteger score = MAX(50, 1000 - self.moves * 5 + diffIdx * 200);
        JFGameResult *r = [JFGameResult resultWithKind:JFGameKindPuzzle score:score win:YES];
        r.difficulty = diffIdx;
        r.extra = @{@"moves": @(self.moves), @"size": @(n)};
        [[JFProfileStore shared] reportResult:r];
        [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindPuzzle difficulty:diffIdx score:score win:YES];
    }
}

@end
