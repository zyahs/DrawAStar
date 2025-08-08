//
//  ColorButton.h
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/8.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface ColorButton : NSObject
+ (UIButton *)createAnimatedButtonWithText:(NSString *)title
                                     target:(id)target
                                     action:(SEL)selector
                                   position:(CGPoint)position;
+ (CAGradientLayer *)createFancyAnimatedGradientForView:(UIView *)view;
+ (void)addAnimationsToGradientLayer:(CAGradientLayer *)gradient;
+ (void)removeAnimationsFromLayer:(CALayer *)layer;
@end

NS_ASSUME_NONNULL_END
