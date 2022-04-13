//
//  APMAddressHashmap.h
//  APM
//
//  Created by unakayou on 2022/3/24.
//
//  key: address, 用于地址角度分析内存

#import "APMBaseHashmap.h"

// 外面传进来的指针crc + size
typedef struct base_ptr_log {
    uint64_t digest;        // rapid_crc64
    uint64_t size;          // 开辟内存占用空间
    uint32_t depth;         // 堆栈深度
    vm_address_t **stack;   // 堆栈数组
} base_ptr_log;

// 下挂链表结构体, 不需要:堆栈数组、堆栈深度、
typedef struct ptr_log_t{
    uint64_t digest;        // rapid_crc64
    uint32_t size;          // 开辟内存占用空间
    vm_address_t address;   // 空间地址
    uint32_t count;         // 开辟数量
    
    ptr_log_t *next;        // 链表下一个
} ptr_log_t;

class APMAddresshashmap : public APMBaseHashmap {
public:
    APMAddresshashmap(size_t entrys,malloc_zone_t *memory_zone):APMBaseHashmap(entrys, memory_zone){};
    ~APMAddresshashmap();

    BOOL insertPtr(vm_address_t addr,base_ptr_log *ptr_log);
    BOOL removePtr(vm_address_t addr,uint32_t *removeSize, uint64_t *removeDigest);
    ptr_log_t *lookupPtr(vm_address_t addr);
protected:
    ptr_log_t *create_hashmap_data(vm_address_t addr,base_ptr_log *base_ptr);
};
