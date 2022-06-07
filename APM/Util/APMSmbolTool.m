//
//  APMSmbolTool.m
//  APM
//
//  Created by unakayou on 2022/6/7.
//

#import "APMSmbolTool.h"
#import <mach/mach.h>
#include <dlfcn.h>
#include <pthread.h>
#include <sys/types.h>
#include <limits.h>
#include <string.h>
#include <mach-o/dyld.h>
#include <mach-o/nlist.h>

#if defined(__arm64__)
#define DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(3UL))
#define CrashTHREAD_STATE_COUNT ARM_THREAD_STATE64_COUNT
#define CrashTHREAD_STATE ARM_THREAD_STATE64
#define CrashFRAME_POINTER __fp
#define CrashSTACK_POINTER __sp
#define CrashINSTRUCTION_ADDRESS __pc

#elif defined(__arm__)
#define DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(1UL))
#define CrashTHREAD_STATE_COUNT ARM_THREAD_STATE_COUNT
#define CrashTHREAD_STATE ARM_THREAD_STATE
#define CrashFRAME_POINTER __r[7]
#define CrashSTACK_POINTER __sp
#define CrashINSTRUCTION_ADDRESS __pc

#elif defined(__x86_64__)
#define DETAG_INSTRUCTION_ADDRESS(A) (A)
#define CrashTHREAD_STATE_COUNT x86_THREAD_STATE64_COUNT
#define CrashTHREAD_STATE x86_THREAD_STATE64
#define CrashFRAME_POINTER __rbp
#define CrashSTACK_POINTER __rsp
#define CrashINSTRUCTION_ADDRESS __rip

#elif defined(__i386__)
#define DETAG_INSTRUCTION_ADDRESS(A) (A)
#define CrashTHREAD_STATE_COUNT x86_THREAD_STATE32_COUNT
#define CrashTHREAD_STATE x86_THREAD_STATE32
#define CrashFRAME_POINTER __ebp
#define CrashSTACK_POINTER __esp
#define CrashINSTRUCTION_ADDRESS __eip

#endif

#define CALL_INSTRUCTION_FROM_RETURN_ADDRESS(A) (DETAG_INSTRUCTION_ADDRESS((A)) - 1)

/*
    struct nlist_64 {
    union {
        uint32_t n_strx;   // index into the string table
    } n_un;
    uint8_t  n_type;       // type flag, see below
    uint8_t  n_sect;       // section number or NO_SECT 符号所在的 section index
    uint16_t n_desc;       // see <mach-o/stab.h>
    uint64_t n_value;      // value of this symbol (or stab offset) 符号的地址值
    };
 */
#if defined(__LP64__)
#define TRACE_FMT         "%-4d%-31s 0x%016lx %s + %lu"
#define POINTER_FMT       "0x%016lx"
#define POINTER_SHORT_FMT "0x%lx"
#define CrashNLIST struct nlist_64
#else
#define TRACE_FMT         "%-4d%-31s 0x%08lx %s + %lu"
#define POINTER_FMT       "0x%08lx"
#define POINTER_SHORT_FMT "0x%lx"
#define CrashNLIST struct nlist
#endif

@implementation APMSmbolTool

// ???
+ (NSString *)addressToSmbol:(const uintptr_t )address addreddNum:(const int) num {
    Dl_info *dlInfo;
    return CrashlogBacktraceEntry(num, address, dlInfo);
}

+ (NSString *)addressToSmbol:(const uintptr_t * const)backtraceBuffer depth:(int)depth {
    int backtraceLength = depth;
    Dl_info symbolicated[backtraceLength];
    Crashsymbolicate(backtraceBuffer, symbolicated, backtraceLength, 0);
    NSMutableString *stackString = [[NSMutableString alloc] init];
    for (int i = 0; i < backtraceLength; ++i) {
        [stackString appendFormat:@"%d %@", i, CrashlogBacktraceEntry(i, backtraceBuffer[i], &symbolicated[i])];
    }
    [stackString appendFormat:@"\n"];
    return stackString;
}

/// 地址转符号字符串
/// @param backtraceBuffer 栈数据数组
/// @param symbolsBuffer 空数组
/// @param numEntries 栈数据长度
/// @param skippedEntries = 0
void Crashsymbolicate(const uintptr_t *const backtraceBuffer, Dl_info *const symbolsBuffer, const int numEntries, const int skippedEntries) {
    int i = 0;
    // 第一个存储的是PC寄存器
    if(!skippedEntries && i < numEntries) {
        Crashdladdr(backtraceBuffer[i], &symbolsBuffer[i]);
        i++;
    }
    // 后面存储的都是LR
    for(; i < numEntries; i++) {
        Crashdladdr(CALL_INSTRUCTION_FROM_RETURN_ADDRESS(backtraceBuffer[i]), &symbolsBuffer[i]);
    }
}

/// 找到LR指针最近的符号, 放到 info 中
bool Crashdladdr(const uintptr_t address, Dl_info* const info) {
    info->dli_fname = NULL;
    info->dli_fbase = NULL;
    info->dli_sname = NULL;
    info->dli_saddr = NULL;
    
    const uint32_t idx = CrashimageIndexContainingAddress(address); // 获取address所在的image序号
    if(idx == UINT_MAX) {
        return false;
    }
    const struct mach_header* header = _dyld_get_image_header(idx);                     // 获取映像的mach-o头部信息结构体指针, header对象存储load command个数及大小
    const uintptr_t imageVMAddrSlide = (uintptr_t)_dyld_get_image_vmaddr_slide(idx);    // slide.
    const uintptr_t addressWithSlide = address - imageVMAddrSlide;                      // LR虚拟内存地址
    const uintptr_t segmentBase = CrashsegmentBaseOfImageIndex(idx) + imageVMAddrSlide; // vmaddr - fileoff + slide
    if(segmentBase == 0) {
        return false;
    }
    
    info->dli_fname = _dyld_get_image_name(idx);
    info->dli_fbase = (void*)header;
    
    // Find symbol tables and get whichever symbol is closest to the address.
    const CrashNLIST* bestMatch = NULL;
    uintptr_t bestDistance = ULONG_MAX;
    uintptr_t cmdPtr = CrashfirstCmdAfterHeader(header);    // Load Commands
    if(cmdPtr == 0) {
        return false;
    }
    
    // 遍历Load Commands,找到 LC_SYMTAB 段
    for(uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++) {
        const struct load_command* loadCmd = (struct load_command*)cmdPtr;
        if(loadCmd->cmd == LC_SYMTAB) {
            const struct symtab_command* symtabCmd = (struct symtab_command*)cmdPtr;        // LC_SYMTAB,内含符号表位于可执行文件的偏移以及字符串表位于可执行文件的偏移
            const CrashNLIST* symbolTable = (CrashNLIST*)(segmentBase + symtabCmd->symoff); // 符号表内存真实地址, symoff 为符号表在 Mach-O 文件中的偏移
            const uintptr_t stringTable = segmentBase + symtabCmd->stroff;                  // 字符串表内存真实地址, stroff 为字符串表在 Mach-O 文件中的偏移
            
            // 遍历所有符号,找到与LR最近的那个
            for(uint32_t iSym = 0; iSym < symtabCmd->nsyms; iSym++) {           //nsyms指示了符号表的条目
                // If n_value is 0, the symbol refers to an external object.
                if(symbolTable[iSym].n_value != 0) {
                    uintptr_t symbolBase = symbolTable[iSym].n_value;           // n_value 符号的虚拟内存地址值
                    uintptr_t currentDistance = addressWithSlide - symbolBase;  // LR与符号的距离
                    if((addressWithSlide >= symbolBase) && (currentDistance <= bestDistance)) { // 函数地址值在本符号之后 且 距离小于之前的最近距离
                        bestMatch = symbolTable + iSym; // 最匹配的符号 = 当前符号表结构体 + n个偏移
                        bestDistance = currentDistance; // 最近距离 = 当前距离
                    }
                }
            }
            if(bestMatch != NULL) {
                info->dli_saddr = (void*)(bestMatch->n_value + imageVMAddrSlide);                       // 符号真实地址 = n_value + slide
                info->dli_sname = (char*)((intptr_t)stringTable + (intptr_t)bestMatch->n_un.n_strx);    // 字符真实地址 = 字符串表地址 + 最接近的符号中的字符串表(数组)索引值 n_strx(输出从此处到下一个null)
                if(*info->dli_sname == '_') {
                    info->dli_sname++;
                }
                // This happens if all symbols have been stripped.
                if(info->dli_saddr == info->dli_fbase && bestMatch->n_type == 3) {
                    info->dli_sname = NULL;
                }
                break;
            }
        }
        cmdPtr += loadCmd->cmdsize;
    }
    return true;
}

// 遍历loadCommands，确认adress是否落在当前image的某个segment中. address: LR地址
uint32_t CrashimageIndexContainingAddress(const uintptr_t address) {
    const uint32_t imageCount = _dyld_image_count();    // 返回当前进程中加载的映像的数量
    const struct mach_header* header = 0;
    // 遍历image
    for(uint32_t iImg = 0; iImg < imageCount; iImg++) {
        header = _dyld_get_image_header(iImg);  // 得到image_header
        if(header != NULL) {
            // Look for a segment command with this address within its range.
            uintptr_t addressWSlide = address - (uintptr_t)_dyld_get_image_vmaddr_slide(iImg);  // 得到减去ASLR之后的地址.在mach-o中真实地址
            uintptr_t cmdPtr = CrashfirstCmdAfterHeader(header);                                // 得到Header下面第一个loadCommands的地址
            if(cmdPtr == 0) {
                continue;
            }
            
            // ncmds: loadcommands的数量.
            for(uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++) {
                const struct load_command* loadCmd = (struct load_command*)cmdPtr;
                if(loadCmd->cmd == LC_SEGMENT) {            // command 类型为 LC_SEGMENT, 使用结构体segment_command
                    const struct segment_command* segCmd = (struct segment_command*)cmdPtr;
                    if(addressWSlide >= segCmd->vmaddr && addressWSlide < segCmd->vmaddr + segCmd->vmsize) {
                        return iImg;    // 如果LR的地址落在这个模块里,则返回映像索引号
                    }
                } else if(loadCmd->cmd == LC_SEGMENT_64) {  // command 类型为 LC_SEGMENT_64
                    const struct segment_command_64* segCmd = (struct segment_command_64*)cmdPtr;
                    if(addressWSlide >= segCmd->vmaddr && addressWSlide < segCmd->vmaddr + segCmd->vmsize) {
//                        CrashLogDebug(@"当前LR位置: %d - %s", iImg, _dyld_get_image_name(iImg));
                        return iImg;    // 如果LR的地址落在这个模块里,则返回映像索引号
                    }
                }
                cmdPtr += loadCmd->cmdsize; // command地址是连续的,移动到下一个command位置
            }
        }
    }
    return UINT_MAX;
}

/*
 *  sym_vmaddr(符号表虚拟地址) - vmaddr(LINKEDIT虚拟地址) = symoff(符号表文件地址) - fileoff(LINKEDIT文件地址)
 *  sym_vmaddr = vmaddr - fileoff + symoff
 *  因为 符号表内存真实地址 = sym_vmaddr + slide
 *  所以 符号表真实内存地址 = vmaddr - fileoff + symoff + slide
 *  此函数只为计算 vmaddr - fileoff
 */
uintptr_t CrashsegmentBaseOfImageIndex(const uint32_t idx) {
    const struct mach_header* header = _dyld_get_image_header(idx);
    
    // Look for a segment command and return the file image address.
    uintptr_t cmdPtr = CrashfirstCmdAfterHeader(header);
    if(cmdPtr == 0) {
        return 0;
    }
    for(uint32_t i = 0;i < header->ncmds; i++) {
        const struct load_command* loadCmd = (struct load_command*)cmdPtr;
        if(loadCmd->cmd == LC_SEGMENT) {
            const struct segment_command* segmentCmd = (struct segment_command*)cmdPtr;
            if(strcmp(segmentCmd->segname, SEG_LINKEDIT) == 0) {
                return segmentCmd->vmaddr - segmentCmd->fileoff;
            }
        }
        else if(loadCmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* segmentCmd = (struct segment_command_64*)cmdPtr;
            if(strcmp(segmentCmd->segname, SEG_LINKEDIT) == 0) {                // __LINKEDIT是链接信息段，可以通过__LINKEDIT进行地址计算
                return (uintptr_t)(segmentCmd->vmaddr - segmentCmd->fileoff);
            }
        }
        cmdPtr += loadCmd->cmdsize;
    }
    return 0;
}

/// 找到Header下面第一个Command
uintptr_t CrashfirstCmdAfterHeader(const struct mach_header* const header) {
    switch(header->magic) {
        case MH_MAGIC:
        case MH_CIGAM:
            return (uintptr_t)(header + 1);                             // 向下偏移1个mach_header长度.
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            return (uintptr_t)(((struct mach_header_64*)header) + 1);   // 向下偏移1个mach_header_64长度.mach_header_64比mach_header多4个字节.
        default:
            return 0;  // Header is corrupt
    }
}

NSString* CrashlogBacktraceEntry(const int entryNum,
                                const uintptr_t address,
                                const Dl_info* const dlInfo) {
    char faddrBuff[20];
    char saddrBuff[20];
    
    const char* fname = CrashlastPathEntry(dlInfo->dli_fname);
    if(fname == NULL) {
        sprintf(faddrBuff, POINTER_FMT, (uintptr_t)dlInfo->dli_fbase);
        fname = faddrBuff;
    }
    
    uintptr_t offset = address - (uintptr_t)dlInfo->dli_saddr;
    const char* sname = dlInfo->dli_sname;
    if(sname == NULL) {
        sprintf(saddrBuff, POINTER_SHORT_FMT, (uintptr_t)dlInfo->dli_fbase);
        sname = saddrBuff;
        offset = address - (uintptr_t)dlInfo->dli_fbase;
    }
    return [NSString stringWithFormat:@"%-30s  0x%08" PRIxPTR " %s + %lu\n" ,fname, (uintptr_t)address, sname, offset];
}

const char* CrashlastPathEntry(const char* const path) {
    if(path == NULL) {
        return NULL;
    }
    
    char* lastFile = strrchr(path, '/');
    return lastFile == NULL ? path : lastFile + 1;
}

@end
