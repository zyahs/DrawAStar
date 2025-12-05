//
//  JFCardThumbCell.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/9/30.
//

#import "JFCardThumbCell.h"
#import "CardsGameViewController.h"
#import <UIKit/UIKit.h>

@interface JFCardThumbCell ()
@property (nonatomic, strong) UIView *cardBG;
@property (nonatomic, strong) UILabel *tlRank;
@property (nonatomic, strong) UILabel *tlSuit;
@property (nonatomic, strong) UILabel *centerLabel;
@end

@implementation JFCardThumbCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = UIColor.clearColor;

        _cardBG = [[UIView alloc] init];
        _cardBG.backgroundColor = [UIColor colorWithWhite:1 alpha:0.95];
        _cardBG.layer.cornerRadius = 8;
        _cardBG.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1].CGColor;
        _cardBG.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
        _cardBG.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.15].CGColor;
        _cardBG.layer.shadowOpacity = 0.5;
        _cardBG.layer.shadowRadius = 4;
        _cardBG.layer.shadowOffset = CGSizeMake(0, 2);
        [self.contentView addSubview:_cardBG];

        _tlRank = [self label:11 weight:UIFontWeightSemibold];
        _tlSuit = [self label:11 weight:UIFontWeightRegular];
        _centerLabel = [self label:18 weight:UIFontWeightBlack];

        [_cardBG addSubview:_tlRank];
        [_cardBG addSubview:_tlSuit];
        [_cardBG addSubview:_centerLabel];
    }
    return self;
}

- (UILabel *)label:(CGFloat)size weight:(UIFontWeight)w {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont systemFontOfSize:size weight:w];
    l.textAlignment = NSTextAlignmentCenter;
    l.adjustsFontSizeToFitWidth = YES;
    return l;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _cardBG.frame = self.contentView.bounds;

    CGFloat pad = 6;
    _tlRank.frame = CGRectMake(pad, pad, 24, 16);
    _tlSuit.frame = CGRectMake(pad, CGRectGetMaxY(_tlRank.frame)-2, 24, 16);
    _centerLabel.frame = CGRectInset(_cardBG.bounds, 10, 10);
}

- (void)configureWithCard:(JFCard *)card {
    BOOL red = [card.suit isEqualToString:@"♥"] || [card.suit isEqualToString:@"♦"];
    UIColor *c = red ? [UIColor systemRedColor] : UIColor.blackColor;
    _tlRank.textColor = c;
    _tlSuit.textColor = c;
    _centerLabel.textColor = c;

    _tlRank.text = card.rank;
    _tlSuit.text = card.suit;
    _centerLabel.text = [NSString stringWithFormat:@"%@%@", card.rank, card.suit];
}

@end
