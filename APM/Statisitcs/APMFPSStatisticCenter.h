//
//  APMFPSStattisitcsCenter.h
//  APM
//
//  Created by unakayou on 2022/3/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef  void (^FPSCallbackHandler)(int fps);

@interface APMFPSStatisticCenter : NSObject

/// 开始
+ (void)start;

/// 停止
+ (void)stop;

/// 设置FPS触底阈值
+ (void)setLimitFPSValue:(float)limitFPSValue;

/// 内存刷新回调
+ (void)setFPSValueHandler:(FPSCallbackHandler _Nonnull)FPSHandler;

@end

NS_ASSUME_NONNULL_END
