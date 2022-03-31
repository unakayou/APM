//
//  APMDefines.h
//  APM
//
//  Created by unakayou on 2022/3/21.
//

#ifndef APMDefines_h
#define APMDefines_h

#define APM_DEALLOC_LOG_SWITCH 0

#define stack_logging_type_free        0
#define stack_logging_type_generic    1    /* anything that is not allocation/deallocation */
#define stack_logging_type_alloc    2    /* malloc, realloc, etc... */
#define stack_logging_type_dealloc    4    /* free, realloc, etc... */
#define stack_logging_flag_zone        8    /* NSZoneMalloc, etc... */
#define stack_logging_type_vm_allocate  16      /* vm_allocate or mmap */
#define stack_logging_type_vm_deallocate  32    /* vm_deallocate or munmap */
#define stack_logging_type_mapped_file_or_shared_mem    128

#endif /* APMDefines_h */
