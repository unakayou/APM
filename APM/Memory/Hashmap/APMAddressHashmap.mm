//
//  APMAddressHashmap.m
//  APM
//
//  Created by unakayou on 2022/3/24.
//

#import "APMAddressHashmap.h"

APMAddresshashmap::~APMAddresshashmap() {
    for(size_t i = 0; i < entry_num; i++){
        base_entry_t *entry = hashmap_entry + i;
        ptr_log_t *current = (ptr_log_t *)entry->root;
        entry->root = NULL;
        while(current != NULL){
            ptr_log_t *next = current->next;
            hashmap_free(current);
            current = next;
        }
    }
}

// malloc地址指针入hashmap
BOOL APMAddresshashmap::insertPtr(vm_address_t addr,base_ptr_log *ptr_log) {
    size_t offset = addr % (entry_num - 1);
    base_entry_t *entry = hashmap_entry + offset;
    ptr_log_t *parent = (ptr_log_t *)entry->root;
    access_num++;
    collision_num++;
    if(parent == NULL) {
        ptr_log_t *insert_data = create_hashmap_data(addr, ptr_log);
        entry->root = insert_data;
        record_num++;
        return YES;
    } else {
        if(parent->address == addr){
            return NO;
        }
        ptr_log_t *current = parent->next;
        while(current != NULL){
            collision_num++;
            if(current->address == addr){
                return NO;
            }
            parent = current;
            current = current->next;
        }
        ptr_log_t *insert_data = create_hashmap_data(addr,ptr_log);
        parent->next = insert_data;
        record_num++;
        return YES;
    }
}

/// 删除指针
BOOL APMAddresshashmap::removePtr(vm_address_t addr, uint32_t *removeSize, uint64_t *removeDigest) {
    size_t offset = addr%(entry_num - 1);
    base_entry_t *entry = hashmap_entry + offset;
    ptr_log_t *parent = (ptr_log_t *)entry->root;
    if(parent == NULL) {
        return NO;
    } else {
        if(parent->address == addr) {
            entry->root = parent->next;
            if(removeSize && removeDigest){
                *removeSize = parent->size;
                *removeDigest = parent->digest;
            }
            hashmap_free(parent);
            record_num--;
            return YES;
        }
        ptr_log_t *current = parent->next;
        while(current != NULL) {
            if(current->address == addr) {
                parent->next = current->next;
                if(removeSize && removeDigest){
                    *removeSize = current->size;
                    *removeDigest = current->digest;
                }
                hashmap_free(current);
                record_num--;
                return YES;
            }
            parent = current;
            current = current->next;
        }
        return NO;
    }
}

/// 查找hashmap，以及下挂链表
ptr_log_t *APMAddresshashmap::lookupPtr(vm_address_t addr) {
    size_t offset = addr % (entry_num - 1);
    base_entry_t *entry = hashmap_entry + offset;
    ptr_log_t *parent = (ptr_log_t *)entry->root;
    if(parent != NULL) {
        if(parent->address == addr) {
            return parent;
        }
        ptr_log_t *current = parent->next;
        while(current != NULL) {
            if(current->address == addr){
                return current;
            }
            parent = current;
            current = current->next;
        }
    }
    return NULL;
}

ptr_log_t *APMAddresshashmap::create_hashmap_data(vm_address_t addr,base_ptr_log *base_ptr) {
    ptr_log_t *ptr_log = (ptr_log_t *)hashmap_malloc(sizeof(ptr_log_t));
    ptr_log->digest = base_ptr->digest;
    ptr_log->size = (uint32_t)base_ptr->size;
    ptr_log->address = addr;
    ptr_log->next = NULL;
    return ptr_log;
}
