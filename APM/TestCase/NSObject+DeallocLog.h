//
//  NSTimer+DeallocLog.h
//  APM
//
//  Created by unakayou on 2022/3/16.
//
//  测试对象释放

#import <Foundation/Foundation.h>
#import "DeallocLogObject.h"
#import "APMDefines.h"

#if APM_DEALLOC_LOG_SWITCH
NS_ASSUME_NONNULL_BEGIN
@interface NSObject (DeallocLog)
@property (nonatomic, strong) DeallocLogObject *deallocObject;
@end
NS_ASSUME_NONNULL_END
#endif
