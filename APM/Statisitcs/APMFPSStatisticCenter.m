//
//  APMFPSStattisitcsCenter.m
//  APM
//
//  Created by unakayou on 2022/3/31.
//

#import "APMFPSStatisticCenter.h"
#import <UIKit/UIKit.h>

#define DEFAULT_LIMIT_FPS_VALUE 30.0f;
static CADisplayLink *_displayLink = nil;
static FPSCallbackHandler _FPSHandler = nil;
static float _limitFPSValue = DEFAULT_LIMIT_FPS_VALUE;
static int _timesOneSecond = 0;                         // CADisplay 时间差 >= 1秒时回调次数
static CFTimeInterval _lastTimestamp = 0;

@implementation APMFPSStatisticCenter
+ (void)start {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_displayLink) {
            _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(CADsplayLinkCallback:)];
            [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        }
    });
}

+ (void)CADsplayLinkCallback:(CADisplayLink *)link {
    if (_lastTimestamp == 0) {
        _lastTimestamp = link.timestamp;
        return;
    }
    
    _timesOneSecond++;
    NSTimeInterval delta = link.timestamp - _lastTimestamp; // 上帧到上上帧时间差
    if (delta < 1) return;                                  // 时间差大于等于1秒时,除以当前回调次数,得到FPS
    _lastTimestamp = link.timestamp;
    
    int fps = _timesOneSecond / delta;
    _timesOneSecond = 0;

    if (fps <= _limitFPSValue) {
        APMLogDebug(@"⚠️ FPS: %d, 低于阈值", fps);
    }
    
    if (_FPSHandler) {
        _FPSHandler(fps);
    }
}

+ (void)stop {
    if (_displayLink) {
        [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [_displayLink invalidate];
        _displayLink = nil;
    }
}

+ (void)setLimitFPSValue:(float)limitFPSValue {
    _limitFPSValue = limitFPSValue;
}

+ (void)setFPSValueHandler:(FPSCallbackHandler)FPSHandler {
    _FPSHandler = [FPSHandler copy];
}

@end
