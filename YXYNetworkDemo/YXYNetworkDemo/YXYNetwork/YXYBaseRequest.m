//
//  YXYBaseRequest.m
//  YXYNetworkDemo
//
//  Created by DuWei on 2017/7/10.
//  Copyright © 2017年 CSCW. All rights reserved.
//

#import "YXYBaseRequest.h"
#import "YXYNetworkConfig.h"
#import "YXYNetworkAgent.h"
#import <PINCache.h>


@interface YXYBaseRequest ()

@property (nonatomic, strong) id cacheJson;
@property (nonatomic, weak) id<YXYAPIRequest> child;
@property (nonatomic, strong) YXYNetworkConfig *config;
@property (nonatomic, strong) NSMutableArray *requestAccessories;
@property (nonatomic, strong) YXYNetworkAgent *agent;


@end

#pragma mark -

@implementation YXYBaseRequest

#pragma mark - life cycle

- (instancetype)init
{
    if(self = [super init])
    {
        if([self conformsToProtocol:@protocol(YXYAPIRequest)])
        {
            _child = (id<YXYAPIRequest>)self;
        }
        else
        {
            //MARK: 可以在创建的类没有遵循YXYAPIRequest协议时抛出异常
            NSException *exception = [[NSException alloc]initWithName:@"YXYBaseRequest Exception" reason:@"API中没有遵循YXYAPIRequest协议" userInfo:nil];
            @throw exception;
        }
    }
    return self;
}

#pragma mark - network request


/**
 block回调方式
 
 @param success 成功回调
 @param failure 失败回调
 */
- (void)startWithBlockSuccess:(YXYRequestCompletionBlock)success
                      failure:(YXYRequestFailureBlock)failure{
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
    [self start];
}


/**
 block回调方式
 
 @param progress 进度回调
 @param success 成功回调
 @param failure 失败回调
 */
- (void)startWithBlockProgress:(void (^)(NSProgress *))progress
                       success:(YXYRequestCompletionBlock)success
                       failure:(YXYRequestFailureBlock)failure{
    self.progressBlock = progress;
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
    [self start];
}


/**
 block回调方式
 
 @param success 成功回调
 @param failure 失败回调
 @param finished 请求完成后的回调
 */
- (void)startWithBlockSuccess:(YXYRequestCompletionBlock)success
                      failure:(YXYRequestFailureBlock)failure
                     finished:(YXYRequestFinishedBlock)finished{
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
    self.finishedCompletionBlock = finished;
    [self start];
}

/**
 block回调方式
 
 @param progress 进度回调
 @param success 成功回调
 @param failure 失败回调
 @param finished 请求完成后的回调
 */
- (void)startWithBlockProgress:(void (^)(NSProgress *))progress
                       success:(YXYRequestCompletionBlock)success
                       failure:(YXYRequestFailureBlock)failure
                      finished:(YXYRequestFinishedBlock)finished{
    self.progressBlock = progress;
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
    self.finishedCompletionBlock = finished;
    [self start];
}

/**
 开始一个请求
 */
- (void)start{
    [self.agent addRequest:self];
}

/**
 停止一个请求
 */
- (void)stop{
    self.delegate = nil;
    [self.agent cancelRequest:self];
}

/**
 清理回调块
 */
- (void)clearCompletionBlock {
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
    self.finishedCompletionBlock = nil;
    self.progressBlock = nil;
}

#pragma mark - response object handle

/**
 统一加工responseObject,通过YXYNetworkConfig中的processRule来对数据进行加工，把数据加工与请求分离开。
 
 @return 加工后的JSON数据
 */
- (id)responseJSONObject{
    id responseJSONObject = nil;
    //TODO: 通过YXYNetworkConfig统一加工response
    if (self.config.processRule && [self.config.processRule respondsToSelector:@selector(processResponseWithRequest:)]) {
        if (([self.child respondsToSelector:@selector(ignoreUnifiedResponseProcess)] && ![self.child ignoreUnifiedResponseProcess]) ||
            ![self.child respondsToSelector:@selector(ignoreUnifiedResponseProcess)]) {
            responseJSONObject = [self.config.processRule processResponseWithRequest:_responseJSONObject];
            if ([self.child respondsToSelector:@selector(responseProcess:)]){
                responseJSONObject = [self.child responseProcess:responseJSONObject];
            }
            return responseJSONObject;
        }
    }
    
    if ([self.child respondsToSelector:@selector(responseProcess:)]){
        responseJSONObject = [self.child responseProcess:_responseJSONObject];
        return responseJSONObject;
    }
    return _responseJSONObject;
    
}


/**
 返回未经处理的数据
 
 @return 未经处理的后台数据
 */
- (id)rawJSONObject{
    return _responseJSONObject;
}


/**
 缓存地址数据
 
 @return 缓存的数据
 */
- (id)cacheJson{
    if (_cacheJson) {
        return _cacheJson;
    }
    else{
        return [[PINCache sharedCache].diskCache objectForKey:self.urlString];
    }
}


#pragma mark - URL config

/**
 组装url地址
 
 @return API所需的URL地址
 */
- (NSString *)urlString{
    NSString *baseUrl = nil;
    //TODO: 使用副地址
    if ([self.child respondsToSelector:@selector(useViceUrl)] && [self.child useViceUrl]){
        baseUrl = self.config.viceBaseUrl;
    }
    //TODO: 使用主地址
    else{
        baseUrl = self.config.mainBaseUrl;
    }
    if (baseUrl) {
        //TODO: 使用自定义地址
        if ( [self.child respondsToSelector:@selector(useCustomApiMethodName)] && [self.child useCustomApiMethodName]) {
            return [self.child apiMethodName];
        }
        
        NSString *urlString = [baseUrl stringByAppendingString:[self.child apiMethodName]];
        //TODO: 当POST下参数不在body中时，拼接queryArgument中的地址
        if (self.queryArgument && [self.queryArgument isKindOfClass:[NSDictionary class]]) {
            return [urlString stringByAppendingString:[self urlStringForQuery]];
        }
        return urlString;
    }
    return [self.child apiMethodName];
    
}

/**
 初始化Query的URL
 
 @return Query的URl
 */
- (NSString *)urlStringForQuery{
    NSMutableString *urlString = [[NSMutableString alloc] init];
    [urlString appendString:@"?"];
    [self.queryArgument enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [urlString appendFormat:@"%@=%@&", key, obj];
    }];
    [urlString deleteCharactersInRange:NSMakeRange(urlString.length - 1, 1)];
    return [urlString copy];
}

@end
