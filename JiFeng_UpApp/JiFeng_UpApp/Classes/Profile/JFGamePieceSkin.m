//
//  JFGamePieceSkin.m
//  JiFeng_UpApp
//

#import "JFGamePieceSkin.h"
#import "JFSkinStore.h"

static UIColor *JFResolvedColor(UIColor *color) {
    if (@available(iOS 13.0, *)) {
        return [color resolvedColorWithTraitCollection:UITraitCollection.currentTraitCollection];
    }
    return color;
}

static void JFColorComponents(UIColor *color, CGFloat *r, CGFloat *g, CGFloat *b, CGFloat *a) {
    UIColor *resolved = JFResolvedColor(color);
    if (![resolved getRed:r green:g blue:b alpha:a]) {
        CGFloat white = 0;
        [resolved getWhite:&white alpha:a];
        *r = white;
        *g = white;
        *b = white;
    }
}

static UIColor *JFBlendColor(UIColor *from, UIColor *to, CGFloat amount) {
    CGFloat fr, fg, fb, fa, tr, tg, tb, ta;
    JFColorComponents(from, &fr, &fg, &fb, &fa);
    JFColorComponents(to, &tr, &tg, &tb, &ta);
    CGFloat t = MAX(0, MIN(1, amount));
    return [UIColor colorWithRed:fr + (tr - fr) * t
                           green:fg + (tg - fg) * t
                            blue:fb + (tb - fb) * t
                           alpha:fa + (ta - fa) * t];
}

static BOOL JFStyleIsDark(NSString *style) {
    return [@[@"circuit", @"noir", @"celestial"] containsObject:style ?: @""];
}

static UIBezierPath *JFRoundedPath(CGRect rect, CGFloat radius) {
    return [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:MIN(radius, MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) * 0.22)];
}

static void JFDrawGradient(CGContextRef context, CGRect rect, UIBezierPath *clipPath, NSArray<UIColor *> *colors) {
    CGContextSaveGState(context);
    [clipPath addClip];
    NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:colors.count];
    for (UIColor *color in colors) [cgColors addObject:(id)JFResolvedColor(color).CGColor];
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(space, (__bridge CFArrayRef)cgColors, NULL);
    CGContextDrawLinearGradient(context, gradient,
                                CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect)),
                                CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect)), 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(space);
    CGContextRestoreGState(context);
}

static void JFStrokeRoundedRect(CGRect rect, CGFloat radius, UIColor *color, CGFloat width) {
    UIBezierPath *path = JFRoundedPath(rect, radius);
    [color setStroke];
    path.lineWidth = width;
    [path stroke];
}

@implementation JFGamePieceSkin

+ (JFSkin *)currentSkin {
    return [JFSkinStore shared].currentSkin;
}

+ (UIColor *)cardFaceColorForSkin:(JFSkin *)skin {
    NSString *style = skin.pieceStyle ?: @"starlight";
    if (JFStyleIsDark(style)) return JFBlendColor(skin.backgroundTop, UIColor.whiteColor, 0.10);
    if ([style isEqualToString:@"royal"]) return [UIColor colorWithRed:0.98 green:0.94 blue:0.80 alpha:1];
    if ([style isEqualToString:@"porcelain"]) return [UIColor colorWithRed:0.96 green:0.98 blue:1.00 alpha:1];
    if ([style isEqualToString:@"sakura"] || [style isEqualToString:@"ribbon"]) {
        return [UIColor colorWithRed:1.00 green:0.95 blue:0.97 alpha:1];
    }
    if ([style isEqualToString:@"woodland"]) return [UIColor colorWithRed:0.96 green:0.96 blue:0.86 alpha:1];
    if ([style isEqualToString:@"pearl"]) return [UIColor colorWithRed:0.91 green:0.99 blue:0.98 alpha:1];
    return JFBlendColor([UIColor colorWithWhite:0.98 alpha:1], skin.brandSecondary, 0.045);
}

+ (UIColor *)cardBorderColorForSkin:(JFSkin *)skin {
    NSString *style = skin.pieceStyle ?: @"starlight";
    if ([style isEqualToString:@"royal"] || [style isEqualToString:@"celestial"]) return skin.accent;
    if ([style isEqualToString:@"porcelain"]) return JFBlendColor(skin.brandPrimary, UIColor.whiteColor, 0.18);
    return JFBlendColor(skin.brandPrimary, skin.accent, 0.45);
}

+ (UIColor *)cardRedInkColorForSkin:(JFSkin *)skin {
    NSString *style = skin.pieceStyle ?: @"starlight";
    if (JFStyleIsDark(style)) return JFBlendColor(skin.brandSecondary, UIColor.whiteColor, 0.12);
    if ([style isEqualToString:@"porcelain"]) return [UIColor colorWithRed:0.78 green:0.10 blue:0.15 alpha:1];
    if ([style isEqualToString:@"royal"]) return [UIColor colorWithRed:0.56 green:0.07 blue:0.09 alpha:1];
    return JFBlendColor([UIColor colorWithRed:0.88 green:0.08 blue:0.16 alpha:1], skin.brandSecondary, 0.18);
}

+ (UIColor *)cardBlackInkColorForSkin:(JFSkin *)skin {
    if (JFStyleIsDark(skin.pieceStyle)) return [UIColor colorWithWhite:1 alpha:0.92];
    if ([skin.pieceStyle isEqualToString:@"porcelain"]) return [UIColor colorWithRed:0.05 green:0.18 blue:0.35 alpha:1];
    if ([skin.pieceStyle isEqualToString:@"woodland"]) return [UIColor colorWithRed:0.08 green:0.24 blue:0.15 alpha:1];
    return [UIColor colorWithWhite:0.075 alpha:1];
}

+ (UIColor *)cardBackDetailColorForSkin:(JFSkin *)skin {
    if ([skin.pieceStyle isEqualToString:@"royal"]) return [UIColor colorWithRed:1.0 green:0.87 blue:0.46 alpha:1];
    if ([skin.pieceStyle isEqualToString:@"porcelain"]) return [UIColor colorWithRed:0.76 green:0.90 blue:1 alpha:1];
    return JFBlendColor(UIColor.whiteColor, skin.accent, 0.28);
}

+ (UIColor *)diceBodyColorForSkin:(JFSkin *)skin {
    NSString *style = skin.pieceStyle ?: @"starlight";
    if (JFStyleIsDark(style)) return JFBlendColor(skin.backgroundBottom, UIColor.whiteColor, 0.08);
    if ([style isEqualToString:@"royal"]) return [UIColor colorWithRed:0.98 green:0.88 blue:0.58 alpha:1];
    if ([style isEqualToString:@"porcelain"]) return [UIColor colorWithRed:0.95 green:0.98 blue:1 alpha:1];
    if ([style isEqualToString:@"pearl"]) return [UIColor colorWithRed:0.88 green:0.99 blue:0.97 alpha:1];
    return JFBlendColor(UIColor.whiteColor, skin.brandSecondary, 0.075);
}

+ (UIColor *)dicePipColorForSkin:(JFSkin *)skin highlighted:(BOOL)highlighted {
    if (highlighted) return skin.accent;
    if (JFStyleIsDark(skin.pieceStyle)) return JFBlendColor(UIColor.whiteColor, skin.accent, 0.35);
    if ([skin.pieceStyle isEqualToString:@"royal"]) return [UIColor colorWithRed:0.32 green:0.06 blue:0.07 alpha:1];
    if ([skin.pieceStyle isEqualToString:@"porcelain"]) return [UIColor colorWithRed:0.04 green:0.24 blue:0.54 alpha:1];
    return JFBlendColor(skin.brandPrimary, [UIColor colorWithWhite:0.04 alpha:1], 0.22);
}

+ (UIColor *)diceBorderColorForSkin:(JFSkin *)skin highlighted:(BOOL)highlighted {
    return highlighted ? skin.accent : JFBlendColor(skin.brandPrimary, skin.accent, 0.38);
}

@end

@interface JFGamePieceSkinView ()
@property (nonatomic, strong) id skinObserver;
@end

@implementation JFGamePieceSkinView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.opaque = NO;
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;
        _showsCenterEmblem = YES;
        __weak typeof(self) weakSelf = self;
        _skinObserver = [NSNotificationCenter.defaultCenter addObserverForName:JFSkinDidChangeNotification
                                                                        object:nil
                                                                         queue:NSOperationQueue.mainQueue
                                                                    usingBlock:^(__unused NSNotification *note) {
            [weakSelf refreshSkin];
        }];
    }
    return self;
}

- (void)dealloc {
    if (self.skinObserver) [NSNotificationCenter.defaultCenter removeObserver:self.skinObserver];
}

- (void)setSurfaceStyle:(JFGamePieceSurfaceStyle)surfaceStyle {
    _surfaceStyle = surfaceStyle;
    [self setNeedsDisplay];
}

- (void)setSkin:(JFSkin *)skin {
    _skin = skin;
    [self setNeedsDisplay];
}

- (void)setShowsCenterEmblem:(BOOL)showsCenterEmblem {
    _showsCenterEmblem = showsCenterEmblem;
    [self setNeedsDisplay];
}

- (void)refreshSkin {
    [self setNeedsDisplay];
}

- (JFSkin *)resolvedSkin {
    return self.skin ?: [JFGamePieceSkin currentSkin];
}

- (void)drawCardFaceInRect:(CGRect)rect skin:(JFSkin *)skin context:(CGContextRef)context {
    CGFloat radius = MIN(16, MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) * 0.12);
    UIBezierPath *outer = JFRoundedPath(CGRectInset(rect, 1, 1), radius);
    UIColor *base = [JFGamePieceSkin cardFaceColorForSkin:skin];
    UIColor *shine = JFBlendColor(base, UIColor.whiteColor, 0.52);
    UIColor *shade = JFBlendColor(base, skin.brandPrimary, JFStyleIsDark(skin.pieceStyle) ? 0.16 : 0.06);
    JFDrawGradient(context, rect, outer, @[shine, base, shade]);

    UIColor *border = [JFGamePieceSkin cardBorderColorForSkin:skin];
    JFStrokeRoundedRect(CGRectInset(rect, 1, 1), radius, [border colorWithAlphaComponent:0.9], 1.2);
    JFStrokeRoundedRect(CGRectInset(rect, 4.5, 4.5), MAX(2, radius - 3), [border colorWithAlphaComponent:0.20], 0.8);

    CGFloat corner = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) * 0.14;
    UIBezierPath *ornament = [UIBezierPath bezierPath];
    [ornament moveToPoint:CGPointMake(6, 6 + corner)];
    [ornament addLineToPoint:CGPointMake(6, 6)];
    [ornament addLineToPoint:CGPointMake(6 + corner, 6)];
    [ornament moveToPoint:CGPointMake(CGRectGetMaxX(rect) - 6 - corner, CGRectGetMaxY(rect) - 6)];
    [ornament addLineToPoint:CGPointMake(CGRectGetMaxX(rect) - 6, CGRectGetMaxY(rect) - 6)];
    [ornament addLineToPoint:CGPointMake(CGRectGetMaxX(rect) - 6, CGRectGetMaxY(rect) - 6 - corner)];
    ornament.lineWidth = 1.2;
    [[border colorWithAlphaComponent:0.46] setStroke];
    [ornament stroke];

    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) * 0.34
                                                                                                  weight:UIImageSymbolWeightBlack];
    UIImage *symbol = [[UIImage systemImageNamed:skin.symbolName ?: @"sparkles" withConfiguration:configuration]
                       imageWithTintColor:[border colorWithAlphaComponent:JFStyleIsDark(skin.pieceStyle) ? 0.08 : 0.055]];
    CGFloat side = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) * 0.46;
    [symbol drawInRect:CGRectMake(CGRectGetMidX(rect) - side / 2, CGRectGetMidY(rect) - side / 2, side, side)];
}

- (void)drawBackPatternInRect:(CGRect)rect skin:(JFSkin *)skin {
    NSString *style = skin.pieceStyle ?: @"starlight";
    UIColor *detail = [[JFGamePieceSkin cardBackDetailColorForSkin:skin] colorWithAlphaComponent:0.18];
    [detail setStroke];

    if ([style isEqualToString:@"circuit"] || [style isEqualToString:@"prism"]) {
        for (CGFloat y = 12; y < CGRectGetHeight(rect); y += 18) {
            UIBezierPath *line = [UIBezierPath bezierPath];
            [line moveToPoint:CGPointMake(4, y)];
            [line addLineToPoint:CGPointMake(CGRectGetWidth(rect) * 0.36, y)];
            [line addLineToPoint:CGPointMake(CGRectGetWidth(rect) * 0.48, y + 8)];
            [line addLineToPoint:CGPointMake(CGRectGetWidth(rect) - 4, y + 8)];
            line.lineWidth = 0.8;
            [line stroke];
        }
        return;
    }

    CGFloat step = MAX(14, MIN(24, CGRectGetWidth(rect) * 0.18));
    for (CGFloat y = -step; y < CGRectGetHeight(rect) + step; y += step) {
        for (CGFloat x = -step; x < CGRectGetWidth(rect) + step; x += step) {
            UIBezierPath *shape;
            if ([style isEqualToString:@"pearl"] || [style isEqualToString:@"porcelain"]) {
                shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(x, y, step, step)];
            } else if ([style isEqualToString:@"sakura"] || [style isEqualToString:@"ribbon"]) {
                shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(x + step * 0.24, y, step * 0.52, step)];
            } else {
                shape = [UIBezierPath bezierPath];
                [shape moveToPoint:CGPointMake(x + step / 2, y)];
                [shape addLineToPoint:CGPointMake(x + step, y + step / 2)];
                [shape addLineToPoint:CGPointMake(x + step / 2, y + step)];
                [shape addLineToPoint:CGPointMake(x, y + step / 2)];
                [shape closePath];
            }
            shape.lineWidth = 0.65;
            [shape stroke];
        }
    }
}

- (void)drawCardBackInRect:(CGRect)rect skin:(JFSkin *)skin context:(CGContextRef)context {
    CGFloat radius = MIN(16, MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) * 0.12);
    UIBezierPath *outer = JFRoundedPath(CGRectInset(rect, 1, 1), radius);
    UIColor *deep = JFBlendColor(skin.backgroundBottom, UIColor.blackColor, 0.16);
    UIColor *middle = JFBlendColor(skin.brandPrimary, skin.backgroundTop, 0.24);
    JFDrawGradient(context, rect, outer, @[deep, middle, skin.brandSecondary, deep]);

    CGContextSaveGState(context);
    [outer addClip];
    [self drawBackPatternInRect:rect skin:skin];
    CGContextRestoreGState(context);

    UIColor *detail = [JFGamePieceSkin cardBackDetailColorForSkin:skin];
    JFStrokeRoundedRect(CGRectInset(rect, 1, 1), radius, [detail colorWithAlphaComponent:0.92], 1.4);
    JFStrokeRoundedRect(CGRectInset(rect, 5, 5), MAX(3, radius - 3), [detail colorWithAlphaComponent:0.56], 1.0);
    JFStrokeRoundedRect(CGRectInset(rect, 8, 8), MAX(2, radius - 5), [detail colorWithAlphaComponent:0.22], 0.7);

    if (self.showsCenterEmblem) {
        CGFloat medallionSide = MIN(CGRectGetWidth(rect) * 0.54, CGRectGetHeight(rect) * 0.34);
        CGRect medallion = CGRectMake(CGRectGetMidX(rect) - medallionSide / 2,
                                      CGRectGetMidY(rect) - medallionSide / 2,
                                      medallionSide, medallionSide);
        UIBezierPath *medallionPath = [UIBezierPath bezierPathWithOvalInRect:medallion];
        [[deep colorWithAlphaComponent:0.64] setFill];
        [medallionPath fill];
        [[detail colorWithAlphaComponent:0.84] setStroke];
        medallionPath.lineWidth = 1.4;
        [medallionPath stroke];

        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:medallionSide * 0.46
                                                                                                      weight:UIImageSymbolWeightBold];
        UIImage *symbol = [[UIImage systemImageNamed:skin.symbolName ?: @"sparkles" withConfiguration:configuration]
                           imageWithTintColor:[detail colorWithAlphaComponent:0.96]];
        CGFloat symbolSide = medallionSide * 0.58;
        [symbol drawInRect:CGRectMake(CGRectGetMidX(rect) - symbolSide / 2,
                                      CGRectGetMidY(rect) - symbolSide / 2,
                                      symbolSide, symbolSide)];
    }
}

- (void)drawDiceTrayInRect:(CGRect)rect skin:(JFSkin *)skin context:(CGContextRef)context {
    CGFloat radius = MIN(14, MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) * 0.10);
    UIBezierPath *outer = JFRoundedPath(CGRectInset(rect, 1, 1), radius);
    UIColor *deep = JFBlendColor(skin.backgroundTop, UIColor.blackColor, 0.34);
    UIColor *middle = JFBlendColor(skin.backgroundBottom, skin.brandPrimary, 0.18);
    JFDrawGradient(context, rect, outer, @[deep, middle, JFBlendColor(deep, skin.brandSecondary, 0.16)]);

    CGContextSaveGState(context);
    [outer addClip];
    UIColor *lineColor = [[JFGamePieceSkin cardBackDetailColorForSkin:skin] colorWithAlphaComponent:0.10];
    [lineColor setStroke];
    CGFloat step = 22;
    for (CGFloat x = -CGRectGetHeight(rect); x < CGRectGetWidth(rect); x += step) {
        UIBezierPath *line = [UIBezierPath bezierPath];
        [line moveToPoint:CGPointMake(x, CGRectGetHeight(rect))];
        [line addLineToPoint:CGPointMake(x + CGRectGetHeight(rect), 0)];
        line.lineWidth = 0.8;
        [line stroke];
    }
    CGContextRestoreGState(context);
    JFStrokeRoundedRect(CGRectInset(rect, 1, 1), radius,
                        [[JFGamePieceSkin diceBorderColorForSkin:skin highlighted:NO] colorWithAlphaComponent:0.52], 1.0);
    JFStrokeRoundedRect(CGRectInset(rect, 6, 6), MAX(2, radius - 4),
                        [[JFGamePieceSkin cardBackDetailColorForSkin:skin] colorWithAlphaComponent:0.11], 0.8);
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context || CGRectIsEmpty(rect)) return;
    JFSkin *skin = [self resolvedSkin];
    switch (self.surfaceStyle) {
        case JFGamePieceSurfaceStyleCardBack:
            [self drawCardBackInRect:self.bounds skin:skin context:context];
            break;
        case JFGamePieceSurfaceStyleDiceTray:
            [self drawDiceTrayInRect:self.bounds skin:skin context:context];
            break;
        case JFGamePieceSurfaceStyleCardFace:
        default:
            [self drawCardFaceInRect:self.bounds skin:skin context:context];
            break;
    }
}

@end

@interface JFCardFaceArtworkView ()
@property (nonatomic, copy) NSString *rank;
@property (nonatomic, copy) NSString *suit;
@property (nonatomic, assign) BOOL compact;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) id skinObserver;
@end

@implementation JFCardFaceArtworkView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.opaque = NO;
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;
        self.clipsToBounds = YES;

        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.alpha = 0.98;
        [self addSubview:_imageView];

        __weak typeof(self) weakSelf = self;
        _skinObserver = [NSNotificationCenter.defaultCenter addObserverForName:JFSkinDidChangeNotification
                                                                        object:nil
                                                                         queue:NSOperationQueue.mainQueue
                                                                    usingBlock:^(__unused NSNotification *note) {
            [weakSelf refreshArtwork];
        }];
    }
    return self;
}

- (void)dealloc {
    if (self.skinObserver) [NSNotificationCenter.defaultCenter removeObserver:self.skinObserver];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    self.layer.cornerRadius = MIN(14, MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) * 0.10);
}

- (void)setSkin:(JFSkin *)skin {
    _skin = skin;
    [self refreshArtwork];
}

- (void)setPresetId:(NSString *)presetId {
    _presetId = [presetId copy];
    [self refreshArtwork];
}

- (JFSkin *)resolvedSkin {
    return self.skin ?: [JFGamePieceSkin currentSkin];
}

- (NSString *)resolvedPresetId {
    return self.presetId ?: [JFSkinStore shared].currentCardFacePresetId ?: @"themed";
}

- (NSString *)suitCode {
    if ([self.suit isEqualToString:@"♣"]) return @"C";
    if ([self.suit isEqualToString:@"♦"]) return @"D";
    if ([self.suit isEqualToString:@"♥"]) return @"H";
    return @"S";
}

- (NSString *)artworkAssetName {
    if (self.rank.length == 0 || self.suit.length == 0) return nil;
    NSString *preset = [self resolvedPresetId];
    if ([preset isEqualToString:@"pixel"]) {
        return [NSString stringWithFormat:@"jf_pixel_%@%@", self.rank, [self suitCode]];
    }
    BOOL court = [@[@"J", @"Q", @"K"] containsObject:self.rank];
    if ([preset isEqualToString:@"classic"] && court) {
        return [NSString stringWithFormat:@"jf_classic_%@%@", self.rank, [self suitCode]];
    }
    return nil;
}

- (BOOL)usesFullCardArtwork {
    return self.imageView.image != nil && !self.imageView.hidden;
}

- (void)configureWithRank:(NSString *)rank suit:(NSString *)suit compact:(BOOL)compact {
    self.rank = rank ?: @"";
    self.suit = suit ?: @"";
    self.compact = compact;
    [self refreshArtwork];
}

- (void)refreshArtwork {
    NSString *assetName = [self artworkAssetName];
    UIImage *image = assetName.length > 0 ? [UIImage imageNamed:assetName] : nil;
    self.imageView.image = image;
    self.imageView.hidden = image == nil;
    BOOL pixel = [[self resolvedPresetId] isEqualToString:@"pixel"];
    self.imageView.layer.magnificationFilter = pixel ? kCAFilterNearest : kCAFilterLinear;
    self.imageView.layer.minificationFilter = pixel ? kCAFilterNearest : kCAFilterTrilinear;
    [self setNeedsDisplay];
}

- (UIColor *)inkColor {
    JFSkin *skin = [self resolvedSkin];
    NSString *preset = [self resolvedPresetId];
    if ([preset isEqualToString:@"fourColor"]) {
        if ([self.suit isEqualToString:@"♥"]) return [UIColor colorWithRed:0.93 green:0.18 blue:0.30 alpha:1];
        if ([self.suit isEqualToString:@"♦"]) return [UIColor colorWithRed:0.12 green:0.48 blue:0.94 alpha:1];
        if ([self.suit isEqualToString:@"♣"]) return [UIColor colorWithRed:0.10 green:0.62 blue:0.34 alpha:1];
    }
    BOOL red = [self.suit isEqualToString:@"♥"] || [self.suit isEqualToString:@"♦"];
    return red ? [JFGamePieceSkin cardRedInkColorForSkin:skin]
               : [JFGamePieceSkin cardBlackInkColorForSkin:skin];
}

- (UIFont *)serifFontOfSize:(CGFloat)size weight:(UIFontWeight)weight {
    UIFont *font = [UIFont fontWithName:weight >= UIFontWeightBold ? @"Georgia-Bold" : @"Georgia" size:size];
    return font ?: [UIFont systemFontOfSize:size weight:weight];
}

- (void)drawString:(NSString *)text
             font:(UIFont *)font
            color:(UIColor *)color
         centered:(CGPoint)center {
    NSDictionary *attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: color,
    };
    CGSize size = [text sizeWithAttributes:attributes];
    [text drawAtPoint:CGPointMake(center.x - size.width / 2, center.y - size.height / 2)
       withAttributes:attributes];
}

- (void)drawPipAt:(CGPoint)point inverted:(BOOL)inverted size:(CGFloat)size color:(UIColor *)color {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    if (inverted) {
        CGContextTranslateCTM(context, point.x, point.y);
        CGContextRotateCTM(context, M_PI);
        point = CGPointZero;
    }
    CGContextSetShadowWithColor(context, CGSizeMake(0, size * 0.055), size * 0.08,
                                [UIColor colorWithWhite:0 alpha:0.16].CGColor);
    [self drawString:self.suit
                font:[self serifFontOfSize:size weight:UIFontWeightBold]
               color:color
            centered:point];
    CGContextRestoreGState(context);
}

- (NSArray<NSArray<NSNumber *> *> *)pipLayoutForValue:(NSInteger)value {
    switch (value) {
        case 2: return @[@[@0.50, @0.22, @NO], @[@0.50, @0.78, @YES]];
        case 3: return @[@[@0.50, @0.20, @NO], @[@0.50, @0.50, @NO], @[@0.50, @0.80, @YES]];
        case 4: return @[@[@0.28, @0.22, @NO], @[@0.72, @0.22, @NO], @[@0.28, @0.78, @YES], @[@0.72, @0.78, @YES]];
        case 5: return @[@[@0.28, @0.20, @NO], @[@0.72, @0.20, @NO], @[@0.50, @0.50, @NO], @[@0.28, @0.80, @YES], @[@0.72, @0.80, @YES]];
        case 6: return @[@[@0.28, @0.18, @NO], @[@0.72, @0.18, @NO], @[@0.28, @0.50, @NO], @[@0.72, @0.50, @NO], @[@0.28, @0.82, @YES], @[@0.72, @0.82, @YES]];
        case 7: return @[@[@0.28, @0.16, @NO], @[@0.72, @0.16, @NO], @[@0.50, @0.34, @NO], @[@0.28, @0.50, @NO], @[@0.72, @0.50, @NO], @[@0.28, @0.84, @YES], @[@0.72, @0.84, @YES]];
        case 8: return @[@[@0.28, @0.15, @NO], @[@0.72, @0.15, @NO], @[@0.50, @0.33, @NO], @[@0.28, @0.45, @NO], @[@0.72, @0.45, @NO], @[@0.50, @0.67, @YES], @[@0.28, @0.85, @YES], @[@0.72, @0.85, @YES]];
        case 9: return @[@[@0.28, @0.14, @NO], @[@0.72, @0.14, @NO], @[@0.28, @0.38, @NO], @[@0.72, @0.38, @NO], @[@0.50, @0.50, @NO], @[@0.28, @0.62, @YES], @[@0.72, @0.62, @YES], @[@0.28, @0.86, @YES], @[@0.72, @0.86, @YES]];
        case 10: return @[@[@0.28, @0.12, @NO], @[@0.72, @0.12, @NO], @[@0.50, @0.28, @NO], @[@0.28, @0.38, @NO], @[@0.72, @0.38, @NO], @[@0.28, @0.62, @YES], @[@0.72, @0.62, @YES], @[@0.50, @0.72, @YES], @[@0.28, @0.88, @YES], @[@0.72, @0.88, @YES]];
        default: return @[];
    }
}

- (void)drawNumberPipsInRect:(CGRect)rect value:(NSInteger)value color:(UIColor *)color {
    NSArray<NSArray<NSNumber *> *> *layout = [self pipLayoutForValue:value];
    CGFloat pipSize = MIN(CGRectGetWidth(rect) * (self.compact ? 0.28 : 0.27),
                          CGRectGetHeight(rect) * (value >= 8 ? 0.14 : 0.17));
    for (NSArray<NSNumber *> *pip in layout) {
        CGPoint point = CGPointMake(CGRectGetMinX(rect) + CGRectGetWidth(rect) * pip[0].doubleValue,
                                    CGRectGetMinY(rect) + CGRectGetHeight(rect) * pip[1].doubleValue);
        [self drawPipAt:point inverted:pip[2].boolValue size:pipSize color:color];
    }
}

- (void)drawAceInRect:(CGRect)rect color:(UIColor *)color {
    JFSkin *skin = [self resolvedSkin];
    CGFloat side = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) * 0.58;
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    UIBezierPath *ring = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x - side * 0.54,
                                                                          center.y - side * 0.54,
                                                                          side * 1.08, side * 1.08)];
    [[skin.accent colorWithAlphaComponent:0.12] setFill];
    [ring fill];
    [[skin.accent colorWithAlphaComponent:0.48] setStroke];
    ring.lineWidth = MAX(1, side * 0.018);
    [ring stroke];
    [self drawString:self.suit
                font:[self serifFontOfSize:side weight:UIFontWeightBold]
               color:color
            centered:center];
}

- (void)drawMinimalInRect:(CGRect)rect color:(UIColor *)color {
    JFSkin *skin = [self resolvedSkin];
    CGFloat rankSize = MIN(CGRectGetWidth(rect) * 0.56, CGRectGetHeight(rect) * 0.36);
    [self drawString:self.rank
                font:[self serifFontOfSize:rankSize weight:UIFontWeightBold]
               color:color
            centered:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect) - rankSize * 0.22)];
    [self drawString:self.suit
                font:[self serifFontOfSize:rankSize * 0.52 weight:UIFontWeightBold]
               color:color
            centered:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect) + rankSize * 0.56)];

    CGFloat lineWidth = CGRectGetWidth(rect) * 0.34;
    UIBezierPath *line = [UIBezierPath bezierPath];
    [line moveToPoint:CGPointMake(CGRectGetMidX(rect) - lineWidth / 2, CGRectGetMidY(rect) + rankSize * 0.18)];
    [line addLineToPoint:CGPointMake(CGRectGetMidX(rect) + lineWidth / 2, CGRectGetMidY(rect) + rankSize * 0.18)];
    [[skin.accent colorWithAlphaComponent:0.58] setStroke];
    line.lineWidth = MAX(1, CGRectGetWidth(rect) * 0.012);
    [line stroke];
}

- (void)drawCourtInRect:(CGRect)rect color:(UIColor *)color {
    JFSkin *skin = [self resolvedSkin];
    CGRect panelRect = CGRectInset(rect, CGRectGetWidth(rect) * 0.15, CGRectGetHeight(rect) * 0.08);
    UIBezierPath *panel = [UIBezierPath bezierPathWithRoundedRect:panelRect
                                                    cornerRadius:MIN(14, CGRectGetWidth(panelRect) * 0.16)];
    JFDrawGradient(UIGraphicsGetCurrentContext(), panelRect, panel,
                   @[[skin.brandPrimary colorWithAlphaComponent:0.10],
                     [skin.accent colorWithAlphaComponent:0.20],
                     [skin.brandSecondary colorWithAlphaComponent:0.12]]);
    [[skin.accent colorWithAlphaComponent:0.52] setStroke];
    panel.lineWidth = MAX(1, CGRectGetWidth(rect) * 0.012);
    [panel stroke];

    NSString *symbolName = [self.rank isEqualToString:@"J"] ? @"shield.lefthalf.filled"
        : ([self.rank isEqualToString:@"Q"] ? @"sparkles" : @"crown.fill");
    CGFloat iconSide = MIN(CGRectGetWidth(panelRect) * 0.48, CGRectGetHeight(panelRect) * 0.26);
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:iconSide
                                                                                                  weight:UIImageSymbolWeightBold];
    UIImage *symbol = [[UIImage systemImageNamed:symbolName withConfiguration:configuration]
                       imageWithTintColor:[color colorWithAlphaComponent:0.88]];
    CGRect topIcon = CGRectMake(CGRectGetMidX(rect) - iconSide / 2,
                                CGRectGetMinY(panelRect) + CGRectGetHeight(panelRect) * 0.12,
                                iconSide, iconSide);
    [symbol drawInRect:topIcon];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGContextRotateCTM(context, M_PI);
    CGRect bottomIcon = CGRectMake(-iconSide / 2,
                                   -CGRectGetHeight(panelRect) / 2 + CGRectGetHeight(panelRect) * 0.12,
                                   iconSide, iconSide);
    [symbol drawInRect:bottomIcon];
    CGContextRestoreGState(context);

    CGFloat medallion = MIN(CGRectGetWidth(rect) * 0.42, CGRectGetHeight(rect) * 0.22);
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(CGRectGetMidX(rect) - medallion / 2,
                                                                            CGRectGetMidY(rect) - medallion / 2,
                                                                            medallion, medallion)];
    [[skin.backgroundBottom colorWithAlphaComponent:0.82] setFill];
    [circle fill];
    [[skin.accent colorWithAlphaComponent:0.82] setStroke];
    circle.lineWidth = MAX(1, medallion * 0.035);
    [circle stroke];
    [self drawString:self.suit
                font:[self serifFontOfSize:medallion * 0.54 weight:UIFontWeightBold]
               color:color
            centered:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))];
}

- (void)drawCornerIndicesWithColor:(UIColor *)color {
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat rankSize = MIN(24, MAX(7, MIN(width * (self.compact ? 0.21 : 0.18),
                                         height * (self.compact ? 0.14 : 0.12))));
    CGFloat suitSize = rankSize * 0.72;
    CGFloat margin = MAX(2, width * 0.055);
    CGFloat blockWidth = MAX(rankSize * 1.42, width * 0.17);

    void (^drawTopIndex)(void) = ^{
        CGFloat centerX = margin + blockWidth / 2;
        [self drawString:self.rank
                    font:[self serifFontOfSize:rankSize weight:UIFontWeightBold]
                   color:color
                centered:CGPointMake(centerX, margin + rankSize * 0.53)];
        [self drawString:self.suit
                    font:[self serifFontOfSize:suitSize weight:UIFontWeightBold]
                   color:color
                centered:CGPointMake(centerX, margin + rankSize + suitSize * 0.48)];
    };

    drawTopIndex();
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, width, height);
    CGContextRotateCTM(context, M_PI);
    drawTopIndex();
    CGContextRestoreGState(context);
}

- (void)drawRect:(CGRect)rect {
    if (self.usesFullCardArtwork || self.rank.length == 0 || self.suit.length == 0) return;
    CGRect contentRect = CGRectInset(self.bounds,
                                     CGRectGetWidth(self.bounds) * (self.compact ? 0.08 : 0.12),
                                     CGRectGetHeight(self.bounds) * (self.compact ? 0.08 : 0.10));
    UIColor *color = [self inkColor];
    NSString *preset = [self resolvedPresetId];
    if ([preset isEqualToString:@"minimal"]) {
        [self drawMinimalInRect:contentRect color:color];
    } else if ([self.rank isEqualToString:@"A"]) {
        [self drawAceInRect:contentRect color:color];
    } else if ([@[@"J", @"Q", @"K"] containsObject:self.rank]) {
        [self drawCourtInRect:contentRect color:color];
    } else {
        CGRect pipRect = CGRectInset(self.bounds,
                                     CGRectGetWidth(self.bounds) * (self.compact ? 0.12 : 0.14),
                                     CGRectGetHeight(self.bounds) * (self.compact ? 0.19 : 0.18));
        [self drawNumberPipsInRect:pipRect value:self.rank.integerValue color:color];
    }
    [self drawCornerIndicesWithColor:color];
}

@end

@interface JFSkinnedDieView ()
@property (nonatomic, strong) id skinObserver;
@end

@implementation JFSkinnedDieView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _face = 1;
        self.opaque = NO;
        self.backgroundColor = UIColor.clearColor;
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOpacity = 0.28;
        self.layer.shadowRadius = 6;
        self.layer.shadowOffset = CGSizeMake(0, 3);
        __weak typeof(self) weakSelf = self;
        _skinObserver = [NSNotificationCenter.defaultCenter addObserverForName:JFSkinDidChangeNotification
                                                                        object:nil
                                                                         queue:NSOperationQueue.mainQueue
                                                                    usingBlock:^(__unused NSNotification *note) {
            [weakSelf setNeedsDisplay];
        }];
    }
    return self;
}

- (void)dealloc {
    if (self.skinObserver) [NSNotificationCenter.defaultCenter removeObserver:self.skinObserver];
}

- (void)setFace:(NSInteger)face {
    _face = MAX(1, MIN(6, face));
    [self setNeedsDisplay];
}

- (void)setLocked:(BOOL)locked {
    _locked = locked;
    [self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted {
    _highlighted = highlighted;
    [self setNeedsDisplay];
}

- (void)setSkin:(JFSkin *)skin {
    _skin = skin;
    [self setNeedsDisplay];
}

- (void)configureWithFace:(NSInteger)face locked:(BOOL)locked {
    _face = MAX(1, MIN(6, face));
    _locked = locked;
    [self setNeedsDisplay];
}

+ (void)drawPipAt:(CGPoint)point radius:(CGFloat)radius color:(UIColor *)color {
    CGRect shadowRect = CGRectMake(point.x - radius, point.y - radius + radius * 0.25, radius * 2, radius * 2);
    [[UIColor colorWithWhite:0 alpha:0.18] setFill];
    [[UIBezierPath bezierPathWithOvalInRect:shadowRect] fill];
    [color setFill];
    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - radius, point.y - radius, radius * 2, radius * 2)] fill];
    [[UIColor colorWithWhite:1 alpha:0.22] setFill];
    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - radius * 0.42,
                                                       point.y - radius * 0.55,
                                                       radius * 0.58,
                                                       radius * 0.58)] fill];
}

+ (void)drawFace:(NSInteger)face
          inRect:(CGRect)rect
            skin:(JFSkin *)skin
     highlighted:(BOOL)highlighted
          locked:(BOOL)locked {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context || CGRectIsEmpty(rect)) return;
    CGFloat inset = MAX(1, CGRectGetWidth(rect) * 0.035);
    CGRect bodyRect = CGRectInset(rect, inset, inset);
    CGFloat radius = MIN(CGRectGetWidth(bodyRect), CGRectGetHeight(bodyRect)) * 0.20;
    UIBezierPath *body = JFRoundedPath(bodyRect, radius);

    UIColor *bodyColor = locked
        ? JFBlendColor(skin.backgroundBottom, UIColor.blackColor, 0.20)
        : [JFGamePieceSkin diceBodyColorForSkin:skin];
    UIColor *top = JFBlendColor(bodyColor, UIColor.whiteColor, locked ? 0.10 : 0.52);
    UIColor *bottom = JFBlendColor(bodyColor, skin.brandPrimary, locked ? 0.18 : 0.11);
    JFDrawGradient(context, bodyRect, body, @[top, bodyColor, bottom]);

    UIColor *border = [JFGamePieceSkin diceBorderColorForSkin:skin highlighted:highlighted];
    JFStrokeRoundedRect(bodyRect, radius, [border colorWithAlphaComponent:highlighted ? 1 : 0.72], highlighted ? 1.8 : 1.05);
    JFStrokeRoundedRect(CGRectInset(bodyRect, inset * 1.8, inset * 1.8), MAX(2, radius - inset * 1.8),
                        [UIColor colorWithWhite:1 alpha:locked ? 0.08 : 0.22], 0.65);

    if (locked) {
        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:CGRectGetWidth(rect) * 0.34
                                                                                                      weight:UIImageSymbolWeightBold];
        UIImage *lock = [[UIImage systemImageNamed:@"lock.fill" withConfiguration:configuration]
                         imageWithTintColor:[[JFGamePieceSkin cardBackDetailColorForSkin:skin] colorWithAlphaComponent:0.74]];
        CGFloat side = CGRectGetWidth(rect) * 0.42;
        [lock drawInRect:CGRectMake(CGRectGetMidX(rect) - side / 2, CGRectGetMidY(rect) - side / 2, side, side)];
        return;
    }

    CGFloat left = CGRectGetMinX(bodyRect) + CGRectGetWidth(bodyRect) * 0.29;
    CGFloat centerX = CGRectGetMidX(bodyRect);
    CGFloat right = CGRectGetMaxX(bodyRect) - CGRectGetWidth(bodyRect) * 0.29;
    CGFloat topY = CGRectGetMinY(bodyRect) + CGRectGetHeight(bodyRect) * 0.29;
    CGFloat centerY = CGRectGetMidY(bodyRect);
    CGFloat bottomY = CGRectGetMaxY(bodyRect) - CGRectGetHeight(bodyRect) * 0.29;
    CGFloat pipRadius = MAX(1.4, CGRectGetWidth(bodyRect) * 0.073);
    UIColor *pipColor = [JFGamePieceSkin dicePipColorForSkin:skin highlighted:highlighted];
    NSInteger clampedFace = MAX(1, MIN(6, face));
    if (clampedFace == 1 || clampedFace == 3 || clampedFace == 5) {
        [self drawPipAt:CGPointMake(centerX, centerY) radius:pipRadius
                  color:clampedFace == 1 ? skin.brandSecondary : pipColor];
    }
    if (clampedFace >= 2) {
        [self drawPipAt:CGPointMake(left, topY) radius:pipRadius color:pipColor];
        [self drawPipAt:CGPointMake(right, bottomY) radius:pipRadius color:pipColor];
    }
    if (clampedFace >= 4) {
        [self drawPipAt:CGPointMake(right, topY) radius:pipRadius color:pipColor];
        [self drawPipAt:CGPointMake(left, bottomY) radius:pipRadius color:pipColor];
    }
    if (clampedFace == 6) {
        [self drawPipAt:CGPointMake(left, centerY) radius:pipRadius color:pipColor];
        [self drawPipAt:CGPointMake(right, centerY) radius:pipRadius color:pipColor];
    }
}

- (void)drawRect:(CGRect)rect {
    [JFSkinnedDieView drawFace:self.face
                        inRect:self.bounds
                          skin:self.skin ?: [JFGamePieceSkin currentSkin]
                   highlighted:self.isHighlighted
                        locked:self.isLocked];
}

@end
