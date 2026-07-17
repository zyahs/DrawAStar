//
//  CubeViewController.m
//  JiFeng_UpApp
//

#import "CubeViewController.h"
#import "JFDiceGameDefinition.h"
#import "JFDiceGameViewController.h"
#import "JFDiceNetworkRoomViewController.h"
#import "JFAnalyticsTracker.h"
#import "JFTheme.h"

@interface JFDiceCollectionCell : UICollectionViewCell
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIView *iconWell;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *groupLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *diceLabel;
- (void)configureWithDefinition:(JFDiceGameDefinition *)definition index:(NSInteger)index;
@end

@implementation JFDiceCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.contentView.layer.cornerRadius = 8;
        self.contentView.layer.cornerCurve = kCACornerCurveContinuous;
        self.contentView.layer.masksToBounds = YES;
        self.contentView.layer.borderWidth = 1;
        self.contentView.layer.borderColor = [JFTheme cardBorder].CGColor;

        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1, 1);
        [self.contentView.layer insertSublayer:_gradientLayer atIndex:0];

        _iconWell = [[UIView alloc] init];
        _iconWell.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.14];
        _iconWell.layer.cornerRadius = 8;
        _iconWell.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_iconWell];

        _iconView = [[UIImageView alloc] init];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.tintColor = UIColor.whiteColor;
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;
        [_iconWell addSubview:_iconView];

        _groupLabel = [[UILabel alloc] init];
        _groupLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
        _groupLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.72];
        _groupLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_groupLabel];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.minimumScaleFactor = 0.76;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        _subtitleLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.76];
        _subtitleLabel.numberOfLines = 2;
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_subtitleLabel];

        _diceLabel = [[UILabel alloc] init];
        _diceLabel.font = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightSemibold];
        _diceLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
        _diceLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_diceLabel];

        UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
        chevron.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.58];
        chevron.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:chevron];

        [NSLayoutConstraint activateConstraints:@[
            [_iconWell.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
            [_iconWell.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
            [_iconWell.widthAnchor constraintEqualToConstant:42],
            [_iconWell.heightAnchor constraintEqualToConstant:42],
            [_iconView.centerXAnchor constraintEqualToAnchor:_iconWell.centerXAnchor],
            [_iconView.centerYAnchor constraintEqualToAnchor:_iconWell.centerYAnchor],
            [_iconView.widthAnchor constraintEqualToConstant:24],
            [_iconView.heightAnchor constraintEqualToConstant:24],

            [_groupLabel.centerYAnchor constraintEqualToAnchor:_iconWell.centerYAnchor],
            [_groupLabel.leadingAnchor constraintEqualToAnchor:_iconWell.trailingAnchor constant:8],
            [_groupLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-10],

            [_titleLabel.topAnchor constraintEqualToAnchor:_iconWell.bottomAnchor constant:10],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],

            [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:4],
            [_subtitleLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_subtitleLabel.trailingAnchor constraintEqualToAnchor:_titleLabel.trailingAnchor],

            [_diceLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_diceLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10],
            [chevron.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
            [chevron.centerYAnchor constraintEqualToAnchor:_diceLabel.centerYAnchor],
            [chevron.widthAnchor constraintEqualToConstant:8],
            [chevron.heightAnchor constraintEqualToConstant:13],
        ]];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.contentView.bounds;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.12 animations:^{
        self.transform = highlighted ? CGAffineTransformMakeScale(0.97, 0.97) : CGAffineTransformIdentity;
        self.contentView.alpha = highlighted ? 0.82 : 1;
    }];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.transform = CGAffineTransformIdentity;
    self.contentView.alpha = 1;
}

- (void)configureWithDefinition:(JFDiceGameDefinition *)definition index:(NSInteger)index {
    NSArray<UIColor *> *colors = [JFTheme gradientColorsForIndex:index + (definition.group == JFDiceGameGroupParty ? 3 : 0)];
    self.gradientLayer.colors = @[
        (__bridge id)[colors[0] colorWithAlphaComponent:0.88].CGColor,
        (__bridge id)[colors[1] colorWithAlphaComponent:0.58].CGColor,
        (__bridge id)[[JFTheme backgroundSecondary] colorWithAlphaComponent:0.96].CGColor,
    ];
    self.iconView.image = [UIImage systemImageNamed:definition.symbolName];
    self.groupLabel.text = definition.isCustomDiceCount
        ? @"本机 / 联机"
        : (definition.group == JFDiceGameGroupParty ? @"酒桌局" : @"轻松局");
    self.titleLabel.text = definition.title;
    self.subtitleLabel.text = definition.subtitle;
    self.diceLabel.text = definition.isCustomDiceCount
        ? @"1-100 颗 / 人"
        : [NSString stringWithFormat:@"%ld 颗 / 人", (long)definition.recommendedDiceCount];
    self.accessibilityLabel = [NSString stringWithFormat:@"%@，%@，%@", definition.title, definition.subtitle, self.diceLabel.text];
}

@end

@interface CubeViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UISegmentedControl *filterControl;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) NSArray<JFDiceGameDefinition *> *allDefinitions;
@property (nonatomic, copy) NSArray<JFDiceGameDefinition *> *visibleDefinitions;
@end

@implementation CubeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"骰子游乐场";
    self.allDefinitions = [JFDiceGameDefinition allDefinitions];
    self.visibleDefinitions = self.allDefinitions;
    [self buildUI];
}

- (void)buildUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"骰子游乐场";
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = @"14 种玩法 · 2 秒封盘 · 线上多人";
    self.subtitleLabel.textColor = [JFTheme textSecondary];
    self.subtitleLabel.font = [JFTheme fontCallout];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.subtitleLabel];

    self.filterControl = [[UISegmentedControl alloc] initWithItems:@[@"全部", @"轻松", @"酒桌"]];
    self.filterControl.selectedSegmentIndex = 0;
    self.filterControl.selectedSegmentTintColor = [[JFTheme accent] colorWithAlphaComponent:0.86];
    [self.filterControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [JFTheme textPrimary],
                                                 NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]}
                                      forState:UIControlStateNormal];
    [self.filterControl addTarget:self action:@selector(onFilterChanged) forControlEvents:UIControlEventValueChanged];
    self.filterControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.filterControl];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 12;
    layout.minimumLineSpacing = 12;
    layout.sectionInset = UIEdgeInsetsMake(4, 16, 20, 16);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.collectionView registerClass:JFDiceCollectionCell.class forCellWithReuseIdentifier:@"diceMode"];
    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:safe.leadingAnchor constant:64],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-64],

        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:5],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],

        [self.filterControl.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:14],
        [self.filterControl.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.filterControl.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.filterControl.heightAnchor constraintEqualToConstant:34],

        [self.collectionView.topAnchor constraintEqualToAnchor:self.filterControl.bottomAnchor constant:8],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)onFilterChanged {
    [JFTheme hapticSelection];
    if (self.filterControl.selectedSegmentIndex == 0) {
        self.visibleDefinitions = self.allDefinitions;
    } else {
        JFDiceGameGroup group = self.filterControl.selectedSegmentIndex == 1 ? JFDiceGameGroupQuick : JFDiceGameGroupParty;
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(JFDiceGameDefinition *definition, NSDictionary *bindings) {
            return definition.group == group;
        }];
        self.visibleDefinitions = [self.allDefinitions filteredArrayUsingPredicate:predicate];
    }
    [self.collectionView reloadData];
    [self.collectionView setContentOffset:CGPointMake(0, -self.collectionView.adjustedContentInset.top) animated:NO];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.visibleDefinitions.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JFDiceCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"diceMode" forIndexPath:indexPath];
    JFDiceGameDefinition *definition = self.visibleDefinitions[indexPath.item];
    NSInteger sourceIndex = [self.allDefinitions indexOfObjectIdenticalTo:definition];
    [cell configureWithDefinition:definition index:sourceIndex == NSNotFound ? indexPath.item : sourceIndex];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
   sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = floor((collectionView.bounds.size.width - 16 * 2 - 12) / 2.0);
    return CGSizeMake(width, 164);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    JFDiceGameDefinition *definition = self.visibleDefinitions[indexPath.item];
    [JFTheme hapticImpactMedium];
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:definition.title
                                                                  message:definition.ruleGuide
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    if (definition.isCustomDiceCount) {
        [menu addAction:[UIAlertAction actionWithTitle:@"本机自定义骰池" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [weakSelf presentLocalConfigurationForDefinition:definition message:nil];
        }]];
    }
    [menu addAction:[UIAlertAction actionWithTitle:@"创建多人骰桌" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [weakSelf prepareNetworkGameForDefinition:definition asHost:YES roomCode:nil];
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"加入多人骰桌" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [weakSelf presentJoinPromptForDefinition:definition message:nil];
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    menu.popoverPresentationController.sourceView = cell ?: collectionView;
    menu.popoverPresentationController.sourceRect = cell ? cell.bounds : CGRectMake(CGRectGetMidX(collectionView.bounds), CGRectGetMidY(collectionView.bounds), 1, 1);
    [self presentViewController:menu animated:YES completion:nil];
}

- (void)presentLocalConfigurationForDefinition:(JFDiceGameDefinition *)definition message:(NSString *)message {
    if (!definition.isCustomDiceCount) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"本机自定义骰池"
                                                                   message:message ?: @"同一台手机按顺序传递，每位玩家封盘后再交给下一位。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"玩家人数（1-12）";
        field.keyboardType = UIKeyboardTypeNumberPad;
        field.text = @"1";
    }];
    if (definition.isCustomDiceCount) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
            field.placeholder = @"每人骰子数（1-100）";
            field.keyboardType = UIKeyboardTypeNumberPad;
            field.text = [NSString stringWithFormat:@"%ld", (long)definition.recommendedDiceCount];
        }];
    }
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"开始" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSInteger players = alert.textFields.firstObject.text.integerValue;
        NSInteger dice = definition.isCustomDiceCount ? alert.textFields.lastObject.text.integerValue : definition.recommendedDiceCount;
        if (players < 1 || players > 12 || dice < 1 || dice > 100) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf presentLocalConfigurationForDefinition:definition message:@"玩家人数需要为 1-12，每人骰子数需要为 1-100。"];
            });
            return;
        }
        [[JFAnalyticsTracker shared] trackEvent:@"game_mode_select"
                                      gameKind:JFGameKindDice
                                    properties:@{@"mode": definition.serviceType, @"playType": @"local"}];
        JFDiceGameViewController *game = [[JFDiceGameViewController alloc] initWithDefinition:definition diceCount:dice playerCount:players];
        [weakSelf.navigationController pushViewController:game animated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)prepareNetworkGameForDefinition:(JFDiceGameDefinition *)definition
                                  asHost:(BOOL)asHost
                                roomCode:(NSString *)roomCode {
    if (asHost && definition.isCustomDiceCount) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置每人骰子数"
                                                                       message:@"自定义骰池支持每人 1-100 颗。"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
            field.placeholder = @"1-100";
            field.keyboardType = UIKeyboardTypeNumberPad;
            field.text = [NSString stringWithFormat:@"%ld", (long)definition.recommendedDiceCount];
        }];
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"创建" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NSInteger dice = alert.textFields.firstObject.text.integerValue;
            if (dice < 1 || dice > 100) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf prepareNetworkGameForDefinition:definition asHost:YES roomCode:nil];
                });
                return;
            }
            [weakSelf pushNetworkGameForDefinition:definition diceCount:dice asHost:YES roomCode:nil];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    [self pushNetworkGameForDefinition:definition
                             diceCount:definition.recommendedDiceCount
                                asHost:asHost
                              roomCode:roomCode];
}

- (void)pushNetworkGameForDefinition:(JFDiceGameDefinition *)definition
                           diceCount:(NSInteger)diceCount
                              asHost:(BOOL)asHost
                            roomCode:(NSString *)roomCode {
    [[JFAnalyticsTracker shared] trackEvent:@"game_mode_select"
                                  gameKind:JFGameKindDice
                                properties:@{@"mode": definition.serviceType,
                                             @"playType": @"online",
                                             @"role": asHost ? @"host" : @"player"}];
    JFDiceNetworkRoomViewController *room = [[JFDiceNetworkRoomViewController alloc] initWithDefinition:definition
                                                                                              diceCount:diceCount
                                                                                                 asHost:asHost
                                                                                               roomCode:roomCode];
    [self.navigationController pushViewController:room animated:YES];
}

- (void)presentJoinPromptForDefinition:(JFDiceGameDefinition *)definition message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"加入%@", definition.title]
                                                                   message:message ?: @"输入房主页面上的 6 位房间码，或加入最近创建的同玩法骰桌。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"例如 A1B2C3";
        field.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
        field.returnKeyType = UIReturnKeyJoin;
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"加入最近骰桌" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [weakSelf prepareNetworkGameForDefinition:definition asHost:NO roomCode:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"按房间码加入" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *code = [[alert.textFields.firstObject.text ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
        if (code.length != 6) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf presentJoinPromptForDefinition:definition message:@"房间码固定为 6 位，请检查后重新输入。"];
            });
            return;
        }
        [weakSelf prepareNetworkGameForDefinition:definition asHost:NO roomCode:code];
    }]];
    [self presentViewController:alert animated:YES completion:^{
        [alert.textFields.firstObject becomeFirstResponder];
    }];
}

@end
