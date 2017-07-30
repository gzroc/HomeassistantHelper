//
//  HAHModelConfigView.m
//  HomeassistantHelper
//
//  Created by TozyZuo on 2017/7/16.
//  Copyright © 2017年 TozyZuo. All rights reserved.
//

#import "HAHModelConfigView.h"
#import "HAHModel.h"
#import "NSTextField_HAH.h"
#import <objc/runtime.h>

CGFloat HAHModelConfigViewTopMargin = 20;
CGFloat HAHModelConfigViewLeftMargin = 20;
CGFloat HAHModelConfigViewRightMargin = 20;
CGFloat HAHModelConfigViewBottomMargin = 20;
CGFloat HAHModelConfigViewVerticalSpace = 5;


@interface HAHModelConfigView ()
@property (nonatomic, readonly) NSArray         *disabledProperties;
@property (nonatomic,  strong ) HAHModel        *model;
@property (nonatomic, readonly) NSDictionary    *dispatchDictionary;
@end

@implementation HAHModelConfigView

- (NSArray *)disabledProperties
{
    static NSArray *disabledProperties = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        disabledProperties = @[@"id",];
    });

    return disabledProperties;
}

- (NSDictionary *)dispatchDictionary
{
    static NSDictionary *dispatchDictionary = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatchDictionary = @{
            @"NSString" : NSStringFromSelector(@selector(viewWithStringProperty:)),
            @"BOOL" : NSStringFromSelector(@selector(viewWithBOOLProperty:)),
        };
    });

    return dispatchDictionary;
}

- (void)reloadWithModel:(HAHModel *)model
{
    self.model = model;

    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    HAHModelInformation *information = [model.class infomation];

    NSMutableArray *array = information.propertyNames.mutableCopy;
    [array addObjectsFromArray:information.propertyNames];
    [array addObjectsFromArray:information.propertyNames];
    [array addObjectsFromArray:information.propertyNames];
    [array addObjectsFromArray:information.propertyNames];
    [array addObjectsFromArray:information.propertyNames];
    [array addObjectsFromArray:information.propertyNames];
    [array addObjectsFromArray:information.propertyNames];
    [array addObjectsFromArray:information.propertyNames];
    [array addObjectsFromArray:information.propertyNames];
    [array addObjectsFromArray:information.propertyNames];
    [array addObjectsFromArray:information.propertyNames];
    [array addObjectsFromArray:information.propertyNames];

    for (NSString *property in information.propertyNames) {
//    for (NSString *property in array) {
        NSString *selectorString = self.dispatchDictionary[[information classStringForProperty:property]];
        if (selectorString) {

            HAH_CLANG_WARNING_IGNORE_BEGIN(-Warc-performSelector-leaks)

            NSView *view = [self performSelector:NSSelectorFromString(selectorString) withObject:property];

            HAH_CLANG_WARNING_IGNORE_END

            view.top = self.subviews.lastObject.bottom;
            [self addSubview:view];
        }
    }

    self.height = MAX(self.superview.height, self.subviews.lastObject.bottom + HAHModelConfigViewBottomMargin);
}

- (NSView *)viewWithStringProperty:(NSString *)property
{
    NSView *view = [[HAHView alloc] initWithFrame:NSZeroRect];
    view.width = HAHModelConfigViewWidth;

    CGFloat width = HAHModelConfigViewWidth - HAHModelConfigViewLeftMargin - HAHModelConfigViewRightMargin;

    NSTextField *title = [[NSTextField alloc] initWithFrame:NSMakeRect(HAHModelConfigViewLeftMargin, HAHModelConfigViewTopMargin, width, 22)];
    [title enableLabelStyle];
    title.stringValue = property;
    [view addSubview:title];

    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(HAHModelConfigViewLeftMargin, title.bottom + HAHModelConfigViewVerticalSpace, width, 22)];
    textField.stringValue = [self.model valueForKey:property] ?: @"";
    if ([self.disabledProperties containsObject:property]) {
        textField.enabled = NO;
    }
    [view addSubview:textField];

    view.height = textField.bottom;

    return view;
}

- (NSView *)viewWithBOOLProperty:(NSString *)property
{
    return nil;
}

@end