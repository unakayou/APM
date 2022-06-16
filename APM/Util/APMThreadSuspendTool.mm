//
//  APMThreadSuspendTool.m
//  APM
//
//  Created by unakayou on 2022/4/24.
//

#import "APMThreadSuspendTool.h"
#import <mach/mach.h>
#import <malloc/malloc.h>

bool suspendAllChildThreads() {
    thread_act_array_t thread_list = NULL;
    mach_msg_type_number_t thread_count = 0;
    kern_return_t ret = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (ret != KERN_SUCCESS) {
        return false;
    }
    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        thread_t thread = thread_list[i];
        if (thread == mach_thread_self()) {
            continue;
        }
        if (KERN_SUCCESS != thread_suspend(thread)) {
            for (mach_msg_type_number_t j = 0; j < i; j++){
                thread_t pre_thread = thread_list[j];
                if (pre_thread == mach_thread_self()) {
                    continue;
                }
                thread_resume(pre_thread);
            }
            for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
                mach_port_deallocate(mach_task_self(), thread_list[i]);
            }
            vm_deallocate(mach_task_self(), (vm_address_t)thread_list, thread_count * sizeof(thread_t));
            return false;
        }
    }
    return YES;
}

void resumeAllChildThreads() {
    thread_act_array_t thread_list = NULL;
    mach_msg_type_number_t thread_count = 0;
    kern_return_t ret = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (ret != KERN_SUCCESS) {
        return;
    }

    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        thread_t thread = thread_list[i];
        if (thread == mach_thread_self()) {
            continue;
        }
        if(thread_resume(thread) != KERN_SUCCESS) {
            malloc_printf("Can't resume thread:%lu\n",thread);
        }
    }
    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        mach_port_deallocate(mach_task_self(), thread_list[i]);
    }
    vm_deallocate(mach_task_self(), (vm_address_t)thread_list, thread_count * sizeof(thread_t));
    thread_list = NULL;
    thread_count = 0;
}
