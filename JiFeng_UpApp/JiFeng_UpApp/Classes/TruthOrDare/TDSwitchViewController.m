//
//  TDSwitchViewController.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/6.
//

#import "TDSwitchViewController.h"

#import <QuartzCore/QuartzCore.h>
#import "TruthOrDareViewController.h"
@interface TDSwitchViewController ()

@property (nonatomic, strong) UIButton *centerButton;
@property (nonatomic, strong) UIButton *truthButton;
@property (nonatomic, strong) UIButton *dareButton;
@property (nonatomic, strong) CAGradientLayer *backgroundLayer;
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, weak) UIButton *finalSelectedCircle;

@end
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





@implementation TDSwitchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"b2"]];
    self.bgImageView.frame = self.view.bounds;
    self.bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.bgImageView];
    self.backgroundLayer = [CAGradientLayer layer];
    self.backgroundLayer.frame = self.view.bounds;
    self.backgroundLayer.colors = @[
        (id)[UIColor colorWithRed:1.0 green:0.8 blue:0.8 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:1.0 green:0.9 blue:0.7 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.9 green:1.0 blue:0.8 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.8 green:0.9 blue:1.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.9 green:0.8 blue:1.0 alpha:1.0].CGColor
    ];
    self.backgroundLayer.startPoint = CGPointMake(0, 0);
    self.backgroundLayer.endPoint = CGPointMake(1, 1);
    [self.view.layer insertSublayer:self.backgroundLayer atIndex:0];
    
    [self startBackgroundAnimationWithDuration:6.0];
    
    [self setupButtons];
    UIButton *advancedButton = [UIButton buttonWithType:UIButtonTypeSystem];
       [advancedButton setTitle:@"进阶" forState:UIControlStateNormal];
       advancedButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
       [advancedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
       advancedButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
       advancedButton.layer.cornerRadius = 10;
       advancedButton.clipsToBounds = YES;
       advancedButton.frame = CGRectMake(self.view.bounds.size.width - 100, self.view.bounds.size.height - 60, 80, 40);
       advancedButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
       [advancedButton addTarget:self action:@selector(advancedButtonTapped) forControlEvents:UIControlEventTouchUpInside];
       [self.view addSubview:advancedButton];
}
- (void)advancedButtonTapped {
    TruthOrDareViewController *vc = [[TruthOrDareViewController alloc] init];
        vc.item = dares1;
        vc.displayText = @"大冒险(进阶)";
    
    [self.navigationController pushViewController:vc animated:YES];
}
- (UIButton *)createCircleButtonWithTitle:(NSString *)title colors:(NSArray *)colors {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    button.layer.cornerRadius = 60;
    button.clipsToBounds = YES;
    button.frame = CGRectMake(0, 0, 120, 120);
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = button.bounds;
    gradient.colors = colors;
    gradient.startPoint = CGPointMake(0.3, 0.3);
    gradient.endPoint = CGPointMake(0.9, 0.9);
    gradient.cornerRadius = 60;
    [button.layer insertSublayer:gradient atIndex:0];
    
    // Add highlight layer for sphere effect
    CAGradientLayer *highlight = [CAGradientLayer layer];
    highlight.frame = CGRectMake(0, 0, 120, 120);
    highlight.colors = @[
        (id)[[UIColor colorWithWhite:1.0 alpha:0.6] CGColor],
        (id)[[UIColor colorWithWhite:1.0 alpha:0.1] CGColor]
    ];
    highlight.startPoint = CGPointMake(0.2, 0.2);
    highlight.endPoint = CGPointMake(0.8, 0.8);
    highlight.cornerRadius = 60;
    [button.layer insertSublayer:highlight atIndex:1];
    
    button.layer.shadowColor = [UIColor blackColor].CGColor;
    button.layer.shadowOpacity = 0.2;
    button.layer.shadowOffset = CGSizeMake(0, 4);
    button.layer.shadowRadius = 8;
    
    return button;
}

- (void)setupButtons {
    CGPoint center = self.view.center;
    
    self.centerButton = [self createCircleButtonWithTitle:@"开始"
                                                   colors:@[(id)[UIColor purpleColor].CGColor, (id)[UIColor systemPinkColor].CGColor]];
    self.centerButton.center = center;
    [self.centerButton addTarget:self action:@selector(startAnimation) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.centerButton];
    
    self.truthButton = [self createCircleButtonWithTitle:@"真心话"
                                                  colors:@[(id)[UIColor blueColor].CGColor, (id)[UIColor greenColor].CGColor]];
    self.truthButton.center = CGPointMake(center.x, center.y + 200);
    [self.truthButton addTarget:self action:@selector(truthSelected) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.truthButton];
    
    self.dareButton = [self createCircleButtonWithTitle:@"大冒险"
                                                 colors:@[(id)[UIColor redColor].CGColor, (id)[UIColor magentaColor].CGColor]];
    self.dareButton.center = CGPointMake(center.x, center.y - 200);
    [self.dareButton addTarget:self action:@selector(dareSelected) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.dareButton];
}

- (void)startAnimation {
    [self startBackgroundAnimationWithDuration:1.0];

    self.centerButton.userInteractionEnabled = NO;

    // 随机提前确定最终选中的圆，并调整层级
    BOOL finalSelectionIsTruth = arc4random_uniform(2) == 0;
    self.finalSelectedCircle = finalSelectionIsTruth ? self.truthButton : self.dareButton;
    [self.view bringSubviewToFront:self.finalSelectedCircle];
    self.truthButton.layer.zPosition = finalSelectionIsTruth ? 1 : 0;
    self.dareButton.layer.zPosition = finalSelectionIsTruth ? 0 : 1;

    [self animateCircle:self.truthButton clockwise:YES];
    [self animateCircle:self.dareButton clockwise:NO];
}

// 新的动画：旋转并收缩合并到中心
- (void)animateCircle:(UIButton *)circle clockwise:(BOOL)clockwise {
    // 只需要在truth和dare都执行完动画后再合并，所以在startAnimation里分别调用
    // 这里我们只触发一次合并动画
    static NSInteger finishedCount = 0;
    CGPoint center = self.centerButton.center;
    CGFloat radius = 120;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat startAngle = clockwise ? -M_PI_2 : M_PI_2;
    CGFloat endAngle = startAngle + (clockwise ? M_PI * 6 : -M_PI * 6);
    
    [path addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:clockwise];
    
    CAKeyframeAnimation *orbit = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    orbit.path = path.CGPath;
    orbit.duration = 2.0;
    orbit.fillMode = kCAFillModeForwards;
    orbit.removedOnCompletion = NO;
    orbit.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [circle.layer addAnimation:orbit forKey:@"orbit"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [circle.layer removeAllAnimations];
        finishedCount++;
        if (finishedCount == 2) {
            finishedCount = 0;
            [self mergeCirclesWithGravityWave];
        }
    });
}

// 引力波式合并动画
- (void)mergeCirclesWithGravityWave {
    UIButton *truthCircle = self.truthButton;
    UIButton *dareCircle = self.dareButton;
    CGPoint center = self.centerButton.center;
    // 初始距离
    CGFloat offset = 60;
    // 先把两个圆放到合适的上下位置
    truthCircle.center = CGPointMake(center.x, center.y - offset);
    dareCircle.center = CGPointMake(center.x, center.y + offset);
    truthCircle.transform = CGAffineTransformIdentity;
    dareCircle.transform = CGAffineTransformIdentity;
    truthCircle.hidden = NO;
    dareCircle.hidden = NO;
    truthCircle.alpha = 1.0;
    dareCircle.alpha = 1.0;

    [UIView animateKeyframesWithDuration:2.0 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
        // 第一段：旋转并靠近
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
            CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI);
            truthCircle.transform = CGAffineTransformConcat(truthCircle.transform, rotate);
            dareCircle.transform = CGAffineTransformConcat(dareCircle.transform, rotate);
            truthCircle.center = CGPointMake(center.x, center.y - offset / 2.0);
            dareCircle.center = CGPointMake(center.x, center.y + offset / 2.0);
        }];
        // 第二段：继续靠近并放大
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
            truthCircle.center = center;
            dareCircle.center = center;
            truthCircle.transform = CGAffineTransformMakeScale(1.2, 1.2);
            dareCircle.transform = CGAffineTransformMakeScale(1.2, 1.2);
        }];
    } completion:^(BOOL finished) {
        [self animateMergeToCenter:self.finalSelectedCircle];
        [self startBackgroundAnimationWithDuration:6.0];
    }];
}

// 合并到中心动画，选中的圆为参数
- (void)animateMergeToCenter:(UIButton *)selectedCircle {
    UIButton *otherCircle = (selectedCircle == self.truthButton) ? self.dareButton : self.truthButton;
    // 恢复状态
    selectedCircle.transform = CGAffineTransformIdentity;
    selectedCircle.alpha = 1.0;
    selectedCircle.hidden = NO;
    otherCircle.transform = CGAffineTransformIdentity;
    otherCircle.alpha = 0.0;
    otherCircle.hidden = YES;

    [UIView animateWithDuration:0.25 animations:^{
        selectedCircle.transform = CGAffineTransformMakeScale(1.5, 1.5);
    } completion:^(BOOL finished2) {
        selectedCircle.userInteractionEnabled = YES;
        [selectedCircle addTarget:self action:@selector(winnerTapped:) forControlEvents:UIControlEventTouchUpInside];
    }];
}

// 修改后的 resolveResult 方法，确保一个按钮放大并保留，另一个按钮仅透明不隐藏
// resolveResult 已被 gravity wave 动画替换，不再使用

- (void)winnerTapped:(UIButton *)sender {
    CAGradientLayer *bgLayer = [CAGradientLayer layer];
    bgLayer.frame = self.view.bounds;
    bgLayer.colors = @[
        (id)[UIColor redColor].CGColor,
        (id)[UIColor orangeColor].CGColor,
        (id)[UIColor yellowColor].CGColor,
        (id)[UIColor greenColor].CGColor,
        (id)[UIColor blueColor].CGColor,
        (id)[UIColor purpleColor].CGColor
    ];
    bgLayer.startPoint = CGPointMake(0, 0);
    bgLayer.endPoint = CGPointMake(1, 1);
    [self.view.layer addSublayer:bgLayer];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"colors"];
    animation.toValue = [[bgLayer.colors reverseObjectEnumerator] allObjects];
    animation.duration = 2.0;
    animation.autoreverses = YES;
    animation.repeatCount = HUGE_VALF;
    [bgLayer addAnimation:animation forKey:@"colorShift"];
    
    
    
}

- (void)startBackgroundAnimationWithDuration:(NSTimeInterval)duration {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"colors"];
    animation.toValue = [[self.backgroundLayer.colors reverseObjectEnumerator] allObjects];
    animation.duration = duration;
    animation.autoreverses = YES;
    animation.repeatCount = HUGE_VALF;
    [self.backgroundLayer removeAnimationForKey:@"colorShift"];
    [self.backgroundLayer addAnimation:animation forKey:@"colorShift"];
}



// 真心话按钮点击
- (void)truthSelected {
    TruthOrDareViewController *vc = [[TruthOrDareViewController alloc] init];
        vc.item = dares;
        vc.displayText = @"真心话";
    
    [self.navigationController pushViewController:vc animated:YES];
//    [self showResultWithText:@"真心话"];
}

// 大冒险按钮点击
- (void)dareSelected {
    TruthOrDareViewController *vc = [[TruthOrDareViewController alloc] init];
    vc.item = funDares;
        vc.displayText = @"大冒险";
    
    [self.navigationController pushViewController:vc animated:YES];
//    [self showResultWithText:@"大冒险"];
}

// 展示结果方法
- (void)showResultWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    label.center = self.view.center;
    label.text = text;
    label.font = [UIFont boldSystemFontOfSize:32];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.alpha = 0.0;
    [self.view addSubview:label];
    
    [UIView animateWithDuration:0.5 animations:^{
        label.transform = CGAffineTransformMakeScale(1.5, 1.5);
        label.alpha = 1.0;
        self.view.backgroundColor = [UIColor colorWithHue:arc4random_uniform(256)/255.0
                                               saturation:0.5 + arc4random_uniform(50)/100.0
                                               brightness:0.8 + arc4random_uniform(20)/100.0
                                                    alpha:1.0];
    }];
}
@end
