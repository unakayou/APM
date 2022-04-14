//
//  APMBaseHashmap.h
//  APM
//
//  Created by unakayou on 2022/3/23.
//
//  Hashmap基类

#import <malloc/malloc.h>

// 节点结构体
typedef struct base_entry_t {
    void *root;
} base_entry_t;

class APMBaseHashmap {
public:
    APMBaseHashmap(size_t entrys,malloc_zone_t *zone);
    virtual ~APMBaseHashmap();
    
    base_entry_t *getHashmapEntry();
    size_t getEntryNum();
    size_t getRecordNum();
    size_t getAccessNum();
    size_t getCollisionNum();
protected:
    void *hashmap_malloc(size_t size);
    void hashmap_free(void *ptr);
protected:
    base_entry_t *hashmap_entry;    // Hashmap入口
    size_t  entry_num;              // 容量
    size_t  record_num;             // 当前记录节点数量
    size_t  access_num;             // Hashmap尝试添加次数
    size_t  collision_num;          // Hash碰撞次数
    malloc_zone_t *malloc_zone;     // 将Hashmap开辟在这个zone中
};
