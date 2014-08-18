//
//  RootWindow.h
//  HTTPFetch
//
//  Created by zjs on 14/8/12.
//  Copyright (c) 2014年 zjs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RootWindow : NSWindow
@property(nonatomic,weak)IBOutlet NSSearchField *searchField;
@property(nonatomic,strong)IBOutlet NSTextView *textView;

@end
