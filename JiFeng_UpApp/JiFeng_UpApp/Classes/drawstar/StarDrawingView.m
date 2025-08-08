//
//  StarDrawingView.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/5.
//

#import "StarDrawingView.h"



@interface StarDrawingView ()

@property (nonatomic, assign) BOOL isDrawing;

@end

@implementation StarDrawingView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.userInteractionEnabled = YES;
        self.imageArray = @[[UIImage imageNamed:@"spark_blue"]]; // 默认图片
        self.isDrawing = NO;
    }
    return self;
}

- (void)startDrawing {
    self.isDrawing = YES;
}

- (void)stopDrawing {
    self.isDrawing = NO;
}

- (void)clearAll {
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            [view removeFromSuperview];
        }
    }
}

- (void)drawStarAtPoint:(CGPoint)point {
    if (!self.isDrawing || self.imageArray.count == 0) return;

    UIImage *img = self.imageArray[arc4random_uniform((uint32_t)self.imageArray.count)];
    UIImageView *star = [[UIImageView alloc] initWithImage:img];
    star.center = point;
    [self addSubview:star];

    [UIView animateWithDuration:0.8 animations:^{
        star.alpha = 0.0;
        star.transform = CGAffineTransformMakeScale(0.5, 0.5);
    } completion:^(BOOL finished) {
        [star removeFromSuperview];
    }];
}

#pragma mark - Touch events
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        [self drawStarAtPoint:[touch locationInView:self]];
    }
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        [self drawStarAtPoint:[touch locationInView:self]];
    }
}

@end
