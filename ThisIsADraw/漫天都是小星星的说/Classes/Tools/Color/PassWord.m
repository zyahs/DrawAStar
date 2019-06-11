//
//  PassWord.m
//  漫天都是小星星的说
//
//  Created by 飞奔的羊 on 16/3/22.
//  Copyright © 2016年 itcast. All rights reserved.
//

#import "PassWord.h"

@interface PassWord ()

@property (nonatomic,strong)NSMutableArray<UIButton *> *nineArray;
@property (nonatomic,assign)CGPoint endPoint;

@property (nonatomic,strong)UIColor *changeColor;
@end
@implementation PassWord
- (UIColor *)changeColor{
    if (!_changeColor) {
        _changeColor = [UIColor whiteColor];
    }
    
    return _changeColor;
}
-(NSMutableArray *)nineArray{
    
    if (!_nineArray) {
        _nineArray = [NSMutableArray array];
    }
    
    return _nineArray;
    
}

- (void)drawRect:(CGRect)rect{
    UIBezierPath *path = [UIBezierPath bezierPath];
    for ( NSInteger i = 0 ; i < self.nineArray.count ; i++) {
        if (i == 0) {
            [path moveToPoint:self.nineArray[i].center];
        }else{
            
            [path addLineToPoint:self.nineArray[i].center];
        }
    }
    if (self.nineArray.count >0) {
        [path addLineToPoint:self.endPoint];
    }
    
    [self.changeColor set];
    [path stroke];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = touches.anyObject;
    CGPoint loc = [touch locationInView:touch.view];
    self.endPoint = loc;
    for ( NSInteger i = 0 ; i < self.subviews.count ; i++) {
        UIButton *btn = self.subviews[i];
        if (CGRectContainsPoint(btn.frame, loc)&&!btn.highlighted) {
            btn.highlighted = YES;
            [self.nineArray addObject:btn];
        }
    }
    
    [self setNeedsDisplay];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = touches.anyObject;
    CGPoint loc = [touch locationInView:touch.view];
    self.endPoint = loc;
    for ( NSInteger i = 0 ; i < self.subviews.count ; i++) {
        UIButton *btn = self.subviews[i];
        if (CGRectContainsPoint(btn.frame, loc)&&!btn.highlighted) {
            btn.highlighted = YES;
            [self.nineArray addObject:btn];
        }
    }
    
    [self setNeedsDisplay];
}
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSMutableString *barr = [NSMutableString string];
    self.endPoint = [[self.nineArray lastObject] center];
    for (UIButton *btn in self.nineArray) {
        [barr appendFormat:@"%@",@(btn.tag)];
    }
    if ([barr isEqualToString:@"0126101413121115"]) {
        [self clearButton];
[UIView animateWithDuration:1 animations:^{
    self.alpha = 0;
}completion:^(BOOL finished) {
    [UIView animateWithDuration:1 animations:^{
         [self removeFromSuperview];
    }];
}];
            
        
           
      
        
    }else{
        for (UIButton *btn  in self.nineArray) {
            btn.highlighted = NO;
            btn.selected = YES;
            
        }
        self.changeColor = [UIColor redColor];
        [self setNeedsDisplay];
        self.userInteractionEnabled = NO;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self clearButton];
            
            self.userInteractionEnabled = YES;
        });
    }
    
}
- (void)ssss{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"友情提示" message:@"输入正确" preferredStyle:UIAlertControllerStyleAlert];
    
    //创建两个UIAlertActoion对象
    UIAlertAction *ActionOK = [UIAlertAction actionWithTitle:@"查看钱包" style:UIAlertActionStyleDefault handler:nil];
    UIAlertAction *ActionCancle = [UIAlertAction actionWithTitle:@"留在本页面" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //        return 0;
        
    }];
    
    //把AlertAction添加到AlertController里
    [alertController addAction:ActionCancle];
    [alertController addAction:ActionOK];
    //显示弹窗
    //            [self presentViewController:alertController animated:YES completion:nil];
}
- (void)clearButton{
    self.changeColor = [UIColor whiteColor];
    for (UIButton *btn in self.nineArray) {
        btn.highlighted = NO;
        btn.selected = NO;
    }
    [self.nineArray removeAllObjects];
    
    
    [self setNeedsDisplay];
}
//创建按钮
- (void)awakeFromNib{
    [super awakeFromNib];
    for (int i = 0 ; i < 16 ; i++) {
        UIButton *btn = [[UIButton alloc]init];
        
        btn.tag = i;
        
        btn.userInteractionEnabled = NO;
        
        [btn setBackgroundImage:[UIImage imageNamed:@"gesture_node_normal"] forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIImage imageNamed:@"gesture_node_highlighted"] forState:UIControlStateHighlighted];
        
        [btn setBackgroundImage:[UIImage imageNamed:@"gesture_node_error"] forState:UIControlStateSelected];
        
        [self addSubview:btn];
    }
    
    
}
- (void)layoutSubviews{
    [super layoutSubviews];
    for ( NSInteger i = 0 ; i < self.subviews.count ; i++) {
        CGFloat W = self.bounds.size.width;
        CGFloat nineW = 100;
        CGFloat nineH =100;
        NSInteger cloums =4;
        CGFloat marginW= (W - cloums *nineW)/(cloums -1);
        //正方格
        CGFloat marginH = marginW;
        //列的索引
        NSInteger col = i%cloums;
        //行的索引
        NSInteger row = i/cloums;
        
        CGFloat nineX = col *(marginW +nineW);
        CGFloat nineY = row *(marginH +nineH)+150;
        
        UIButton *btn = self.subviews[i];
        btn.frame = CGRectMake(nineX, nineY, nineW, nineH);
        
//        NSLog(@"%@", NSStringFromCGRect(btn.frame) );
    }
    
    
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end

