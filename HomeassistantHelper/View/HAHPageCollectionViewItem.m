//
//  HAHPageCollectionViewItem.m
//  HomeassistantHelper
//
//  Created by TozyZuo on 2017/7/16.
//  Copyright © 2017年 TozyZuo. All rights reserved.
//

#import "HAHPageCollectionViewItem.h"
#import "NSColor_HAH.h"
#import "NSString_HAH.h"

@interface HAHPageCollectionViewItem ()
@property (weak) IBOutlet NSView *line;
@end

@implementation HAHPageCollectionViewItem

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.wantsLayer = YES;
    CALayer *layer = self.view.layer;
    layer.backgroundColor = [NSColor pageCollectionViewItemNormalColor];

    self.line.wantsLayer = YES;
    self.line.layer.backgroundColor = [NSColor pageCollectionViewItemLineColor];
}

- (void)setText:(NSString *)text
{
    _text = text;
    self.textField.stringValue = text;
}

- (void)setSize:(NSSize)size
{
    self.view.size = size;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    CALayer *layer = self.view.layer;
    if (selected) {
        layer.backgroundColor = [NSColor pageCollectionViewItemSelectedColor];
    } else {
        layer.backgroundColor = [NSColor pageCollectionViewItemNormalColor];
    }
}

+ (CGFloat)widthWithText:(NSString *)text
{
    static HAHPageCollectionViewItem *item;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        item = [[HAHPageCollectionViewItem alloc] init];
        [item view];
    });

    return [text sizeWithFont:item.textField.font].width + 44;
}

@end
