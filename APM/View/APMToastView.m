//
//  CrashToastView.m
//  CrashSDKDevelop
//
//  Created by unakayou on 2021/9/1.
//

#import "APMToastView.h"
#import <UIKit/UIKit.h>

@implementation APMToastView
+ (void)showToastViewWithMessage:(NSString *)message {
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.text = message;
    textLabel.textColor = [UIColor whiteColor];
    textLabel.backgroundColor = [UIColor darkGrayColor];
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.font = [UIFont boldSystemFontOfSize:15];
    textLabel.layer.cornerRadius = 5;
    textLabel.layer.masksToBounds = YES;
    textLabel.adjustsFontSizeToFitWidth = YES;
    
    NSDictionary *attrs = @{NSFontAttributeName : textLabel.font};
    CGSize size = [textLabel.text sizeWithAttributes:attrs];
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow addSubview:textLabel];
    [textLabel setFrame:CGRectMake(0, 0, size.width + 10, 35)];
    textLabel.center = CGPointMake(keyWindow.center.x, keyWindow.center.y + keyWindow.center.y / 2);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1
                         animations:^{
            textLabel.alpha = 0;
        } completion:^(BOOL finished) {
            [textLabel removeFromSuperview];
        }];
    });
}
@end
