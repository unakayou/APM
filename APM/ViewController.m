//
//  ViewController.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "ViewController.h"
#import "APMDeviceInfo.h"
#import "APMRebootMonitor.h"
#import "APMMemoryStatisitcsCenter.h"
#import "APMMemoryUtil.h"
#import "TestCase.h"
#import <mach/mach.h>

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, assign) APMMemoryStatisitcsCenter *memoryCenter;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray <TestCase *>*tableViewDataSource;

@property (nonatomic, strong) UITextView *messageView;
@property (nonatomic, strong) NSMutableDictionary *messageViewDataSource;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"OOM监测";
    
    [self initTableView];
    [self initMessageView];

    // 启动时间
    [self getLaunchTime];
    
    // OOM监测
    [self rebootTypeLog];
    
    // 启动内存监测
    [self initMemoryStatisitcs];
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
    NSArray *nameArray = @[@"重启类型", @"启动耗时", @"内存占用"];
    NSArray *allKeys = _messageViewDataSource.allKeys;
    NSMutableString *text = [[NSMutableString alloc] initWithCapacity:allKeys.count];
    for (int i = 0; i < allKeys.count; i++) {
        NSString *key = allKeys[i];
        NSString *value = _messageViewDataSource[key];
        if (value) {
            [text appendFormat:@"%@: %@\n", nameArray[key.intValue], value];
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
    self.memoryCenter = [APMMemoryStatisitcsCenter shareMemoryCenter];
    [_memoryCenter start];
    
    __weak typeof(self) weakSelf = self;
    [_memoryCenter setMemoryInfoHandler:^(double memory) {
        NSString *memoryValueString = [NSString stringWithFormat:@"%.1fMB", memory];
        [weakSelf.messageViewDataSource setObject:memoryValueString forKey:@"2"];
        [weakSelf updateMessageView];
    }];
}

#pragma mark - 布局
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat x = 0, y = 0, width = self.view.frame.size.width, height = self.view.frame.size.height;
    self.tableView.frame = CGRectMake(x, y, width, height / 2);
    y += _tableView.frame.size.height;
    
    self.messageView.frame = CGRectMake( x, y, width, height / 2);
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
@end
