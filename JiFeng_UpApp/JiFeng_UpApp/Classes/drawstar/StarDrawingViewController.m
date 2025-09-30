//
//  StarDrawingViewController.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/5.
//

//
//  StarDrawingViewController.m
//

#import "StarDrawingViewController.h"
#import <Photos/Photos.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#define Width [UIScreen mainScreen].bounds.size.width
#define Height  [UIScreen mainScreen].bounds.size.height
@interface StarDrawingViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>


@property (weak, nonatomic) IBOutlet UIImageView *myGIF;
@property (weak, nonatomic) IBOutlet UIView *coverView;

@property (weak, nonatomic) IBOutlet UIButton *bluebtn;

@property (weak, nonatomic) IBOutlet UIButton *blue1btn;

@property (weak, nonatomic) IBOutlet UIButton *greenbtn;
@property (weak, nonatomic) IBOutlet UIButton *Yredbtn;
@property (weak, nonatomic) IBOutlet UIButton *redbtn;
@property (weak, nonatomic) IBOutlet UIButton *yellbtn;
@property (weak, nonatomic) IBOutlet UIButton *gif1btn;
@property (weak, nonatomic) IBOutlet UIButton *gif2btn;
@property (weak, nonatomic) IBOutlet UIButton *gifbtn3;
@property (weak, nonatomic) IBOutlet UIButton *gifbtn4;
@property (weak, nonatomic) IBOutlet UIButton *gifbtn5;
@property (weak, nonatomic) IBOutlet UIButton *gifbtn6;

/**
 *  放颜色的 View
 */
@property (weak, nonatomic) IBOutlet UIView *colorVIew;
/**
 *  放按钮的 View
 */
@property (weak, nonatomic) IBOutlet UIView *buttonView;

/**
 *  荧光笔
 */
@property (weak, nonatomic) IBOutlet UIButton *yin;
/**
 *  流水笔
 */
@property (weak, nonatomic) IBOutlet UIButton *water;
/**
 *  笔种数组
 */
@property (nonatomic,strong) NSArray *imageArray;
/**
 *  透明度
 */
@property (nonatomic,assign)NSInteger alph;
/**
 *  是否清除
 */
@property (nonatomic,assign)BOOL clear;
/**
 *  清除按钮
 */
@property (nonatomic,weak) UIButton *alp;
/**
 *  是否开始
 */
@property (nonatomic,assign)NSInteger star;
/**
 *  开始按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *starBtn;
/**
 *  记录开始位置
 */
@property (nonatomic,assign)CGRect originFram;
/**
 *  画笔
 */
@property (nonatomic,weak)UIImageView *myview;
@property (nonatomic,weak)UIButton *yy;
@property (nonatomic,assign)CGPoint ss;



@end

@implementation StarDrawingViewController

/**
 *  清除
 *
 *  @return  bool
 */
-(BOOL)clear{
    if (!_clear) {
        _clear =YES;

    }
    return _clear;
}
/**
 *  懒加载
 *
 *  @return
 */
-(NSInteger)alph{

    if (!_alph) {
        _alph =0;
    }
    return _alph;
}
/**
 *  懒加载
 *
 *  @return
 */
- (NSInteger)star{
    if (!_star) {
        _star =0;
    }
    
    
    return _star;
}
/**
 *  懒加载
 *
 *  @return
 */
- (NSArray *)imageArray{

    if (!_imageArray) {
        _imageArray = @[
                        [UIImage imageNamed:@"spark_magenta"],
                         [UIImage imageNamed:@"spark_yellow"],
                        [UIImage imageNamed:@"spark_blue"],
                        [UIImage imageNamed:@"spark_green"],
                        [UIImage imageNamed:@"spark_cyan"],
                        [UIImage imageNamed:@"spark_red"],
                        ];
    }

    return _imageArray;
}
/**
 *  画笔
 *
 *  @param
 */
- (IBAction)yellow:(id)sender {
    self.imageArray = @[
                         [UIImage imageNamed:@"spark_yellow"],
                         [UIImage imageNamed:@"spark_magenta"],
                         [UIImage imageNamed:@"spark_blue"],
                         [UIImage imageNamed:@"spark_green"],
                         [UIImage imageNamed:@"spark_cyan"],
                         
                         ];
 
}
- (IBAction)red:(id)sender {
    self.imageArray = @[ [UIImage imageNamed:@"spark_red"],
                         
                         [UIImage imageNamed:@"spark_green"],
                         [UIImage imageNamed:@"spark_magenta"],
                         [UIImage imageNamed:@"spark_blue"],
                         [UIImage imageNamed:@"spark_cyan"],
                         
                         ];
}
- (IBAction)magenta:(id)sender {
    self.imageArray = @[ [UIImage imageNamed:@"spark_magenta"],
                         
                         [UIImage imageNamed:@"spark_red"],
                         [UIImage imageNamed:@"spark_blue"],
                         [UIImage imageNamed:@"spark_green"],
                         [UIImage imageNamed:@"spark_cyan"],
                         
                         ];
}
- (IBAction)green:(id)sender {
    self.imageArray = @[ [UIImage imageNamed:@"spark_green"],
                         [UIImage imageNamed:@"spark_cyan"],
                         
                         [UIImage imageNamed:@"spark_magenta"],
                         [UIImage imageNamed:@"spark_red"],
                         [UIImage imageNamed:@"spark_blue"],
                         
                         ];
}
- (IBAction)blue:(id)sender {
    self.imageArray = @[ [UIImage imageNamed:@"spark_blue"],
                         [UIImage imageNamed:@"spark_magenta"],
                         [UIImage imageNamed:@"spark_red"],
                           [UIImage imageNamed:@"spark_green"],
                         [UIImage imageNamed:@"spark_cyan"],
                         
                         
                         ];
}
- (IBAction)cyan:(id)sender {
    self.imageArray = @[ [UIImage imageNamed:@"spark_cyan"],
                         [UIImage imageNamed:@"spark_blue"],
                         
                         [UIImage imageNamed:@"spark_magenta"],
                         [UIImage imageNamed:@"spark_red"],
                         [UIImage imageNamed:@"spark_green"],
                         
                         ];
}
/**
 *  闪光
 *
 *  @param sender
 */
- (IBAction)fixed:(UIButton *)sender {
    self.water.selected = NO;
    sender.selected =YES;
    self.alph =1;
}
- (IBAction)Water:(UIButton *)sender {
    self.yin.selected = NO;
    sender.selected = YES;
     self.alph =0;
}
- (IBAction)star:(UIButton *)sender {
//    sender.selected = NO;
    self.starBtn.hidden =YES;
    UIButton *btn = [[UIButton alloc]initWithFrame:self.starBtn.frame];
    [btn setTitle:@"静止" forState: UIControlStateNormal];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(remove:) forControlEvents:UIControlEventTouchUpInside];
    [self.buttonView addSubview:btn];
    self.star = 1;
    
}
/**
 *  移除按钮
 *
 *  @param sender
 */
- (void)remove:(UIButton *)sender{

     self.starBtn.hidden =NO;
    [sender removeFromSuperview];
    self.star = 0;
    
}
/**
 *  绘制
 *
 
 */
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSInteger i = 0;
    [UIView animateWithDuration:2 animations:^{
        
        self.colorVIew.hidden = YES;
        self.buttonView.hidden =YES;
    }];
    for (UITouch *touch in touches) {
        UIImageView *imView = [[UIImageView alloc]initWithImage:self.imageArray[i]];
        CGPoint currentPoint = [touch locationInView:self.view];
        imView.center = currentPoint;
        [self.view addSubview:imView];
        [self jf_applyNeonGlowUnderView:imView];
        if (self.yy != nil) {
            self.originFram = imView.frame;
            CGRect oo = imView.frame;
            if (oo.origin.x >= CGRectGetMinX(self.originFram)&&oo.origin.x <= CGRectGetMaxX(self.originFram)&&oo.origin.y >= CGRectGetMinY(self.originFram)&&oo.origin.y <= CGRectGetMaxY(self.originFram)){
                
                [imView removeFromSuperview];
                
            }
        }
       
        if (CGRectContainsRect(imView.frame, self.originFram)) {
            [imView removeFromSuperview];
        }
        
        if (self.star) {
            CABasicAnimation *basic = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            
            
            basic.toValue = @(0.4);
            
            basic.repeatCount = CGFLOAT_MAX;
             [imView.layer addAnimation:basic forKey:nil];
        }
       
        i++;
        if (!self.alph) {
            [UIView animateWithDuration:1 animations:^{
                
                imView.alpha = self.alph;
                
                
            }completion:^(BOOL finished) {
                [UIView animateWithDuration:1 animations:^{
                    
                    [imView removeFromSuperview];
                }];
            }];

        }
    
        
    }
    

}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

    NSInteger i = 0;
    for (UITouch *touch in touches) {
        UIImageView *imView = [[UIImageView alloc]initWithImage:self.imageArray[i]];
        CGPoint currentPoint = [touch locationInView:self.view];
        imView.center = currentPoint;
        // Add neon glow (separate layer under the image to avoid covering the content)
        [self jf_applyNeonGlowUnderView:imView];
        [self.view addSubview:imView];
        if (self.yy != nil) {
            self.originFram = imView.frame;
            CGRect oo = imView.frame;
            if (oo.origin.x >= CGRectGetMinX(self.originFram)&&oo.origin.x <= CGRectGetMaxX(self.originFram)&&oo.origin.y >= CGRectGetMinY(self.originFram)&&oo.origin.y <= CGRectGetMaxY(self.originFram)){
                [imView removeFromSuperview];
            }
        }

        if (self.star) {
            // Complex animation: scale + rotation
            CAKeyframeAnimation *scale = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            scale.values = @[@1.0, @0.7, @1.0];
            scale.keyTimes = @[@0, @0.5, @1];
            scale.duration = 1.0;
            scale.repeatCount = HUGE_VALF;

            CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            rotation.toValue = @(M_PI * 2);
            rotation.duration = 2.5;
            rotation.repeatCount = HUGE_VALF;
            [imView.layer addAnimation:scale forKey:@"jf.scale"];
            [imView.layer addAnimation:rotation forKey:@"jf.rotation"];
        }

        i++;
        if (!self.alph) {
            [UIView animateWithDuration:1 animations:^{
                imView.alpha = self.alph;
            }completion:^(BOOL finished) {
                [UIView animateWithDuration:1 animations:^{
                    [imView removeFromSuperview];
                }];
            }];
        }
    }
}

/// Create a softer neon glow that follows the image silhouette (no circular ring)
- (void)jf_applyNeonGlowUnderView:(UIView *)target {
    // Remove old
    for (CALayer *sub in target.layer.sublayers.copy) {
        if ([sub.name isEqualToString:@"jf.neon.glow"]) {
            [sub removeFromSuperlayer];
        }
    }

    if (![target isKindOfClass:[UIImageView class]]) { return; }
    UIImageView *iv = (UIImageView *)target;
    UIImage *src = iv.image;
    if (!src) { return; }

    // Container
    CALayer *glow = [CALayer layer];
    glow.name = @"jf.neon.glow";
    glow.frame = iv.bounds;
    glow.masksToBounds = NO;
    glow.compositingFilter = @"screenBlendMode"; // additive look
    [iv.layer insertSublayer:glow atIndex:0];

    // 1) Build a blurred copy of the actual image so the glow hugs the shape (no ring)
    UIColor *tint = [self jf_randomNeonUIColor:0.85];

    // Core Image blur + tint
    CIImage *ciInput = [[CIImage alloc] initWithImage:src options:nil];
    if (ciInput) {
        CIContext *ciContext = [CIContext contextWithOptions:nil];

        // Gaussian blur
        CIFilter *blur = [CIFilter filterWithName:@"CIGaussianBlur"];
        [blur setValue:ciInput forKey:kCIInputImageKey];
        [blur setValue:@(8.0) forKey:kCIInputRadiusKey];
        CIImage *blurred = blur.outputImage;

        // Tint (multiply the blurred alpha with a color)
        CGFloat r,g,b,a; [tint getRed:&r green:&g blue:&b alpha:&a];
        CIFilter *tintFilter = [CIFilter filterWithName:@"CIColorMatrix"];
        [tintFilter setValue:blurred forKey:kCIInputImageKey];
        // Apply color channels while preserving alpha
        [tintFilter setValue:[CIVector vectorWithX:r Y:0 Z:0 W:0] forKey:@"inputRVector"];
        [tintFilter setValue:[CIVector vectorWithX:0 Y:g Z:0 W:0] forKey:@"inputGVector"];
        [tintFilter setValue:[CIVector vectorWithX:0 Y:0 Z:b W:0] forKey:@"inputBVector"];
        [tintFilter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:a] forKey:@"inputAVector"];
        CIImage *tinted = tintFilter.outputImage;

        // Crop to image extent to avoid CI's infinite extent
        CGRect extent = ciInput.extent;
        CIImage *cropped = [tinted imageByCroppingToRect:extent];

        // Render back to UIImage
        CGImageRef cg = [ciContext createCGImage:cropped fromRect:extent];
        if (cg) {
            UIImage *glowImage = [UIImage imageWithCGImage:cg scale:src.scale orientation:src.imageOrientation];
            CGImageRelease(cg);

            // Place slightly larger than image to show the blur
            CALayer *imgGlow = [CALayer layer];
            imgGlow.frame = CGRectInset(glow.bounds, -6, -6);
            imgGlow.contents = (__bridge id)glowImage.CGImage;
            imgGlow.opacity = 0.9;
            imgGlow.compositingFilter = @"screenBlendMode";
            [glow addSublayer:imgGlow];

            // Subtle breathing
            CABasicAnimation *breath = [CABasicAnimation animationWithKeyPath:@"opacity"];
            breath.fromValue = @0.6;
            breath.toValue   = @1.0;
            breath.duration  = 1.1;
            breath.autoreverses = YES;
            breath.repeatCount  = HUGE_VALF;
            breath.removedOnCompletion = NO;
            [imgGlow addAnimation:breath forKey:@"jf.glow.breath"];
        }
    }

    // 2) Tiny sparkle emitter (short life, cheap)
    CAEmitterLayer *spark = [CAEmitterLayer layer];
    spark.emitterShape = kCAEmitterLayerPoint;
    spark.emitterMode  = kCAEmitterLayerPoints;
    spark.emitterPosition = CGPointMake(CGRectGetMidX(glow.bounds), CGRectGetMidY(glow.bounds));
    spark.renderMode   = kCAEmitterLayerAdditive;
    spark.birthRate    = 0;

    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    UIImage *particleImage = [UIImage imageNamed:@"spark_blue"]; // sprite
    if (particleImage) {
        cell.contents = (__bridge id)particleImage.CGImage;
    }
    cell.name = @"cell";
    cell.lifetime = 0.45;
    cell.lifetimeRange = 0.15;
    cell.scale = 0.18;
    cell.scaleRange = 0.10;
    cell.velocity = 80;
    cell.velocityRange = 60;
    cell.emissionRange = (CGFloat)M_PI * 2.0;
    cell.alphaSpeed = -1.5;
    spark.emitterCells = @[cell];
    [glow addSublayer:spark];

    // One short pulse
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [spark setValue:@(220.0) forKeyPath:@"emitterCells.cell.birthRate"];
    [CATransaction commit];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.06 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [spark setValue:@(0.0) forKeyPath:@"emitterCells.cell.birthRate"];
        [CATransaction commit];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [spark removeFromSuperlayer];
        });
    });
}

/// Random vivid neon UIColor with given alpha
- (UIColor *)jf_randomNeonUIColor:(CGFloat)alpha {
    NSArray<UIColor *> *pool = @[
        [UIColor colorWithRed:1.00 green:0.36 blue:0.60 alpha:alpha], // pink
        [UIColor colorWithRed:0.34 green:0.64 blue:1.00 alpha:alpha], // blue
        [UIColor colorWithRed:0.40 green:1.00 blue:0.67 alpha:alpha], // mint
        [UIColor colorWithRed:0.99 green:0.84 blue:0.36 alpha:alpha], // yellow
        [UIColor colorWithRed:0.64 green:0.36 blue:1.00 alpha:alpha], // purple
        [UIColor colorWithRed:1.00 green:0.55 blue:0.35 alpha:alpha], // orange
        [UIColor colorWithRed:0.65 green:0.90 blue:0.40 alpha:alpha]  // lime
    ];
    return pool[arc4random_uniform((uint32_t)pool.count)];
}
/**
 *  清除
 *
 *  @param sender
 */
- (IBAction)clearImageView:(id)sender {
    NSArray *list=self.view.subviews;
    
    for (id obj in list) {
        if ([obj isKindOfClass:[UIImageView class]]) {
            UIImageView *imageView=(UIImageView *)obj;
            [UIView animateWithDuration:1 animations:^{
                imageView.alpha = 0;
            }completion:^(BOOL finished) {
                [UIView animateWithDuration:1 animations:^{
                    
                    [imageView removeFromSuperview];
                }];
                
            }];
}
    }

            
 self.view.layer.contents = (__bridge id _Nullable)([UIColor blueColor].CGColor);

  
}
/**
 *  全屏
 *
 *  @param sender
 */
- (IBAction)全屏:(id)sender {
    NSArray *list=self.view.subviews;
    
    for (id obj in list) {
        if ([obj isKindOfClass:[UIButton class]]) {
            UIButton *btn=(UIButton *)obj;
            
            [UIView animateWithDuration:1 animations:^{
                btn.alpha = 0;
            }completion:^(BOOL finished) {
                [UIView animateWithDuration:1 animations:^{
                    
                    btn.hidden =YES;
                }];
                
            }];
        }
    }
    
    for (id obj in list) {
        if ([obj isKindOfClass:[UILabel class]]) {
            UILabel *lab=(UILabel *)obj;
            [UIView animateWithDuration:1 animations:^{
                lab.alpha = 0;
            }completion:^(BOOL finished) {
                [UIView animateWithDuration:1 animations:^{
                    
                   lab.hidden = YES;
                }];
                
            }];
        }
    }
    
    
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
    [btn setTitle:@"返回设置" forState: UIControlStateNormal];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(returnBigr:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.view addSubview:btn];

}
/**
 *  返回小屏
 *
 *  @param cen
 */
-(void)returnBigr:(UIButton *)cen{


    
    NSArray *list=self.view.subviews;
 
    for (id obj in list) {
        if ([obj isKindOfClass:[UIButton class]]) {
            UIButton *btn=(UIButton *)obj;
            
            [UIView animateWithDuration:1 animations:^{
                btn.hidden =NO;
            }completion:^(BOOL finished) {
                [UIView animateWithDuration:1 animations:^{
                     btn.alpha = 1;
                   
                }];
                
            }];
        }
    }
    
    for (id obj in list) {
        if ([obj isKindOfClass:[UILabel class]]) {
            UILabel *lab=(UILabel *)obj;
            [UIView animateWithDuration:1 animations:^{
                lab.hidden = NO;
            }completion:^(BOOL finished) {
                [UIView animateWithDuration:1 animations:^{
                     lab.alpha = 1;
                   
                }];
                
            }];
        }
    }

    [UIView animateWithDuration:1 animations:^{
        cen.alpha = 0;
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:1
                         animations:^{
                             [cen removeFromSuperview];
                         }];
    }];
}
/**
 *  保存到相册
 *
 *  @param sender
 */

- (IBAction)Phtot:(UIButton *)sender {
        //访问相册
        UIImagePickerController *imss = [[UIImagePickerController alloc]init];
        [self presentViewController:imss animated:YES completion:nil];
        imss.delegate = self;
   
    /**
     *  返回 赋值
     *
     *
     */
   
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    //获取到的图片
//    UIImage *iamge = info[UIImagePickerControllerOriginalImage];
//
//    self.view.layer.contents  = (id)iamge.CGImage;
//
//    [self dismissViewControllerAnimated:YES completion:nil];
    
    // 获取图片
    UIImage *image = info[UIImagePickerControllerOriginalImage];
      UIImage *fixedImage = [self normalizedImage:image]; // 关键修正

      UIImageView *bgImageView = [[UIImageView alloc] initWithImage:fixedImage];
      bgImageView.frame = self.view.bounds;
      bgImageView.contentMode = UIViewContentModeScaleAspectFill; // 或者 AspectFit 看你要铺满还是完整
      bgImageView.clipsToBounds = YES;
      bgImageView.tag = 9999;

      // 清除旧背景
      UIView *old = [self.view viewWithTag:9999];
      if (old) [old removeFromSuperview];

      [self.view insertSubview:bgImageView atIndex:0];

      [self dismissViewControllerAnimated:YES completion:nil];
    
}
- (UIImage *)normalizedImage:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;

    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

/**
 *  添加画笔
 *
 *  @param sender
 */
- (IBAction)addWrit:(id)sender {
    

    [UIView animateWithDuration:1 animations:^{
        self.coverView.frame = CGRectMake(0, 0, 414, 179);
    }];
}
/**
 *  保存功能
 *
 *  @param sender <#sender description#>
 */
- (IBAction)save:(id)sender {
    [UIView animateWithDuration:1 animations:^{
        
        self.colorVIew.hidden = YES;
        self.buttonView.hidden =YES;
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 0.0);
        
        CGContextRef ctx = UIGraphicsGetCurrentContext();

        [self.view.layer renderInContext:ctx];

        UIImage *cilckImage = UIGraphicsGetImageFromCurrentImageContext();

        UIGraphicsEndImageContext();
  
        UIImageWriteToSavedPhotosAlbum(cilckImage, nil, nil, nil);
    });
}
/**
 *  颜色选择面板
 *
 *  @param sender <#sender description#>
 */
- (IBAction)ColorChange:(UIButton *)sender {
    [UIView animateWithDuration:1 animations:^{
        self.colorVIew.frame = CGRectMake(0, 0, 414, 179);
    }];
    
}
/**
 *  功能按钮面板
 *
 *  @param sender
 */
- (IBAction)ButtonVIew:(UIButton *)sender {
    [UIView animateWithDuration:2 animations:^{
        
        self.buttonView.hidden = NO;
        self.colorVIew.hidden = NO;
    }];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.colorVIew.hidden = NO;
    self.buttonView.hidden = NO;
    
    [self.navigationController.navigationBar setHidden:YES];
}
- (void)layoutColorButtons {
    NSArray *buttons = @[
        self.bluebtn, self.blue1btn, self.greenbtn,
        self.Yredbtn, self.redbtn, self.yellbtn,
        self.gif1btn, self.gif2btn, self.gifbtn3,
        self.gifbtn4, self.gifbtn5, self.gifbtn6
    ];

    NSInteger columns = 6;
    NSInteger rows = 2;
    
    CGFloat padding = 10.0;
    CGFloat buttonWidth = (self.colorVIew.bounds.size.width - (columns + 1) * padding) / columns;
    CGFloat buttonHeight = (self.colorVIew.bounds.size.height - (rows + 1) * padding) / rows;

    for (NSInteger i = 0; i < buttons.count; i++) {
        UIButton *btn = buttons[i];
        NSInteger row = i / columns;
        NSInteger col = i % columns;

        CGFloat x = padding + col * (buttonWidth + padding);
        CGFloat y = padding + row * (buttonHeight + padding);
        btn.frame = CGRectMake(x, y, buttonWidth, buttonHeight);
    }
}
- (void)setupGifButtons {
    NSArray<UIButton *> *gifButtons = @[
        self.gif1btn,
        self.gif2btn,
        self.gifbtn3,
        self.gifbtn4,
        self.gifbtn5,
        self.gifbtn6
    ];
    
    [gifButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull btn, NSUInteger idx, BOOL * _Nonnull stop) {
        btn.tag = idx;
        [btn addTarget:self action:@selector(handleGifButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    }];
}
- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (void)handleGifButtonTap:(UIButton *)sender {
 
    switch (sender.tag) {
        case 0:
            self.imageArray = @[[self resizeImage: [UIImage imageNamed:@"PS3"] toSize:CGSizeMake(40, 40)],
                                 [UIImage imageNamed:@"spark_blue"],
                                 
                                 [UIImage imageNamed:@"spark_magenta"],
                                 [UIImage imageNamed:@"spark_red"],
                                 [UIImage imageNamed:@"spark_green"], ];
            break;
        case 1:
            self.imageArray = @[
                [self resizeImage: [UIImage imageNamed:@"linecolor"] toSize:CGSizeMake(40, 40)],
                [UIImage imageNamed:@"spark_blue"],
                                 [UIImage imageNamed:@"spark_magenta"],
                                 [UIImage imageNamed:@"spark_red"],
                                 [UIImage imageNamed:@"spark_green"], ];
            break;
           
            
        case 2:
            self.imageArray = @[ [self resizeImage: [UIImage imageNamed:@"snow"] toSize:CGSizeMake(40, 40)],
                                  [UIImage imageNamed:@"spark_blue"],
                                  
                                  [UIImage imageNamed:@"spark_magenta"],
                                  [UIImage imageNamed:@"spark_red"],
                                  [UIImage imageNamed:@"spark_green"],];
            break;
        case 3:
            self.imageArray = @[
                [self resizeImage: [UIImage imageNamed:@"burst"] toSize:CGSizeMake(40, 40)],
                [UIImage imageNamed:@"linecolor"],
                                  [UIImage imageNamed:@"spark_blue"],
                                  
                                  [UIImage imageNamed:@"spark_magenta"],
                                  [UIImage imageNamed:@"spark_red"],
                                  [UIImage imageNamed:@"spark_green"], ];
            break;
        case 4:
            self.imageArray = @[    [self resizeImage: [UIImage imageNamed:@"55"] toSize:CGSizeMake(40, 40)],
                                  [UIImage imageNamed:@"spark_blue"],
                                  
                                  [UIImage imageNamed:@"spark_magenta"],
                                  [UIImage imageNamed:@"spark_red"],
                                  [UIImage imageNamed:@"spark_green"], ];
            break;
        case 5:
            self.imageArray = @[  [UIImage imageNamed:@"spark_green"],
                                  [UIImage imageNamed:@"spark_blue"],
                                  
                                  [UIImage imageNamed:@"spark_magenta"],
                                  [UIImage imageNamed:@"spark_red"],
                                  [UIImage imageNamed:@"spark_green"], ];
            break;
        default:
            break;
    }
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutColorButtons];
}
- (void)viewDidLoad {
    [super viewDidLoad];
//    self.water.selected = YES;
    self.yin.selected = YES;
    self.starBtn.hidden =NO;
    self.star = 1;
    self.alph = 1;
    [self setupGifButtons];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end

