//
//  APMStackHashmap.h
//  APM
//
//  Created by unakayou on 2022/4/13.
//
//  存储堆栈摘要,统计大内存开辟.(为何stackMap不能用在leakMap: 因为leakMap需要保存堆栈详细信息,会成倍增加内存占用)

#import "APMBaseHashmap.h"

class APMStackWriter;

typedef struct base_stack_t {
    uint32_t            depth;
    vm_address_t        **stack;
    uint32_t            size;
} base_stack_t;

typedef struct merge_stack_t {
    uint64_t            digest;
    uint32_t            depth;
    uint32_t            count;
    uint32_t            cache_flag;
    uint32_t            size;
    struct merge_stack_t       *next;
} merge_stack_t;

class APMStackHashmap : public APMBaseHashmap {
public:
    APMStackHashmap(size_t entrys, malloc_zone_t *memory_zone, size_t functionLimitSize, NSString *path, size_t mmap_size);
    ~APMStackHashmap();
    
    void insertStackAndIncreaseCountIfExist(uint64_t digest, base_stack_t *stack, bool *functionOverLimit);
    void removeIfCountIsZero(uint64_t digest,uint32_t size,uint32_t count);
    merge_stack_t *lookupStack(uint64_t digest);
protected:
    merge_stack_t *create_hashmap_data(uint64_t digest,base_stack_t *stack);
private:
    size_t _functionLimitSize;
    APMStackWriter *_stackWriter;
};
