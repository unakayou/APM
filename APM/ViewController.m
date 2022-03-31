//
//  ViewController.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "ViewController.h"
#import "APMDeviceInfo.h"
#import "APMRebootMonitor.h"
#import "APMMemoryStatisticCenter.h"
#import "APMCPUStatisticCenter.h"
#import "APMController.h"
#import "TestCase.h"
#import <mach/mach.h>

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray <TestCase *>*tableViewDataSource;

@property (nonatomic, strong) UITextView *messageView;
@property (nonatomic, strong) NSMutableDictionary *messageViewDataSource;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"测试";
    
    // 开启FPS
    [APMController startFPSMonitor];
    
    // 开启malloc监控
    [APMController startMallocMonitor];
    
    [self initTableView];
    [self initMessageView];

    // 启动时间
    [self getLaunchTime];
    
    // OOM监测
    [self rebootTypeLog];
    
    // 内存监测
    [self initMemoryStatisitcs];
    
    // CPU监控
    [self initCPUStatisitcs];
}

#pragma mark - 初始化
- (void)initTableView {
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
    _messageView.userInteractionEnabled = NO;
    [self.view addSubview:_messageView];
    
    self.messageViewDataSource = [NSMutableDictionary new];
}

- (void)updateMessageView {
    NSArray *nameArray = @[@"重启类型", @"启动耗时", @"CPU占用", @"内存占用"];
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
    [_messageViewDataSource setObject:APMRebootMonitor.rebootTypeString forKey:@"0"];
    [self updateMessageView];
}

// 启动时间
- (void)getLaunchTime {
    NSTimeInterval launchTime = [APMDeviceInfo processStartTime];
    [_messageViewDataSource setObject:[NSString stringWithFormat:@"%f秒", launchTime / USEC_PER_SEC] forKey:@"1"];
    [self updateMessageView];
}

- (void)initMemoryStatisitcs {
    [APMMemoryStatisticCenter start];
    
    __weak typeof(self) weakSelf = self;
    [APMMemoryStatisticCenter setMemoryInfoHandler:^(Float32 memory) {
        NSString *memoryValueString = [NSString stringWithFormat:@"%.1fMB", memory];
        [weakSelf.messageViewDataSource setObject:memoryValueString forKey:@"3"];
        [weakSelf updateMessageView];
    }];
}

- (void)initCPUStatisitcs {
    [APMCPUStatisticCenter start];
    
    __weak typeof(self) weakSelf = self;
    [APMCPUStatisticCenter setCPUUsageHandler:^(double usage) {
        NSString *cpuUsage = [NSString stringWithFormat:@"%.1f%%",[APMDeviceInfo currentCPUUsagePercent] * 100];
        [weakSelf.messageViewDataSource setObject:cpuUsage forKey:@"2"];
        [weakSelf updateMessageView];
    }];
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
