//
//  APMSegmentChecker.m
//  APM
//
//  Created by unakayou on 2022/5/9.
//

#import "APMSegmentChecker.h"
#import <mach/mach.h>
#import <mach-o/dyld.h>

// 将macho文件中存在的指针加到 std::vector<dataSegment> segments 中
void APMSegmentChecker::initAllSegments() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const mach_header_t* header = (const mach_header_t*)_dyld_get_image_header(i);
        const char* image_name = _dyld_get_image_name(i);
        const char* tmp = strrchr(image_name, '/');             // image名称
        vm_address_t slide = _dyld_get_image_vmaddr_slide(i);   // ASLR
        if (tmp) {
            image_name = tmp + 1;
        }
        // 偏移到header下面的loadcommands
        long offset = (long)header + sizeof(mach_header_t);
        for (unsigned int i = 0; i < header->ncmds; i++)
        {
            // 遍历loadCommands(segmentCommands)
            const segment_command_t* segment = (const segment_command_t*)offset;
            // 找到DATA段
            if (segment->cmd == MY_SEGMENT_CMD_TYPE && strncmp(segment->segname,"__DATA",6) == 0) {
                // 获取段下面的第一个节
                section_t *section = (section_t *)((char*)segment + sizeof(segment_command_t));
                // segment->nsects:段(segment)中节(section)的数量
                for(uint32_t j = 0; j < segment->nsects; j++) {
                    // __data: OC初始化过的变量、__common:未初始化过的符号声明、__bss:未初始化的全局变量
                    if((strncmp(section->sectname,"__data",6) == 0) || (strncmp(section->sectname,"__common",8) == 0) || (strncmp(section->sectname,"__bss",5) == 0)) {
                        vm_address_t begin = (vm_address_t)section->addr + slide;
                        vm_size_t size = (vm_size_t)section->size;
                        dataSegment seg = {image_name,section->sectname,begin,size};
                        // 将这些可能存在指针的"节"启始、结束地址，放入"段"数组中...
                        segments.push_back(seg);
                    }
                    section = (section_t *)((char *)section + sizeof(section_t));
                }
            }
            offset += segment->cmdsize;
        }
    }
}


void APMSegmentChecker::removeAllSegments() {
    segments.clear();
}


void APMSegmentChecker::startPtrCheck() {
    // 遍历段数组
    for(auto it = segments.begin();it != segments.end();it++){
        dataSegment seg = *it;
        vm_range_t range = {seg.beginAddr,seg.size};
        // 去qleak_ptrs_hashmap匹配，查找泄漏
        check_ptr_in_vmrange(range);
    }
}
