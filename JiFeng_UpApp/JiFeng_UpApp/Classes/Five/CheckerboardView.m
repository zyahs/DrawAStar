
//
//  CheckerboardView.m
//  Gomoku
//
//  Created by Sekorm on 16/7/25.
//  Copyright © 2016年 HY. All rights reserved.
//

#import "CheckerboardView.h"
#import "UIView+Frame.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_WIDTH_RATIO (SCREEN_WIDTH / 300)  //屏宽比例
static const NSInteger kGridCount = 16;         //多少个格子
static const CGFloat kChessmanSizeRatio = 0.8; //棋子宽高占格子宽高的百分比,大于0,小于1
static const CGFloat kBoardSpace = 20;

typedef enum : NSUInteger {
    GmkHorizontal,
    GmkVertical,
    GmkObliqueDown, //斜向下
    GmkObliqueUp //斜向上
} GmkDirection;

@interface CheckerboardView ()
@property (nonatomic,assign) CGFloat gridWidth;
@property (nonatomic,assign) CGFloat gridHeight;
@property (nonatomic,assign) CGFloat isBlack;
@property (nonatomic,strong) NSMutableArray * sameChessmanArray; //一条线上的同颜色的棋子个数
@property (nonatomic,strong) NSMutableDictionary * chessmanDict; //存放棋子字典的字典
@property (nonatomic,strong) NSString * lastKey; //上一个棋子字典的key值
@property (nonatomic,assign) BOOL  isHighLevel;  //是否是高级棋盘
@property (nonatomic,assign) NSInteger  gridCount;
@property (nonatomic,assign) BOOL  isOver; //游戏是否结束
@property (nonatomic,assign) CGSize lastBoardSize;

@end

@implementation CheckerboardView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:200/255.0 green:160/255.0 blue:130/255.0 alpha:1];
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBoard:)]];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    // 只要 bounds 尺寸变了就重画一次背景(替换旧的 dispatch_once 逻辑)
    if (self.bounds.size.width <= 0 || self.bounds.size.height <= 0) return;
    if (fabs(self.bounds.size.width - self.lastBoardSize.width) < 0.5 &&
        fabs(self.bounds.size.height - self.lastBoardSize.height) < 0.5) return;
    self.lastBoardSize = self.bounds.size;
    [self redrawBoard];
}

- (void)redrawBoard {
    // 先把旧的背景图层移除(避免叠加)
    for (UIView *sub in [self.subviews copy]) {
        if ([sub isKindOfClass:[UIImageView class]] && sub.tag == 9999) {
            [sub removeFromSuperview];
        }
    }
    [self drawBackground:self.bounds.size];
}

#pragma mark - 绘制棋盘
- (void)drawBackground:(CGSize)size{
    
    self.gridWidth = (size.width - 2 * kBoardSpace) / self.gridCount;
    self.gridHeight = (size.height - 2 * kBoardSpace) / self.gridCount;
    
    //1.开启图像上下文
    UIGraphicsBeginImageContext(size);
    //2.获取上下文
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(ctx, 0.8f);
    //3.1 画16条竖线
    for (int i = 0; i <= self.gridCount; i ++) {
        CGContextMoveToPoint(ctx, kBoardSpace + i * self.gridWidth , kBoardSpace);
        CGContextAddLineToPoint(ctx, kBoardSpace + i * self.gridWidth , kBoardSpace + self.gridCount * self.gridHeight);
    }
    //3.1 画16条横线
    for (int i = 0; i <= self.gridCount; i ++) {
        CGContextMoveToPoint(ctx, kBoardSpace, kBoardSpace  + i * self.gridHeight );
        CGContextAddLineToPoint(ctx, kBoardSpace + self.gridCount * self.gridWidth , kBoardSpace + i * self.gridHeight);
    }
    CGContextStrokePath(ctx);
    
    //4.获取生成的图片
    UIImage *image=UIGraphicsGetImageFromCurrentImageContext();
    //5.显示生成的图片到imageview
    UIImageView * imageView = [[UIImageView alloc]initWithImage:image];
    imageView.tag = 9999;
    [self insertSubview:imageView atIndex:0];
    UIGraphicsEndImageContext();
}

//点击棋盘,下棋
- (void)tapBoard:(UITapGestureRecognizer *)tap{

    CGPoint point = [tap locationInView:tap.view];
    //计算下子的列号行号
    NSInteger col = (point.x - kBoardSpace + 0.5 * self.gridWidth) / self.gridWidth;
    NSInteger row = (point.y - kBoardSpace + 0.5 * self.gridHeight) / self.gridHeight;
    if (col < 0 || row < 0 || col > self.gridCount || row > self.gridCount) return;
    NSString * key = [NSString stringWithFormat:@"%ld-%ld",col,row];
    if (![self.chessmanDict.allKeys containsObject:key]) {
        UIView * chessman = [self chessman];
        chessman.center = CGPointMake(kBoardSpace + col * self.gridWidth, kBoardSpace + row * self.gridHeight);
        [self addSubview:chessman];
        [self.chessmanDict setValue:chessman forKey:key];
        self.lastKey = key;
        //检查游戏结果
        [self checkResult:col andRow:row andColor:self.isBlack];
        self.isBlack = !self.isBlack;
    }
}

#pragma mark - 私有方法
//检查此时游戏结果
- (void)checkResult:(NSInteger)col andRow:(NSInteger)row andColor:(BOOL)isBlack{
    
    [self checkResult:col andRow:row andColor:isBlack andDirection:GmkHorizontal];
    [self checkResult:col andRow:row andColor:isBlack andDirection:GmkVertical];
    [self checkResult:col andRow:row andColor:isBlack andDirection:GmkObliqueDown];
    [self checkResult:col andRow:row andColor:isBlack andDirection:GmkObliqueUp];
}

 //判断是否大于等于五个同色相连
- (BOOL)checkResult:(NSInteger)col andRow:(NSInteger)row andColor:(BOOL)isBlack andDirection:(GmkDirection)direction{

    if (self.sameChessmanArray.count >= 5) {
        return YES;
    }
    UIView *currentChessman = self.chessmanDict[[NSString stringWithFormat:@"%ld-%ld",col,row]];
    UIColor * currentChessmanColor = currentChessman.backgroundColor;
    [self.sameChessmanArray addObject:self.chessmanDict[self.lastKey]];
    switch (direction) {
        //水平方向检查结果
        case GmkHorizontal:{
            //向前遍历
            for (NSInteger i = col - 1; i > 0; i --) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",i,row];
                UIView *view = self.chessmanDict[key];
                if (!view || ![view.backgroundColor isEqual:currentChessmanColor]) break;
                [self.sameChessmanArray addObject:self.chessmanDict[key]];
            }
            //向后遍历
            for (NSInteger i = col + 1; i < kGridCount; i ++) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",i,row];
                UIView *view = self.chessmanDict[key];
                if (!view || ![view.backgroundColor isEqual:currentChessmanColor]) break;
                [self.sameChessmanArray addObject:self.chessmanDict[key]];
            }
            if (self.sameChessmanArray.count >= 5) {
                [self alertResult];
                return YES;
            }
            [self.sameChessmanArray removeAllObjects];
            
        }
            break;
        case GmkVertical:{
            //向前遍历
            for (NSInteger i = row - 1; i > 0; i --) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",col,i];
                UIView *view = self.chessmanDict[key];
                if (!view || ![view.backgroundColor isEqual:currentChessmanColor]) break;
                [self.sameChessmanArray addObject:self.chessmanDict[key]];
            }
            //向后遍历
            for (NSInteger i = row + 1; i < kGridCount; i ++) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",col,i];
                UIView *view = self.chessmanDict[key];
                if (!view || ![view.backgroundColor isEqual:currentChessmanColor]) break;
                [self.sameChessmanArray addObject:self.chessmanDict[key]];
            }
            if (self.sameChessmanArray.count >= 5) {
                [self alertResult];
                return YES;
            }
            [self.sameChessmanArray removeAllObjects];
            
        }
            break;
        case GmkObliqueDown:{
            
            //向前遍历
            NSInteger j = col - 1;
            for (NSInteger i = row - 1; i >= 0; i--,j--) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",j,i];
                UIView *view = self.chessmanDict[key];
                if (!view || ![view.backgroundColor isEqual:currentChessmanColor] || j < 0) break;
                [self.sameChessmanArray addObject:self.chessmanDict[key]];
            }
            //向后遍历
            j = col + 1;
            for (NSInteger i = row + 1 ; i < kGridCount; i++,j++) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",j,i];
                UIView *view = self.chessmanDict[key];
                if (!view || ![view.backgroundColor isEqual:currentChessmanColor] || j > kGridCount) break;
                [self.sameChessmanArray addObject:self.chessmanDict[key]];
            }
            if (self.sameChessmanArray.count >= 5) {
                [self alertResult];
                return YES;
            }
            [self.sameChessmanArray removeAllObjects];
            
        
        }
            break;
        case GmkObliqueUp:{
            //向前遍历
            NSInteger j = col + 1;
            for (NSInteger i = row - 1; i >= 0; i--,j++) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",j,i];
                UIView *view = self.chessmanDict[key];
                if (!view || ![view.backgroundColor isEqual:currentChessmanColor] || j > kGridCount) break;
                [self.sameChessmanArray addObject:self.chessmanDict[key]];
            }
            //向后遍历
            j = col - 1;
            for (NSInteger i = row + 1 ; i < kGridCount; i++,j--) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",j,i];
                UIView *view = self.chessmanDict[key];
                if (!view || ![view.backgroundColor isEqual:currentChessmanColor] || j < 0) break;
                [self.sameChessmanArray addObject:self.chessmanDict[key]];
            }
            if (self.sameChessmanArray.count >= 5) {
                [self alertResult];
                return YES;
            }
            [self.sameChessmanArray removeAllObjects];
            
        }
            break;
    }
    return NO;
}

//游戏结果,提示效果
- (void)alertResult{

    self.isOver = YES;

    CGFloat width = SCREEN_WIDTH * 0.4 * SCREEN_WIDTH_RATIO;
    UIView * tip = [[UIView alloc]initWithFrame:CGRectMake(0, 0, width, 0.6 * width)];
    tip.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    tip.alpha = 1;
    tip.layer.cornerRadius = 8.0f;
    [self addSubview:tip];
    tip.center = CGPointMake(self.width * 0.5, self.height * 0.5);
    UILabel * label = [[UILabel alloc]init];
    label.text = self.isBlack?@"白方胜":@"黑方胜";
    [label sizeToFit];
    label.center = CGPointMake(tip.width * 0.5, tip.height * 0.5);
    [tip addSubview:label];
    
    CAKeyframeAnimation * anim = [CAKeyframeAnimation animation];
    anim.values = @[@(1),@(0),@(1)];
    anim.keyPath = @"opacity";
    anim.duration = 0.8f;
    anim.repeatCount = CGFLOAT_MAX;
    for (UIView * view in self.sameChessmanArray) {
        [view.layer addAnimation:anim forKey:@"alpha"];
    }
    
    self.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tip removeFromSuperview];
    });

    // 广播一次游戏结束
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JFFiveInRowDidFinishNotification"
                                                         object:nil
                                                       userInfo:@{@"isBlack": @(self.isBlack)}];
}

#pragma mark - 功能方法
- (void)newGame{
    
    self.isOver = NO;
    self.lastKey = nil;
    [self.sameChessmanArray removeAllObjects];
    self.userInteractionEnabled = YES;
    [self.chessmanDict removeAllObjects];
    for (UIView * view in self.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            continue;
        }
        [view removeFromSuperview];
    }
    self.isBlack = NO;
}

//撤回至上一步棋
- (void)backOneStep:(UIButton *)sender{

    if(self.isOver) return;
    
    if (self.lastKey == nil) {
        sender.enabled = NO;
        CGFloat width = SCREEN_WIDTH * 0.4 * SCREEN_WIDTH_RATIO;
        UIView * tip = [[UIView alloc]initWithFrame:CGRectMake(0, 0, width, 0.6 * width)];
        tip.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
        tip.layer.cornerRadius = 8.0f;
        [self addSubview:tip];
        tip.center = CGPointMake(self.width * 0.5, self.height * 0.5);
        UILabel * label = [[UILabel alloc]init];
        label.text = self.chessmanDict.count > 0 ? @"只能悔一步棋!!!" : @"请先落子!!!";
        label.font = [UIFont systemFontOfSize:15];
        [label sizeToFit];
        label.center = CGPointMake(tip.width * 0.5, tip.height * 0.5);
        [tip addSubview:label];
        
        self.userInteractionEnabled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.userInteractionEnabled = YES;
            sender.enabled = YES;
            [tip removeFromSuperview];
            
        });
        return;
    }
    [self.chessmanDict removeObjectForKey:self.lastKey];
    [self.subviews.lastObject removeFromSuperview];
    self.isBlack = !self.isBlack;
    self.lastKey = nil;
}

//改变键盘级别
- (void)changeBoardLevel{
    
    for (UIView * view in self.subviews) {
        [view removeFromSuperview];
    }
    [self newGame];
    self.isHighLevel = !self.isHighLevel;
    [self drawBackground:self.bounds.size];
}

#pragma mark - getter/setter 方法

- (UIView *)chessman{
    CGFloat side = MIN(self.gridWidth, self.gridHeight) * kChessmanSizeRatio;
    UIView * chessmanView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, side, side)];
    chessmanView.layer.cornerRadius = chessmanView.width * 0.5;
    chessmanView.backgroundColor = !self.isBlack ? [UIColor blackColor]:[UIColor whiteColor];
    return chessmanView;
}

- (NSMutableDictionary *)chessmanDict{
    if (!_chessmanDict) {
        _chessmanDict = [NSMutableDictionary dictionary];
    }
    return _chessmanDict;
}

- (NSMutableArray *)sameChessmanArray{
    if (!_sameChessmanArray) {
        _sameChessmanArray = [NSMutableArray array];
    }
    return _sameChessmanArray;
}

- (NSInteger)gridCount{
    // 不再区分初/高级,统一使用 kGridCount(全屏棋盘)
    return kGridCount;
}
@end
