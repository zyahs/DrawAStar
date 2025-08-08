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

@interface StarDrawingViewController () <UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIView *toolPanel;
@property (nonatomic, strong) NSArray<UIButton *> *colorButtons;
@property (nonatomic, strong) NSArray<UIImage *> *brushImages;
@property (nonatomic, strong) UIImage *currentBrushImage;
@property (nonatomic, strong) UIButton *albumButton;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIButton *clearButton;

@end

@implementation StarDrawingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.backgroundColor = [UIColor blackColor];
    
//    [self setupBackgroundImageView];
//    [self setupToolPanel];
//    [self setupGestureRecognizer];
}

- (void)setupBackgroundImageView {
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.backgroundImageView];
}

- (void)setupToolPanel {
    self.toolPanel = [[UIView alloc] initWithFrame:CGRectZero];
    self.toolPanel.translatesAutoresizingMaskIntoConstraints = NO;
    self.toolPanel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    self.toolPanel.layer.cornerRadius = 12;
    [self.view addSubview:self.toolPanel];

    NSMutableArray *buttons = [NSMutableArray array];
    NSArray *imageNames = @[@"spark_red", @"spark_green", @"spark_blue", @"spark_yellow", @"spark_cyan", @"spark_magenta"];
    NSMutableArray *brushes = [NSMutableArray array];

    for (NSString *name in imageNames) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *img = [UIImage imageNamed:name];
        [btn setImage:img forState:UIControlStateNormal];
        btn.tag = buttons.count;
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn addTarget:self action:@selector(changeBrush:) forControlEvents:UIControlEventTouchUpInside];
        [self.toolPanel addSubview:btn];
        [buttons addObject:btn];
        [brushes addObject:img];
    }
    self.colorButtons = buttons;
    self.brushImages = brushes;
    self.currentBrushImage = brushes.firstObject;

    self.albumButton = [self createToolButtonWithTitle:@"相册" action:@selector(openPhotoAlbum)];
    self.saveButton = [self createToolButtonWithTitle:@"保存" action:@selector(saveToAlbum)];
    self.clearButton = [self createToolButtonWithTitle:@"清除" action:@selector(clearAllStars)];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[self.albumButton, self.saveButton, self.clearButton]];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.spacing = 10;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolPanel addSubview:stack];

    // Auto Layout
    [NSLayoutConstraint activateConstraints:@[
        [self.toolPanel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.toolPanel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.toolPanel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        [self.toolPanel.heightAnchor constraintEqualToConstant:120]
    ]];

    for (int i = 0; i < buttons.count; i++) {
        UIButton *btn = buttons[i];
        CGFloat size = 36;
        btn.frame = CGRectMake(10 + i * (size + 8), 10, size, size);
    }
    stack.frame = CGRectMake(10, 60, 200, 40);
}

- (UIButton *)createToolButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    btn.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.3];
    btn.layer.cornerRadius = 8;
    btn.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    [btn addTarget:self action:@selector(hideToolPanelOnDraw) forControlEvents:UIControlEventTouchDown];
    [btn addTarget:self action:@selector(hideToolPanelOnDraw) forControlEvents:UIControlEventTouchDragInside];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)setupGestureRecognizer {
    UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showToolPanel)];
    tripleTap.numberOfTapsRequired = 3;
    tripleTap.delegate = self;
    [self.view addGestureRecognizer:tripleTap];
}

- (void)changeBrush:(UIButton *)sender {
    self.currentBrushImage = self.brushImages[sender.tag];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint point = [touch locationInView:self.view];
        UIImageView *star = [[UIImageView alloc] initWithImage:self.currentBrushImage];
        star.center = point;
        [self.view addSubview:star];
    }
    self.toolPanel.hidden = YES;
}

- (void)openPhotoAlbum {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    self.backgroundImageView.image = image;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveToAlbum {
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 0);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIImageWriteToSavedPhotosAlbum(snapshot, nil, nil, nil);
}

- (void)clearAllStars {
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[UIImageView class]] && subview != self.backgroundImageView) {
            [subview removeFromSuperview];
        }
    }
}

- (void)showToolPanel {
    self.toolPanel.hidden = NO;
}

- (void)hideToolPanelOnDraw {
    self.toolPanel.hidden = YES;
}

@end
