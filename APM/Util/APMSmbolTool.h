//
//  APMSmbolTool.h
//  APM
//
//  Created by unakayou on 2022/6/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface APMSmbolTool : NSObject
+ (NSString *)addressToSmbol:(const uintptr_t * const)backtraceBuffer depth:(int)depth;
@end

NS_ASSUME_NONNULL_END
