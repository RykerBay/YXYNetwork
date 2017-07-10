//
//  YXYNetworkAgent.h
//  YXYNetworkDemo
//
//  Created by DuWei on 2017/7/10.
//  Copyright © 2017年 CSCW. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YXYBaseRequest;

@interface YXYNetworkAgent : NSObject

/**
 新建一个请求，并判断该请求需要进行的操作，并针对不同操作对其进行不同的解析操作。
 
 @param request 是由各个API发起的请求，可以是post 或者是get
 */
- (void)addRequest:(YXYBaseRequest *)request;

/**
 取消请求的操作
 
 @param request 需要被取消的请求
 */
- (void)cancelRequest:(YXYBaseRequest *)request;

@end
