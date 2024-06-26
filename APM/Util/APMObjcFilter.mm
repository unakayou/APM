//
//  APMObjcFilter.m
//  APM
//
//  Created by unakayou on 2022/5/13.
//

#import "APMObjcFilter.h"
#import <objc/runtime.h>

#if __has_feature(objc_arc)
#error This file must be compiled without ARC. Use -fno-objc-arc flag.
#endif

#define ISA_MASK    0x0000000ffffffff8ULL

typedef struct{
    void* isa;
} objc_class_ptr;

CObjcFilter::~CObjcFilter() {
    if(black_class_set != NULL) {
        delete black_class_set;
    }
    
    if(current_class_set != NULL) {
        delete current_class_set;
    }
}

void CObjcFilter::initBlackClass() {
    black_class_set = new std::unordered_set<vm_address_t>();//__gnu_cxx::hash_set<vm_address_t>();
    current_class_set = new std::unordered_set<vm_address_t>();//__gnu_cxx::hash_set<vm_address_t>();
    int num = objc_getClassList(NULL, 0);
    if(num > 0) {
        Class *classList = (Class *)malloc(num * sizeof(Class));
        num = objc_getClassList(classList, num);
        for(int i = 0; i < num; i++) {
            const char* name = class_getName(classList[i]);
            if(name != NULL) {
                if((strncmp(name, "_", 1) == 0 && strncmp(name, "__NS", 4) != 0 && strncmp(name,"_NS",3) != 0) || strncmp(name,"__NSCFType",10) == 0) {
                    black_class_set->insert((vm_address_t)classList[i]);
                }
            }
        }
        free(classList);
    }
}

void CObjcFilter::updateCurrentClass() {
    int num = objc_getClassList(NULL, 0);
    if(num > 0) {
        Class *classList = (Class *)malloc(num * sizeof(Class));
        num = objc_getClassList(classList, num);
        for(int i = 0; i < num; i++) {
            current_class_set->insert((vm_address_t)classList[i]);
        }
        free(classList);
    }
}

void CObjcFilter::clearCurrentClass() {
    current_class_set->clear();
}

bool CObjcFilter::isClassInBlackList(Class cl) {
    auto it = black_class_set->find((vm_address_t)cl);
    if(it != black_class_set->end()) {
        return true;
    }
    return false;
}

const char *CObjcFilter::getObjectNameExceptBlack(void *obj) {
    objc_class_ptr *objc_ptr = (objc_class_ptr *)obj;
    Class isa = (Class)((vm_address_t)objc_ptr->isa & ISA_MASK);
    if(isClassInBlackList(isa)) {
        return NULL;
    }
    auto it = current_class_set->find((vm_address_t)isa);
    if(it != current_class_set->end()) {
        return class_getName(isa);
    }
    return NULL;
}

const char *CObjcFilter::getObjectName(void *obj) {
    objc_class_ptr *objc_ptr = (objc_class_ptr *)obj;
    Class isa = (Class)((vm_address_t)objc_ptr->isa & ISA_MASK);
    auto it = current_class_set->find((vm_address_t)isa);
    if(it != current_class_set->end()) {
        return class_getName(isa);
    }
    return NULL;
}
