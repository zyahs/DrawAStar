//
//  Movie.h
//  漫天都是小星星的说
//
//  Created by 飞奔的羊 on 2017/12/20.
//  Copyright © 2017年 itcast. All rights reserved.
//

#import <AVOSCloud/AVOSCloud.h>

//static NSString *const kStudnetKeyAvatar = @"avatar";
//static NSString *const kStudnetKeyAge = @"stars";
//static NSString *const kStudentKeyName = @"movie";
//static NSString *const kStudentKeyCom = @"comment";
@interface Movie : AVObject<AVSubclassing>
@property (nonatomic, copy)   NSString *movie;
@property (nonatomic, assign) int stars;
@property (nonatomic, copy)   NSString *comment;
@property (nonatomic, strong) AVFile *avatar;
@property (nonatomic, strong) id any;
@end
