//
//  ViewController.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "ViewController.h"
#import <mach/mach.h>
#import "APMController.h"
#import "TestCase.h"
#import "APMMallocManager.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray <TestCase *>*tableViewDataSource;

@property (nonatomic, strong) UITextView *messageView;
@property (nonatomic, strong) NSMutableDictionary *messageViewDataSource;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化UI
    [self initTableView];
    [self initMessageView];

    // 启动时间
    [self launchTime];
    
    // OOM监测
    [self rebootTypeLog];

    __weak typeof(self) weakSelf = self;
    // 内存监测
    [APMController startMemoryMonitor];
    [APMController setMemoryInfoHandler:^(Float32 memory) {
        NSString *memoryValueString = [NSString stringWithFormat:@"%.1fMB", memory];
        [weakSelf.messageViewDataSource setObject:memoryValueString forKey:@"3"];
        [weakSelf updateMessageView];
    }];
    
    // CPU监控
    [APMController startCPUMonitor];
    [APMController setCPUUsageHandler:^(double usage) {
        NSString *cpuUsage = [NSString stringWithFormat:@"%.1f%%",usage * 100];
        [weakSelf.messageViewDataSource setObject:cpuUsage forKey:@"2"];
        [weakSelf updateMessageView];
    }];
    
    // 开启FPS
    [APMController startFPSMonitor];
    [APMController setFPSValueHandler:^(int fps) {
        NSString *fpsString = [NSString stringWithFormat:@"%d", fps];
        [weakSelf.messageViewDataSource setObject:fpsString forKey:@"4"];
        [weakSelf updateMessageView];
    }];

    // 开启malloc监控
    [APMController startMallocMonitorWithFunctionLimitSize:1024 * 1024 singleLimitSize:1024 * 1024];
    
    [APMController setFunctionMallocExceedCallback:^(size_t bytes, NSString * _Nonnull stack) {
        APMLogDebug(@"\n发现累积大内存: %ldKB\n堆栈详情:\n%@", bytes / 1024, stack);
    }];
    
    [APMController setSingleMallocExceedCallback:^(size_t bytes, NSString * _Nonnull stack) {
        APMLogDebug(@"\n发现单次大内存: %ldKB\n堆栈详情:\n%@", bytes / 1024, stack);
        NSString *stackString = [NSString stringWithFormat:@"%ldKB\n%@", bytes / 1024, stack];
        [weakSelf.messageViewDataSource setObject:stackString forKey:@"5"];
        [weakSelf updateMessageView];
    }];
}

#pragma mark - 初始化
- (void)initTableView {
    self.title = @"测试";
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView setSeparatorInset:UIEdgeInsetsZero];
    [_tableView setLayoutMargins:UIEdgeInsetsZero];
    [self.view addSubview:_tableView];
    
    self.tableViewDataSource = [TestCase allTestCase];
}

- (void)initMessageView {
    // 信息显示
    self.messageView = [[UITextView alloc] init];
    _messageView.font = [UIFont systemFontOfSize:15];
    _messageView.backgroundColor = [UIColor groupTableViewBackgroundColor];
//    _messageView.userInteractionEnabled = NO;
    [self.view addSubview:_messageView];
    
    self.messageViewDataSource = [NSMutableDictionary new];
}

- (void)updateMessageView {
    NSArray *nameArray = @[@"重启类型", @"启动耗时", @"CPU占用", @"内存占用", @"FPS", @"大内存捕获"];
    NSArray *allKeys = _messageViewDataSource.allKeys;
    NSMutableString *text = [[NSMutableString alloc] initWithCapacity:allKeys.count];
    for (int i = 0; i < nameArray.count; i++) {
        NSString *key = [NSString stringWithFormat:@"%d",i];
        NSString *value = _messageViewDataSource[key];
        if (value) {
            [text appendFormat:@"%@: %@\n", nameArray[i], value];
        }
    }
    _messageView.text = text;
}

// 显示重启类型
- (void)rebootTypeLog {
    [APMController startOOMMonitor];
    NSString *typeString = [APMController rebootTypeString];
    [_messageViewDataSource setObject:typeString forKey:@"0"];
    [self updateMessageView];
}

// 启动时间
- (void)launchTime {
    NSTimeInterval launchTime = [APMController launchTime];
    [_messageViewDataSource setObject:[NSString stringWithFormat:@"%f秒", launchTime / USEC_PER_SEC] forKey:@"1"];
    [self updateMessageView];
}

#pragma mark - 布局
#define CELL_HEIGHT 50
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat x = 0, y = 0, width = self.view.frame.size.width, height = CELL_HEIGHT * self.tableViewDataSource.count;
    CGFloat maxHeight = self.view.frame.size.height / 3 * 2;
    height = height < maxHeight ? height : maxHeight;
    
    self.tableView.frame = CGRectMake(x, y, width, height);
    y += height;
    
    self.messageView.frame = CGRectMake( x, y, width, self.view.frame.size.height - y);
}

#pragma mark - tableview delegate
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.description];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.description];
        cell.textLabel.text = [_tableViewDataSource[indexPath.row] name];
    }
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tableViewDataSource.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [_tableViewDataSource[indexPath.row] caseBlock]();
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}
@end
