//
//  JFDiceResultBoardView.m
//  JiFeng_UpApp
//

#import "JFDiceResultBoardView.h"
#import "JFDiceGameDefinition.h"
#import "JFTheme.h"
#import "JFGamePieceSkin.h"
#import "JFSkinStore.h"

static const NSInteger JFDiceFacesPerRow = 8;
static const CGFloat JFDiceFaceSide = 25;
static const CGFloat JFDiceFaceSpacing = 5;

@interface JFDiceFacesGridView : UIView
@property (nonatomic, copy) NSArray<NSNumber *> *values;
@property (nonatomic, assign) BOOL highlighted;
- (instancetype)initWithValues:(NSArray<NSNumber *> *)values highlighted:(BOOL)highlighted;
@end

@implementation JFDiceFacesGridView

- (instancetype)initWithValues:(NSArray<NSNumber *> *)values highlighted:(BOOL)highlighted {
    if ((self = [super initWithFrame:CGRectZero])) {
        _values = [values copy];
        _highlighted = highlighted;
        self.backgroundColor = UIColor.clearColor;
        self.isAccessibilityElement = YES;
        NSMutableArray<NSString *> *faces = [NSMutableArray arrayWithCapacity:values.count];
        for (NSNumber *value in values) [faces addObject:value.stringValue];
        self.accessibilityLabel = [NSString stringWithFormat:@"骰子：%@", [faces componentsJoinedByString:@"、"]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onSkinChanged:)
                                                     name:JFSkinDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onSkinChanged:(NSNotification *)notification {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [self.values enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger index, BOOL *stop) {
        NSInteger row = index / JFDiceFacesPerRow;
        NSInteger column = index % JFDiceFacesPerRow;
        NSInteger rowStart = row * JFDiceFacesPerRow;
        NSInteger rowCount = MIN(JFDiceFacesPerRow, (NSInteger)self.values.count - rowStart);
        CGFloat rowWidth = rowCount * JFDiceFaceSide + (rowCount - 1) * JFDiceFaceSpacing;
        CGFloat originX = floor(MAX(0, (CGRectGetWidth(self.bounds) - rowWidth) / 2.0));
        CGRect dieRect = CGRectMake(originX + column * (JFDiceFaceSide + JFDiceFaceSpacing),
                                    row * (JFDiceFaceSide + JFDiceFaceSpacing),
                                    JFDiceFaceSide,
                                    JFDiceFaceSide);
        [JFSkinnedDieView drawFace:MAX(1, MIN(6, value.integerValue))
                            inRect:dieRect
                              skin:[JFGamePieceSkin currentSkin]
                       highlighted:self.highlighted
                            locked:NO];
    }];
}

@end

@interface JFDiceResultBoardView ()
@property (nonatomic, strong) JFDiceGameDefinition *definition;
@property (nonatomic, strong) UIStackView *contentStack;
@end

@implementation JFDiceResultBoardView

- (instancetype)initWithDefinition:(JFDiceGameDefinition *)definition {
    if ((self = [super initWithFrame:CGRectZero])) {
        _definition = definition;
        self.backgroundColor = UIColor.clearColor;
        _contentStack = [[UIStackView alloc] init];
        _contentStack.axis = UILayoutConstraintAxisVertical;
        _contentStack.spacing = 10;
        _contentStack.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_contentStack];
        [NSLayoutConstraint activateConstraints:@[
            [_contentStack.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_contentStack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_contentStack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_contentStack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        ]];
    }
    return self;
}

- (UILabel *)labelWithFont:(UIFont *)font color:(UIColor *)color lines:(NSInteger)lines {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.textColor = color;
    label.numberOfLines = lines;
    return label;
}

- (void)reset {
    for (UIView *view in self.contentStack.arrangedSubviews.copy) {
        [self.contentStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
}

- (UIView *)overallStatsViewWithValues:(NSArray<NSNumber *> *)values summary:(NSString *)summary {
    UIView *band = [[UIView alloc] init];
    band.backgroundColor = [[JFTheme brandPrimary] colorWithAlphaComponent:0.18];
    band.layer.cornerRadius = 8;
    band.layer.cornerCurve = kCACornerCurveContinuous;
    band.layer.borderWidth = 1;
    band.layer.borderColor = [[JFTheme accent] colorWithAlphaComponent:0.42].CGColor;

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [band addSubview:stack];

    UIStackView *heading = [[UIStackView alloc] init];
    heading.axis = UILayoutConstraintAxisHorizontal;
    heading.alignment = UIStackViewAlignmentFirstBaseline;
    UILabel *title = [self labelWithFont:[UIFont systemFontOfSize:17 weight:UIFontWeightBold]
                                   color:[JFTheme textPrimary]
                                   lines:1];
    title.text = @"全场 1-6 点统计";
    [heading addArrangedSubview:title];
    [heading addArrangedSubview:[[UIView alloc] init]];
    UILabel *total = [self labelWithFont:[UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightSemibold]
                                   color:[JFTheme textSecondary]
                                   lines:1];
    total.text = [NSString stringWithFormat:@"共 %lu 颗", (unsigned long)values.count];
    [heading addArrangedSubview:total];
    [stack addArrangedSubview:heading];

    NSArray<NSNumber *> *counts = [self.definition faceCountsForValues:values];
    UIStackView *histogram = [[UIStackView alloc] init];
    histogram.axis = UILayoutConstraintAxisHorizontal;
    histogram.distribution = UIStackViewDistributionFillEqually;
    histogram.spacing = 4;
    for (NSInteger face = 1; face <= 6; face++) {
        UIStackView *column = [[UIStackView alloc] init];
        column.axis = UILayoutConstraintAxisVertical;
        column.alignment = UIStackViewAlignmentCenter;
        column.spacing = 4;
        JFSkinnedDieView *icon = [[JFSkinnedDieView alloc] init];
        icon.face = face;
        icon.highlighted = YES;
        [icon.widthAnchor constraintEqualToConstant:27].active = YES;
        [icon.heightAnchor constraintEqualToConstant:27].active = YES;
        [column addArrangedSubview:icon];
        UILabel *count = [self labelWithFont:[UIFont monospacedDigitSystemFontOfSize:16 weight:UIFontWeightBold]
                                       color:[JFTheme textPrimary]
                                       lines:1];
        count.text = counts[face - 1].stringValue;
        count.textAlignment = NSTextAlignmentCenter;
        count.adjustsFontSizeToFitWidth = YES;
        count.minimumScaleFactor = 0.72;
        [column addArrangedSubview:count];
        [histogram addArrangedSubview:column];
    }
    [stack addArrangedSubview:histogram];

    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [[JFTheme separator] colorWithAlphaComponent:0.7];
    [line.heightAnchor constraintEqualToConstant:1].active = YES;
    [stack addArrangedSubview:line];

    UILabel *summaryLabel = [self labelWithFont:[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold]
                                          color:[JFTheme textPrimary]
                                          lines:0];
    summaryLabel.text = summary;
    [stack addArrangedSubview:summaryLabel];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:band.topAnchor constant:14],
        [stack.leadingAnchor constraintEqualToAnchor:band.leadingAnchor constant:14],
        [stack.trailingAnchor constraintEqualToAnchor:band.trailingAnchor constant:-14],
        [stack.bottomAnchor constraintEqualToAnchor:band.bottomAnchor constant:-14],
    ]];
    return band;
}

- (UIView *)playerViewForResult:(NSDictionary *)result localPlayerId:(NSString *)localPlayerId {
    NSString *playerId = [result[@"playerId"] isKindOfClass:NSString.class] ? result[@"playerId"] : @"";
    BOOL isLocal = localPlayerId.length > 0 && [playerId isEqualToString:localPlayerId];
    NSArray<NSNumber *> *values = [result[@"values"] isKindOfClass:NSArray.class] ? result[@"values"] : @[];
    NSString *name = [result[@"displayName"] isKindOfClass:NSString.class] ? result[@"displayName"] : @"玩家";

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = isLocal
        ? [[JFTheme accent] colorWithAlphaComponent:0.11]
        : [[UIColor whiteColor] colorWithAlphaComponent:0.055];
    card.layer.cornerRadius = 8;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.borderWidth = isLocal ? 1.4 : 1;
    card.layer.borderColor = (isLocal ? [[JFTheme accent] colorWithAlphaComponent:0.72] : [JFTheme cardBorder]).CGColor;

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 9;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];

    UIStackView *heading = [[UIStackView alloc] init];
    heading.axis = UILayoutConstraintAxisHorizontal;
    heading.alignment = UIStackViewAlignmentCenter;
    heading.spacing = 8;
    UIImageView *person = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"person.crop.circle.fill"]];
    person.tintColor = isLocal ? [JFTheme accent] : [JFTheme textSecondary];
    [person.widthAnchor constraintEqualToConstant:28].active = YES;
    [person.heightAnchor constraintEqualToConstant:28].active = YES;
    [heading addArrangedSubview:person];
    UILabel *nameLabel = [self labelWithFont:[UIFont systemFontOfSize:16 weight:UIFontWeightBold]
                                       color:[JFTheme textPrimary]
                                       lines:1];
    nameLabel.text = isLocal ? [NSString stringWithFormat:@"%@  · 我", name] : name;
    nameLabel.adjustsFontSizeToFitWidth = YES;
    nameLabel.minimumScaleFactor = 0.78;
    [heading addArrangedSubview:nameLabel];
    [stack addArrangedSubview:heading];

    UILabel *detail = [self labelWithFont:[UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightSemibold]
                                     color:isLocal ? [JFTheme accent] : [JFTheme textSecondary]
                                     lines:1];
    detail.text = [self.definition resultDetailForValues:values];
    detail.adjustsFontSizeToFitWidth = YES;
    detail.minimumScaleFactor = 0.78;
    [stack addArrangedSubview:detail];

    if (values.count > 0) {
        NSInteger rows = (values.count + JFDiceFacesPerRow - 1) / JFDiceFacesPerRow;
        CGFloat height = rows * JFDiceFaceSide + MAX(0, rows - 1) * JFDiceFaceSpacing;
        JFDiceFacesGridView *faces = [[JFDiceFacesGridView alloc] initWithValues:values highlighted:isLocal];
        [faces.heightAnchor constraintEqualToConstant:height].active = YES;
        [stack addArrangedSubview:faces];
    }

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:12],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-12],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-12],
    ]];
    card.accessibilityLabel = [NSString stringWithFormat:@"%@，%@", nameLabel.text, detail.text];
    return card;
}

- (void)showResults:(NSArray<NSDictionary *> *)results
             summary:(NSString *)summary
       localPlayerId:(NSString *)localPlayerId {
    [self reset];
    NSMutableArray<NSNumber *> *allValues = [NSMutableArray array];
    for (NSDictionary *result in results) {
        NSArray *values = [result[@"values"] isKindOfClass:NSArray.class] ? result[@"values"] : @[];
        [allValues addObjectsFromArray:values];
    }
    [self.contentStack addArrangedSubview:[self overallStatsViewWithValues:allValues summary:summary]];

    NSArray<NSDictionary *> *ordered = [results sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        BOOL leftIsLocal = localPlayerId.length > 0 && [left[@"playerId"] isEqualToString:localPlayerId];
        BOOL rightIsLocal = localPlayerId.length > 0 && [right[@"playerId"] isEqualToString:localPlayerId];
        if (leftIsLocal != rightIsLocal) return leftIsLocal ? NSOrderedAscending : NSOrderedDescending;
        NSString *leftName = [left[@"displayName"] isKindOfClass:NSString.class] ? left[@"displayName"] : @"";
        NSString *rightName = [right[@"displayName"] isKindOfClass:NSString.class] ? right[@"displayName"] : @"";
        return [leftName compare:rightName options:NSCaseInsensitiveSearch];
    }];
    [ordered enumerateObjectsUsingBlock:^(NSDictionary *result, NSUInteger index, BOOL *stop) {
        UIView *card = [self playerViewForResult:result localPlayerId:localPlayerId];
        card.alpha = 0;
        card.transform = CGAffineTransformMakeTranslation(0, 12);
        [self.contentStack addArrangedSubview:card];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((0.04 * index) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.34
                                  delay:0
                 usingSpringWithDamping:0.86
                  initialSpringVelocity:0.25
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                card.alpha = 1;
                card.transform = CGAffineTransformIdentity;
            } completion:nil];
        });
    }];
}

@end
