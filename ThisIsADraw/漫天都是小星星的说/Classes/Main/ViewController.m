//
//  ViewController.m
//  漫天都是小星星的说
//
//  Created by 飞奔的羊 on 16/3/21.
//  Copyright © 2016年 itcast. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+GIF.h"
#import "FiveQiVc.h"
#import <AVOSCloud/AVOSCloud.h>
#import "Student.h"
#import "ProtopiaWebViewController.h"
#define Width [UIScreen mainScreen].bounds.size.width
#define Height  [UIScreen mainScreen].bounds.size.height
#import "Movie.h"
@interface ViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>


@property (weak, nonatomic) IBOutlet UIImageView *myGIF;
@property (weak, nonatomic) IBOutlet UIView *coverView;
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

/**
 *  <#描述#>
 */
@property (nonatomic,strong) UIWebView *webView;
@end

@implementation ViewController
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
                [self.view addSubview:imView];
        if (self.yy != nil) {
            self.originFram = imView.frame;
            CGRect oo = imView.frame;
            if (oo.origin.x >= CGRectGetMinX(self.originFram)&&oo.origin.x <= CGRectGetMaxX(self.originFram)&&oo.origin.y >= CGRectGetMinY(self.originFram)&&oo.origin.y <= CGRectGetMaxY(self.originFram)){
                
                [imView removeFromSuperview];
                
            }
        }
//        if (CGRectContainsRect(imView.frame, self.moveClear.frame)) {
//            [imView removeFromSuperview];
//        }
//        CALayer *layer = [CALayer layer];
//        layer.position =  [touch locationInView:self.view];
//        
//        layer.bounds = CGRectMake(0, 0, 200, 200);
//        layer.contents = (__bridge id _Nullable)([(id)self.imageArray[i] CGImage]);
//        [self.view.layer addSublayer:layer];
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
    UIImage *iamge = info[UIImagePickerControllerOriginalImage];
    
    self.view.layer.contents  = (id)iamge.CGImage;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

/**
 *  添加画笔
 *
 *  @param sender
 */
- (IBAction)addWrit:(id)sender {
    
    
    
//    UIWebView *webView = [[UIWebView alloc]initWithFrame:[UIScreen mainScreen].bounds];
//    
//    NSURL *url = [NSURL URLWithString:@"http://m.baidu.com"];
//    
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    
//    [webView loadRequest:request];
//    
//    [self.view addSubview:webView];
//    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
//        
//    }];
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 0.0);
        
        CGContextRef ctx = UIGraphicsGetCurrentContext();

        [self.view.layer renderInContext:ctx];

        UIImage *cilckImage = UIGraphicsGetImageFromCurrentImageContext();

        UIGraphicsEndImageContext();
  
        UIImageWriteToSavedPhotosAlbum(cilckImage, nil, nil, nil);
    });
}
- (IBAction)newPen:(id)sender {
    self.imageArray = @[
                        [UIImage imageNamed:@"ps4"],
                         [UIImage imageNamed:@"spark_blue"],
                         
                         [UIImage imageNamed:@"spark_magenta"],
                         [UIImage imageNamed:@"spark_red"],
                         [UIImage imageNamed:@"spark_green"],
                         
                         ];
    
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

/**
 *  gif
 */
//- (void)gif
//{
//    self.myGIF.image = [UIImage sd_animatedGIFNamed:@"0"];
//
//}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.colorVIew.hidden = NO;
    self.buttonView.hidden = NO;
    
    [self.navigationController.navigationBar setHidden:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.water.selected = YES;
//      [self post];
//    [self jump];
//    Student *student = [Student objectWithClassName:@"nimeimei"];
//    student.name = @"Mike";
//    student.age = 12;
//    student.gender = GenderMale;
//    [student saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        ZYLog(@"创建成功 %@", student);
//    }];
  
//    AVObject *testObject = [AVObject objectWithClassName:@"Review"];
//
//    [testObject setObject:@"夏洛特" forKey:@"movie"];
//    [testObject setObject:@"5" forKey:@"stars"];
//    [testObject setObject:@"你妹夫" forKey:@"comment"];
//    [testObject save];
//    [self gif];
}

- (void)jump{
    AVObject *student =[AVObject objectWithClassName:@"Review" objectId:@"5a39fdc7fe88c20063af246a"];
    //    Movie *movre = [Movie objectWithClassName:@"Review" objectId:@"5a39fd1e570c350032eb6d86"];
    
    [student fetchInBackgroundWithBlock:^(AVObject *object, NSError *error) {
        
        NSString *movie = [object objectForKey:@"comment"];
        if ([movie isEqualToString:@"百度"]) {
            NSString *url = [object objectForKey:@"movie"];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                ProtopiaWebViewController *ss = [[ProtopiaWebViewController alloc]init];
                ss.WebUrlStr = url;
                [self.navigationController pushViewController:ss animated:YES];
            });
            
        }else{
            
            
        }
        
    }];
    
}
- (UIWebView *)webView
{
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        _webView.dataDetectorTypes = UIDataDetectorTypeAll;
    }
    return _webView;
}

- (IBAction)fiveQi:(id)sender {
    
    
    AVObject *student =[AVObject objectWithClassName:@"Review" objectId:@"5a39fdc7fe88c20063af246a"];
    //    Movie *movre = [Movie objectWithClassName:@"Review" objectId:@"5a39fd1e570c350032eb6d86"];
    
    [student fetchInBackgroundWithBlock:^(AVObject *object, NSError *error) {
        
        NSString *movie = [object objectForKey:@"comment"];
        if ([movie isEqualToString:@"百度"]) {
            NSString *url = [object objectForKey:@"movie"];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                ProtopiaWebViewController *ss = [[ProtopiaWebViewController alloc]init];
                ss.WebUrlStr = url;
                [self.navigationController pushViewController:ss animated:YES];
            });
            
        }else{
            
            FiveQiVc *five = [[FiveQiVc alloc]init];
            self.water.selected = NO;
            self.yin.selected = NO;
            
            // 1. URL 定位资源,需要资源的地址
            
            
            
            [self.navigationController pushViewController:five animated:YES];

        }
        
    }];
    
    
    
    
  
}

- (void)post
{
    
//    NSURLSession *session = [NSURLSession sharedSession];
//
//    NSString *urlStr = @"http://192.168.0.6/x.json";
//
//    NSURL *url = [NSURL URLWithString:urlStr];
//
//    //通过单例的session得到一个sessionTask，且通过URL初始化task 在block内部可以直接对返回的数据进行处理
//
//    NSURLSessionTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//
//        //请求之后会调用这个block
//
//        NSString *resultStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//
//        NSDictionary *dic = [self dictionaryWithJsonString:resultStr];
//        NSString *x  = [NSString stringWithFormat:@"%d",[dic valueForKey:@"x"]];
//
//        NSLog(@"resultStr->%@",x);
//        if (![x isEqualToString:@"1"]) {
//
//        }else{
//
//
//
//        }
//
//    }];
//
//    //启动人物,让task开始之前执行
//
//    [task resume];
    
   
//    NSDictionary *dicParameters = [NSDictionary dictionaryWithObject:@"夏洛特"
//                                                              forKey:@"movie"];
//
//    // 调用指定名称的云函数 averageStars，并且传递参数
//    [AVCloud callFunctionInBackground:@"averageStars"
//                       withParameters:dicParameters
//                                block:^(id object, NSError *error) {
//
//
//                                    NSLog(@"这是什么~~~%@",object);
//                                    if(error == nil){
//                                        // 处理结果
//
//                                    } else {
//                                        // 处理报错
//                                    }
//                                    NSLog(@"这是咩啊!!!%@",error);
//
//                                }];
    
    
    
    
    
}
- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    
    
    
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
