//
//  CardsGameViewController.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/9/30.
//

#import "CardsGameViewController.h"
#import "JFCardsPreviewGridVC.h"
#import "JFCard.h"
#import <QuartzCore/QuartzCore.h>
#pragma mark - Rules Banner UI

@interface JFRulesBannerView : UIView
@property (nonatomic, strong) CAGradientLayer *gradient;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
- (void)showWithTitle:(NSString *)title body:(NSString *)body inView:(UIView *)parent autoHide:(BOOL)autoHide;
@end

@implementation JFRulesBannerView
- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.layer.cornerRadius = 16;
        self.layer.masksToBounds = YES;
        self.alpha = 0.0;
        // Gradient
        _gradient = [CAGradientLayer layer];
        _gradient.colors = @[(__bridge id)[UIColor colorWithRed:0.98 green:0.67 blue:0.94 alpha:1].CGColor,
                             (__bridge id)[UIColor colorWithRed:0.67 green:0.80 blue:1 alpha:1].CGColor,
                             (__bridge id)[UIColor colorWithRed:0.76 green:1 blue:0.86 alpha:1].CGColor];
        _gradient.startPoint = CGPointMake(0, 0);
        _gradient.endPoint = CGPointMake(1, 1);
        [self.layer addSublayer:_gradient];
        // Blur-like soft overlay
        self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
        // Labels
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:18];
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _bodyLabel = [[UILabel alloc] init];
        _bodyLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        _bodyLabel.textColor = UIColor.whiteColor;
        _bodyLabel.numberOfLines = 0;
        _bodyLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_titleLabel];
        [self addSubview:_bodyLabel];
        // Subtle wobble animation
        CABasicAnimation *rot = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rot.fromValue = @( - M_PI / 360.0 * 2 );
        rot.toValue   = @(   M_PI / 360.0 * 2 );
        rot.duration = 2.2;
        rot.autoreverses = YES;
        rot.repeatCount = HUGE_VALF;
        [self.layer addAnimation:rot forKey:@"wobble"];
        // Animated gradient shift
        CABasicAnimation *grad = [CABasicAnimation animationWithKeyPath:@"colors"];
        grad.duration = 4.0;
        grad.repeatCount = HUGE_VALF;
        grad.autoreverses = YES;
        grad.toValue = @[(__bridge id)[UIColor colorWithRed:0.88 green:0.70 blue:1 alpha:1].CGColor,
                         (__bridge id)[UIColor colorWithRed:0.60 green:0.86 blue:1 alpha:1].CGColor,
                         (__bridge id)[UIColor colorWithRed:0.86 green:1 blue:0.78 alpha:1].CGColor];
        [_gradient addAnimation:grad forKey:@"shift"];
        // Tap to dismiss
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
//        [self addGestureRecognizer:tap];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _gradient.frame = self.bounds;
    CGFloat pad = 16;
    _titleLabel.frame = CGRectMake(pad, pad, self.bounds.size.width - pad*2, 24);
    _bodyLabel.frame  = CGRectMake(pad, CGRectGetMaxY(_titleLabel.frame)+8, self.bounds.size.width - pad*2, self.bounds.size.height - pad*3 - 24);
}
- (void)showWithTitle:(NSString *)title body:(NSString *)body inView:(UIView *)parent autoHide:(BOOL)autoHide {
    _titleLabel.text = title;
    _bodyLabel.text  = body;
    if (!self.superview) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [parent addSubview:self];
        UILayoutGuide *safe = parent.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
            [self.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
            [self.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
            [self.topAnchor constraintEqualToAnchor:safe.topAnchor constant:80],
        ]];
        // Set an intrinsic height
        [self.heightAnchor constraintGreaterThanOrEqualToConstant:160].active = YES;
    }
    [self.superview layoutIfNeeded];
    [UIView animateWithDuration:0.25 animations:^{ self.alpha = 1.0; }];
    if (autoHide) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self hide]; });
    }
}
- (void)hide {
    [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0.0; } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
@end

#pragma mark - Card View (no assets, pure drawing)

@interface JFCardView : UIView
@property (nonatomic, strong) JFCard *card;
@end

@implementation JFCardView {
    UILabel *_tlRank, *_tlSuit, *_brRank, *_brSuit, *_centerLabel;
}
- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = UIColor.clearColor;
        self.layer.cornerRadius = 16;
        self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.25].CGColor;
        self.layer.shadowOpacity = 0.6;
        self.layer.shadowRadius  = 12;
        self.layer.shadowOffset  = CGSizeMake(0, 6);

        UIView *cardBG = [[UIView alloc] init];
        cardBG.backgroundColor = [UIColor colorWithWhite:1 alpha:0.96];
        cardBG.layer.cornerRadius = 16;
        cardBG.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1].CGColor;
        cardBG.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
        cardBG.tag = 101;
        [self addSubview:cardBG];

        _tlRank = [self label:18 weight:UIFontWeightSemibold];
        _tlSuit = [self label:18 weight:UIFontWeightRegular];
        _brRank = [self label:18 weight:UIFontWeightSemibold];
        _brSuit = [self label:18 weight:UIFontWeightRegular];
        _centerLabel = [self label:56 weight:UIFontWeightBlack];

        [self addSubview:_tlRank];
        [self addSubview:_tlSuit];
        [self addSubview:_brRank];
        [self addSubview:_brSuit];
        [self addSubview:_centerLabel];
    }
    return self;
}

- (UILabel *)label:(CGFloat)size weight:(UIFontWeight)w {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont systemFontOfSize:size weight:w];
    l.textAlignment = NSTextAlignmentCenter;
    l.adjustsFontSizeToFitWidth = YES;
    return l;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIView *bg = [self viewWithTag:101];
    bg.frame = self.bounds;

    CGFloat pad = 12;
    _tlRank.frame = CGRectMake(pad, pad, 40, 22);
    _tlSuit.frame = CGRectMake(pad, CGRectGetMaxY(_tlRank.frame)-2, 40, 22);

    _brRank.frame = CGRectMake(self.bounds.size.width - pad - 40,
                               self.bounds.size.height - pad - 44, 40, 22);
    _brSuit.frame = CGRectMake(self.bounds.size.width - pad - 40,
                               self.bounds.size.height - pad - 22, 40, 22);

    _centerLabel.frame = CGRectInset(self.bounds, 24, 24);
}

- (void)setCard:(JFCard *)card {
    _card = card;
    // Fallback to placeholder when card is nil
    NSString *rank = card ? card.rank : @"999";
    NSString *suit = card ? card.suit : @"999";

    BOOL red = [suit isEqualToString:@"♥"] || [suit isEqualToString:@"♦"];
    UIColor *c = card ? (red ? [UIColor colorWithRed:0.90 green:0.11 blue:0.14 alpha:1]
                                : UIColor.blackColor)
                    : [UIColor secondaryLabelColor];

    _tlRank.textColor = c;
    _tlSuit.textColor = c;
    _brRank.textColor = c;
    _brSuit.textColor = c;
    _centerLabel.textColor = c;

    _tlRank.text = rank;
    _tlSuit.text = suit;
    _brRank.text = rank;
    _brSuit.text = suit;
    _centerLabel.text = [NSString stringWithFormat:@"%@%@", rank, suit];
}

@end

#pragma mark - Preview Controller

@interface JFCardsPreviewVC : UITableViewController
@property (nonatomic, copy) NSArray<JFCard *> *discarded;
@end

@implementation JFCardsPreviewVC
- (instancetype)init {
    if (self = [super initWithStyle:UITableViewStyleInsetGrouped]) {}
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"已出过的牌";
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                      target:self
                                                      action:@selector(close)];
}
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.discarded.count;
}
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)idx {
    static NSString *rid = @"c";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:rid];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:rid];
    JFCard *card = self.discarded[idx.row];
    BOOL red = [card.suit isEqualToString:@"♥"] || [card.suit isEqualToString:@"♦"];
    cell.textLabel.text = [NSString stringWithFormat:@"%@%@", card.rank, card.suit];
    cell.textLabel.textColor = red ? [UIColor systemRedColor] : UIColor.labelColor;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"第 %ld 张", (long)idx.row+1];
    return cell;
}
@end

#pragma mark - Main VC

@interface CardsGameViewController ()
@property (nonatomic, strong) NSMutableArray<JFCard *> *fullDeck;
@property (nonatomic, strong) NSMutableArray<JFCard *> *remainDeck;
@property (nonatomic, strong) NSMutableArray<JFCard *> *discarded;

@property (nonatomic, strong) JFCardView *centerCard;
@property (nonatomic, strong) UIButton *shuffleBtn;
@property (nonatomic, strong) UIButton *previewBtn;
@property (nonatomic, strong) UILabel *counterLabel;

@property (nonatomic, strong) JFRulesBannerView *rulesBanner;

@end

@implementation CardsGameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self buildDeck];

    // 先创建并安置规则条（常驻）
    self.rulesBanner = [JFRulesBannerView new];
    [self.rulesBanner showWithTitle:@"开场牌"
                               body:@"点击屏幕抽牌；左下角可洗牌，右下角可预览已出牌。"
                             inView:self.view
                           autoHide:NO];

    // 再构建其余 UI（卡片会锚到 rulesBanner 底部）
    [self setupUI];

    // 洗牌并显示占位卡
    [self resetAndShuffle];
}

#pragma mark - Deck

- (void)buildDeck {
    self.fullDeck = [NSMutableArray arrayWithCapacity:52];
    NSArray *ranks = @[ @"A",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"J",@"Q",@"K" ];
    NSArray *suits = @[ @"♠",@"♥",@"♦",@"♣" ];
    for (NSString *s in suits) {
        for (NSString *r in ranks) {
            JFCard *c = [JFCard new]; c.rank = r; c.suit = s;
            [self.fullDeck addObject:c];
        }
    }
}

- (void)resetAndShuffle {
    self.remainDeck = self.fullDeck.mutableCopy;
    self.discarded = [NSMutableArray array];
    [self shuffle:self.remainDeck];
    [self updateCounter];

    // 显示占位牌面（不计入牌堆）
    self.centerCard.card = [self placeholderCard];
    [self.centerCard setNeedsLayout];
}

- (void)shuffle:(NSMutableArray<JFCard *> *)arr {
    for (NSInteger i = arr.count - 1; i > 0; i--) {
        NSInteger j = arc4random_uniform((uint32_t)(i+1));
        [arr exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
}

#pragma mark - UI

- (void)setupUI {
    // 中心卡片
    JFCardView *card = [[JFCardView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:card];
    self.centerCard = card;
  
    self.centerCard.card = [self placeholderCard];
    // 尺寸自适应（宽:高 = 5:7）
    CGFloat maxW = MIN(self.view.bounds.size.width, self.view.bounds.size.height) * 0.6;
    CGFloat aspect = 7.0/5.0;

    // 计数标签
    UILabel *counter = [[UILabel alloc] init];
    counter.translatesAutoresizingMaskIntoConstraints = NO;
    counter.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    counter.textColor = [UIColor secondaryLabelColor];
    [self.view addSubview:counter];
    self.counterLabel = counter;

    // 洗牌按钮（左下）
    UIButton *shuffle = [self roundButton:@"洗牌"];
    [shuffle addTarget:self action:@selector(onShuffle) forControlEvents:UIControlEventTouchUpInside];
    shuffle.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:shuffle];
    self.shuffleBtn = shuffle;

    // 预览按钮（右下）
    UIButton *preview = [self roundButton:@"预览"];
    [preview addTarget:self action:@selector(onPreview) forControlEvents:UIControlEventTouchUpInside];
    preview.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:preview];
    self.previewBtn = preview;

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [counter.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [counter.topAnchor constraintEqualToAnchor:self.rulesBanner.bottomAnchor constant:8],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [card.topAnchor constraintEqualToAnchor:self.counterLabel.bottomAnchor constant:8],
        [card.widthAnchor constraintEqualToConstant:maxW],
        [card.heightAnchor constraintEqualToConstant:maxW * aspect],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [shuffle.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:20],
        [shuffle.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-20],
        [shuffle.widthAnchor constraintEqualToConstant:88],
        [shuffle.heightAnchor constraintEqualToConstant:44],

        [preview.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-20],
        [preview.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-20],
        [preview.widthAnchor constraintEqualToConstant:88],
        [preview.heightAnchor constraintEqualToConstant:44],
    ]];

    // 点击手势：抽牌
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapAnywhere)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];

    // 帮助按钮（右上角，显示全部规则）
    UIButton *helpBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [helpBtn setTitle:@"规则" forState:UIControlStateNormal];
    helpBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    helpBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [helpBtn addTarget:self action:@selector(onShowAllRules) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:helpBtn];
//    [NSLayoutConstraint activateConstraints:@[
//        [helpBtn.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-16],
//        [helpBtn.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10]
//    ]];
}

- (UIButton *)roundButton:(NSString *)title {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
    b.layer.cornerRadius = 12;
    b.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
    b.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    b.contentEdgeInsets = UIEdgeInsetsMake(8, 14, 8, 14);
    return b;
}

- (void)updateCounter {
    self.counterLabel.text = [NSString stringWithFormat:@"剩余：%lu / 52   已出：%lu",
                              (unsigned long)self.remainDeck.count, (unsigned long)self.discarded.count];
}

// 占位卡片
- (JFCard *)placeholderCard {
    JFCard *c = [JFCard new];
    c.rank = @"999";
    c.suit = @"999";
    return c;
}

// 规则映射
- (NSString *)ruleTitleForCard:(JFCard *)card {
    if (!card || [card.rank isEqualToString:@"999"]) return @"开场牌";
    return [NSString stringWithFormat:@"%@ - 规则", card.rank];
}

- (NSString *)ruleBodyForCard:(JFCard *)card {
    if (!card || [card.rank isEqualToString:@"999"]) return @"点击屏幕抽牌；左下角可洗牌，右下角可预览已出牌。";
    NSString *r = card.rank;
    if ([r isEqualToString:@"A"]) return @"命令牌：抽到A的人可以任意指定一个人喝酒。";
    if ([r isEqualToString:@"2"]) return @"“小姐”牌：抽到2的人成为本轮‘小姐’，给自己起个名字。直到下一个2出现，被罚酒的人可喊‘(名字)，陪一个！’，小姐需站起来说‘各位老板，辛苦了！’并陪喝一口。";
    if ([r isEqualToString:@"3"]) return @"逛三园：抽到3的人说‘逛三园，什么园？’，下一位接（如‘动物园’），依次说出该园的事物。说不出/说慢/重复者喝酒。可换‘水果园’‘蔬菜园’等。";
    if ([r isEqualToString:@"4"]) return @"玩游戏：抽到4的人可随时大喊‘玩游戏！’，全员立即玩石头剪刀布或任意小游戏，输的人喝酒。";
    if ([r isEqualToString:@"5"]) return @"照相机：抽到5的人可在任意时刻大喊‘照相机！’，所有人立刻静止，谁先动谁喝酒。";
    if ([r isEqualToString:@"6"]) return @"摸鼻子/柳树扭：抽到6的人可偷偷摸鼻子，其他人发现要跟着摸，最后一个摸的人喝。或玩‘柳树扭一扭’，从x颗柳树扭x扭开始依次，出错喝酒。";
    if ([r isEqualToString:@"7"]) return @"逢7过：依次报数，遇到含7或7的倍数要拍手跳过；说错或慢的人喝酒。";
    if ([r isEqualToString:@"8"]) return @"厕所牌：获得‘厕所通行证’，持证可离开上厕所；无证离开可被罚酒。";
    if ([r isEqualToString:@"9"]) return @"自饮：抽到9的人自己喝一杯。";
    if ([r isEqualToString:@"10"]) return @"神经病：成为‘神经病’，在你宣布‘我恢复正常’前，任何人和你说话都被你罚酒（你不能主动招惹别人）。";
    if ([r isEqualToString:@"J"]) return @"左边喝：指定左手边的玩家喝一杯。";
    if ([r isEqualToString:@"Q"]) return @"右边喝：指定右手边的玩家喝一杯。";
    if ([r isEqualToString:@"K"]) return @"定规则：可制定一条新规则（如不许说‘喝’），直到下一张K出现。或进行‘加酒’，下一位抽到K的人将酒全喝掉并继续加。";
    return @"自由发挥：为这张牌想一个有趣的惩罚或小游戏！";
}

#pragma mark - Actions

- (void)onShuffle {
    [self resetAndShuffle];

    // 小反馈
    UIImpactFeedbackGenerator *h = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [h impactOccurred];
    // 更新规则为开场提示且常驻
    [self.rulesBanner showWithTitle:@"开场牌"
                               body:@"点击屏幕抽牌；左下角可洗牌，右下角可预览已出牌。"
                             inView:self.view
                           autoHide:NO];
}

- (void)onPreview {
    if (self.discarded.count == 0) {
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"还没有出牌"
                                                                   message:@"点屏幕抽牌后，再来看看预览吧～"
                                                            preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:a animated:YES completion:nil];
        return;
    }
    JFCardsPreviewGridVC *vc = [JFCardsPreviewGridVC new];
    vc.allCards = self.discarded.copy; // 不强制顺序，预览里会随机
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationPageSheet; // iPhone: 底部弹起 / iPad: 置中页
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onTapAnywhere {
    if (self.remainDeck.count == 0) {
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"牌发完啦"
                                                                   message:@"点击左下角“洗牌”可重新开始"
                                                            preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:a animated:YES completion:nil];
        return;
    }

    // 随机抽一张
    NSUInteger idx = arc4random_uniform((uint32_t)self.remainDeck.count);
    JFCard *next = self.remainDeck[idx];
    [self.remainDeck removeObjectAtIndex:idx];
    [self.discarded addObject:next];
    [self updateCounter];

    // 翻牌动画（Y 轴翻转）
    [self flipToCard:next];
}

// 翻牌动画
- (void)flipToCard:(JFCard *)card {
    // 半程：翻到背面
    [UIView transitionWithView:self.centerCard
                      duration:0.22
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        self.centerCard.layer.transform = CATransform3DMakeScale(0.98, 0.98, 1);
                        self.centerCard.layer.opacity = 0.0;
                    } completion:^(BOOL finished) {
                        // 更新卡面
                        self.centerCard.card = card;
                        // 回程：展示正面
                        [UIView transitionWithView:self.centerCard
                                          duration:0.28
                                           options:UIViewAnimationOptionTransitionFlipFromRight
                                        animations:^{
                                            self.centerCard.layer.transform = CATransform3DIdentity;
                                            self.centerCard.layer.opacity = 1.0;
                                        } completion:^(BOOL finished2){
                                            if (![card.rank isEqualToString:@"999"]) {
                                                NSString *title = [self ruleTitleForCard:card];
                                                NSString *body  = [self ruleBodyForCard:card];
                                                [self.rulesBanner showWithTitle:title body:body inView:self.view autoHide:NO];
                                            }
                                        }];
                    }];
}

// 显示全部规则
- (void)onShowAllRules {
    NSString *all = @"A 命令牌：抽到A的人可以任意指定一个人喝酒或者留置挡酒用。\n\n"
    "2 小姐：抽到2的人成为本轮‘小姐’，需要给自己起一个名字,喝酒的人可点名陪喝.直到下一个2出现。\n\n"
    "3 逛三园：轮流说指定‘园’内的事物，说错/慢/重复者喝。\n\n"
    "4 玩游戏：可随时发起全员小游戏，输的人喝。\n\n"
    "5 照相机：发令后所有人静止，先动者喝。\n\n"
    "6 摸鼻子/柳树扭：最后一个跟动作摸鼻子的人喝；或玩‘柳树扭一扭’。\n\n"
    "7 逢7过：含7或7倍数拍手跳过，错误者喝。\n\n"
    "8 厕所牌：持证可上厕所，无证离席可罚酒。\n\n"
    "9 自饮：自己喝一杯。\n\n"
    "10 神经病：直到宣布恢复前，和你说话的人都被你罚酒。\n\n"
    "J 左边喝：指定左边玩家喝。\n\n"
    "Q 右边喝：指定右边玩家喝。\n\n"
    "K 定规则/加酒：制定规则(如说话之前必须先说我爱你...等等)至下一个K；或加酒，下一张K者全喝并继续加。";
    [self.rulesBanner showWithTitle:@"规则总览" body:all inView:self.view autoHide:NO];
}

@end
