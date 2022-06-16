//
//  APMObjcFilter.h
//  APM
//
//  Created by unakayou on 2022/5/13.
//
//  判断是否为OC对象

#import <Foundation/Foundation.h>
#import <unordered_set>
#import <malloc/malloc.h>

class CObjcFilter {
public:
    ~CObjcFilter();
    void initBlackClass();
    void updateCurrentClass();
    void clearCurrentClass();
    bool isClassInBlackList(Class cl);
    const char *getObjectNameExceptBlack(void *obj);
    const char *getObjectName(void *obj);
private:
    std::unordered_set<vm_address_t> *black_class_set = NULL;
    std::unordered_set<vm_address_t> *current_class_set = NULL;
};
