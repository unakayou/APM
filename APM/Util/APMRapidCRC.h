//
//  APMRapidCRC.h
//  APM
//
//  Created by unakayou on 2022/4/12.
//

#ifndef APMRapidCRC_h
#define APMRapidCRC_h

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif
    extern void initCRCTable(void);
    extern uint64_t APMCRC64(uint64_t crc,  const char *buf, uint64_t len);
#ifdef __cplusplus
}
#endif

#endif /* APMRapidCRC_h */
