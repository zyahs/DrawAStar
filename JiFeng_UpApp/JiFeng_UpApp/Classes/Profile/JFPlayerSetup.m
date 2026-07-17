//
//  JFPlayerSetup.m
//  JiFeng_UpApp
//

#import "JFPlayerSetup.h"
#import "JFProfileStore.h"
#import "JFBackendClient.h"

static NSString * const kJFPlayerSetupCompleteKey = @"jf_player_setup_complete_v1";

@implementation JFPlayerSetup

+ (BOOL)isComplete {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults boolForKey:kJFPlayerSetupCompleteKey]) return YES;

    NSString *name = [JFProfileStore shared].displayName;
    if (name.length >= 2 && ![name isEqualToString:@"继风玩家"] && ![name isEqualToString:@"新玩家"]) {
        [defaults setBool:YES forKey:kJFPlayerSetupCompleteKey];
        return YES;
    }
    return NO;
}

+ (NSString *)currentDisplayName {
    return [JFProfileStore shared].displayName;
}

+ (void)ensureFromViewController:(UIViewController *)viewController
                      completion:(void (^)(BOOL))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isComplete]) {
            if (completion) completion(YES);
            return;
        }
        [self presentPromptFromViewController:viewController message:nil completion:completion];
    });
}

+ (void)presentPromptFromViewController:(UIViewController *)viewController
                                message:(NSString * _Nullable)message
                             completion:(void (^ _Nullable)(BOOL complete))completion {
    if (!viewController || viewController.presentedViewController) return;

    NSString *body = message.length > 0
        ? message
        : @"设置一个昵称，它会用于大厅聊天、我有你没有、国王游戏、谁是卧底和联机牌桌。无需额外记住密码。";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"创建玩家账号"
                                                                   message:body
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"输入 2-16 个字符的昵称";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];

    __weak UIAlertController *weakAlert = alert;
    __weak UIViewController *weakViewController = viewController;
    UIAlertAction *create = [UIAlertAction actionWithTitle:@"创建并进入"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(__unused UIAlertAction * _Nonnull action) {
        NSString *name = [weakAlert.textFields.firstObject.text ?: @""
                          stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (name.length < 2 || name.length > 16) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentPromptFromViewController:weakViewController
                                              message:@"昵称需要保持在 2-16 个字符之间，请重新输入。"
                                           completion:completion];
            });
            return;
        }

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kJFPlayerSetupCompleteKey];
        [[JFProfileStore shared] updateDisplayName:name];
        [[JFBackendClient shared] ensureSignedInWithCompletion:nil];
        if (completion) completion(YES);
    }];
    [alert addAction:create];
    [viewController presentViewController:alert animated:YES completion:^{
        [alert.textFields.firstObject becomeFirstResponder];
    }];
}

@end
