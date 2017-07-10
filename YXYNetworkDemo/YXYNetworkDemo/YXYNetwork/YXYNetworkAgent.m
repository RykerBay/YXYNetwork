//
//  YXYNetworkAgent.m
//  YXYNetworkDemo
//
//  Created by DuWei on 2017/7/10.
//  Copyright © 2017年 CSCW. All rights reserved.
//

#import "YXYNetworkAgent.h"
#import "YXYBaseRequest.h"
#import "YXYNetworkConfig.h"
#import <AFNetworking.h>
#import <PINCache.h>

@interface YXYNetworkAgent ()

@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, strong) NSMutableDictionary *requestsRecord;
@property (nonatomic, strong) YXYNetworkConfig *config;

@end

@implementation YXYNetworkAgent

#pragma mark - life cycle

- (id)init {
    self = [super init];
    if (self) {
        _config = [YXYNetworkConfig sharedInstance];
        _requestsRecord = [NSMutableDictionary dictionary];
        _manager.securityPolicy = _config.securityPolicy;
        _manager = [AFHTTPSessionManager manager];
        _manager.operationQueue.maxConcurrentOperationCount = 4;
    }
    return self;
}

- (void)dealloc{
    [self.manager invalidateSessionCancelingTasks:NO];
}

#pragma mark - request handle


/**
 新建一个请求，并判断该请求需要进行的操作，并针对不同操作对其进行不同的解析操作。
 
 @param request 是由各个API发起的请求，可以是post 或者是get
 */
- (void)addRequest:(YXYBaseRequest <YXYAPIRequest>*)request {
    
    //TODO: 检查网络是否通畅
    if(![self checkNetworkConnection])
    {
        [self showNetworkAlertForRequest:request];
        return;
    }
    
    NSString *url = request.urlString;
    
    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    serializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", @"text/plain", nil];
    
    //TODO: 检查是否对返回数据中的 null 进行处理
    if ([request.child respondsToSelector:@selector(removesKeysWithNullValues)]) {
        serializer.removesKeysWithNullValues = [request.child removesKeysWithNullValues];
    }
    
    self.manager.responseSerializer = serializer;
    NSDictionary *argument = request.requestArgument;
    
    //TODO: 检查是否有统一的参数加工
    if (self.config.processRule && [self.config.processRule respondsToSelector:@selector(processArgumentWithRequest:query:)]) {
        argument = [self.config.processRule processArgumentWithRequest:request.requestArgument query:request.queryArgument];
    }
    
    //TODO: 检查服务端数据接收类型
    if ([request.child respondsToSelector:@selector(requestSerializerType)]) {
        if ([request.child requestSerializerType] == YXYRequestSerializerTypeHTTP) {
            self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        }
        else{
            self.manager.requestSerializer = [AFJSONRequestSerializer serializer];
        }
    }
    
    //TODO: 检查是否使用自定义超时时间
    if ([request.child respondsToSelector:@selector(requestTimeoutInterval)]) {
        self.manager.requestSerializer.timeoutInterval = [request.child requestTimeoutInterval];
    }
    else{
        self.manager.requestSerializer.timeoutInterval = 60.0;
    }
    
    //TODO: 检查缓存策略
    if ([request.child respondsToSelector:@selector(cachePolicy)]) {
        [self.manager.requestSerializer setCachePolicy:[request.child cachePolicy]];
    }
    else{
        [self.manager.requestSerializer setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    }
    
    //TODO: 处理get请求
    if ([request.child requestMethod] == YXYRequestMethodGet) {
        request.sessionDataTask = [self.manager GET:url parameters:argument progress:^(NSProgress * _Nonnull downloadProgress) {
            [self handleRequestProgress:downloadProgress request:request];
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            //TODO: 处理返回的错误数据
            if(self.config.processRule && [self.config.processRule respondsToSelector:@selector(validResponseObject:)])
            {
                if([self.config.processRule validResponseObject:responseObject])
                {
                    request.responseJSONObject = responseObject;
                    [self handleRequestSuccess:task];
                }
                else
                {
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
                    request.responseJSONObject = responseObject;
                    [self handleRequestFailure:task error:error];
                }
            }
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self handleRequestFailure:task error:error];
        }];
    }
    //TODO: 处理post请求
    else if ([request.child requestMethod] == YXYRequestMethodPost){
        //TODO: 处理上传操作
        if ([request.child respondsToSelector:@selector(constructingBodyBlock)] && [request.child constructingBodyBlock]) {
            request.sessionDataTask = [self.manager POST:url parameters:argument constructingBodyWithBlock:[request.child constructingBodyBlock] progress:^(NSProgress * _Nonnull uploadProgress) {
                [self handleRequestProgress:uploadProgress request:request];
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                //TODO: 处理返回的错误数据
                if(self.config.processRule && [self.config.processRule respondsToSelector:@selector(validResponseObject:)])
                {
                    if([self.config.processRule validResponseObject:responseObject])
                    {
                        request.responseJSONObject = responseObject;
                        [self handleRequestSuccess:task];
                    }
                    else
                    {
                        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
                        request.responseJSONObject = responseObject;
                        [self handleRequestFailure:task error:error];
                    }
                }
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self handleRequestFailure:task error:error];
            }];
        }
        else
        {
            request.sessionDataTask = [self.manager POST:url parameters:argument progress:^(NSProgress * _Nonnull uploadProgress) {
                [self handleRequestProgress:uploadProgress request:request];
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                //TODO: 处理返回的错误数据
                if(self.config.processRule && [self.config.processRule respondsToSelector:@selector(validResponseObject:)])
                {
                    if([self.config.processRule validResponseObject:responseObject])
                    {
                        request.responseJSONObject = responseObject;
                        [self handleRequestSuccess:task];
                    }
                    else
                    {
                        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
                        request.responseJSONObject = responseObject;
                        [self handleRequestFailure:task error:error];
                    }
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self handleRequestFailure:task error:error];
            }];
        }
    }
}


/**
 处理请求进程
 
 @param progress 请求的进程
 @param request API中的请求
 */
- (void)handleRequestProgress:(NSProgress *)progress request:(YXYBaseRequest *)request{
    if (request.delegate && [request.delegate respondsToSelector:@selector(requestProgress:)]) {
        [request.delegate requestProgress:progress];
    }
    if (request.progressBlock) {
        request.progressBlock(progress);
    }
}


/**
 请求完成后的处理
 
 @param sessionDataTask NSURLSessionDataTask用来下载数据到内存里，数据的格式是NSData，同时本方法对相关操作进行缓存处理
 */
- (void)handleRequestSuccess:(NSURLSessionDataTask *)sessionDataTask{
    NSString *key = [self keyForRequest:sessionDataTask];
    YXYBaseRequest *request = _requestsRecord[key];
    if (request) {
        
        //TODO: 更新缓存
        if (([request.child respondsToSelector:@selector(cacheResponse)] && [request.child cacheResponse])) {
            [[[PINCache sharedCache] diskCache] setObject:request.responseJSONObject forKey:request.urlString];
        }
        
        if (request.delegate != nil && [request.delegate respondsToSelector:@selector(requestSuccess:)]) {
            [request.delegate requestSuccess:request];
        }
        if (request.delegate != nil && [request.delegate respondsToSelector:@selector(requestFinished:error:)]) {
            [request.delegate requestFinished:request error:nil];
        }
        if (request.successCompletionBlock) {
            request.successCompletionBlock(request);
        }
        if (request.finishedCompletionBlock) {
            request.finishedCompletionBlock(request, nil);
        }
    }
    
    [self removeOperation:sessionDataTask];
    [request clearCompletionBlock];
}


/**
 请求失败后的处理
 
 @param sessionDataTask NSURLSessionDataTask用来下载数据到内存里，数据的格式是NSData
 @param error 导致请求失败的错误
 */
- (void)handleRequestFailure:(NSURLSessionDataTask *)sessionDataTask error:(NSError *)error{
    NSString *key = [self keyForRequest:sessionDataTask];
    YXYBaseRequest *request = _requestsRecord[key];
    request.error = error;
    
    if (request) {
        if (request.delegate != nil && [request.delegate respondsToSelector:@selector(requestFailed:error:)]) {
            [request.delegate requestFailed:request error:error];
        }
        if (request.delegate != nil && [request.delegate respondsToSelector:@selector(requestFinished:error:)]) {
            [request.delegate requestFinished:request error:error];
        }
        if (request.failureCompletionBlock) {
            request.failureCompletionBlock(request, error);
        }
        if (request.finishedCompletionBlock) {
            request.finishedCompletionBlock(request, error);
        }
    }
    [self removeOperation:sessionDataTask];
    [request clearCompletionBlock];
}

/**
 取消请求的操作
 
 @param request 需要被取消的请求
 */
- (void)cancelRequest:(YXYBaseRequest *)request {
    [request.sessionDataTask cancel];
    [self removeOperation:request.sessionDataTask];
    [request clearCompletionBlock];
}


/**
 移除DataTask的操作
 
 @param operation 需要被移除的操作
 */
- (void)removeOperation:(NSURLSessionDataTask *)operation {
    NSString *key = [self keyForRequest:operation];
    @synchronized(self) {
        [_requestsRecord removeObjectForKey:key];
    }
}


/**
 增加一个操作请求
 
 @param request 需要被增加的请求
 */
- (void)addOperation:(YXYBaseRequest *)request {
    if (request.sessionDataTask != nil) {
        NSString *key = [self keyForRequest:request.sessionDataTask];
        @synchronized(self) {
            self.requestsRecord[key] = request;
        }
    }
}


/**
 获取一个请求的健值
 
 @param object 需要获取键值的DataTask
 @return 对应的键值
 */
- (NSString *)keyForRequest:(NSURLSessionDataTask *)object {
    NSString *key = [@(object.taskIdentifier) stringValue];
    return key;
}

#pragma mark - network handle

/**
 检查当前网络环境
 
 @return 当前网络是否联通
 */
- (BOOL)checkNetworkConnection
{
    struct sockaddr zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sa_len = sizeof(zeroAddress);
    zeroAddress.sa_family = AF_INET;
    
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    
    if (!didRetrieveFlags) {
        printf("Error. Count not recover network reachability flags\n");
        return NO;
    }
    
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    return (isReachable && !needsConnection) ? YES : NO;
}

/**
 显示无网络的提示
 
 @param request 当前的请求
 */
- (void)showNetworkAlertForRequest:(YXYBaseRequest*)request
{
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:nil];
    request.failureCompletionBlock(request, error);
    //MARK: 接下来设置显示一个view用于警告当前没有网络
}

@end
