//
//  APMStackDumper.h
//  APM
//
//  Created by unakayou on 2022/4/12.
//

#import <Foundation/Foundation.h>
#import <mach/vm_types.h>

#define MAX_STACK_DEPTH 64

// Image 信息结构体
typedef struct {
    const char* name;
    long loadAddr;
    long beginAddr;
    long endAddr;
} segImageInfo;

// App中的Image们
typedef struct AppImages {
    size_t size;
    segImageInfo **imageInfos;
} AppImages;

class APMStackDumper {
public:
    APMStackDumper();
    ~APMStackDumper();
    
    
    /// 生成堆栈信息
    /// @param needSystemStack 是否需要系统堆栈
    /// @param backtrace_to_skip 堆栈导出层数
    /// @param app_stack 堆栈地址
    /// @param digest 堆栈crc
    /// @param max_stack_depth 容器最大深度
    size_t recordBacktrace(bool needSystemStack,
                           size_t backtrace_to_skip,
                           vm_address_t **app_stack,
                           uint64_t *digest,
                           size_t max_stack_depth);
    
    
    /// 判断地址是否属于主模块
    /// @param address 地址
    bool isInAppAddress(vm_address_t address);
    
    /// 通过地址获取所属Image
    bool getImageByAddr(vm_address_t addr,segImageInfo *image);
    
private:
    AppImages allImages;    // 所有Image信息结构
};
