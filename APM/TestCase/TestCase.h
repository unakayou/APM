//
//  OOMLauncher.h
//  APM
//
//  Created by unakayou on 2022/3/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^TestCaseBlock)(void);

@interface TestCase : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) TestCaseBlock caseBlock;

+ (NSArray <TestCase *>*)allTestCase;
@end

NS_ASSUME_NONNULL_END
