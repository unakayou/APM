//
//  NSTimer+DeallocLog.m
//  APM
//
//  Created by unakayou on 2022/3/16.
//

#import "NSObject+DeallocLog.h"
#import <objc/runtime.h>

@implementation NSObject (DeallocLog)
static char _deallocLogSentryKey;

- (DeallocLogObject *)deallocObject {
    return objc_getAssociatedObject(self, &_deallocLogSentryKey);
}

- (void)setDeallocObject:(DeallocLogObject *)object {
    objc_setAssociatedObject(self, &_deallocLogSentryKey, object, OBJC_ASSOCIATION_RETAIN);
}
@end
