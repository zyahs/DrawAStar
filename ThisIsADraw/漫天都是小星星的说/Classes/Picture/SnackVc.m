//
//  ViewController.m
//  新浪微博
//
//  Created by 飞奔的羊 on 16/3/5.
//  Copyright © 2016年 itcast. All rights reserved.
//

#import "SnackVc.h"

@interface SnackVc ()
@property (strong, nonatomic) UIBarButtonItem * leftItem;
/**
 *  动画者
 */
@property (nonatomic,strong)UIDynamicAnimator *myAnimtor;
/**
 *  头球
 */
@property (nonatomic,weak)UIView *bigHead;
/**
 *连一块
 */
@property (nonatomic,strong)UIAttachmentBehavior *myAttach;
/**
 *  球球现有数组
 */
@property (nonatomic,strong)NSMutableArray<UIView *> *ballsArray;
/**
 *  吸附
 */
@property (nonatomic,strong)UISnapBehavior *mySnap;
/**
 *  生成的小球
 */
@property (nonatomic,weak)UIView *addBalls;
/**
 *  添加的小球
 */
@property (nonatomic,weak)UIView *myBall;
/**
 *  当前位置
 */
@property (nonatomic)CGRect originFram;
/**
 *  生成小球速度
 */
@property (nonatomic,weak)NSTimer *timer;
/**
 *字组
 */
@property (nonatomic,strong) NSArray * titleArray;
/**
 *  当前球球记录
 */
@property (nonatomic,assign)NSInteger index;
/**
 *  最后的点
 */
@property (nonatomic)CGPoint currentPoint;
/**
 *  球球爆裂数组
 */
@property (nonatomic,strong)NSArray *boomBallsArray;
@end

@implementation SnackVc
- (void)viewDidLoad {
	[super viewDidLoad];
	[self snow];
	
	[self setStartBalls];
	[self move];
	[self setLabels];
	self.index = 3;
	//    [self boomButton];
//	self.view.layer.contents = (__bridge id _Nullable)([UIImage imageNamed:@"BackgroundTile"].CGImage);
	
}
- (void)snow
{
	self.view.backgroundColor = [UIColor blackColor];
	flakeLayer = [CAEmitterLayer layer];
	
	
	CGRect bounds = [[UIScreen mainScreen] bounds];
	flakeLayer.emitterPosition = CGPointMake(bounds.size.width / 2, -10); //center of rectangle//发射位置
	flakeLayer.emitterSize = CGSizeMake(self.view.bounds.size.width * 2.0, 0.0);//bounds.size;//发射源的尺寸大小
	flakeLayer.emitterShape = kCAEmitterLayerLine;
	// Spawn points for the flakes are within on the outline of the line
	flakeLayer.emitterMode	= kCAEmitterLayerVolume;//发射模式
//	kCAEmitterLayerPoints
//	kCAEmitterLayerSurface
// kCAEmitterLayerVolume
	
	
	CAEmitterCell *flakeCell = [CAEmitterCell emitterCell];
	flakeCell.contents = (id)[[UIImage imageNamed:@"11111"] CGImage];//是个CGImageRef的对象,既粒子要展现的图片
	flakeCell.birthRate = 10;//粒子参数的速度乘数因子
	flakeCell.lifetime = 180.0;//生命周期
	flakeCell.lifetimeRange = 8;//生命周期范围
	
	flakeCell.velocity = -10;//速度
	flakeCell.velocityRange = 10;//速度范围
	flakeCell.yAcceleration = 10;//粒子y方向的加速度分量
	flakeCell.emissionLongitude = -M_PI / 2; // upx-y平面的发射方向  ....>> emissionLatitude：发射的z轴方向的角度
	flakeCell.emissionRange = M_PI / 4; // 90 degree cone for variety周围发射角度
	flakeCell.spinRange		= 0.25 * M_PI;		// slow spin子旋转角度范围
	
	
	flakeCell.scale = 0.5;//缩放比例：
	flakeCell.scaleSpeed = 0.1;//1.0;//缩放比例速度
	flakeCell.scaleRange = 1.0;//缩放比例范围；
	
	flakeCell.color = [[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0] CGColor];//粒子的颜色
	flakeCell.redRange = 1.0;//一个粒子的颜色red 能改变的范围；
	flakeCell.redSpeed = 0.1;//粒子red在生命周期内的改变速度；
	flakeCell.blueRange = 1.0;//一个粒子的颜色blue 能改变的范围
	flakeCell.blueSpeed = 0.1;//粒子blue在生命周期内的改变速度
	flakeCell.greenRange = 1.0;//个粒子的颜色green 能改变的范围；
	flakeCell.greenSpeed = 0.1;//粒子green在生命周期内的改变速度；
	flakeCell.alphaSpeed = -0.08;//粒子透明度在生命周期内的改变速度
	
	flakeLayer.emitterCells = [NSArray arrayWithObject:flakeCell];//粒子发射的粒子
	
	[self.view.layer insertSublayer:flakeLayer atIndex:0];
}
/**
 *  初始字组
 *
 */
- (NSArray *)titleArray{
	
	if (!_titleArray) {
		_titleArray = @[
						@"临",
						@"兵",
						@"斗",
						@"者",
						@"皆",
						@"阵",
						@"列",
						@"前"
						];
	}
	return _titleArray;
}
/**
 *  初始字
 */
- (void)setLabels{
	for (int i = 0 ; i < self.titleArray.count ; i++) {
		//九宫格布局
		CGFloat W = self.view.bounds.size.width;
		CGFloat btnW = 50;
		CGFloat btnH =50;
		//计算间隔
		//列数
		NSInteger cloums = 8;
		//总宽度 - 总按钮的宽度/2
		CGFloat marginW= (W - cloums *btnW)/(cloums -1);
		//正方格
		CGFloat marginH = marginW;
		//列的索引
		NSInteger col = i%cloums;
		//行的索引
		NSInteger row = i/cloums;
		
		CGFloat btnX = col *(marginW +btnW);
		CGFloat btnY = row *(marginH +btnH);
		
		//设置按钮的 frame
		UILabel *lab = [[UILabel alloc]init];
		lab.frame = CGRectMake(btnX+15, btnY+60, btnW, btnH);
		lab.text = self.titleArray[i];
		lab.font =[UIFont systemFontOfSize:20];
		lab.textColor = [UIColor grayColor];
		[self.view addSubview:lab];
	}
}
/**
 *  设置初始小球
 */
- (void)setStartBalls{
	
	NSMutableArray *balls = [NSMutableArray array];
	for ( NSInteger i = 0 ; i < 3 ; i++) {
		UIView *ballView = [[UIView alloc]init];
		ballView.backgroundColor = [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1];
		
		CGFloat ballW =20;
		CGFloat ballH =20;
		CGFloat ballX =100 +i*ballW;
		CGFloat ballY =100;
		
		ballView.layer.cornerRadius =10;
		ballView.layer.masksToBounds = YES;
		ballView.frame = CGRectMake(ballX, ballY, ballW, ballH);
		if (i == 0) {
			CGFloat ballW =40;
			CGFloat ballH =40;
			ballX -=15;
			ballY -=10;
			
			ballView.layer.cornerRadius =20;
			ballView.layer.masksToBounds = YES;
			ballView.frame = CGRectMake(ballX, ballY, ballW, ballH);
			self.bigHead = ballView;
			self.originFram = self.bigHead.frame;
		}
		
		[self.view addSubview:ballView];
		self.myBall = ballView;
		
		[balls addObject:ballView];
		self.ballsArray = balls;
		
	}
	
	NSTimer *time = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(addFood) userInfo:nil repeats:YES];
	self.timer =time;
	
}
/**
 *  添加移动
 */
- (void)move{
	
	self.myAnimtor = [[UIDynamicAnimator alloc]initWithReferenceView:self.view];
	
	UIGravityBehavior *gravity = [[UIGravityBehavior alloc]initWithItems:self.ballsArray];
	
	[self.myAnimtor addBehavior:gravity];
	
	UICollisionBehavior *collison = [[UICollisionBehavior alloc]initWithItems:self.ballsArray];
	collison.translatesReferenceBoundsIntoBoundary = YES;
	[self.myAnimtor addBehavior:collison];
	collison.collisionDelegate =self;
	//创建拖拽手势
	UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
	[self.view addGestureRecognizer:pan];
	
	//让几个球一个爱着一个
	for ( NSInteger i = 0 ; i < self.ballsArray.count -1 ; i++) {
		
		UIAttachmentBehavior *attach = [[UIAttachmentBehavior alloc]initWithItem:self.ballsArray
										[i] attachedToItem:self.ballsArray[i + 1]];
		[self.myAnimtor addBehavior:attach];
		
	}
	
}
/**
 *  生成小球
 */
- (void)addFood{
	
	[self.addBalls removeFromSuperview];
	CGFloat x = arc4random_uniform(400);
	CGFloat y = arc4random_uniform(700);
	CGFloat w = 20;
	CGFloat h = 20;
	
	UIView *add = [[UIView alloc]init];
	add.layer.contents =(__bridge id _Nullable)([UIImage imageNamed:@"btn_starred@2x.png.base.universal.regular.off.horizontal.normal.active.onepartscale.onepart.14258.000.00."].CGImage);
	add.frame = CGRectMake(x, y, w, h);
	
	[self.view addSubview:add];
	self.addBalls = add;
	
}
/**
 *  增加小球
 */
-(void)addBa{
	UIView *lastView = [[UIView alloc]init];
	lastView.frame = CGRectMake(100, 100, 100, 100);
	
	[self.ballsArray addObject:lastView];
}
/**
 *  拖拽方法
 *
 */
- (void)pan:(UIPanGestureRecognizer *)recognizer{
	
	//触摸的 Ian
	CGPoint loc = [recognizer locationInView:recognizer.view];
	
 //判断下 拖拽的状态
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		UIAttachmentBehavior *attach = [[UIAttachmentBehavior alloc]initWithItem:self.bigHead attachedToAnchor:loc];
		[self.myAnimtor addBehavior:attach];
		self.myAttach = attach;
		
	}else if(recognizer.state == UIGestureRecognizerStateChanged   ){
		//修改附着点
		self.myAttach.anchorPoint = loc;
		
	}else if (recognizer.state == UIGestureRecognizerStateEnded){
		[self.myAnimtor removeBehavior:self.myAttach];
		
	}
	
}
/**
 *  点击方法
 *
 */
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
	[self.myAnimtor removeBehavior:self.mySnap];
	
	UITouch *tou = touches.anyObject;
	CGPoint loc = [tou locationInView:self.view];
	self.currentPoint = loc;
	UISnapBehavior *snap = [[UISnapBehavior alloc]initWithItem:self.bigHead snapToPoint:loc];
	[self.myAnimtor addBehavior:snap];
	self.mySnap = snap;
	
	self.originFram =self.bigHead.frame;
	
	if (loc.x >= CGRectGetMinX(self.originFram)&&loc.x <= CGRectGetMaxX(self.originFram)&&loc.y >= CGRectGetMinY(self.originFram)&&loc.y <= CGRectGetMaxY(self.originFram)){
		//        NSLog(@"吃到了");
		self.index ++;
		[self addBa];
		NSLog(@"%@",NSStringFromCGRect(self.ballsArray.firstObject.frame)) ;
		
		for (UIView *view in self.ballsArray) {
			[view removeFromSuperview];
			
		}
		[self.ballsArray removeAllObjects];
		
		[self reprtBall];
		[self move];
		[self.addBalls removeFromSuperview];
	}
	
}
/**
 *  障碍变色
 *
 */
- (void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(nonnull id<UIDynamicItem>)item withBoundaryIdentifier:(nullable id<NSCopying>)identifier
{
	
	for (UIView *vi in self.ballsArray) {
		vi.backgroundColor = [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1];
		
	}
	
}
/**
 *  重新添加
 */
-(void)reprtBall{
 
	for ( NSInteger i = 0 ; i <self.index ; i++) {
		UIView *ballView = [[UIView alloc]init];
		ballView.backgroundColor = [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1];
		
		CGFloat ballW =20;
		CGFloat ballH =20;
		CGFloat ballX =self.currentPoint.x +i*ballW;
		CGFloat ballY =self.currentPoint.y;
		
		ballView.layer.cornerRadius =10;
		ballView.layer.masksToBounds = YES;
		ballView.frame = CGRectMake(ballX, ballY, ballW, ballH);
		[self.view addSubview:ballView];
		if (i == 0) {
			CGFloat ballW =40;
			CGFloat ballH =40;
			ballX-=20;
			ballY -=10;
			
			ballView.layer.cornerRadius =20;
			ballView.layer.masksToBounds = YES;
			ballView.frame = CGRectMake(ballX, ballY, ballW, ballH);
			self.bigHead = ballView;
			self.originFram = self.bigHead.frame;
			//             [self.view addSubview:ballView];
		}
		
		//.包了  删了
		//耍
		
		[self.ballsArray addObject:ballView];
		self.boomBallsArray = self.ballsArray ;
	}
	
}

- (UIBarButtonItem *)leftItem{
	if (!_leftItem) {
		_leftItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"0"] style:UIBarButtonItemStyleDone target:self action:@selector(backMethod)];
		[_leftItem setTintColor:[UIColor whiteColor]];
	}
	return _leftItem;
}
- (void)backMethod{
	[self.navigationController popViewControllerAnimated:YES];
	
}
//- (void)boomButton{
//    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 100)];
//    [btn setTitle:@"爆炸'" forState:UIControlStateNormal];
//    btn.backgroundColor = [UIColor redColor];
//    [btn addTarget:self action:@selector(boomBalls:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:btn];
//
//}
//- (void)boomBalls:(UIButton *)sender{
//    for ( NSInteger i = 0 ; i <self.boomBallsArray.count ; i++) {
//
//        UIView *ballView = [[UIView alloc]init];
//        ballView.backgroundColor = [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1];
//
//        CGFloat ballW =arc4random_uniform(50);
//        CGFloat ballH =arc4random_uniform(50);
//        CGFloat ballX =414;
//        CGFloat ballY =736;
//
//        ballView.layer.cornerRadius =10;
//        ballView.layer.masksToBounds = YES;
//        ballView.frame = CGRectMake(ballX, ballY, ballW, ballH);
//         [self.view addSubview:ballView];
//    }
//}
- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	self.navigationItem.leftBarButtonItem = self.leftItem;
	// Dispose of any resources that can be recreated.
}

@end
