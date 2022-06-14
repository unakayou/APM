//
//  APMRegisterChecker.m
//  APM
//
//  Created by unakayou on 2022/4/29.
//

#import "APMRegisterChecker.h"
#import <mach/mach.h>
#import "APMDefines.h"

bool APMRegisterChecker::startPtrCheck() {
#if !TARGET_IPHONE_SIMULATOR
    thread_act_array_t thread_list;
    mach_msg_type_number_t thread_count;
    kern_return_t ret = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (ret != KERN_SUCCESS) {
        return false;
    }
    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        thread_t thread = thread_list[i];
        if(thread != mach_thread_self()){
            _STRUCT_MCONTEXT _mcontext;
            mach_msg_type_number_t stateCount = MY_EXCEPTION_STATE_COUNT;
            // 获取线程上下文,写入machineContext.__es中, 扩展段寄存器
            kern_return_t ret = thread_get_state(thread, MY_EXCEPITON_STATE, (thread_state_t)&_mcontext.__es, &stateCount);
            if (ret != KERN_SUCCESS) {
                return false;
            }
            // 有exception就返回
            if (_mcontext.__es.__exception != 0) {
                return false;
            }
            stateCount = MY_THREAD_STATE_COUTE;
            // 获取线程上下文,写入machineContext.ss中, ss: Stack Segment 栈段寄存器.内涵FP、LR、SP、PC...等寄存器
            ret = thread_get_state(thread, MY_THREAD_STATE, (thread_state_t)&_mcontext.__ss, &stateCount);
            if (ret != KERN_SUCCESS) {
                return false;
            }
#ifdef __LP64__
            vm_address_t x_regs[29];
            vm_size_t len = sizeof(x_regs);
            
            // 从目标进程"读取"内存, x0-x28
            ret = vm_read_overwrite(mach_task_self(), (vm_address_t)(_mcontext.__ss.__x),len, (vm_address_t)x_regs, &len);
            for(int i = 0; i < 29; i++) {
                // 看寄存器中地址是否存在与hashmap中
                leak_manager->findPtrInMemoryRegion((vm_address_t)x_regs[i]);
            }
#else
            vm_address_t r_regs[13];
            vm_size_t len = sizeof(r_regs);
            ret = vm_read_overwrite(mach_task_self(), (vm_address_t)(_mcontext.__ss.__r),len, (vm_address_t)r_regs, &len);
            for(int i = 0;i < 13;i++){
                leak_manager->findPtrInMemoryRegion((vm_address_t)r_regs[i]);
            }
#endif
        }
    }
    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        // 释放mach_thread_self(), 建议用:pthread_mach_thread_np(pthread_self())替代mach_thread_self（）
        mach_port_deallocate(mach_task_self(), thread_list[i]);
    }
    
    // 在指定任务的地址空间中释放虚拟内存区域
    vm_deallocate(mach_task_self(), (vm_address_t)thread_list, thread_count * sizeof(thread_t));
    return true;
#else
    return true;
#endif
}
