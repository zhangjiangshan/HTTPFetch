//
//  RootWindow.m
//  HTTPFetch
//
//  Created by zjs on 14/8/12.
//  Copyright (c) 2014年 zjs. All rights reserved.
//

#import "RootWindow.h"
#import "HTTPRequest.h"

@implementation RootWindow
{
    HTTPRequest * _request;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    if([theEvent keyCode] == 36) {
        [self.textView setString:@"loading..."];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *str = self.searchField.stringValue;
            NSString * header = [self fetchHeader:[NSURL URLWithString:str]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(header.length)
                    [self.textView setString:header];
                else
                    [self.textView setString:@"过程出错"];
            });
        });
        return YES;
    } else {
        return [super performKeyEquivalent:theEvent];
    }
}

- (NSString *)fetchHeader:(NSURL *)url
{
    //NSURL * url = [NSURL URLWithString:@"http://baike.baidu.com/subview/835/5062332.htm"];
    HTTPRequest * request = [[HTTPRequest alloc] init];
    NSString *header = [request fetchHeaderWithURL:url];
    NSLog(@"header:%@",header);
    return header;
}
@end
