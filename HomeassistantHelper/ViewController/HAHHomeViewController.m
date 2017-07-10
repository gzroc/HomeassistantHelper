//
//  HAHHomeViewController.m
//  HomeassistantHelper
//
//  Created by TozyZuo on 2017/7/9.
//  Copyright © 2017年 TozyZuo. All rights reserved.
//

#import "HAHHomeViewController.h"
#import "HAHEntityModel.h"
#import "HAHDataManager.h"

@interface HAHHomeViewController ()
@property (weak) IBOutlet NSButton *readInfoButton;
@property (weak) IBOutlet NSTextField *addressTextField;
@property (nonatomic, strong) NSArray<HAHEntityModel *> *models;
@end

@implementation HAHHomeViewController

#pragma mark - Life cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    // 注册通知
//    NSDictionary *notificationDictionary = @{NSWindowDidResizeNotification : NSStringFromSelector(@selector(windowDidResizeNotification:))};

//    for (NSString *notificationName in notificationDictionary) {
//        SEL selector = NSSelectorFromString(notificationDictionary[notificationName]);
//        [[NSNotificationCenter defaultCenter] removeObserver:self name:notificationName object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:selector name:notificationName object:nil];
//    }

}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSRect frame;
    frame.size = [NSScreen mainScreen].visibleFrame.size;
    self.view.frame = frame;

    self.addressTextField.stringValue =  [[NSUserDefaults standardUserDefaults] objectForKey:HAHUDAdressKey] ?: @"http://192.168.x.x:8123";
}

- (void)viewDidAppear
{
    [super viewDidAppear];

}

#pragma mark - Action

- (IBAction)readInfoButtonAction:(NSButton *)sender
{

    [[HAHDataManager sharedManager] startFileRequestWithURL:self.addressTextField.stringValue user:@"pi" password:@"312358520"];
    return;
    NSString *text = self.addressTextField.stringValue;
    self.addressTextField.enabled = NO;
    self.addressTextField.stringValue = text;
    sender.title = @"获取中";
    __weak typeof(self) weakSelf = self;
    [[HAHDataManager sharedManager] requestEntitiesWithURL:text complete:^(NSArray<HAHEntityModel *> *models) {
        weakSelf.models = models;
        HAHLOG(@"%@", models);
        sender.title = @"获取";
        weakSelf.addressTextField.enabled = YES;
        [[NSUserDefaults standardUserDefaults] setObject:weakSelf.addressTextField.stringValue forKey:HAHUDAdressKey];
    }];
}

#pragma mark - Notification

- (void)windowDidResizeNotification:(NSNotification *)notification
{
    NSWindow *window = notification.object;

    NSLog(@"%@", NSStringFromRect(window.frame));
}

- (void)controlTextDidEndEditingNotification:(NSNotification *)notification
{
//    NSTextField *textField = notification.object;

}

@end
