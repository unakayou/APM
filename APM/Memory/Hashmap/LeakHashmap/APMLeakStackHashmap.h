//
//  APMLeakStackHashmap.h
//  APM
//
//  Created by unakayou on 2022/4/21.
//
//  统计泄漏时,保存所有堆栈详情

#import "APMBaseHashmap.h"

typedef struct extra_t {
    const char      *name;
    uint32_t        size;
}extra_t;

// 泄漏堆栈(对外)
typedef struct base_leaked_stack_t {
    uint16_t            depth;
    vm_address_t        **stack;
    extra_t             extra;
}base_leaked_stack_t;

// 泄漏堆栈
typedef struct merge_leaked_stack_t {
    uint64_t                digest;
    uint32_t                depth;
    uint32_t                count;
    vm_address_t            **stack;
    merge_leaked_stack_t    *next;
    extra_t                 extra;
} merge_leaked_stack_t;

class APMLeakStackHashmap : public APMBaseHashmap {
public:
    APMLeakStackHashmap(size_t entrys, malloc_zone_t *memory_zone) : APMBaseHashmap(entrys, memory_zone){};
    ~APMLeakStackHashmap();
    
    void insertStackAndIncreaseCountIfExist(uint64_t digest,base_leaked_stack_t *stack);
    void removeIfCountIsZero(uint64_t digest, size_t size);
    merge_leaked_stack_t *lookupStack(uint64_t digest);
    
protected:
    merge_leaked_stack_t *create_hashmap_data(uint64_t digest,base_leaked_stack_t *stack);
};
