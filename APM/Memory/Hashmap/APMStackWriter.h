//
//  APMStackWriter.h
//  APM
//
//  Created by unakayou on 2022/4/14.
//

#import "APMStackHashmap.h"

class APMStackWriter {
public:
    APMStackWriter();
    ~APMStackWriter();
    
    void updateStack(merge_stack_t *current, base_stack_t *stack);
    void removeStack(merge_stack_t *current,bool needRemove);
};
