//
//  APMAddressHashmap.h
//  APM
//
//  Created by unakayou on 2022/3/24.
//
//  记录malloc空间地址

#import <Foundation/Foundation.h>
#import "APMBaseHashmap.h"

// 外面传进来的指针crc + size
typedef struct base_ptr_log{
    uint64_t digest;        // rapid_crc64
    uint64_t size;          // 占用空间
} base_ptr_log;

// 下挂链表结构体
typedef struct ptr_log_t{
    uint64_t digest;        // rapid_crc64
    uint32_t size;          // 占用空间
    vm_address_t address;
    ptr_log_t *next;
} ptr_log_t;

class APMAddresshashmap : public APMBaseHashmap {
public:
    APMAddresshashmap(size_t entrys,malloc_zone_t *memory_zone):APMBaseHashmap(entrys,memory_zone){};
    ~APMAddresshashmap();

    BOOL insertPtr(vm_address_t addr,base_ptr_log *ptr_log);
    BOOL removePtr(vm_address_t addr,uint32_t *removeSize, uint64_t *removeDigest);
    ptr_log_t *lookupPtr(vm_address_t addr);
protected:
    ptr_log_t *create_hashmap_data(vm_address_t addr,base_ptr_log *base_ptr);
};
