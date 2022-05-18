//
//  APMLeakedHashmap.m
//  APM
//
//  Created by unakayou on 2022/4/21.
//

#import "APMLeakedHashmap.h"

// 销毁所有节点
APMLeakedHashmap::~APMLeakedHashmap() {
    for(size_t i = 0; i < entry_num; i++) {
        base_entry_t *entry = hashmap_entry + i;
        leaked_ptr_t *current = (leaked_ptr_t *)entry->root;
        entry->root = NULL;
        while(current != NULL) {
            leaked_ptr_t *next = current->next;
            hashmap_free(current);
            current = next;
        }
    }
}

// 添加泄漏节点
void APMLeakedHashmap::insertLeakPtrAndIncreaseCountIfExist(uint64_t digest, ptr_log_t *ptr_log) {
    size_t offset = hash_code(digest);
    base_entry_t *entry = hashmap_entry + offset;
    leaked_ptr_t *parent = (leaked_ptr_t *)entry->root;
    access_num++;
    collision_num++;
    if(parent == NULL) {
        leaked_ptr_t *insert_data = create_hashmap_data(digest, ptr_log);
        entry->root = insert_data;
        record_num++;
        return ;
    } else {
        if(compare(parent, digest) == 0) {
            parent->leak_count++;
            parent->address = ptr_log->address;
            return;
        }
        leaked_ptr_t *current = parent->next;
        while(current != NULL) {
            collision_num++;
            if(compare(current, digest) == 0) {
                current->leak_count++;
                current->address = ptr_log->address;
                return ;
            }
            parent = current;
            current = current->next;
        }
        leaked_ptr_t *insert_data = create_hashmap_data(digest,ptr_log);
        parent->next = insert_data;
        record_num++;
        return;
    }
}

leaked_ptr_t *APMLeakedHashmap::create_hashmap_data(uint64_t digest,ptr_log_t *ptr_log) {
    leaked_ptr_t *leak_ptr = (leaked_ptr_t *)hashmap_malloc(sizeof(leaked_ptr_t));
    leak_ptr->digest = digest;
    vm_address_t address = (vm_address_t)(0x100000000 | ptr_log->address);
    leak_ptr->address = address;
    leak_ptr->leak_count = 1;
    leak_ptr->next = NULL;
    return leak_ptr;
}

int APMLeakedHashmap::compare(leaked_ptr_t *leak_ptr,uint64_t digest) {
    if(leak_ptr->digest == digest) return 0;
    return -1;
}

size_t APMLeakedHashmap::hash_code(uint64_t digest) {
    size_t offset = (size_t)digest%(entry_num - 1);
    return offset;
}



