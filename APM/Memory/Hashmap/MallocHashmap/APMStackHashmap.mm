//
//  APMStackHashmap.m
//  APM
//
//  Created by unakayou on 2022/4/13.
//

#import "APMStackHashmap.h"
#import "APMStackWriter.h"

APMStackHashmap::APMStackHashmap(size_t entrys,
                                 malloc_zone_t *memory_zone,
                                 size_t functionLimitSize,
                                 NSString *path,
                                 size_t mmap_size) : APMBaseHashmap(entrys, memory_zone) {
                                     _stackWriter = new APMStackWriter();
                                     _functionLimitSize = functionLimitSize;
}

APMStackHashmap::~APMStackHashmap() {
    for(size_t i = 0; i < entry_num; i++){
        base_entry_t *entry = hashmap_entry + i;
        merge_stack_t *current = (merge_stack_t *)entry->root;
        entry->root = NULL;
        while(current != NULL){
            merge_stack_t *next = current->next;
            hashmap_free(current);
            current = next;
        }
    }
}

void APMStackHashmap::insertStackAndIncreaseCountIfExist(uint64_t digest,base_stack_t *stack, bool *functionOverLimit) {
    size_t offset = (size_t)digest % (entry_num - 1);
    base_entry_t *entry = hashmap_entry + offset;
    merge_stack_t *parent = (merge_stack_t *)entry->root;   // 下挂节点第一个
    access_num++;
    collision_num++;
    if(parent == NULL) {
        // 没有下挂节点
        merge_stack_t *insert_data = create_hashmap_data(digest,stack); // stack生成特定结构,准备放入hashMap
        entry->root = insert_data;
        // 直接达到"大内存"标准
        if(insert_data->size > _functionLimitSize) {
            insert_data->cache_flag = 1;
            _stackWriter->updateStack(insert_data, stack);
            *functionOverLimit = true;
        }
        record_num++;
        return;
    } else {
        // hash碰撞的是相同的堆栈信息,则只增加结构体里面的记数
        if(parent->digest == digest) {
            parent->count++;
            parent->size += stack->size;
            // 如果累积达到大内存标准
            if(parent->size > _functionLimitSize) {
                parent->cache_flag = 1;
                _stackWriter->updateStack(parent, stack);
                *functionOverLimit = true;
            }
            return;
        }
        
        // 如果不是相同堆栈,继续查链表
        merge_stack_t *current = parent->next;
        while(current != NULL){
            collision_num++;
            if(current->digest == digest){
                current->count++;
                current->size += stack->size;
                if(current->size > _functionLimitSize) {
                    current->cache_flag = 1;
                    _stackWriter->updateStack(current, stack);
                    *functionOverLimit = true;
                }
                return ;
            }
            parent = current;
            current = current->next;
        }
        
        // 没查询到,则新增
        merge_stack_t *insert_data = create_hashmap_data(digest,stack);
        parent->next = insert_data;
        current = parent->next;
        if(current->size > _functionLimitSize) {
            current->cache_flag = 1;
            _stackWriter->updateStack(current, stack);
            *functionOverLimit = true;
        }
        record_num++;
        return ;
    }
}

void APMStackHashmap::removeIfCountIsZero(uint64_t digest,uint32_t size,uint32_t count) {
    size_t offset = (size_t)digest % (entry_num - 1);
    base_entry_t *entry = hashmap_entry + offset;
    merge_stack_t *parent = (merge_stack_t *)entry->root;
    if(parent == NULL){
        return ;
    } else {
        if(parent->digest == digest) {
            // 减少对应堆栈的累积size
            if(parent->size < size) {
                parent->size = 0;
            } else {
                parent->size -= size;
            }
            
            // 减少对应堆栈累积次数
            if(parent->count < count){
                parent->count = 0;
            } else {
                parent->count -= count;
            }
            
            if(parent->cache_flag == 1) {
                if(parent->size < _functionLimitSize) {
                    _stackWriter->removeStack(parent,true);
                    parent->cache_flag = 0;
                } else {
                    _stackWriter->removeStack(parent,false);
                }
            }
            
            if(parent->count <= 0) {
                entry->root = parent->next;
                hashmap_free(parent);
                record_num--;
            }
            return;
        }
        
        merge_stack_t *current = parent->next;
        while(current != NULL){
            if(current->digest == digest){
                if(current->size < size) {
                    current->size = 0;
                } else {
                    current->size -= size;
                }
                
                if(current->count < count){
                    current->count = 0;
                } else {
                    current->count -= count;
                }
                
                if(current->cache_flag == 1) {
                    if(current->size < _functionLimitSize) {
                        _stackWriter->removeStack(current,true);
                        current->cache_flag = 0;
                    } else {
                        _stackWriter->removeStack(current,false);
                    }
                }
                
                if((current->count) <= 0) {
                    parent->next = current->next;
                    hashmap_free(current);
                    record_num--;
                }
                return ;
            }
            parent = current;
            current = current->next;
        }
    }
}

merge_stack_t *APMStackHashmap::lookupStack(uint64_t digest) {
    size_t offset = (size_t)digest%(entry_num - 1);
    base_entry_t *entry = hashmap_entry + offset;
    merge_stack_t *parent = (merge_stack_t *)entry->root;
    if(parent == NULL) {
        return NULL;
    } else {
        if(parent->digest == digest) {
            return parent;
        }
        merge_stack_t *current = parent->next;
        
        while(current != NULL) {
            if(current->digest == digest){
                return current;
            }
            parent = current;
            current = current->next;
        }
    }
    return NULL;
}

merge_stack_t *APMStackHashmap::create_hashmap_data(uint64_t digest,base_stack_t *stack) {
    merge_stack_t *merge_data = (merge_stack_t *)hashmap_malloc(sizeof(merge_stack_t));
    merge_data->digest = digest;
    merge_data->count = 1;
    merge_data->cache_flag = 0;
    merge_data->size = stack->size;
    merge_data->depth = 0;
    merge_data->next = NULL;
    return merge_data;
}


