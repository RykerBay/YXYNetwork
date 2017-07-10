//
//  YXYNetworkConfig.h
//  YXYNetworkDemo
//
//  Created by DuWei on 2017/7/10.
//  Copyright © 2017年 CSCW. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YXYBaseRequest;
@class AFSecurityPolicy;

#pragma mark - class protocol
/*--------------------------------------------*/

/**
 用于处理 response 的协议
 */
@protocol YXYProcessProtocol <NSObject>

@optional

/**
 *  用于统一加工参数，返回处理后的参数值
 *
 *  @param argument 参数
 *  @param queryArgument query 信息，某些POST请求希望参数不放在body里面，需要用Query来附带数据，这时候就用到queryArgument属性。
 *
 *  @return 处理后的参数
 */
- (NSDictionary *)processArgumentWithRequest:(NSDictionary *)argument query:(NSDictionary *)queryArgument;

/**
 *  用于统一加工response，返回处理后response
 *
 *  @param responseObject response
 *
 *  @return 处理后的response
 */
- (id)processResponseWithRequest:(id)responseObject;

/**
 用于判断返回数据是否合法
 
 @param responseObject 请求获取的数据
 @return 数据合法与否
 */
- (BOOL)validResponseObject:(id)responseObject;



@end

#pragma mark -

@interface YXYNetworkConfig : NSObject

+ (YXYNetworkConfig *)sharedInstance;

/**
 请求所用的主URL
 */
@property (nonatomic, strong) NSString *mainBaseUrl;

/**
 请求所用的副URL
 */
@property (nonatomic, strong) NSString *viceBaseUrl;
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

/**
 数据过滤器器
 */
@property (nonatomic, strong) id <YXYProcessProtocol> processRule;

@end
