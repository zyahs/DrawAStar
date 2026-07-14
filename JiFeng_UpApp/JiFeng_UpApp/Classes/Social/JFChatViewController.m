//
//  JFChatViewController.m
//  JiFeng_UpApp
//

#import "JFChatViewController.h"
#import "JFTheme.h"
#import "JFBackendClient.h"
#import "JFPlayerSetup.h"

@interface JFChatCell : UITableViewCell
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
- (void)configure:(NSDictionary *)message;
@end

@implementation JFChatCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _bubbleView = [[UIView alloc] init];
        _bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
        _bubbleView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
        _bubbleView.layer.cornerRadius = 18;
        _bubbleView.layer.cornerCurve = kCACornerCurveContinuous;
        _bubbleView.layer.borderWidth = 1;
        _bubbleView.layer.borderColor = [JFTheme cardBorder].CGColor;
        [self.contentView addSubview:_bubbleView];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.font = [JFTheme fontCaption];
        _nameLabel.textColor = [JFTheme accent];
        [_bubbleView addSubview:_nameLabel];

        _bodyLabel = [[UILabel alloc] init];
        _bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _bodyLabel.font = [JFTheme fontBody];
        _bodyLabel.textColor = [JFTheme textPrimary];
        _bodyLabel.numberOfLines = 0;
        [_bubbleView addSubview:_bodyLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_bubbleView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:JFSpacing8],
            [_bubbleView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:JFSpacing16],
            [_bubbleView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-JFSpacing16],
            [_bubbleView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-JFSpacing8],

            [_nameLabel.topAnchor constraintEqualToAnchor:_bubbleView.topAnchor constant:JFSpacing12],
            [_nameLabel.leadingAnchor constraintEqualToAnchor:_bubbleView.leadingAnchor constant:JFSpacing16],
            [_nameLabel.trailingAnchor constraintEqualToAnchor:_bubbleView.trailingAnchor constant:-JFSpacing16],

            [_bodyLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:JFSpacing4],
            [_bodyLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
            [_bodyLabel.trailingAnchor constraintEqualToAnchor:_nameLabel.trailingAnchor],
            [_bodyLabel.bottomAnchor constraintEqualToAnchor:_bubbleView.bottomAnchor constant:-JFSpacing12],
        ]];
    }
    return self;
}

- (void)configure:(NSDictionary *)message {
    NSDictionary *user = [message[@"user"] isKindOfClass:[NSDictionary class]] ? message[@"user"] : @{};
    NSString *name = [user[@"displayName"] isKindOfClass:[NSString class]] ? user[@"displayName"] : @"继风玩家";
    NSString *content = [message[@"content"] isKindOfClass:[NSString class]] ? message[@"content"] : @"";
    self.nameLabel.text = name;
    self.bodyLabel.text = content;
}

@end

@interface JFChatViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *inputBar;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) NSArray<NSDictionary *> *messages;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UIView *themeBackground;
@property (nonatomic, assign) BOOL accountReady;
@end

@implementation JFChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.messages = @[];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.themeBackground = [JFTheme installThemedBackgroundInView:self.view];
    [self setupUI];
    [self reloadMessages];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(reloadMessages) userInfo:nil repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self requirePlayerAccount];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)setupUI {
    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"大厅聊天";
    title.font = [JFTheme fontTitle];
    title.textColor = [JFTheme textPrimary];
    [self.view addSubview:title];

    self.inputBar = [[UIView alloc] init];
    self.inputBar.translatesAutoresizingMaskIntoConstraints = NO;
    [JFTheme decorateGlassPanel:self.inputBar];
    [self.view addSubview:self.inputBar];

    self.inputField = [[UITextField alloc] init];
    self.inputField.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputField.placeholder = @"说点什么";
    self.inputField.textColor = [JFTheme textPrimary];
    self.inputField.font = [JFTheme fontBody];
    self.inputField.returnKeyType = UIReturnKeySend;
    self.inputField.delegate = self;
    self.inputField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.07];
    self.inputField.layer.cornerRadius = JFRadiusMedium;
    self.inputField.layer.cornerCurve = kCACornerCurveContinuous;
    self.inputField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
    self.inputField.leftViewMode = UITextFieldViewModeAlways;
    [self.inputBar addSubview:self.inputField];

    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.sendButton.tintColor = [JFTheme textOnAccent];
    self.sendButton.backgroundColor = [JFTheme accent];
    self.sendButton.layer.cornerRadius = JFRadiusMedium;
    self.sendButton.layer.cornerCurve = kCACornerCurveContinuous;
    [self.sendButton setImage:[UIImage systemImageNamed:@"paperplane.fill"] forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(onSend) forControlEvents:UIControlEventTouchUpInside];
    [self.inputBar addSubview:self.sendButton];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorColor = [JFTheme separator];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = 72;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.tableView registerClass:[JFChatCell class] forCellReuseIdentifier:@"chat"];
    [self.view addSubview:self.tableView];

    self.inputField.enabled = NO;
    self.sendButton.enabled = NO;

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [title.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:72],
        [title.topAnchor constraintEqualToAnchor:safe.topAnchor constant:JFSpacing16],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],

        [self.inputBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.inputBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.inputBar.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor],
        [self.inputBar.heightAnchor constraintEqualToConstant:76],

        [self.inputField.leadingAnchor constraintEqualToAnchor:self.inputBar.leadingAnchor constant:JFSpacing16],
        [self.inputField.topAnchor constraintEqualToAnchor:self.inputBar.topAnchor constant:JFSpacing12],
        [self.inputField.trailingAnchor constraintEqualToAnchor:self.sendButton.leadingAnchor constant:-JFSpacing12],
        [self.inputField.heightAnchor constraintEqualToConstant:44],

        [self.sendButton.trailingAnchor constraintEqualToAnchor:self.inputBar.trailingAnchor constant:-JFSpacing16],
        [self.sendButton.centerYAnchor constraintEqualToAnchor:self.inputField.centerYAnchor],
        [self.sendButton.widthAnchor constraintEqualToConstant:48],
        [self.sendButton.heightAnchor constraintEqualToConstant:44],

        [self.tableView.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:JFSpacing16],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.inputBar.topAnchor],
    ]];
}

- (void)requirePlayerAccount {
    __weak typeof(self) weakSelf = self;
    [JFPlayerSetup ensureFromViewController:self completion:^(BOOL complete) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !complete) return;
        self.accountReady = YES;
        self.inputField.enabled = YES;
        self.sendButton.enabled = YES;
        self.inputField.placeholder = [NSString stringWithFormat:@"以 %@ 发言", JFPlayerSetup.currentDisplayName];
    }];
}

- (void)reloadMessages {
    [[JFBackendClient shared] fetchChatMessagesInRoom:@"global" take:50 completion:^(NSArray<NSDictionary *> * _Nullable messages, __unused NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.messages = messages ?: self.messages;
            [self.tableView reloadData];
            [self scrollToBottom];
        });
    }];
}

- (void)onSend {
    if (!self.accountReady) {
        [self requirePlayerAccount];
        return;
    }
    NSString *text = [self.inputField.text ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.inputField resignFirstResponder];
    if (text.length == 0) return;
    self.sendButton.enabled = NO;
    [[JFBackendClient shared] sendChatMessage:text inRoom:@"global" completion:^(BOOL success, __unused NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.sendButton.enabled = YES;
            if (success) {
                self.inputField.text = @"";
                [self reloadMessages];
            }
        });
    }];
}

- (void)scrollToBottom {
    if (self.messages.count == 0) return;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self onSend];
    return YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.inputField resignFirstResponder];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JFChatCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chat" forIndexPath:indexPath];
    [cell configure:self.messages[indexPath.row]];
    return cell;
}

@end
