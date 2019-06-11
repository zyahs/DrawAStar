//
//  NSObject+extra.m
//  OC
//
//  Created by codeIsMyGirl on 16/8/1.
//  Copyright © 2016年 codeIsMyGirl. All rights reserved.
//

#import "NSObject+extra.h"

@implementation NSObject (extra)

- (void)grestrueNext:(UIGestureRecognizerState)state withIndexPath:(NSIndexPath *)indexPath withTableView:(UITableView *)tableView withLocation:(CGPoint)location withData:(NSMutableArray *)items {
    
    static UIView *snapshot = nil;
    
    ///< A snapshot of the row user is moving.
    static NSIndexPath *sourceIndexPath = nil;
    
    ///< Initial index path, where gesture begins.
    
    switch (state) {
        case UIGestureRecognizerStateBegan: {
            if (indexPath) {
                sourceIndexPath = indexPath;
                
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                
                // Take a snapshot of the selected row using helper method.
                snapshot = [self customSnapshoFromView:cell];
                
                // Add the snapshot as subview, centered at cell's center...
                __block CGPoint center = cell.center;
                
                snapshot.center = center;
                
                snapshot.alpha = 0.0;
                
                [tableView addSubview:snapshot];
                
                [UIView animateWithDuration:0.25
                                 animations:^{
                                     
                                     // Offset for gesture location.
                                     center.y = location.y;
                                     
                                     snapshot.center = center;
                                     
                                     snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05);
                                     
                                     snapshot.alpha = 0.98;
                                     
                                     cell.alpha = 0.0f;
                                     
                                 }
                                 completion:^(BOOL finished) {
                                     cell.hidden = YES;
                                     
                                 }];
            }
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            CGPoint center = snapshot.center;
            
            center.y = location.y;
            
            snapshot.center = center;
            
            // Is destination valid and is it different from source?
            if (indexPath && ![indexPath isEqual:sourceIndexPath]) {
                
                // ... update data source.
                
                // 交换 二个数组 的 数据顺序
                [items exchangeObjectAtIndex:indexPath.row
                            withObjectAtIndex:sourceIndexPath.row];
                
                // ... move the rows.
         
                [tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
                
                // ... and update source so it is in sync with UI changes.
                sourceIndexPath = indexPath;
            }
            break;
        }
            
        default: {
            // Clean up.
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:sourceIndexPath];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 
                                 snapshot.center = cell.center;
                                 
                                 snapshot.transform = CGAffineTransformIdentity;
                                 
                                 snapshot.alpha = 0.0;
                                 
                                 cell.alpha = 1.0f;
                                 
                             }
                             completion:^(BOOL finished) {
                                 
                                 cell.hidden = NO;
                                 
                                 [snapshot removeFromSuperview];
                                 
                                 snapshot = nil;
                                 
                             }];
            
            sourceIndexPath = nil;
            
            break;
        }
    }
}

#pragma mark - 自定义快照短从视图
- (UIView *)customSnapShortFromViewEx:(UIView *)inputView {
    
    CGSize inSize = inputView.bounds.size;
    
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(inSize, false,
                                           [UIScreen mainScreen].scale);
    
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    UIImageView *snapshot = [[UIImageView alloc] initWithImage:image];
    
    return snapshot;
}

#pragma mark - 辅助方法 Helper methods

/** @brief Returns a customized snapshot of a given view. */
- (UIView *)customSnapshoFromView:(UIView *)inputView {
    UIView *snapshot = nil;
    
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] < 7.0) {
        // ios7.0 以下通过截图形式保存快照
        snapshot = [self customSnapShortFromViewEx:inputView];
        
    } else {
        // ios7.0 系统的快照方法
        snapshot = [inputView snapshotViewAfterScreenUpdates:YES];
    }
    
    snapshot.layer.masksToBounds = NO;
    
    snapshot.layer.cornerRadius = 0.0;
    
    snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    
    // 阴影范围
    snapshot.layer.shadowRadius = 5.0;
    
    // 阴影不透明度 范围: 0 ~ 1
    snapshot.layer.shadowOpacity = 0.4;
    
    // 边框 宽度
    snapshot.layer.borderWidth = 0.5;
    
    // 边框 颜色
    snapshot.layer.borderColor  = [UIColor colorWithWhite:0.498 alpha:1.000].CGColor;
    
    return snapshot;
}




@end
