//
//  NSObject+extra.h
//  OC
//
//  Created by codeIsMyGirl on 16/8/1.
//  Copyright © 2016年 codeIsMyGirl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSObject (extra)

- (void)grestrueNext:(UIGestureRecognizerState)state withIndexPath:(NSIndexPath *)indexPath withTableView:(UITableView *)tableView withLocation:(CGPoint)location withData:(NSMutableArray *)items;

#pragma mark - 自定义快照短从视图
- (UIView *)customSnapShortFromViewEx:(UIView *)inputView;

- (UIView *)customSnapshoFromView:(UIView *)inputView;

@end
