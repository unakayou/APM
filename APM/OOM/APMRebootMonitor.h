//
//  APMRebootAnalyzer.h
//  APM
//
//  Created by unakayou on 2022/3/14.
//
//  获取上次启动状态

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, APMRebootType) {
    APMRebootTypeUnKnow             = 0,    // 未知
    APMRebootTypeBegin              = 1,    // 开始
    
    APMRebootTypeQuitByUser         = 2,    // 上滑退出
    APMRebootTypeOSReboot           = 3,    // 系统重启
    APMRebootTypeAppVersionChange   = 4,    // App升级
    APMRebootTypeOSVersionChange    = 5,    // 系统升级
    APMRebootTypeQuitByExit         = 6,    // exit()

    APMRebootTypeCrash              = 7,    // 崩溃
    APMRebootTypeANR                = 8,    // 卡死
    APMRebootTypeFOOM               = 9,    // 前台OOM
    APMRebootTypeBOOM               = 10,   // 后台OOM或被Jestam杀掉
};

NS_ASSUME_NONNULL_BEGIN

@interface APMRebootMonitor : NSObject
@property (nonatomic, assign, class, readonly) APMRebootType rebootType;
@property (nonatomic,   weak, class, readonly) NSString *rebootTypeString;

/// 卡顿 (需要卡顿模块调用)
+ (void)applicationMainThreadBlocked;

/// 崩溃 (需要崩溃模块调用)
+ (void)applicationCrashed;

/// 可能发生OOM时调用.用于记录当前内存值
+ (void)applicationWillOOM:(double)memoryValue;
@end

NS_ASSUME_NONNULL_END
