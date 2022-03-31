//
//  APMMemoryManager.h
//  APM
//
//  Created by unakayou on 2022/3/23.
//
//  malloc统计管理器

#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <os/lock.h>
#import <stdio.h>
#import "APMAddressHashmap.h"

typedef void (^ChunkMallocBlock)(size_t bytes, NSString *stack);

class APMMallocManager {
public:
    APMMallocManager();
    ~APMMallocManager();
    
    /// 初始化logger
    /// @param path 存储mmap文件路径
    /// @param mmap_size mmap文件大小
    void initLogger(NSString *path, size_t mmap_size);

    /// malloc监控开始、停止
    /// @param threshholdInBytes 同一函数开辟空间累积阈值
    void startMallocStackMonitor(size_t threshholdInBytes);
    void stopMallocStackMonitor();

    /// 大内存开辟监控
    /// @param threshholdInBytes 单次大内存阈值
    /// @param mallocBlock 回调
    void startSingleChunkMallocDetector(size_t threshholdInBytes, ChunkMallocBlock mallocBlock);
    void stopSingleChunkMallocDetector();
    
    /// 记录内存开辟
    void recordMallocStack(vm_address_t address,uint32_t size,size_t stack_num_to_skip);
    
    /// 删除内存记录
    void removeMallocStack(vm_address_t address);
    
    BOOL enableMallocMonitor = NO;  // 开启malloc监控
private:
    /// 记录内存地址、大小...
    APMAddresshashmap *apmAddressHashmap = NULL;
    
    /// Hashmap锁
    os_unfair_lock hashmap_unfair_lock = OS_UNFAIR_LOCK_INIT;
};
