//
//  JFCardThumbCell.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/9/30.
//

#import "JFCardThumbCell.h"
#import "CardsGameViewController.h"
#import "JFGamePieceSkin.h"
#import "JFSkinStore.h"
#import <UIKit/UIKit.h>

@interface JFCardThumbCell ()
@property (nonatomic, strong) JFGamePieceSkinView *cardBG;
@property (nonatomic, strong) JFCardFaceArtworkView *artworkView;
@property (nonatomic, strong) UILabel *tlRank;
@property (nonatomic, strong) UILabel *tlSuit;
@property (nonatomic, strong) UILabel *centerLabel;
@property (nonatomic, strong) JFCard *currentCard;
@end

@implementation JFCardThumbCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = UIColor.clearColor;

        _cardBG = [[JFGamePieceSkinView alloc] init];
        _cardBG.surfaceStyle = JFGamePieceSurfaceStyleCardFace;
        _cardBG.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.15].CGColor;
        _cardBG.layer.shadowOpacity = 0.5;
        _cardBG.layer.shadowRadius = 4;
        _cardBG.layer.shadowOffset = CGSizeMake(0, 2);
        [self.contentView addSubview:_cardBG];

        _artworkView = [[JFCardFaceArtworkView alloc] init];
        _artworkView.userInteractionEnabled = NO;
        [_cardBG addSubview:_artworkView];

        _tlRank = [self label:11 weight:UIFontWeightSemibold];
        _tlSuit = [self label:11 weight:UIFontWeightRegular];
        _centerLabel = [self label:18 weight:UIFontWeightBlack];

        [_cardBG addSubview:_tlRank];
        [_cardBG addSubview:_tlSuit];
        [_cardBG addSubview:_centerLabel];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onSkinChanged)
                                                     name:JFSkinDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    _artworkView.frame = _cardBG.bounds;

    CGFloat pad = 6;
    _tlRank.frame = CGRectMake(pad, pad, 24, 16);
    _tlSuit.frame = CGRectMake(pad, CGRectGetMaxY(_tlRank.frame)-2, 24, 16);
    _centerLabel.frame = CGRectInset(_cardBG.bounds, 10, 10);
}

- (void)configureWithCard:(JFCard *)card {
    self.currentCard = card;
    JFSkin *skin = [JFGamePieceSkin currentSkin];
    BOOL red = [card.suit isEqualToString:@"♥"] || [card.suit isEqualToString:@"♦"];
    UIColor *c = red ? [JFGamePieceSkin cardRedInkColorForSkin:skin]
                     : [JFGamePieceSkin cardBlackInkColorForSkin:skin];
    _tlRank.textColor = c;
    _tlSuit.textColor = c;
    _centerLabel.textColor = c;

    _tlRank.text = card.rank;
    _tlSuit.text = card.suit;
    [_artworkView configureWithRank:card.rank suit:card.suit compact:YES];
    _tlRank.hidden = YES;
    _tlSuit.hidden = YES;
    _centerLabel.hidden = YES;
    _centerLabel.text = @"";
    [self.cardBG refreshSkin];
}

- (void)onSkinChanged {
    if (self.currentCard) [self configureWithCard:self.currentCard];
}

@end
