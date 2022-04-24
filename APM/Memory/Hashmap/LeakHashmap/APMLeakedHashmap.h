//
//  APMLeakedHashmap.h
//  APM
//
//  Created by unakayou on 2022/4/21.
//
//  发现的泄漏内存保存于此

#import "APMBaseHashmap.h"

// 泄漏的节点
typedef struct leaked_ptr_t{
    uint64_t digest;      
    uint32_t leak_count;
    vm_address_t address;
    leaked_ptr_t *next;
} leaked_ptr_t;

class APMLeakedHashmap : public APMBaseHashmap {
public:
    APMLeakedHashmap(size_t entrys,malloc_zone_t *memory_zone):APMBaseHashmap(entrys,memory_zone){};
    ~APMLeakedHashmap();
    
    // 添加泄漏空间指针
    void insertLeakPtrAndIncreaseCountIfExist(uint64_t digest, ptr_log_t *ptr_log);
    
protected:
    leaked_ptr_t *create_hashmap_data(uint64_t digest,ptr_log_t *ptr_log);
    int compare(leaked_ptr_t *leak_ptr,uint64_t digest);
    size_t hash_code(uint64_t digest);
};
