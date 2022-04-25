//
//  APMThreadSuspendTool.h
//  APM
//
//  Created by unakayou on 2022/4/24.
//
//  线程挂起、恢复工具

/// 挂起非自身线程
bool suspendAllChildThreads();

/// 恢复线程
void resumeAllChildThreads();
