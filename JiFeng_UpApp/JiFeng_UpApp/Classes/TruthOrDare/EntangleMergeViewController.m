//
//  EntangleMergeViewController.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/9/1.
//
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "TruthOrDareViewController.h"

@interface EntangleMergeViewController : rootVcViewController
/// 可选：给外部一个回调，点中放大的“胜出球”后跳转
@property (nonatomic, copy) void (^onWinnerTapped)(BOOL winnerIsTruth); // YES=真心话, NO=大冒险
@property (nonatomic,strong)UIImageView *bgImageView;
@end

@implementation EntangleMergeViewController {
    // 背景
    CAGradientLayer *_bgLayer;
    CADisplayLink   *_bgLink;
    CFTimeInterval   _bgPhase;
    BOOL             _bgFast;

    // 球
    UIView *_ballTruth;
    UIView *_ballDare;
    UILabel *_labelTruth;
    UILabel *_labelDare;
    // 进阶小球
    UIView *_ballPro;
    UILabel *_labelPro;
    // 中心闪光
    UIView *_centerFlash;

    // 控制
    UIButton *_startBtn;
    BOOL _isAnimating;
    BOOL _winnerIsTruth;   // 预先决定的胜出球（在上层 & 最终保留）
    UITapGestureRecognizer *_winnerTap;
}
static NSArray *funDares = @[
    @"用你的鼻子在空中写出我的名字。",
    @"对我说一句电影台词并让我猜出处。",
    @"做个10秒的可爱表情，不许笑场。",
    @"发一个你小时候的照片给我。",
    @"模仿你喜欢的动漫角色说一句话。",
    @"对着镜子自拍做鬼脸发给我。",
    @"用手比出你现在的心情。",
    @"10秒内说出5种水果名，不许重复。",
    @"说出你最近收藏的一个搞笑表情包。",
    @"现场配音一段我们聊天记录。",
    @"对自己大喊三遍“我是小可爱”。",
    @"用英语说一句你最近想说的话。",
    @"学猫叫5秒，认真点！",
    @"用鼻音念我的名字三次。",
    @"发一个“打工人”自拍姿态。",
    @"跳一个10秒抖音热舞片段。",
    @"用手比心，然后发个照片。",
    @"念绕口令：黑化肥发灰会挥发。",
    @"给我取一个你觉得适合我的绰号。",
    @"模仿我打字的语气说一句话。",
    @"说出最近一个让你大笑的瞬间。",
    @"用“我是谁我在哪”造一个小段子。",
    @"表演你早起后最懒的动作。",
    @"用微信语音发出最真实的叹气声。",
    @"对着空气比个耶，说“我最棒”。",
    @"背诵一首你记得最牢的小诗或歌词。",
    @"描述你最喜欢的动画人物并说理由。",
    @"演一个喝水喝呛了但还要装没事的样子。",
    @"假装被采访，说出你的一句“名言”。",
    @"模仿你的老师讲课语气1句。",
    @"假装你是美食博主，推荐今晚吃啥。",
    @"随机翻朋友圈第5条并模仿发布人语气读出来。",
    @"当我是老板，请求我给你涨工资。",
    @"用“你好吗我很好”编一段 5 秒小剧场。",
    @"找出你手机相册里最糗的一张自拍。",
    @"用一种动物的声音打招呼。",
    @"学一个外国口音说“我超爱你”。",
    @"做出三种你以为很酷的Pose。",
    @"用你爸妈小时候骂你的语气说句“别再玩手机了”。",
    @"发一个你最懒的一天的描述语音。",
    @"模仿小孩子的语气说一句话。",
    @"画一个你印象中的我，随便画。",
    @"夸我三句，不能带重复词。",
    @"模仿我发语音的习惯一句话。",
    @"给我一个5字以内的“外号”并解释理由。",
    @"模仿电影《喜剧之王》演一句“我养你啊”。",
    @"模拟一段“遇到明星”的激动反应。",
    @"现场编一首歌，哪怕只一句也行。",
    @"用嘴叼住一张纸比心拍照。",
    @"一分钟内找出三个你房间里的红色物品并说出。",
    @"模仿你最常看up主的开头3秒。",
    @"发一个你认为“土得可爱”的自拍姿势。",
    @"从你书包/口袋/包包里随机拿一样东西介绍它。",
    @"打开你相册，随机选第10张，发给我（不能挑）。",
    @"发出你最“社恐”的一次经历。",
    @"说出一个你小时候误以为是真理的事情。",
    @"用搞笑语气朗读你今天的待办事项。",
    @"假装自己是恋综选手，念一段心动独白。",
    @"你认为我最适合扮演的卡通角色是谁？",
    @"给我发一条“反差萌”的语音。",
    @"模仿一个综艺主持人开场白。",
    @"用“我今天有点疯”语气发一句撒娇话。",
    @"模仿一位老师/领导语气读一则通知。",
    @"对着镜头录一段“谢谢大家支持我”感言。",
    @"用一种你最讨厌的语气说“我想你”。",
    @"学动物叫三种，连续来。",
    @"用最平淡的语气说一句最甜的情话。",
    @"编一句“渣男语录”或者“渣女语录”。",
    @"用emoji拼一句暗示情话。",
    @"模仿一个你朋友圈常发自拍的人说话。",
    @"发一个“我好无聊”的视频动态（不用@）。",
    @"打一句“土味情话”，最好带押韵。",
    @"现场来段rap，押不押韵不重要。",
    @"说出你脑袋里此刻冒出的第一个想法。",
    @"模仿你妈/你爸最经典的一句话语调。",
    @"模仿电台情感主播，说一句话给我。",
    @"打开某短视频App，模仿第一个视频主角语气。",
    @"假装你是王者荣耀主播来一段解说。",
    @"录一段你演“吃到超好吃东西”的反应。",
    @"夸你自己3句，越夸张越好。",
    @"对我说一句“今天我最可爱”。",
    @"选一个你听不懂的方言朗读一个成语。",
    @"拍照你现在最邋遢的一面。",
    @"用你家乡口音说“你真好看”。",
    @"录一段你模仿AI语音助手对话。",
    @"说一句你最想穿越到的年代+理由。",
    @"打开天气App，用播音腔播报今天的天气。",
    @"翻一张以前的自拍加一句吐槽发我。",
    @"模仿你打游戏输掉时的反应。",
    @"对自己做鬼脸自拍并发我。",
    @"给我发一个“自夸不带脸红”的语音。",
    @"选一个好友备注改成“我大王”一天。",
    @"念出你收藏夹中最羞耻的表情名字。",
    @"模拟一段“你误会我了”的小剧场。",
    @"念出你今天发送的最后一条微信内容。",
    @"假装现在是情人节，对我录一条祝福语音。",
    @"录一段“我要暴富”的洗脑宣言。",
    @"说一句你今天脑子短路的瞬间。",
    @"描述一顿你梦中理想的大餐。",
    @"选一首歌，用哼唱方式唱副歌。",
    @"用一句话形容“现在的我有点疯”。",
    @"拍一个“我要起飞”的Pose发来。",
    @"发你衣柜里颜色最亮的一件衣服合影。"
];
static NSArray *dares1 = @[
    @"现场模仿一次最性感的猫步。",
    @"用最撩的声音对我说：今晚别走。",
    @"给我发一张你觉得最撩的自拍。",
    @"含住手指看着我10秒。",
    @"撩我一句话，说得我脸红为止。",
    @"假装亲吻镜头5秒钟。",
    @"对着我说出你今晚的幻想内容。",
    @"打个语音说“我想你”，娇羞一点。",
    @"选一个emoji表达你现在的羞羞心情。",
    @"现在脱下一件衣服（可选帽子袜子等）。",
    @"给我录一个你撒娇的语音。",
    @"连续wink我三下并说“今晚有空吗？”",
    @"跳一小段热舞，发我看。",
    @"发送手机相册里第3张照片。",
    @"发一句你曾对前任说过的情话。",
    @"打电话说“我现在只想听你声音”。",
    @"做一个你认为最性感的动作。",
    @"尝试把舌头伸得最长发我看。",
    @"发你最满意的嘴唇自拍。",
    @"模仿床上的呻吟声2秒钟。",
    @"给我发一条你看了会脸红的链接。",
    @"转发朋友圈说“今晚想被抱着睡”。",
    @"打开后摄自拍说“我最想的人是你”。",
    @"录一个你最甜的称呼喊我。",
    @"给我取一个羞羞小名，并解释原因。",
    @"发一张你今天最贴身的穿搭。",
    @"录一段10秒小剧场，说你等我来找你。",
    @"用手指比心发我，并说我爱你三遍。",
    @"舔一下手背并拍照发我。",
    @"说一句你觉得最骚气的台词。",
    @"发一段“你想我了吗”的撒娇语音。",
    @"模仿一段电影里的情欲对白。",
    @"说一句你想和我去开房的话。",
    @"描述一下你理想中羞羞场景。",
    @"发一个能撩到你的视频。",
    @"说出你现在最想被亲哪里。",
    @"拍照你现在坐着的姿势。",
    @"想象我们现在在车里，说一句应景的话。",
    @"发一个“我想你了”的变调语音。",
    @"表演一个“看到我就想扑上来”的样子。",
    @"发我你最性感的一段舞蹈（或想象）。",
    @"说出你最想我做的三件羞羞的事。",
    @"发一个“我需要你”的自拍。",
    @"发出一个你不敢让别人看到的照片。",
    @"自拍摸头+撒娇表情包。",
    @"说出你现在立刻想吻的程度。",
    @"录一段你假装被壁咚的反应。",
    @"发一张你洗完澡后的自拍（保守也行）。",
    @"发一段“今晚你别走”的声音视频。",
    @"闭眼说出你脑子里现在的画面。",
    @"和身边的人做一个法式舌吻30秒。",
    @"主动给喜欢的人发一条尺度较大的信息。",
    @"当众模仿一下自己高潮时的表情。",
    @"在伴侣耳边轻声细语说出自己的性幻想。",
    @"亲吻对方身体任意指定部位一分钟。",
    @"挑战脱去对方一件衣服。",
    @"互相喂食，嘴对嘴交换食物。",
    @"在现场跳一段性感舞蹈或钢管舞动作。",
    @"给对方一个浪漫性感的按摩（指定部位）。",
    @"当众进行一场公主抱或背起对方绕场一圈。",
    @"发一条朋友圈表达今晚寂寞或空虚，需要陪伴。",
    @"选现场一人摸自己指定的敏感部位10秒。",
    @"与现场一人表演电影经典吻戏片段。",
    @"将自己穿的贴身衣物交给对方保管直到游戏结束。",
    @"和指定异性牵手，深情对视一分钟。",
    @"模仿电影中的经典告白片段，对着现场某人深情表白。",
    @"打电话给一个暧昧对象，大胆调情一分钟。",
    @"现场展示自己穿的内衣（仅上半身）。",
    @"和指定异性对视互相赞美一分钟，不得笑场。",
    @"现场做10个深蹲，对方抱在怀中。",
    @"朗读一段情色小说，带上情绪并表演出来。",
    @"给异性喂食水果，不得用手，只能嘴对嘴传递。",
    @"主动对某人耳边吹气，持续10秒。",
    @"发朋友圈秀恩爱，但对象为现场指定异性。",
    @"主动吻对方颈部30秒。",
    @"用异性声音给朋友打电话，持续一分钟。",
    @"拍摄并发送一张性感自拍给现场随机异性。",
    @"将对方抱到腿上，互动30秒。",
    @"现场对异性做壁咚动作，亲密对视15秒。",
    @"用现场物品模仿一种成人用品的用法。",
    @"挑战撩拨现场任意异性，直到对方主动笑出来为止。",
    @"发一条信息给喜欢的人，邀请对方今晚共进晚餐。",
    @"和现场任意异性交换一件随身物品（例如戒指、项链、手表）。",
    @"现场表演一个极具挑逗性的wink和飞吻组合。",
    @"当众模仿异性声音撒娇30秒。",
    @"发朋友圈晒一张自己性感部位的特写。",
    @"现场将异性抱起并保持30秒不放下。",
    @"用嘴解开对方衣服的一颗扣子。",
    @"现场对指定异性用鼻子轻蹭面颊20秒。",
    @"主动邀请现场某人跳一段贴身热舞。",
    @"挑战给伴侣或指定异性做腿部按摩2分钟。",
    @"现场为异性系鞋带，过程中不断进行眼神互动。",
    @"打电话给最近暧昧的人，说想念对方并邀约。",
    @"挑战现场做出自己觉得最诱人的动作或姿势。",
    @"和对方互相抱紧1分钟，不允许松开。",
    @"对现场异性真诚告白一分钟，说出喜欢的原因。",
    @"模仿经典吻戏片段，与指定异性假戏真做30秒。",
    @"当众演绎一种情趣用品的广告。",
    @"和指定异性额头贴额头，保持静止30秒。",
    @"将伴侣抱起或坐在怀里并自拍一张甜蜜照，发朋友圈。"
];

static NSArray *dares = @[
    @"你曾经最疯狂的一次恋爱经历是什么？",
    @"你现在最想对我说的一句话是什么？",
    @"你有没有偷偷暗恋过我？",
    @"说出你最羞耻的一次梦境内容。",
    @"你有没有在洗澡时唱歌的习惯？唱哪首？",
    @"你是否曾对朋友隐瞒重大秘密？什么内容？",
    @"最近一次心动是因为什么？",
    @"你手机里有没有不敢让别人看的照片？",
    @"有没有什么话一直没敢对我说？现在说。",
    @"你最怕一个人面对什么场景？",
    @"你有没有和对象偷情过？",
    @"有没有对前任说过谎？说了什么？",
    @"你目前有没有性幻想对象？是谁？",
    @"你会不会为了爱情放弃梦想？",
    @"你有没有和别人接吻却想着另一个人？",
    @"你最想尝试的情趣体验是什么？",
    @"你在暧昧期做过最大胆的事是？",
    @"你有没有为爱疯狂追过一个人？",
    @"你最喜欢别人对你身体哪个部位赞美？",
    @"你是否看过小黄片？喜欢哪一类？",
    @"你有自慰的习惯吗？频率是？",
    @"你有没有在公共场所做过出格的事？",
    @"你觉得自己哪个行为最性感？",
    @"你和对象在一起最长的一次亲密行为持续了多久？",
    @"你有没有偷拍过喜欢的人？",
    @"你会不会和不喜欢但性感的人发生关系？",
    @"你现在会不会想和某人接吻？是谁？",
    @"你有没有幻想过和我……？",
    @"说出你最喜欢的前戏方式。",
    @"描述一次你最印象深刻的羞羞经历。",
    @"你有没有同时爱过两个人？",
    @"你最难忘的一次调情经历是什么？",
    @"你最想尝试的羞羞场所是？",
    @"你有没有说过谎骗对象上床？",
    @"你最不能接受伴侣的哪种行为？",
    @"你有没有对异性朋友动过歪心思？",
    @"你有没有删过自己不该有的聊天记录？",
    @"你觉得自己几分好色？",
    @"你有没有故意穿得很撩引起别人注意？",
    @"你有没有和对象一起拍过私密照？",
    @"你有没有在亲密中笑场过？为什么？",
    @"你觉得羞羞时最重要的是什么？",
    @"你有没有在亲密时喊错名字？",
    @"有没有在酒店被投诉太吵？",
    @"你有没有被捉奸在床过？",
    @"你有没有主动邀约过露骨的关系？",
    @"你有没有穿着情趣内衣自拍过？",
    @"你和现任/前任最羞耻的角色扮演是？",
    @"你有没有因为太想对方而冲动行动？",
    @"你是否曾暗中关注某人很久？是谁？",
    @"你第一次和异性亲密接触是在什么时候？",
    @"描述一下你最刺激的一次接吻经历。",
    @"你和现任/暧昧对象第一次见面时的真实想法是什么？",
    @"说出你对异性最敏感的身体部位。",
    @"你喜欢伴侣在床上主动还是被动？",
    @"你对自己的身材满意吗？觉得哪里最性感？",
    @"你最喜欢的体位是哪个？",
    @"第一次约会你能接受的尺度有多大？",
    @"描述你幻想过的最刺激的场景。",
    @"你最喜欢伴侣对你做什么小动作？",
    @"谈过几次恋爱，最难忘的一次因为什么？",
    @"你对伴侣说过最大的谎是什么？",
    @"最近一次自己解决需求是什么时候？",
    @"如果现在给你一个机会和在场某人接吻，你会选谁？",
    @"描述一下你最享受的接吻方式。",
    @"你最想尝试却一直没尝试过的事情是什么？",
    @"曾经有过一夜情吗？描述一下过程。",
    @"你最讨厌伴侣床上的什么习惯？",
    @"有没有被抓到过做羞羞的事情？",
    @"你会偷偷看伴侣的手机吗？",
    @"你觉得在场谁的身材最好？说出具体原因。",
    @"第一次亲热时发生了哪些尴尬的事？",
    @"你内心隐藏的最深的癖好是什么？",
    @"你有没有主动勾引过别人？",
    @"你觉得伴侣的哪个部位最吸引你？",
    @"你能接受伴侣的最大尺度是什么？",
    @"曾经偷偷喜欢过朋友的伴侣吗？",
    @"如果伴侣想拍私密视频/照片，你的真实想法是什么？",
    @"有没有做羞羞的事情时被别人听到或看到？",
    @"你的初吻是在什么情况下发生的？",
    @"你最敏感的三个点是哪几个？",
    @"你和伴侣吵架时有没有幻想过别人？",
    @"你最害怕伴侣问你的问题是什么？",
    @"伴侣提出最让你难为情的要求是什么？",
    @"有没有偷偷用过情趣用品？",
    @"你最喜欢异性穿什么样的内衣？",
    @"对于多人游戏你怎么看？",
    @"有没有假装过高潮？",
    @"你会接受伴侣带你去特殊的俱乐部吗？",
    @"你收到过最性感的礼物是什么？",
    @"你觉得异性的哪些声音或动作最性感？",
    @"有没有偷偷关注过成人网站或论坛？",
    @"如果现在只能穿一件衣服，你会穿什么？",
    @"有没有偷偷用伴侣的私人用品？",
    @"最喜欢伴侣怎样称呼你？",
    @"有没有幻想过和身边某个朋友亲密接触？",
    @"如果可以自由选择，你最想在哪个地方做亲密的事？"
];
#pragma mark - Life

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"b2"]];
    self.bgImageView.frame = self.view.bounds;
    self.bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.bgImageView];
    [self setupBackground];
    [self decideWinnerEarly];    // 一进来就先决定层级，避免“突兀”
    [self setupBallsAndLabels];
    [self setupCenterStart];
    [self setupCenterFlash];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startBackgroundLoopFast:NO];
    [self startAdvancedSpinIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopBackgroundLoop];
}

#pragma mark - Background

- (void)setupBackground {
    _bgLayer = [CAGradientLayer layer];
    _bgLayer.frame = self.view.bounds;
    _bgLayer.colors = [self bgColorsAtPhase:0];
    _bgLayer.startPoint = CGPointMake(0, 0);
    _bgLayer.endPoint   = CGPointMake(1, 1);
    [self.view.layer insertSublayer:_bgLayer atIndex:0];
}

- (NSArray *)bgColorsAtPhase:(CGFloat)phase {
    UIColor *c1 = [UIColor colorWithHue:fmod(phase+0.00,1.0) saturation:0.60 brightness:0.96 alpha:1];
    UIColor *c2 = [UIColor colorWithHue:fmod(phase+0.33,1.0) saturation:0.55 brightness:0.92 alpha:1];
    UIColor *c3 = [UIColor colorWithHue:fmod(phase+0.66,1.0) saturation:0.58 brightness:0.88 alpha:1];
    return @[(__bridge id)c1.CGColor, (__bridge id)c2.CGColor, (__bridge id)c3.CGColor];
}

- (void)startBackgroundLoopFast:(BOOL)fast {
    _bgFast = fast;
    if (_bgLink) return;
    _bgPhase = 0;
    _bgLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onBgTick)];
    [_bgLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}
- (void)stopBackgroundLoop {
    [_bgLink invalidate];
    _bgLink = nil;
}
- (void)onBgTick {
    _bgPhase += _bgFast ? 0.02 : 0.004;
    if (_bgPhase > 1.0) _bgPhase -= 1.0;
    _bgLayer.colors = [self bgColorsAtPhase:_bgPhase];
}

#pragma mark - Balls

- (void)decideWinnerEarly {
    // 这里你可以写死，也可以随机。示例：随机决定
    _winnerIsTruth = (arc4random_uniform(2) == 0);
}

- (UIView *)makeBallWithDiameter:(CGFloat)d baseColor:(UIColor *)base {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, d, d)];
    v.layer.cornerRadius = d*0.5;
    v.layer.masksToBounds = NO;
    v.backgroundColor = [base colorWithAlphaComponent:0.5];

    // 径向高光（伪 3D）
    CAGradientLayer *gloss = [CAGradientLayer layer];
    gloss.type = kCAGradientLayerRadial;
    gloss.frame = v.bounds;
    gloss.colors = @[ (__bridge id)[UIColor colorWithWhite:1 alpha:0.85].CGColor,
                      (__bridge id)[UIColor colorWithWhite:1 alpha:0.22].CGColor,
                      (__bridge id)[UIColor colorWithWhite:1 alpha:0.02].CGColor,
                      (__bridge id)[UIColor clearColor].CGColor ];
    gloss.locations = @[@0.0,@0.25,@0.55,@1.0];
    gloss.startPoint = CGPointMake(0.30, 0.30);
    gloss.endPoint   = CGPointMake(1.0, 1.0);
    gloss.cornerRadius = v.layer.cornerRadius;
    [v.layer addSublayer:gloss];

    // 外发光
    v.layer.shadowColor   = base.CGColor;
    v.layer.shadowOpacity = 0.85;
    v.layer.shadowRadius  = d*0.27;
    v.layer.shadowOffset  = CGSizeZero;

    return v;
}

- (UILabel *)makeBallLabel:(NSString *)text {
    UILabel *lab = [[UILabel alloc] init];
    lab.text = text;
    lab.textColor = UIColor.whiteColor;
    lab.font = [UIFont boldSystemFontOfSize:18];
    lab.textAlignment = NSTextAlignmentCenter;
    lab.adjustsFontSizeToFitWidth = YES;

    // 发光描边
    lab.layer.shadowColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    lab.layer.shadowOffset = CGSizeZero;
    lab.layer.shadowOpacity = 1.0;
    lab.layer.shadowRadius = 6.0;

    return lab;
}
- (void)startAdvancedSpinIfNeeded {
    if (!_ballPro) return;
    // 已存在则不重复添加
    if ([_ballPro.layer animationForKey:@"pro.spin"]) return;

    CABasicAnimation *rot = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rot.toValue = @(2*M_PI);
    rot.duration = 1.6;                 // 稍慢的常驻旋转
    rot.repeatCount = HUGE_VALF;
    rot.removedOnCompletion = NO;
    rot.fillMode = kCAFillModeForwards;
    [_ballPro.layer addAnimation:rot forKey:@"pro.spin"];
}
- (void)setupBallsAndLabels {
    CGFloat D = 78.0;
    // 真心话（粉）
    _ballTruth = [self makeBallWithDiameter:D baseColor:[UIColor colorWithRed:1.0 green:0.45 blue:0.70 alpha:1]];
    _labelTruth = [self makeBallLabel:@"真心话"];
    // 大冒险（蓝）
    _ballDare = [self makeBallWithDiameter:D baseColor:[UIColor colorWithRed:0.45 green:0.70 blue:1.0 alpha:1]];
    _labelDare = [self makeBallLabel:@"大冒险"];

    // 布局
    CGPoint c = self.view.center;
    CGFloat R = MIN(self.view.bounds.size.width, self.view.bounds.size.height)*0.28;
    _ballTruth.center = CGPointMake(c.x + R, c.y);
    _ballDare.center  = CGPointMake(c.x - R, c.y);

    // 把 label 放到球中间
    _labelTruth.frame = CGRectInset(_ballTruth.bounds, 8, 8);
    _labelDare.frame  = CGRectInset(_ballDare.bounds, 8, 8);
    [_ballTruth addSubview:_labelTruth];
    [_ballDare addSubview:_labelDare];

    // 初始就可点击
    UITapGestureRecognizer *tapTruth = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTruthTapped)];
    [_ballTruth addGestureRecognizer:tapTruth];
    _ballTruth.userInteractionEnabled = YES;

    UITapGestureRecognizer *tapDare = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDareTapped)];
    [_ballDare addGestureRecognizer:tapDare];
    _ballDare.userInteractionEnabled = YES;

    // 胜出球提前设置层级更高（避免最后“突兀切层级”）
    if (_winnerIsTruth) {
        _ballTruth.layer.zPosition = 10;
        _ballDare.layer.zPosition  = 0;
    } else {
        _ballDare.layer.zPosition  = 10;
        _ballTruth.layer.zPosition = 0;
    }

    [self.view addSubview:_ballTruth];
    [self.view addSubview:_ballDare];
    // 进阶（黄）：右下角常驻旋转
    _ballPro = [self makeBallWithDiameter:D
                               baseColor:[UIColor colorWithRed:1.00 green:0.85 blue:0.20 alpha:1.0]]; // 柔黄
    _labelPro = [self makeBallLabel:@"进阶"];
    _labelPro.frame = CGRectInset(_ballPro.bounds, 8, 8);
    [_ballPro addSubview:_labelPro];

    CGFloat inset = 24.0;
    _ballPro.center = CGPointMake(self.view.bounds.size.width - inset - D*0.5,
                                  self.view.bounds.size.height - inset - D*0.5);
    [self.view addSubview:_ballPro];
    _ballPro.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapPro = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAdvancedTapped)];
    [_ballPro addGestureRecognizer:tapPro];
    // 开启常驻自转
    [self startAdvancedSpinIfNeeded];
}

- (void)setupCenterFlash {
    _centerFlash = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    _centerFlash.center = self.view.center;
    _centerFlash.layer.cornerRadius = 10;
    _centerFlash.backgroundColor = [UIColor whiteColor];
    _centerFlash.alpha = 0;
//    [self.view addSubview:_centerFlash];
}
- (void)onAdvancedTapped {
    // push 或弹窗
    TruthOrDareViewController *vc = [[TruthOrDareViewController alloc] init];
        vc.item = dares1;
        vc.displayText = @"大冒险(进阶)";
    vc.imageName = @"d1";
    [self.navigationController pushViewController:vc animated:YES];
}
#pragma mark - Immediate taps

- (void)onTruthTapped {
    if (_isAnimating) return; // 动画中不响应
    if (self.onWinnerTapped) { self.onWinnerTapped(YES); return; }
    TruthOrDareViewController *vc = [[TruthOrDareViewController alloc] init];
        vc.item = dares;
        vc.displayText = @"真心话";
    vc.imageName = @"z1";
    [self.navigationController pushViewController:vc animated:YES];
//    [self showResultWithText:@"真心话"];
}



- (void)onDareTapped {
    if (_isAnimating) return; // 动画中不响应
    if (self.onWinnerTapped) { self.onWinnerTapped(NO); return; }
    TruthOrDareViewController *vc = [[TruthOrDareViewController alloc] init];
    vc.item = funDares;
        vc.displayText = @"大冒险";
    vc.imageName = @"d2";
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Controls

- (UIButton *)prettyButtonWithTitle:(NSString *)title {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
    b.layer.cornerRadius = 22;
    b.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.35].CGColor;
    b.layer.borderWidth = 1;
    b.layer.shadowColor = [UIColor whiteColor].CGColor;
    b.layer.shadowOpacity = 0.6;
    b.layer.shadowRadius = 8;
    b.layer.shadowOffset = CGSizeZero;
    return b;
}

- (void)setupCenterStart {
    _startBtn = [self prettyButtonWithTitle:@"开始"];
    CGFloat W = 120, H = 44;
    _startBtn.frame = CGRectMake((self.view.bounds.size.width-W)/2.0,
                                 self.view.center.y - H/2.0,
                                 W,H);
    [_startBtn addTarget:self action:@selector(onStart) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_startBtn];
}

#pragma mark - Spiral

- (UIBezierPath *)spiralPathAround:(CGPoint)center
                       startRadius:(CGFloat)r0
                         endRadius:(CGFloat)r1
                         rotations:(CGFloat)rotations
                         phaseBias:(CGFloat)phase
                             steps:(NSInteger)steps {
    UIBezierPath *p = [UIBezierPath bezierPath];
    for (NSInteger i=0;i<=steps;i++){
        CGFloat t = (CGFloat)i/(CGFloat)steps;             // 0..1
        CGFloat ang = (rotations * 2*M_PI) * t + phase;    // 角度
        CGFloat r   = r0 + (r1 - r0) * t;                  // 半径渐变
        CGFloat x = center.x + r * cos(ang);
        CGFloat y = center.y + r * sin(ang);
        if (i==0) [p moveToPoint:CGPointMake(x, y)];
        else [p addLineToPoint:CGPointMake(x, y)];
    }
    return p;
}

#pragma mark - Start

- (void)onStart {
    if (_isAnimating) return;
    _isAnimating = YES;
    _startBtn.hidden = YES;

    // 背景加速
    [self startBackgroundLoopFast:YES];

    CGPoint C = self.view.center;
    CGFloat R0 = MIN(self.view.bounds.size.width, self.view.bounds.size.height)*0.28;
    CGFloat R1 = 0;
    CGFloat rotCount = 3.5;

    UIBezierPath *pathTruth = [self spiralPathAround:C startRadius:R0 endRadius:R1 rotations:rotCount phaseBias:0 steps:420];
    UIBezierPath *pathDare  = [self spiralPathAround:C startRadius:R0 endRadius:R1 rotations:rotCount phaseBias:M_PI steps:420];

    CFTimeInterval moveDur = 2.6;
    CAKeyframeAnimation *moveT = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    moveT.path = pathTruth.CGPath; moveT.duration = moveDur;
    moveT.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    moveT.fillMode = kCAFillModeForwards; moveT.removedOnCompletion = NO;

    CAKeyframeAnimation *moveD = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    moveD.path = pathDare.CGPath; moveD.duration = moveDur;
    moveD.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    moveD.fillMode = kCAFillModeForwards; moveD.removedOnCompletion = NO;

    // 自转 + 呼吸
    CABasicAnimation *rotT = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotT.toValue = @(2*M_PI); rotT.duration = 1.2; rotT.repeatCount = HUGE_VALF;
    CABasicAnimation *rotD = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotD.toValue = @(-2*M_PI); rotD.duration = 1.2; rotD.repeatCount = HUGE_VALF;

    CABasicAnimation *breath = [CABasicAnimation animationWithKeyPath:@"opacity"];
    breath.fromValue=@0.9; breath.toValue=@1.0; breath.duration=0.8; breath.autoreverses=YES; breath.repeatCount=HUGE_VALF;

    [_ballTruth.layer addAnimation:rotT forKey:@"rot"];
    [_ballDare.layer addAnimation:rotD forKey:@"rot"];
    [_ballTruth.layer addAnimation:breath forKey:@"breath"];
    [_ballDare.layer addAnimation:breath forKey:@"breath"];

    [_ballTruth.layer addAnimation:moveT forKey:@"move"];
    [_ballDare.layer addAnimation:moveD forKey:@"move"];

    // 合并时刻
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(moveDur * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 落位中心
        self->_ballTruth.center = C;
        self->_ballDare.center  = C;

        [self flashMergeAtCenter:C completion:^{
            // 显示胜出球，隐藏另一个
            if (self->_winnerIsTruth) {
                self->_ballDare.hidden = YES;
                [self showWinnerBall:self->_ballTruth isTruth:YES];
            } else {
                self->_ballTruth.hidden = YES;
                [self showWinnerBall:self->_ballDare isTruth:NO];
            }
            // 背景恢复慢速
            [self startBackgroundLoopFast:NO];
            self->_isAnimating = NO;
        }];
    });
}

- (void)flashMergeAtCenter:(CGPoint)C completion:(void(^)(void))finish {
    _centerFlash.center = C;
    _centerFlash.transform = CGAffineTransformIdentity;
    _centerFlash.alpha = 0.0;

    [UIView animateWithDuration:0.12 animations:^{
        self->_centerFlash.alpha = 1.0;
        self->_centerFlash.transform = CGAffineTransformMakeScale(10, 10);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.28 animations:^{
            self->_centerFlash.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (finish) finish();
        }];
    }];
}

#pragma mark - Winner

- (void)showWinnerBall:(UIView *)ball isTruth:(BOOL)truth {
    [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.65 initialSpringVelocity:0.6 options:0 animations:^{
        ball.transform = CGAffineTransformMakeScale(1.5, 1.5);
    } completion:nil];
}

- (void)onWinnerTappedAction {
    if (self.onWinnerTapped) {
        self.onWinnerTapped(_winnerIsTruth);
        return;
    }
    // 默认行为：弹窗模拟跳转
    NSString *title = _winnerIsTruth ? @"真心话" : @"大冒险";
    UIAlertController *a = [UIAlertController alertControllerWithTitle:title
                                                               message:@"这里触发你的页面跳转"
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _bgLayer.frame = self.view.bounds;

    // 旋转/尺寸变化时，尽量保持初始位置（未开始动画的情况）
    if (!_isAnimating && !_startBtn.hidden) {
        CGPoint c = self.view.center;
        CGFloat R = MIN(self.view.bounds.size.width, self.view.bounds.size.height)*0.28;
        _ballTruth.center = CGPointMake(c.x + R, c.y);
        _ballDare.center  = CGPointMake(c.x - R, c.y);

        CGFloat W = 120, H = 44;
        _startBtn.frame = CGRectMake((self.view.bounds.size.width-W)/2.0,
                                     self.view.center.y - H/2.0,
                                     W,H);
    }
    if (_ballPro) {
        CGFloat Dp = _ballPro.bounds.size.width;
        CGFloat inset = 24.0;
        _ballPro.center = CGPointMake(self.view.bounds.size.width - inset - Dp*0.5,
                                      self.view.bounds.size.height - inset - Dp*0.5);
    }
}

@end
