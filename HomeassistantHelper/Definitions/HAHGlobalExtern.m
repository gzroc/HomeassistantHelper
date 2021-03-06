//
//  HAHGlobalExtern.m
//  HomeassistantHelper
//
//  Created by TozyZuo on 2017/7/10.
//  Copyright © 2017年 TozyZuo. All rights reserved.
//

#import "HAHGlobalExtern.h"

#pragma mark - UserDefaults

NSString * const HAHUDAdressKey = @"HAHUDAdressKey";
NSString * const HAHUDUserNameKey = @"HAHUDUserNameKey";
NSString * const HAHUDPasswordKey = @"HAHUDPasswordKey";
NSString * const HAHUDKeepPasswordKey = @"HAHUDKeepPasswordKey";

NSString * const HAHUDMainWindowFrameKey = @"HAHUDMainWindowFrameKey";
NSString * const HAHUDBrowserWindowFrameKey = @"HAHUDBrowserWindowFrameKey";
NSString * const HAHUDConsoleWindowFrameKey = @"HAHUDConsoleWindowFrameKey";
NSString * const HAHUDBackupWindowFrameKey = @"HAHUDBackupWindowFrameKey";

NSString * const HAHUDConsoleFontSizeKey = @"HAHUDConsoleFontSizeKey";

#pragma mark - System

BOOL HAHDebug = YES;

#pragma mark - Function

void HAHExecuteBlockOnMainThread(void (^block)(void))
{
    if (!block) {
        return;
    }

    if ([[NSThread currentThread] isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

NSString *HAHFilterCommentsAndEmptyLineWithText(NSString *text)
{
    return [HAHSeparateTextToLinesAndFilterCommentsAndEmptyLine(text) componentsJoinedByString:@"\n"];
}

NSArray *HAHSeparateTextToLinesAndFilterCommentsAndEmptyLine(NSString *text)
{
    NSMutableArray *lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]].mutableCopy;

    NSUInteger i = 0;
    while (i < lines.count) {
        NSString *line = [lines[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([line hasPrefix:@"#"] ||
            !line.length)
        {
            [lines removeObjectAtIndex:i];
            continue;
        }
        i++;
    }

    return lines;
}

NSString *HAHTrimAllWhiteSpaceWithText(NSString *text)
{
    return [text stringByReplacingOccurrencesOfString:@" " withString:@""];
}

#pragma mark - Global

CGFloat const HAHModelConfigViewWidth = 235;

#pragma mark - Notification

NSString * const HAHRestorBackupNotification = @"HAHRestorBackupNotification";

#pragma mark - String

NSString * const HAHSFriendlyName = @"friendly_name";
NSString * const HAHSConfigurationFileName = @"configuration.yaml";
NSString * const HAHSGroupFileName = @"groups.yaml";
NSString * const HAHSCustomizeFileName = @"customize.yaml";

