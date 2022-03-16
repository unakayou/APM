//
//  APMDeviceInfo.m
//  APM
//
//  Created by unakayou on 2022/3/15.
//

#import "APMDeviceInfo.h"
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>

@implementation APMDeviceInfo

+ (NSString *)systemVersion {
    return [UIDevice currentDevice].systemVersion;
}

+ (uint64_t)systemLaunchTimeStamp {
    NSTimeInterval time = [NSProcessInfo processInfo].systemUptime;
    NSDate *curDate = [[NSDate alloc] init];
    NSDate *startTime = [curDate dateByAddingTimeInterval:-time];
    return [startTime timeIntervalSince1970];
}

+ (NSTimeInterval)processStartTime {
    struct kinfo_proc kProcInfo;
    if ([self processInfoForPID:[[NSProcessInfo processInfo] processIdentifier] procInfo:&kProcInfo]) {
        NSTimeInterval timeStart = kProcInfo.kp_proc.p_un.__p_starttime.tv_sec * USEC_PER_SEC + kProcInfo.kp_proc.p_un.__p_starttime.tv_usec;
        NSTimeInterval timeNow = [[NSDate date] timeIntervalSince1970];
        return timeNow * USEC_PER_SEC - timeStart;
    } else {
        return 0;
    }
}

// sysctl():在运行时配置内核参数
+ (BOOL)processInfoForPID:(int)pid procInfo:(struct kinfo_proc*)procInfo {
    int cmd[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
    size_t size = sizeof(*procInfo);
    return sysctl(cmd, sizeof(cmd)/sizeof(*cmd), procInfo, &size, NULL, 0) == 0;
}

@end
