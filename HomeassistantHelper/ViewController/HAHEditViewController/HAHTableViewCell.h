//
//  HAHTableViewCell.h
//  HomeassistantHelper
//
//  Created by TozyZuo on 2017/7/30.
//  Copyright © 2017年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HAHEntityModel;

@interface HAHTableViewCell : NSTableCellView
<NSCopying>

@property (nonatomic, strong) HAHEntityModel    *entity;
@property (nonatomic, strong) NSString          *text;

@property (class, readonly) NSString *identifier;

@end


@interface HAHTableViewCell (HAHUsedForEdit)
@property (nonatomic, assign) BOOL      editing;
@property (nonatomic, assign) NSPoint   startOrigin;
@property (nonatomic,  weak ) HAHTableViewCell *cellInTableView;
@end
