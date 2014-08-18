//
//  HTTPRequest.h
//  HTTPFetch
//
//  Created by zjs on 14/8/12.
//  Copyright (c) 2014年 zjs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTTPRequest : NSObject

- (NSString *)fetchHeaderWithURL:(NSURL *)url;

@end
