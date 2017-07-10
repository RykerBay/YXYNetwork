//
//  YXYNetworkConfig.m
//  YXYNetworkDemo
//
//  Created by DuWei on 2017/7/10.
//  Copyright © 2017年 CSCW. All rights reserved.
//

#import "YXYNetworkConfig.h"
#import "YXYBaseFilter.h"
#import <AFSecurityPolicy.h>

@implementation YXYNetworkConfig

+ (YXYNetworkConfig *)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
        _processRule = [[YXYBaseFilter alloc]init];
    }
    return self;
}


@end

