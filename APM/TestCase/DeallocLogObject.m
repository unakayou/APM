//
//  DeallocLogObject.m
//  APM
//
//  Created by unakayou on 2022/3/16.
//

#import "DeallocLogObject.h"

@implementation DeallocLogObject
- (void)dealloc {
    NSLog(@"⚠️ %@ dealloc", self.name);
}
@end
