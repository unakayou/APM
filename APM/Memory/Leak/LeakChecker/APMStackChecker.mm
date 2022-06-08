//
//  APMStackChecker.m
//  APM
//
//  Created by unakayou on 2022/4/24.
//

#import "APMStackChecker.h"
#import <mach/mach.h>
#import <pthread.h>
#import "APMDefines.h"

void APMStackChecker::startPtrCheck(size_t bt) {
    thread_act_array_t thread_list;
    mach_msg_type_number_t thread_count;
    // 获取当前进程线程
    kern_return_t ret = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (ret != KERN_SUCCESS) {
        return;
    }
    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        thread_t thread = thread_list[i];
        
        // mach_thread 转 pthread
        pthread_t pthread = pthread_from_mach_thread_np(thread);
        // 获取线程堆栈大小
        vm_size_t stacksize = pthread_get_stacksize_np(pthread);
        if(stacksize > 0) {
            // 栈底地址
            void *stack = pthread_get_stackaddr_np(pthread);
            if(stack != NULL){
                vm_address_t stack_ptr = 0;
                if(thread == mach_thread_self()) {
                    // 获取FP
                    find_thread_fp(thread, &stack_ptr, bt);
                } else {
                    // 获取SP
                    find_thread_sp(thread, &stack_ptr);
                }
                
                // 获取栈已用深度
                vm_size_t depth = (vm_address_t)stack - stack_ptr + 1;
                if(depth > 0 && depth <= stacksize) {
                    // 栈已用范围
                    vm_range_t range = {stack_ptr,depth};
                    
                    // 遍历栈中所有位置的指针，去记录开辟内存的hashmap中查找
                    check_ptr_in_vmrange(range);
                }
            }
        }
    }
    
    // 释放
    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        mach_port_deallocate(mach_task_self(), thread_list[i]);
    }
    vm_deallocate(mach_task_self(), (vm_address_t)thread_list, thread_count * sizeof(thread_t));
}

bool APMStackChecker::find_thread_sp(thread_t thread,vm_address_t *sp) {
#if !TARGET_IPHONE_SIMULATOR
    mach_msg_type_number_t stateCount = MY_THREAD_STATE_COUTE;
    _STRUCT_MCONTEXT _mcontext;
    kern_return_t ret = thread_get_state(thread, MY_THREAD_STATE, (thread_state_t)&_mcontext.__ss, &stateCount);
    
    if (ret != KERN_SUCCESS) {
        return false;
    }
    stateCount = MY_EXCEPTION_STATE_COUNT;
    ret = thread_get_state(thread, MY_EXCEPITON_STATE, (thread_state_t)&_mcontext.__es, &stateCount);
    
    if (ret != KERN_SUCCESS) {
        return false;
    }
    
    if (_mcontext.__es.__exception != 0) {
        return false;
    }
    *sp = (vm_address_t)_mcontext.__ss.__sp;
    return true;
#else
    return false;
#endif
}

bool APMStackChecker::find_thread_fp(thread_t thread,vm_address_t *fp,size_t bt_count) {
#if !TARGET_IPHONE_SIMULATOR
    mach_msg_type_number_t stateCount = MY_THREAD_STATE_COUTE;
    _STRUCT_MCONTEXT _mcontext;
    kern_return_t ret = thread_get_state(thread, MY_THREAD_STATE, (thread_state_t)&_mcontext.__ss, &stateCount);
    
    if (ret != KERN_SUCCESS) {
        return false;
    }
    stateCount = MY_EXCEPTION_STATE_COUNT;
    ret = thread_get_state(thread, MY_EXCEPITON_STATE, (thread_state_t)&_mcontext.__es, &stateCount);
    
    if (ret != KERN_SUCCESS) {
        return false;
    }
    
    if (_mcontext.__es.__exception != 0) {
        return false;
    }
    vm_size_t len = sizeof(fp);
#ifdef __LP64__
    ret = vm_read_overwrite(mach_task_self(), (vm_address_t)(_mcontext.__ss.__fp),len, (vm_address_t)fp, &len);

#else
    ret = vm_read_overwrite(mach_task_self(), (vm_address_t)(_mcontext.__ss.__r[7]),len, (vm_address_t)fp, &len);
#endif
    if (ret != KERN_SUCCESS) {
        return false;
    }
    ret = vm_read_overwrite(mach_task_self(), *fp,len, (vm_address_t)fp, &len);
    if (ret != KERN_SUCCESS) {
        return false;
    }
    for(size_t i=0;i < bt_count;i++){
        ret = vm_read_overwrite(mach_task_self(), *fp,len, (vm_address_t)fp, &len);
    }
    if (ret != KERN_SUCCESS) {
        return false;
    }
    return true;
#else
    return false;
#endif
}

