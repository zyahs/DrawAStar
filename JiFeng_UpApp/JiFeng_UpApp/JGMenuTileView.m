//
//  JGMenuTileView.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/9/2.
//

// JGMenuTileView.m
#import "JGMenuTileView.h"

@interface JGMenuTileView ()
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *glowBorder;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation JGMenuTileView

- (instancetype)initWithTitle:(NSString *)title icon:(UIImage *)icon {
    if (self = [super initWithFrame:CGRectZero]) {
        self.layer.cornerRadius = 16;
        self.layer.masksToBounds = NO;

        // 毛玻璃
        UIBlurEffect *eff = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:eff];
        _blurView.layer.cornerRadius = 16;
        _blurView.layer.masksToBounds = YES;
        [self addSubview:_blurView];

        // 霓虹边（淡淡的发光描边）
        _glowBorder = [[UIView alloc] init];
        _glowBorder.userInteractionEnabled = NO;
        _glowBorder.layer.cornerRadius = 16;
        _glowBorder.layer.borderWidth = 1.0;
        _glowBorder.layer.borderColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.25].CGColor;
        _glowBorder.layer.shadowColor = [UIColor colorWithRed:0.4 green:0.7 blue:1 alpha:1].CGColor;
        _glowBorder.layer.shadowRadius = 12;
        _glowBorder.layer.shadowOpacity = 0.6;
        _glowBorder.layer.shadowOffset = CGSizeZero;
        [self addSubview:_glowBorder];

        // 图标
        _iconView = [[UIImageView alloc] initWithImage:icon];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.tintColor = [UIColor whiteColor]; // 若用 SF Symbols
        [_blurView.contentView addSubview:_iconView];

        // 标题
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = title;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [_blurView.contentView addSubview:_titleLabel];

        // 触控动效
        [self addTarget:self action:@selector(onTouchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(onTouchUp) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _blurView.frame = self.bounds;
    _glowBorder.frame = self.bounds;

    CGFloat pad = 12;
    CGFloat iconH = CGRectGetHeight(self.bounds)*0.45;
    _iconView.frame = CGRectMake(pad, pad, CGRectGetWidth(self.bounds)-pad*2, iconH);

    CGFloat titleH = 22;
    _titleLabel.frame = CGRectMake(pad,
                                   CGRectGetMaxY(_iconView.frame)+6,
                                   CGRectGetWidth(self.bounds)-pad*2,
                                   titleH);
}

- (void)onTouchDown {
    [UIView animateWithDuration:0.12 animations:^{
        self.transform = CGAffineTransformMakeScale(0.96, 0.96);
        self.layer.shadowOpacity = 0.9;
    }];
}

- (void)onTouchUp {
    [UIView animateWithDuration:0.16
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

@end
