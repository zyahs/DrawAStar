//
//  JFCardsPreviewGridVC.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/9/30.
//

#import "JFCardsPreviewGridVC.h"
#import "JFCardThumbCell.h"
#import "CardsGameViewController.h" // 为拿到 JFCard 类型
#import "JFTheme.h"

@interface JFCardsPreviewGridVC () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@end

@implementation JFCardsPreviewGridVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"已出过的牌";
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    [JFTheme installThemedBackgroundInView:self.view];

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                      target:self action:@selector(close)];

    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    // 横向滚动
    flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;

    // 小牌宽高（5:7 比例）
    CGFloat h = 110;
    CGFloat w = h * (5.0/7.0);
    flow.itemSize = CGSizeMake(w, h);
    flow.minimumLineSpacing = 12;     // 同方向间距
    flow.minimumInteritemSpacing = 12;// 不同行的间距（这里通常只有一行）
    flow.sectionInset = UIEdgeInsetsMake(16, 16, 16, 16);

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flow];
    _collectionView.backgroundColor = UIColor.clearColor;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.showsHorizontalScrollIndicator = NO;
    [_collectionView registerClass:JFCardThumbCell.class forCellWithReuseIdentifier:@"thumb"];
    [self.view addSubview:_collectionView];

    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [_collectionView.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [_collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_collectionView.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
    ]];
}

- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }

#pragma mark - Collection

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.allCards.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JFCardThumbCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"thumb" forIndexPath:indexPath];
    // 不按顺序展示：这里可以随机打乱一次
    // 若想每次打开都随机，下面这句保留；若想维持传入顺序，删除它。
    // （仅第一次 cellForItem 时洗一遍）
    static dispatch_once_t onceToken;
    static BOOL shuffled = NO;
    if (!shuffled) {
        shuffled = YES;
        NSMutableArray *tmp = self.allCards.mutableCopy;
        for (NSInteger i = tmp.count-1; i>0; i--) {
            NSInteger j = arc4random_uniform((uint32_t)(i+1));
            [tmp exchangeObjectAtIndex:i withObjectAtIndex:j];
        }
        self.allCards = tmp.copy;
    }
    [cell configureWithCard:self.allCards[indexPath.item]];
    return cell;
}

@end
