//
//  StarDrawingView.h
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface StarDrawingView : UIView
@property (nonatomic, strong) NSArray<UIImage *> *imageArray;
/// 开启涂鸦
- (void)startDrawing;

/// 停止涂鸦
- (void)stopDrawing;

/// 清除所有图案
- (void)clearAll;
@end

NS_ASSUME_NONNULL_END
