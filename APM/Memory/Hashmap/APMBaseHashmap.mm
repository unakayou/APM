//
//  APMBaseHashmap.m
//  APM
//
//  Created by unakayou on 2022/3/23.
//

#import "APMBaseHashmap.h"

APMBaseHashmap::APMBaseHashmap(size_t entrys,malloc_zone_t *zone) {
    entry_num = entrys;
    malloc_zone = zone;
    hashmap_entry = (base_entry_t *)hashmap_malloc((entry_num)*sizeof(base_entry_t));
    for(size_t i = 0; i < entry_num;i++){
        base_entry_t *entry_tmp = hashmap_entry + i;
        entry_tmp->root = NULL;
    }
    record_num = 0;
    access_num = 0;
    collision_num = 0;
}

APMBaseHashmap::~APMBaseHashmap() {
    hashmap_free(hashmap_entry);
}

void *APMBaseHashmap::hashmap_malloc(size_t size) {
    return malloc_zone->malloc(malloc_zone,size);
}

void APMBaseHashmap::hashmap_free(void *ptr) {
    malloc_zone->free(malloc_zone, ptr);
}

base_entry_t *APMBaseHashmap::getHashmapEntry() {
    return hashmap_entry;
}

size_t APMBaseHashmap::getEntryNum() {
    return entry_num;
}

size_t APMBaseHashmap::getRecordNum() {
    return record_num;
}

size_t APMBaseHashmap::getAccessNum() {
    return access_num;
}

size_t APMBaseHashmap::getCollisionNum() {
    return collision_num;
}
