//
//  APMStackHashmap.m
//  APM
//
//  Created by unakayou on 2022/4/13.
//

#import "APMStackHashmap.h"

APMStackHashmap::APMStackHashmap(size_t entrys,
                                 malloc_zone_t *memory_zone,
                                 size_t limitSize,
                                 NSString *path,
                                 size_t mmap_size):APMBaseHashmap(entrys,memory_zone) {
                                     _limitSize = limitSize;
}

APMStackHashmap::~APMStackHashmap() {
    
}

void APMStackHashmap::insertStackAndIncreaseCountIfExist(uint64_t digest,base_stack_t *stack) {
    
}

void APMStackHashmap::removeIfCountIsZero(uint64_t digest,uint32_t size,uint32_t count) {
    
}
