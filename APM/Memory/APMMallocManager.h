//
//  APMMemoryManager.h
//  APM
//
//  Created by unakayou on 2022/3/23.
//
//  malloc统计管理器

#import <Foundation/Foundation.h>

#import "APMAddressHashmap.h"
#import "APMStackHashmap.h"
#import "APMStackDumper.h"

#import <mach/mach.h>
#import <os/lock.h>
#import <stdio.h>

typedef void (^MallocChunkCallback)(size_t bytes, NSString *stack);

class APMMallocManager {
public:
    /// 一次性开辟大块内存, 不纳入malloc统计
    APMMallocManager();
    ~APMMallocManager();
    
    /// 初始化写入位置, 内存映射大小
    /// @param path 存储mmap文件路径
    /// @param mmap_size mmap映射大小
    void setWriterParamarters(NSString *path, size_t mmap_size);

    /// malloc() 单独函数累积开辟内存阈值
    /// @param funcLimitSize 阈值大小
    void setMallocFuncLimitSize(size_t funcLimitSize);

    /// malloc() 单次内存阈值设置
    /// @param singleLimitSize 阈值大小
    /// @param mallocBlock 单次触顶回调
    void setSingleMallocLimitSize(size_t singleLimitSize, MallocChunkCallback mallocBlock);
    
    /// 重新开始记录malloc
    void startMallocManager(void);
    
    /// 停止记录malloc, 已记录内容清空
    void stopMallocManager(void);
    
    /// malloc_logger()  记录内存开辟
    void recordMallocStack(vm_address_t address,uint32_t size,size_t stack_num_to_skip);
    
    /// malloc_logger() 删除内存记录
    void removeMallocStack(vm_address_t address);
    
    /// 获取 malloc_manager 使用的内存块地址.用于 malloc_logger 中过滤可能来自自身内存申请.
    uintptr_t getMemoryZone();
private:
    /// 同一函数累积开辟内存阈值
    size_t _funcLimitSize;
    
    /// 单次内存阈值
    size_t _singleLimitSize;
    
    /// 单次触顶回调
    MallocChunkCallback _mallocBlock = nil;
    
    /// mmap文件路径
    NSString *_logPath = nil;
    
    /// mmap映射尺寸
    size_t _logMmapSize = 0;
    
    /// 堆栈导出工具
    APMStackDumper *_stackDumper;
    
    /// MallocLogger所需要的HashMap开辟在这里,不统计此zone中的内存变化
    malloc_zone_t *g_apmHashmapZone = NULL;

    /// Key:  地址
    APMAddresshashmap *_apmAddressHashmap = NULL;
    
    /// Key: 堆栈CRC
    APMStackHashmap *_apmStackHashmap = NULL;
    
    /// Hashmap锁
    os_unfair_lock _hashmap_unfair_lock = OS_UNFAIR_LOCK_INIT;
};
