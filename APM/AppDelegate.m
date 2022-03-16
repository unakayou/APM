//
//  AppDelegate.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (nonatomic, weak) UIWindow *keyWindow;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (@available(iOS 13.0, *)) {
        // 在SceneDelegate里创建UIWindow
    } else {
        self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [self.window setBackgroundColor:[UIColor whiteColor]];
        NSString *mainStoryboardFileName = [[NSBundle mainBundle].infoDictionary valueForKey:@"UIMainStoryboardFile"];
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:mainStoryboardFileName bundle:[NSBundle mainBundle]];
        [self.window setRootViewController:[mainStoryboard instantiateInitialViewController]];
        [self.window makeKeyAndVisible];
    }
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
