//
//  AppDelegate.m
//  FashionApp
//
//  Created by 1 on 2018/4/9.
//  Copyright © 2018年 1. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (nonatomic, strong)UINavigationController *rootNav;
@property (nonatomic, strong)UIViewController *rootvc;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self appInitThirdLib];
    [self appInitRootViewController];
    [self registerAPNs];
    return YES;
}

//初始化第三方库
- (void)appInitThirdLib
{
    [FSServiceRoute syncCallService:@"FSMiddleWareService" func:@"setupCrashReporter" withParam:nil];
    [FSServiceRoute syncCallService:@"FSMiddleWareService" func:@"initDDLoggerSystem" withParam:nil];
    [FSServiceRoute syncCallService:@"FSNetWorkService" func:@"connectNetWns" withParam:nil ];
    [FSServiceRoute syncCallService:@"FSLoginService" func:@"registerWXLogin" withParam:nil];
    [FSServiceRoute syncCallService:@"FSLoginService" func:@"registerQQLogin" withParam:nil];
    [FSServiceRoute syncCallService:@"FSMsgService" func:@"startSubcriptionMsgSer" withParam:nil];
#warning 临时测试
    [self appLoginSuccessAction];
}

//初始化首页面
- (void)appInitRootViewController
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.rootvc = [FSServiceRoute syncCallService:@"FSFirstService" func:@"getModuleViewController" withParam:nil];
    
    self.rootNav = [[UINavigationController alloc] initWithRootViewController:self.rootvc];
    self.window.rootViewController = self.rootNav;
    [self.window makeKeyAndVisible];
}

//注册APN
- (void)registerAPNs
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerForRemoteNotifications)])
    {
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types
                                                                                 categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

//处理初始化hook事件
- (void)appInitAOPEvent
{
//    [FSServiceRoute syncCallService:@"FSAPOObjectService" func:@"hookViewSetFrame" withParam:nil];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    DebugLog(@"url");
    if([[url absoluteString] containsString:kWEIXINLoginAppid])
    {
        [FSServiceRoute syncCallService:@"FSLoginService" func:@"handWXLoginUrl:" withParam:@{@"url":url}];
    }
    if ([[url absoluteString] containsString:kQQLoginAPPID]) {
        [FSServiceRoute syncCallService:@"FSLoginService" func:@"handQQLoginUrl:" withParam:@{@"url":url}];
    }
    return YES;
}
//登录成功后的操作
- (void)appLoginSuccessAction
{
    [FSServiceRoute syncCallService:@"FSNetWorkService" func:@"bindUser:" withParam:@{@"bindUserId":@"88888888"}];
}

//注册aps后的delegate函数
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *deviceTokenString2 = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""]
                                     stringByReplacingOccurrencesOfString:@">" withString:@""]
                                    stringByReplacingOccurrencesOfString:@" " withString:@""];
    [FSServiceRoute syncCallService:@"FSNetWorkService" func:@"registerRemoteNotification" withParam:@{@"deviceToken":deviceTokenString2}];
    DDLogDebug(@"didRegisterForRemoteNotificationsWithDeviceToken:  %@", deviceTokenString2);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    DDLogDebug(@"receive remote notification:  %@", userInfo);
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    DDLogDebug(@"fail to get apns token :%@",error);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
