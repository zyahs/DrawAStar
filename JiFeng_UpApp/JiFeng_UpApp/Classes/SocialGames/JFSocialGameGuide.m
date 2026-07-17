//
//  JFSocialGameGuide.m
//  JiFeng_UpApp
//

#import "JFSocialGameGuide.h"

@implementation JFSocialGameGuide

static JFSocialGameGuide *Guide(NSString *guideId,
                                NSString *title,
                                NSString *subtitle,
                                NSString *symbolName,
                                NSInteger minPlayers,
                                NSInteger maxPlayers,
                                NSInteger durationMinutes,
                                JFSocialGameMood mood,
                                NSString *props,
                                NSString *summary,
                                NSString *setup,
                                NSArray<NSString *> *steps,
                                NSArray<NSString *> *tips,
                                NSNumber *launchKindValue) {
    JFSocialGameGuide *guide = [[JFSocialGameGuide alloc] init];
    guide.guideId = guideId;
    guide.title = title;
    guide.subtitle = subtitle;
    guide.symbolName = symbolName;
    guide.minPlayers = minPlayers;
    guide.maxPlayers = maxPlayers;
    guide.durationMinutes = durationMinutes;
    guide.mood = mood;
    guide.props = props;
    guide.summary = summary;
    guide.setup = setup;
    guide.steps = steps;
    guide.tips = tips;
    guide.launchKindValue = launchKindValue;
    return guide;
}

+ (NSArray<JFSocialGameGuide *> *)allGuides {
    static NSArray<JFSocialGameGuide *> *guides;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        guides = @[
            Guide(@"never_have_i_ever", @"我有你没有", @"谁没有，谁熄灭一根",
                  @"hand.raised.fingers.spread.fill", 2, 10, 20, JFSocialGameMoodFriends, @"每人一部手机",
                  @"轮流说一件自己有、但别人可能没有的事。没有这段经历的人熄灭一根手指，用彼此不同的经历打开话题。",
                  @"由一人创建实时房间，其他人用房间码加入。每个人确认自己的昵称，进入后都能看到全员剩余手指。",
                  @[@"系统按加入顺序指定发言者；轮到你时，说一件自己确实有过的经历。",
                    @"除发言者外，所有仍有手指的玩家在自己的手机上选择“我有”或“我没有”。",
                    @"所有人投完后系统统一结算：选择“我没有”的玩家熄灭一根手指，并自动轮到下一位。",
                    @"手指归零的玩家停止发言和投票，最后仍有手指的人获胜。"],
                  @[@"任何人都可以跳过让自己不舒服的题目，不需要说明理由。",
                    @"刚认识时优先使用生活与兴趣题，熟人局再逐渐提高话题强度。",
                    @"酒精不是游戏的一部分，可以用讲故事、唱一句歌等轻量任务代替惩罚。"],
                  @(JFGameKindNeverHaveIEver)),

            Guide(@"undercover", @"谁是卧底", @"相近词语里的隐藏身份",
                  @"person.3.sequence.fill", 4, 12, 30, JFSocialGameMoodThinking, @"手机发词",
                  @"多数人拿到同一个词，少数卧底拿到相近词。大家只能描述不能直说，在信息差里找到卧底。",
                  @"选择一组容易混淆但都能描述的词，例如“牛奶/豆浆”。每位玩家私下查看自己的词，确认后把手机交给下一位。",
                  @[@"从任意玩家开始，每人用一句话描述自己的词，不能出现词本身或明显谐音。",
                    @"全部描述结束后讨论并匿名投票，得票最多者出局；平票时让平票玩家补充描述后重投。",
                    @"出局玩家公布身份。若卧底仍在场，就进入下一轮描述与投票。",
                    @"卧底全部出局则平民获胜；人数缩减到卧底与平民数量相同时，卧底获胜。"],
                  @[@"第一轮描述不要太具体，否则卧底很难参与。",
                    @"出现争议时由主持人判断描述是否直接泄题，避免临场改变标准。"],
                  @(JFGameKindUndercover)),

            Guide(@"king", @"国王游戏", @"抽到国王的人发布双人指令",
                  @"crown.fill", 4, 12, 25, JFSocialGameMoodLively, @"手机发牌",
                  @"每轮随机产生一位国王，其他玩家只知道自己的编号。国王发布涉及编号的轻量任务，再揭晓由谁完成。",
                  @"开始前约定任务边界，并明确所有人都有一次无条件否决权。房主创建房间后，其他玩家用昵称加入。",
                  @[@"房主发牌，抽到 K 的玩家成为本轮国王，其余玩家得到唯一编号。",
                    @"国王先说出任务和需要的编号，例如“2 号和 5 号互相模仿十秒”。",
                    @"相关玩家亮出编号并完成任务；任何一方否决时，国王改成更轻的任务。",
                    @"完成后收回身份并重新发牌，上一轮身份不延续到下一轮。"],
                  @[@"任务应当短、可拒绝、不涉及隐私公开和危险动作。",
                    @"让不同类型的任务轮换，避免连续把焦点放在同一位玩家身上。"],
                  @(JFGameKindKing)),

            Guide(@"truth_or_dare", @"真心话大冒险", @"回答问题或完成挑战",
                  @"heart.circle.fill", 3, 10, 25, JFSocialGameMoodFriends, @"无需道具",
                  @"用随机选择把话题和表演任务交给当前玩家，适合熟悉彼此，也适合用温和题库破冰。",
                  @"先选定题目强度和轮数。明确可以跳过任何题目，跳过时只需换一题，不追加惩罚。",
                  @[@"随机选出当前玩家，再由系统决定真心话或大冒险。",
                    @"当前玩家读题并回答或完成挑战，其他人不能临时提高难度。",
                    @"完成后由下一位继续；若题目重复或不合适，直接换题。",
                    @"玩满约定轮数后结束，也可以在每人都完成一次后收尾。"],
                  @[@"新朋友局使用兴趣、旅行和日常习惯题更容易进入状态。",
                    @"避免偷拍视频或把回答转发到群外。"],
                  @(JFGameKindTruthOrDare)),

            Guide(@"liars_dice", @"吹牛骰子", @"报价、质疑与概率判断",
                  @"die.face.5.fill", 3, 10, 25, JFSocialGameMoodLively, @"每人若干骰子",
                  @"每个人只看自己的骰子，却要判断全场某个点数到底有多少颗。报价会不断升高，直到有人选择开盅。",
                  @"每人使用五颗骰子并遮住结果。先约定 1 是否作为万能点，以及失败者是少一颗骰子还是记录一次失误。",
                  @[@"所有人同时摇骰并只查看自己的结果。",
                    @"首位玩家报价“全场至少有几颗某点数”，下一位必须提高数量或提高点数。",
                    @"认为上一家夸大时可以喊开，全场同时展示骰子并统计。",
                    @"报价不足则质疑者失败，报价达到则报价者安全；处理完结果后重新摇下一轮。"],
                  @[@"第一次玩建议关闭万能点规则，理解后再开启。",
                    @"报价是“至少有”，不是必须刚好等于。"],
                  @(JFGameKindDice)),

            Guide(@"party_cards", @"小姐牌与派对牌", @"一副牌驱动整场任务",
                  @"rectangle.stack.fill", 3, 12, 35, JFSocialGameMoodLively, @"手机牌堆",
                  @"不同点数对应不同角色、口令或挑战。玩法节奏由翻牌推进，适合希望少主持、多随机的聚会。",
                  @"选择一套规则后先让所有人看完点数说明。牌堆放在中央，按顺时针每次只翻一张。",
                  @[@"当前玩家翻牌并朗读牌面任务。",
                    @"立即执行一次性任务，或记录持续身份，例如小姐、大姐、少爷。",
                    @"持续身份在规则指定的新牌出现时交接或解除。",
                    @"牌堆用完或达到约定时间后结束，最后清算仍未完成的保留任务。"],
                  @[@"第一次玩选择规则较少的牌组，避免同时记住太多持续效果。",
                    @"预览和洗牌只在开局前进行，开始后保持牌序。"],
                  @(JFGameKindCard)),

            Guide(@"gesture_bomb", @"手势炸弹", @"看清手势再快速模仿",
                  @"hand.raised.fingers.spread.fill", 3, 12, 12, JFSocialGameMoodIcebreaker, @"一台手机",
                  @"屏幕随机生成一组手势，其中藏着本轮炸弹。玩家按顺序模仿，命中炸弹者完成一项轻量挑战。",
                  @"根据人数设置手势数量，人数多时适当增加展示区域。所有人先看清炸弹规则，再开始传递手机。",
                  @[@"系统生成本轮手势并秘密标记炸弹位置。",
                    @"玩家按顺序选择并模仿一个尚未处理的手势。",
                    @"安全手势继续传递；命中炸弹时揭晓并完成本轮挑战。",
                    @"重新生成下一轮，可以逐渐增加手势数量提高难度。"],
                  @[@"手势数量应略多于参与人数，避免最后一位必然命中。",
                    @"挑战以表情、绕口令和快速反应为主，避免危险动作。"],
                  @(JFGameKindGesture)),

            Guide(@"turtle_soup", @"海龟汤", @"只靠是、否还原离奇故事",
                  @"questionmark.bubble.fill", 3, 12, 40, JFSocialGameMoodThinking, @"一则谜面与答案",
                  @"主持人只读故事的异常结果，其他人通过只能回答“是、不是、无关”的问题，还原完整经过。",
                  @"由一位主持人提前读完谜底并确认关键事实。其余玩家只看到谜面，不能搜索答案。",
                  @[@"主持人朗读谜面，不补充谜底里的背景信息。",
                    @"玩家轮流提出可以用是、否或无关回答的问题。",
                    @"问题接近关键点时，主持人可以回答“方向正确”但不要直接泄底。",
                    @"当玩家说出核心因果后，由主持人公布完整答案并解释遗漏细节。"],
                  @[@"第一次玩选择生活逻辑型谜题，避免过度依赖冷知识。",
                    @"涉及惊吓或敏感主题时，主持人应在开局前给出内容提示。"],
                  nil),

            Guide(@"three_gardens", @"逛三园", @"同类词接龙，重复就出错",
                  @"leaf.fill", 4, 15, 15, JFSocialGameMoodLively, @"无需道具",
                  @"先确定一个类别，所有人按节奏说出属于该类别且没有出现过的词，停顿、重复或答错即失误。",
                  @"围成一圈并选定固定节拍。第一位喊“星期天，逛三园”，下一位从动物园、植物园、果园中选一个类别。",
                  @[@"类别确定后，下一位说出一个符合类别的词。",
                    @"沿顺时针继续，每人必须在约定时间内作答。",
                    @"说过的词不能重复，类别不符、停顿过久或抢答都记一次失误。",
                    @"本轮失误者发起下一轮并更换类别。"],
                  @[@"可把类别扩展为电影、城市、食物或在场可见物品。",
                    @"用拍手维持节拍，比口头倒计时更自然。"],
                  nil),

            Guide(@"who_am_i", @"我是谁", @"用提问猜出额头上的身份",
                  @"person.crop.circle.badge.questionmark", 4, 12, 25, JFSocialGameMoodIcebreaker, @"身份词卡",
                  @"每个人都知道别人的身份词，却看不到自己的。通过有限的是非问题逐步缩小范围。",
                  @"为每位玩家准备一个大家熟悉的人物、职业或物品词，避免只有少数人知道的内部梗。",
                  @[@"玩家不能看自己的词，其他人可以同时看到。",
                    @"轮到自己时提出一个只能回答是或否的问题。",
                    @"回答为“是”可以继续问，回答为“否”则换下一位。",
                    @"猜中身份即完成；最后仍未猜中的玩家可以获得一次全场提示。"],
                  @[@"给词时保持难度相近，避免有人是“苹果”、有人是冷门历史人物。",
                    @"限定主题会显著降低新手难度。"],
                  nil),

            Guide(@"telephone", @"动作传声筒", @"一段表演会被传成什么样",
                  @"person.3.fill", 6, 20, 20, JFSocialGameMoodLively, @"题目卡或短句",
                  @"第一位看到题目后只用动作传给下一位，最后一位说出答案，再回放每一段理解差异。",
                  @"分成每队至少三人的小组并排成队。除当前两位外，其余人背对传递方向。",
                  @[@"每队第一位查看同一题目，准备十秒。",
                    @"第一位拍下一位肩膀，只表演一次且不能说话或指向现场文字。",
                    @"动作逐人向后传递，已看过的人不能补充提示。",
                    @"最后一位说出答案，最接近原题的队伍得分。"],
                  @[@"题目使用具体动作，例如“企鹅打羽毛球”，效果比抽象词更好。",
                    @"提前清出安全活动范围，避免快速动作碰到桌椅。"],
                  nil),

            Guide(@"count_seven", @"逢七过", @"数字里有 7 就用动作代替",
                  @"7.circle.fill", 3, 15, 12, JFSocialGameMoodIcebreaker, @"无需道具",
                  @"玩家依次报数，遇到 7 的倍数或包含 7 的数字时不能说数字，必须拍手或说“过”。",
                  @"约定从 1 开始、顺时针进行，并统一特殊数字的替代动作。新手可以只用 7 的倍数规则。",
                  @[@"第一位报 1，之后每位玩家按顺序加一。",
                    @"遇到 7 的倍数或数字中包含 7 时，用拍手代替报数。",
                    @"报错、停顿过久或在特殊数字时报出数字都记一次失误。",
                    @"失误后从 1 重新开始，或从失误数字继续以提高难度。"],
                  @[@"熟练后加入反转方向规则，连续两次拍手则再次反转。",
                    @"保持稳定节奏，不要通过突然加速只针对某位玩家。"],
                  nil),

            Guide(@"story_chain", @"关键词故事接龙", @"每人一句，把随机词串成故事",
                  @"text.book.closed.fill", 3, 10, 20, JFSocialGameMoodIcebreaker, @"若干关键词",
                  @"每个人必须在自己的句子里加入指定关键词，并接住上一位留下的情节，最后得到一段共同创作的故事。",
                  @"准备一组互不相关的关键词，例如“电梯、月亮、泡面、冠军”。随机确定故事类型和第一位玩家。",
                  @[@"第一位抽取关键词并用一句话开场。",
                    @"下一位抽新词，在十秒内用一句话延续情节且必须包含该词。",
                    @"故事不能直接推翻上一句已经发生的事实。",
                    @"每人说过两次后，由最后一位用一句话收尾，全场给故事起名。"],
                  @[@"关键词越具体、差异越大，故事通常越有趣。",
                    @"卡住时允许使用一次“转折提示”，不要因表达能力淘汰玩家。"],
                  nil),

            Guide(@"most_likely", @"谁最像", @"同时指向最符合描述的人",
                  @"person.2.fill", 4, 12, 18, JFSocialGameMoodFriends, @"问题题库",
                  @"主持人读出“谁最可能……”的问题，倒数后所有人同时指向一位玩家，再由被指最多的人讲一个相关故事。",
                  @"开局前约定问题必须是善意或中性的，不评价外貌、收入、家庭与个人创伤。",
                  @[@"主持人读题，例如“谁最可能突然去环游世界”。",
                    @"所有人先在心里选择，倒数三秒后同时指向。",
                    @"统计被指次数，被指最多者可以解释、反驳或分享一段相关经历。",
                    @"换下一位主持人继续读题，玩满约定题数后结束。"],
                  @[@"问题应让人容易讲故事，而不是给人贴负面标签。",
                    @"平票时让平票玩家互相说一个对方符合题目的理由。"],
                  nil),
        ];
    });
    return guides;
}

+ (NSString *)displayNameForMood:(JFSocialGameMood)mood {
    switch (mood) {
        case JFSocialGameMoodIcebreaker: return @"轻松破冰";
        case JFSocialGameMoodFriends: return @"熟人聊天";
        case JFSocialGameMoodLively: return @"热闹互动";
        case JFSocialGameMoodThinking: return @"推理动脑";
    }
}

- (NSString *)playersText {
    return self.minPlayers == self.maxPlayers
        ? [NSString stringWithFormat:@"%ld 人", (long)self.minPlayers]
        : [NSString stringWithFormat:@"%ld-%ld 人", (long)self.minPlayers, (long)self.maxPlayers];
}

- (NSString *)durationText {
    return [NSString stringWithFormat:@"约 %ld 分钟", (long)self.durationMinutes];
}

- (NSString *)moodText {
    return [JFSocialGameGuide displayNameForMood:self.mood];
}

- (BOOL)playableInApp {
    return self.launchKindValue != nil;
}

@end
