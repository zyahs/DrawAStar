#import "JFDrawGuessViewController.h"
#import "JFTheme.h"
#import "JFGameSession.h"
#import "JFGameMessage.h"
#import "JFPlayerSetup.h"

@protocol JFDrawGuessCanvasDelegate;

@interface JFDrawGuessCanvas : UIView
@property (nonatomic, weak) id<JFDrawGuessCanvasDelegate> delegate;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *segments;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, assign) CGFloat strokeWidth;
@property (nonatomic, assign) BOOL erasing;
@property (nonatomic, assign) BOOL drawingEnabled;
@property (nonatomic, assign) CGPoint previousPoint;
- (void)addSegmentFrom:(CGPoint)from to:(CGPoint)to color:(UIColor *)color width:(CGFloat)width;
- (void)clearCanvas;
@end

@protocol JFDrawGuessCanvasDelegate <NSObject>
- (void)canvas:(JFDrawGuessCanvas *)canvas drewFrom:(CGPoint)from to:(CGPoint)to color:(UIColor *)color width:(CGFloat)width;
@end

@implementation JFDrawGuessCanvas
- (instancetype)init {
    if ((self = [super init])) {
        _segments = [NSMutableArray array];
        _strokeColor = UIColor.blackColor;
        _strokeWidth = 5;
        _drawingEnabled = NO;
        self.backgroundColor = UIColor.whiteColor;
        self.layer.cornerRadius = 18;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.clipsToBounds = YES;
    }
    return self;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.drawingEnabled) return;
    self.previousPoint = [[touches anyObject] locationInView:self];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.drawingEnabled) return;
    CGPoint point = [[touches anyObject] locationInView:self];
    UIColor *color = self.erasing ? UIColor.whiteColor : self.strokeColor;
    CGFloat width = self.erasing ? MAX(18, self.strokeWidth * 3) : self.strokeWidth;
    [self addSegmentFrom:self.previousPoint to:point color:color width:width];
    [self.delegate canvas:self drewFrom:self.previousPoint to:point color:color width:width];
    self.previousPoint = point;
}
- (void)addSegmentFrom:(CGPoint)from to:(CGPoint)to color:(UIColor *)color width:(CGFloat)width {
    [self.segments addObject:@{@"fx": @(from.x), @"fy": @(from.y), @"tx": @(to.x), @"ty": @(to.y),
                               @"color": color, @"width": @(width)}];
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    for (NSDictionary *segment in self.segments) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        path.lineCapStyle = kCGLineCapRound;
        path.lineJoinStyle = kCGLineJoinRound;
        path.lineWidth = [segment[@"width"] doubleValue];
        [segment[@"color"] setStroke];
        [path moveToPoint:CGPointMake([segment[@"fx"] doubleValue], [segment[@"fy"] doubleValue])];
        [path addLineToPoint:CGPointMake([segment[@"tx"] doubleValue], [segment[@"ty"] doubleValue])];
        [path stroke];
    }
}
- (void)clearCanvas { [self.segments removeAllObjects]; [self setNeedsDisplay]; }
@end

@interface JFDrawGuessViewController () <JFGameSessionDelegate, JFDrawGuessCanvasDelegate, UITextFieldDelegate>
@property (nonatomic, strong) id<JFGameSession> session;
@property (nonatomic, assign) BOOL host;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, copy) NSString *requestedCode;
@property (nonatomic, strong) NSMutableArray<JFGamePeer *> *players;
@property (nonatomic, assign) NSInteger drawerIndex;
@property (nonatomic, assign) NSInteger round;
@property (nonatomic, copy) NSString *answer;
@property (nonatomic, assign) BOOL customNextWord;
@property (nonatomic, strong) UILabel *roomLabel;
@property (nonatomic, strong) UILabel *roundLabel;
@property (nonatomic, strong) UILabel *roleLabel;
@property (nonatomic, strong) UILabel *wordLabel;
@property (nonatomic, strong) UILabel *playersLabel;
@property (nonatomic, strong) JFDrawGuessCanvas *canvas;
@property (nonatomic, strong) UIStackView *palette;
@property (nonatomic, strong) UIStackView *toolsStack;
@property (nonatomic, strong) UITextField *answerField;
@property (nonatomic, strong) UIButton *startButton;
@end

@implementation JFDrawGuessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"你画我猜";
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.players = [NSMutableArray array];
    [self presentModeMenu];
}
- (void)dealloc { [self.session stop]; }

- (NSArray<NSString *> *)words {
    return @[@"长颈鹿", @"火锅", @"宇航员", @"摩天轮", @"自拍杆", @"外卖员", @"孙悟空", @"灭火器", @"过山车", @"招财猫",
             @"红绿灯", @"海绵宝宝", @"挖掘机", @"美人鱼", @"热气球", @"打麻将", @"求婚", @"抢红包", @"广场舞",
             @"一见钟情", @"摸鱼", @"鸡飞狗跳", @"画蛇添足", @"对牛弹琴", @"守株待兔", @"眉飞色舞"];
}

- (void)presentModeMenu {
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"实时你画我猜"
                                                                   message:@"创建房间后分享房间码，所有玩家按顺序轮流作画。"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [menu addAction:[UIAlertAction actionWithTitle:@"创建房间" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
        [weakSelf configureAsHost:YES code:nil];
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"加入房间" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
        [weakSelf presentJoinPrompt];
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *a) {
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }]];
    menu.popoverPresentationController.sourceView = self.view;
    menu.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), 80, 1, 1);
    [self presentViewController:menu animated:YES completion:nil];
}
- (void)presentJoinPrompt {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"加入房间" message:@"输入房主的 6 位房间码；留空则加入最近房间。" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"例如 A1B2C3"; field.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters; }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *a) { [weakSelf presentModeMenu]; }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"加入" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
        NSString *code = [[alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
        [weakSelf configureAsHost:NO code:code];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)configureAsHost:(BOOL)host code:(NSString *)code {
    self.host = host;
    self.requestedCode = code ?: @"";
    self.session = [JFGameSessionFactory sessionForServiceType:@"drawguess" mode:JFSessionModeRemote];
    self.session.delegate = self;
    [self buildUI];
    __weak typeof(self) weakSelf = self;
    [JFPlayerSetup ensureFromViewController:self completion:^(BOOL complete) {
        if (!complete) return;
        if (host) [weakSelf.session startAsHost];
        else if (weakSelf.requestedCode.length && [weakSelf.session respondsToSelector:@selector(startAsClientWithRoomCode:)])
            [weakSelf.session startAsClientWithRoomCode:weakSelf.requestedCode];
        else [weakSelf.session startAsClient];
        [weakSelf.players addObject:weakSelf.session.localPeer];
        [weakSelf refreshHeader];
    }];
}

- (UILabel *)label:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init]; label.translatesAutoresizingMaskIntoConstraints = NO; label.font = font; label.textColor = color; return label;
}
- (UIButton *)button:(NSString *)title color:(UIColor *)color action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem]; button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal]; [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold]; button.backgroundColor = color; button.layer.cornerRadius = 12;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside]; return button;
}
- (void)buildUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    self.roomLabel = [self label:[UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightBold] color:[JFTheme accent]];
    self.roundLabel = [self label:[UIFont systemFontOfSize:14 weight:UIFontWeightBold] color:[JFTheme textSecondary]];
    self.roundLabel.textAlignment = NSTextAlignmentCenter;
    self.playersLabel = [self label:[UIFont systemFontOfSize:13 weight:UIFontWeightMedium] color:[JFTheme textSecondary]];
    self.playersLabel.textAlignment = NSTextAlignmentRight;
    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[self.roomLabel, self.roundLabel, self.playersLabel]];
    header.translatesAutoresizingMaskIntoConstraints = NO; header.distribution = UIStackViewDistributionFillEqually;
    self.roleLabel = [self label:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold] color:[JFTheme textSecondary]];
    self.roleLabel.textAlignment = NSTextAlignmentCenter;
    self.wordLabel = [self label:[UIFont systemFontOfSize:27 weight:UIFontWeightBlack] color:[JFTheme textPrimary]];
    self.wordLabel.textAlignment = NSTextAlignmentCenter; self.wordLabel.adjustsFontSizeToFitWidth = YES;
    self.canvas = [[JFDrawGuessCanvas alloc] init]; self.canvas.translatesAutoresizingMaskIntoConstraints = NO; self.canvas.delegate = self;
    self.canvas.layer.borderWidth = 1; self.canvas.layer.borderColor = [JFTheme cardBorder].CGColor;
    [self.view addSubview:header]; [self.view addSubview:self.roleLabel]; [self.view addSubview:self.wordLabel]; [self.view addSubview:self.canvas];

    self.palette = [[UIStackView alloc] init]; self.palette.translatesAutoresizingMaskIntoConstraints = NO; self.palette.spacing = 8; self.palette.distribution = UIStackViewDistributionFillEqually;
    NSArray *colors = @[UIColor.blackColor, UIColor.systemRedColor, UIColor.systemBlueColor, UIColor.systemGreenColor, UIColor.systemOrangeColor, UIColor.systemPurpleColor];
    for (UIColor *color in colors) {
        UIButton *swatch = [UIButton buttonWithType:UIButtonTypeSystem]; swatch.backgroundColor = color; swatch.layer.cornerRadius = 16;
        [swatch addAction:[UIAction actionWithHandler:^(__unused UIAction *a) { self.canvas.strokeColor = color; self.canvas.erasing = NO; }] forControlEvents:UIControlEventTouchUpInside];
        [self.palette addArrangedSubview:swatch];
    }
    UIButton *eraser = [self button:@"橡皮" color:[UIColor systemGrayColor] action:@selector(selectEraser)];
    UIButton *thin = [self button:@"细" color:[UIColor colorWithWhite:0.28 alpha:1] action:@selector(selectThin)];
    UIButton *thick = [self button:@"粗" color:[UIColor colorWithWhite:0.18 alpha:1] action:@selector(selectThick)];
    UIButton *clear = [self button:@"清空" color:UIColor.systemRedColor action:@selector(clearCanvas)];
    [self.palette addArrangedSubview:eraser];
    self.toolsStack = [[UIStackView alloc] initWithArrangedSubviews:@[thin, thick, clear]];
    self.toolsStack.translatesAutoresizingMaskIntoConstraints = NO; self.toolsStack.spacing = 8; self.toolsStack.distribution = UIStackViewDistributionFillEqually;
    self.answerField = [[UITextField alloc] init]; self.answerField.translatesAutoresizingMaskIntoConstraints = NO; self.answerField.placeholder = @"输入答案后回车";
    self.answerField.backgroundColor = [JFTheme backgroundElevated]; self.answerField.textColor = [JFTheme textPrimary]; self.answerField.layer.cornerRadius = 12;
    self.answerField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 1)]; self.answerField.leftViewMode = UITextFieldViewModeAlways;
    self.answerField.returnKeyType = UIReturnKeySend; self.answerField.delegate = self;
    self.startButton = [self button:@"开始游戏" color:[JFTheme accent] action:@selector(startOrNextRound)];
    UIButton *custom = [self button:@"自定义下一词" color:UIColor.systemIndigoColor action:@selector(customWord)];
    UIStackView *bottom = [[UIStackView alloc] initWithArrangedSubviews:@[self.answerField, self.startButton, custom]];
    bottom.translatesAutoresizingMaskIntoConstraints = NO; bottom.spacing = 8; bottom.distribution = UIStackViewDistributionFillProportionally;
    [self.startButton.widthAnchor constraintEqualToConstant:92].active = YES; [custom.widthAnchor constraintEqualToConstant:116].active = YES;
    [self.view addSubview:self.palette]; [self.view addSubview:self.toolsStack]; [self.view addSubview:bottom];
    [NSLayoutConstraint activateConstraints:@[
        // rootVcViewController 的自定义返回按钮占用 safe.top + 8...48。
        // 顶部状态栏整体放到按钮下方，避免房间号/轮次与返回键重叠。
        [header.topAnchor constraintEqualToAnchor:safe.topAnchor constant:58], [header.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:18], [header.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-18], [header.heightAnchor constraintEqualToConstant:24],
        [self.roleLabel.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:5], [self.roleLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor], [self.roleLabel.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [self.wordLabel.topAnchor constraintEqualToAnchor:self.roleLabel.bottomAnchor constant:5], [self.wordLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor], [self.wordLabel.trailingAnchor constraintEqualToAnchor:header.trailingAnchor], [self.wordLabel.heightAnchor constraintEqualToConstant:38],
        [self.canvas.topAnchor constraintEqualToAnchor:self.wordLabel.bottomAnchor constant:8], [self.canvas.leadingAnchor constraintEqualToAnchor:header.leadingAnchor], [self.canvas.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [self.palette.topAnchor constraintEqualToAnchor:self.canvas.bottomAnchor constant:8], [self.palette.leadingAnchor constraintEqualToAnchor:header.leadingAnchor], [self.palette.trailingAnchor constraintEqualToAnchor:header.trailingAnchor], [self.palette.heightAnchor constraintEqualToConstant:36],
        [self.toolsStack.topAnchor constraintEqualToAnchor:self.palette.bottomAnchor constant:8], [self.toolsStack.leadingAnchor constraintEqualToAnchor:header.leadingAnchor], [self.toolsStack.trailingAnchor constraintEqualToAnchor:header.trailingAnchor], [self.toolsStack.heightAnchor constraintEqualToConstant:40],
        [bottom.topAnchor constraintEqualToAnchor:self.toolsStack.bottomAnchor constant:8], [bottom.leadingAnchor constraintEqualToAnchor:header.leadingAnchor], [bottom.trailingAnchor constraintEqualToAnchor:header.trailingAnchor], [bottom.heightAnchor constraintEqualToConstant:46], [bottom.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-8]
    ]];
    self.palette.hidden = YES; self.toolsStack.hidden = YES; self.answerField.hidden = YES; self.startButton.hidden = !self.host; custom.hidden = !self.host;
}

- (void)refreshHeader {
    NSString *code = [self.session respondsToSelector:@selector(roomCode)] ? self.session.roomCode : nil;
    self.roomLabel.text = code.length ? [NSString stringWithFormat:@"房间 %@", code] : (self.host ? @"创建中…" : @"连接中…");
    self.roundLabel.text = self.round ? [NSString stringWithFormat:@"第 %ld 轮", (long)self.round] : @"等待开始";
    self.playersLabel.text = [NSString stringWithFormat:@"%ld 人", (long)self.players.count];
}
- (void)startOrNextRound {
    if (!self.host || self.players.count < 2) { self.roleLabel.text = @"至少需要 2 名玩家"; return; }
    if (self.customNextWord) { [self promptCustomWord]; return; }
    [self beginRoundWithWord:[self words][arc4random_uniform((uint32_t)self.words.count)]];
}
- (void)customWord { self.customNextWord = YES; [self promptCustomWord]; }
- (void)promptCustomWord {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"自定义本轮词语" message:@"词语只会发送给本轮画手。" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"输入词语"; }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"开始" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
        NSString *word = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (word.length) { weakSelf.customNextWord = NO; [weakSelf beginRoundWithWord:word]; }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)beginRoundWithWord:(NSString *)word {
    self.round += 1; self.drawerIndex = (self.round - 1) % self.players.count; self.answer = word;
    [self.canvas clearCanvas];
    JFGamePeer *drawer = self.players[self.drawerIndex];
    NSDictionary *state = @{@"round": @(self.round), @"drawerId": drawer.peerId ?: @"", @"drawerName": drawer.displayName ?: @"玩家"};
    [self.session sendMessage:[JFGameMessage messageWithType:JFMessageTypeDrawGuessState payload:state] toPeer:nil];
    if ([drawer.peerId isEqualToString:self.session.localPeer.peerId]) [self applyState:state secret:word];
    else [self.session sendMessage:[JFGameMessage messageWithType:JFMessageTypeDrawGuessSecret payload:@{@"word": word}] toPeer:drawer];
    self.startButton.hidden = YES; [self refreshHeader];
}
- (void)applyState:(NSDictionary *)state secret:(NSString *)secret {
    self.round = [state[@"round"] integerValue];
    BOOL drawing = [state[@"drawerId"] isEqualToString:self.session.localPeer.peerId];
    self.canvas.drawingEnabled = drawing;
    self.palette.hidden = !drawing;
    self.toolsStack.hidden = !drawing;
    self.answerField.hidden = drawing;
    self.roleLabel.text = drawing ? @"轮到你画，其他人正在实时猜" : [NSString stringWithFormat:@"%@ 正在画", state[@"drawerName"] ?: @"画手"];
    self.wordLabel.text = drawing ? (secret.length ? secret : @"等待题目…") : @"看画猜词";
    [self refreshHeader];
}
- (void)selectEraser { self.canvas.erasing = YES; }
- (void)selectThin { self.canvas.strokeWidth = 3; self.canvas.erasing = NO; }
- (void)selectThick { self.canvas.strokeWidth = 9; self.canvas.erasing = NO; }
- (void)clearCanvas {
    if (!self.canvas.drawingEnabled) return;
    [self.canvas clearCanvas];
    [self.session sendMessage:[JFGameMessage messageWithType:JFMessageTypeDrawGuessClear payload:@{}] toPeer:nil];
}
- (NSString *)hexForColor:(UIColor *)color {
    CGFloat r=0,g=0,b=0,a=0; [color getRed:&r green:&g blue:&b alpha:&a];
    return [NSString stringWithFormat:@"#%02X%02X%02X", (int)round(r*255), (int)round(g*255), (int)round(b*255)];
}
- (UIColor *)colorFromHex:(NSString *)hex {
    unsigned value = 0; [[NSScanner scannerWithString:[hex stringByReplacingOccurrencesOfString:@"#" withString:@""]] scanHexInt:&value];
    return [UIColor colorWithRed:((value>>16)&255)/255.0 green:((value>>8)&255)/255.0 blue:(value&255)/255.0 alpha:1];
}
- (void)canvas:(JFDrawGuessCanvas *)canvas drewFrom:(CGPoint)from to:(CGPoint)to color:(UIColor *)color width:(CGFloat)width {
    if (canvas.bounds.size.width <= 0 || canvas.bounds.size.height <= 0) return;
    NSDictionary *p = @{@"fx": @(from.x/canvas.bounds.size.width), @"fy": @(from.y/canvas.bounds.size.height),
                         @"tx": @(to.x/canvas.bounds.size.width), @"ty": @(to.y/canvas.bounds.size.height),
                         @"color": [self hexForColor:color], @"width": @(width)};
    [self.session sendMessage:[JFGameMessage messageWithType:JFMessageTypeDrawGuessStroke payload:p] toPeer:nil];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *text = [textField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (text.length) [self.session sendMessage:[JFGameMessage messageWithType:JFMessageTypeDrawGuessAnswer payload:@{@"answer": text}] toPeer:nil];
    textField.text = @""; [textField resignFirstResponder]; return YES;
}

- (void)gameSession:(id<JFGameSession>)session peer:(JFGamePeer *)peer didChangeState:(JFSessionPeerState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (state == JFSessionPeerStateConnected && ![self.players containsObject:peer]) [self.players addObject:peer];
        if (state == JFSessionPeerStateNotConnected) [self.players removeObject:peer];
        [self refreshHeader];
    });
}
- (void)gameSessionDidUpdateRoom:(id<JFGameSession>)session { dispatch_async(dispatch_get_main_queue(), ^{ [self refreshHeader]; }); }
- (void)gameSession:(id<JFGameSession>)session didReceiveMessage:(JFGameMessage *)message fromPeer:(JFGamePeer *)peer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([message.type isEqualToString:JFMessageTypeDrawGuessState]) [self applyState:message.payload secret:nil];
        else if ([message.type isEqualToString:JFMessageTypeDrawGuessSecret]) {
            self.answer = message.payload[@"word"]; self.wordLabel.text = self.answer ?: @"";
        } else if ([message.type isEqualToString:JFMessageTypeDrawGuessStroke]) {
            NSDictionary *p = message.payload; CGSize s = self.canvas.bounds.size;
            [self.canvas addSegmentFrom:CGPointMake([p[@"fx"] doubleValue]*s.width, [p[@"fy"] doubleValue]*s.height)
                                     to:CGPointMake([p[@"tx"] doubleValue]*s.width, [p[@"ty"] doubleValue]*s.height)
                                  color:[self colorFromHex:p[@"color"]] width:[p[@"width"] doubleValue]];
        } else if ([message.type isEqualToString:JFMessageTypeDrawGuessClear]) [self.canvas clearCanvas];
        else if ([message.type isEqualToString:JFMessageTypeDrawGuessAnswer] && self.host) {
            NSString *guess = [message.payload[@"answer"] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if ([guess caseInsensitiveCompare:self.answer] == NSOrderedSame) {
                NSDictionary *result = @{@"winner": peer.displayName ?: @"玩家", @"word": self.answer ?: @""};
                [self.session sendMessage:[JFGameMessage messageWithType:JFMessageTypeDrawGuessResult payload:result] toPeer:nil];
                [self showResult:result];
            }
        } else if ([message.type isEqualToString:JFMessageTypeDrawGuessResult]) [self showResult:message.payload];
    });
}
- (void)showResult:(NSDictionary *)result {
    self.canvas.drawingEnabled = NO; self.answerField.hidden = YES; self.palette.hidden = YES; self.toolsStack.hidden = YES;
    self.roleLabel.text = [NSString stringWithFormat:@"%@ 猜对了", result[@"winner"] ?: @"玩家"];
    self.wordLabel.text = [NSString stringWithFormat:@"答案：%@", result[@"word"] ?: @""];
    if (self.host) { self.startButton.hidden = NO; [self.startButton setTitle:@"下一轮" forState:UIControlStateNormal]; }
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
}
- (void)gameSession:(id<JFGameSession>)session didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{ self.roleLabel.text = error.localizedDescription ?: @"连接失败"; });
}
@end
