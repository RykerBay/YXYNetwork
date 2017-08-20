//
//  YXYBaseRequest.h
//  YXYNetworkDemo
//
//  Created by DuWei on 2017/7/10.
//  Copyright © 2017年 CSCW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

#pragma mark - type define

@class YXYBaseRequest;
typedef void (^AFConstructingBlock)(id<AFMultipartFormData> formData);
typedef void (^YXYRequestCompletionBlock)(__kindof YXYBaseRequest *request);
typedef void (^YXYRequestFailureBlock)(__kindof YXYBaseRequest *request, NSError *error);
typedef void (^YXYRequestFinishedBlock)(__kindof YXYBaseRequest *request, NSError *error);

typedef NS_ENUM(NSInteger , YXYRequestMethod) {
    YXYRequestMethodGet = 0,
    YXYRequestMethodPost,
    YXYRequestMethodHead
};

typedef NS_ENUM(NSInteger , YXYRequestSerializerType) {
    YXYRequestSerializerTypeHTTP = 0,
    YXYRequestSerializerTypeJSON,
};

#pragma mark - class protocol

/*--------------------------------------------*/
/**
 所有继承自YXYBaseRequest的API都必须遵守本协议中的 apiMethodName 与 requestMethod 方法。
 */
@protocol YXYAPIRequest <NSObject>

@required

/*--------------------------------------------*/
//MARK: base config


/**
 *  请求方式，包括Get、Post、Head、Put、Delete、Patch，具体查看 YXYRequestMethod
 *
 *  @return 请求方式
 */
- (YXYRequestMethod)requestMethod;

@optional

/**
 api请求地址
 
 @return api请求地址
 */
- (NSString *)apiMethodName;

/*--------------------------------------------*/
//MARK: URL config
/**
 *  可以使用两个根地址，比如可能会用到测试地址、https之类的
 *
 *  @return 是否使用副Url
 */
- (BOOL)useViceUrl;

/**
 *  是否使用自定义的接口地址，也就是不会使用 mainBaseUrl 或 viceBaseUrl，这时候在 apiMethodName 就可以是用自定义的接口地址了
 *
 *  @return 是否使用自定义的接口地址
 */
- (BOOL)useCustomApiMethodName;

/*--------------------------------------------*/
//MARK: resonseObject config

/**
 对网络请求返回的JSON数据进行建模处理，返回model数组
 
 @param JSONResponseObject 网络请求返回的JSON数据
 @return 建模后的model数组
 */
- (NSArray *)modelingFormJSONResponseObject:(id)JSONResponseObject;

/**
 *  是否忽略统一的参数加工，默认返回否，resonseObject 将返回加工后的数据。
 *
 *  @return 返回 YES，那么 rawJSONResponseObject 将返回原始的数据
 */
- (BOOL)ignoreResponseObjectUniformFiltering;

/**
 检查请求返回的数据是否不可用，默认返回否，具体判断方法可以通过API自行设定
 
 @param responseObject 请求返回的数据
 @return 数据是否合法
 */
- (BOOL)isInvalidResponseObject:(id)responseObject;

/*--------------------------------------------*/
//MARK: cache config
/**
 *  是否缓存数据 response 数据
 *
 *  @return 是否缓存数据 response 数据
 */
- (BOOL)cacheResponse;


/**
 *  缓存策略
 *
 *  @return NSURLRequestCachePolicy
 */
- (NSURLRequestCachePolicy)cachePolicy;

/*--------------------------------------------*/
//MARK: ohter config
/**
 *  当数据返回 null 时是否删除这个字段的值，也就是为 nil，默认YES。因为如果数据返回 null 时，Json会把这个null解析成NSNull对象，当向这个对象发送信息时会导致崩溃，所以在这里对返回数据中的 null 值进行处理判断。
 *
 *  @return YES/NO
 */
- (BOOL)removesKeysWithNullValues;

/**
 *  服务端数据接收类型，比如 YXYRequestSerializerTypeJSON 用于 post json 数据
 *
 *  @return 服务端数据接收类型
 */
- (YXYRequestSerializerType)requestSerializerType;

/**
 *  自定义超时时间，默认为60
 *
 *  @return 超时时间
 */
- (NSTimeInterval)requestTimeoutInterval;


/**
 muiltpart数据，用于上传操作
 用法：在API接口中实现代理方法
 - (AFConstructingBlock)constructingBodyBlock {
 return ^(id<AFMultipartFormData> formData) {
 for (UIImage *image in _images) {
 NSData *data = UIImageJPEGRepresentation(image, 1.0);
 NSString *name = @"images";
 NSString *formKey = @"images";
 NSString *type = @"image/jpeg";
 [formData appendPartWithFileData:data name:formKey fileName:name mimeType:type];
 }
 };
 }
 
 @return 用于muiltpart的数据block
 */
- (AFConstructingBlock)constructingBodyBlock;

@end

/*--------------------------------------------*/

/**
 请求成功、失败、完成和进行中的委托方法。
 */
@protocol YXYRequestDelegate <NSObject>

@optional

- (void)requestSuccess:(YXYBaseRequest *)request;
- (void)requestFinished:(YXYBaseRequest *)request error:(NSError *)error;
- (void)requestFailed:(YXYBaseRequest *)request error:(NSError *)error;
- (void)requestProgress:(NSProgress *)progress;

@end

/*--------------------------------------------*/

/**
 请求将要成功、停止时的委托方法
 */
@protocol YXYRequestAccessory <NSObject>

@optional

- (void)requestWillStart:(id)request;
- (void)requestWillStop:(id)request;
- (void)requestDidStop:(id)request;

@end


#pragma mark -

@interface YXYBaseRequest : NSObject

@property (nonatomic, strong) NSURLSessionDataTask *sessionDataTask;
@property (nonatomic, strong) id requestArgument;
/**
 *  用于 POST 情况下，拼接参数请求，而不是放在body里面
 */
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *queryArgument;
@property (nonatomic, weak) id<YXYRequestDelegate> delegate;
@property (nonatomic, weak, readonly) id<YXYAPIRequest> child;
/**
 *  将json建模后的model数组
 */
@property (nonatomic, strong) NSArray *modeledResponseObject;

/**
 * 过滤后的json数据
 */
@property (nonatomic, strong) id filteredJSONResponseObject;
/**
 *  接口返回的原始数据
 */
@property (nonatomic, strong) id rawJSONResponseObject;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong, readonly) id cacheJson;
@property (nonatomic, strong, readonly) NSString *urlString;
@property (nonatomic, copy) void (^successCompletionBlock)(YXYBaseRequest *);
@property (nonatomic, copy) void (^failureCompletionBlock)(YXYBaseRequest *, NSError *error);
@property (nonatomic, copy) void (^finishedCompletionBlock)(YXYBaseRequest *, NSError *error);
@property (nonatomic, copy) void (^progressBlock)(NSProgress * progress);

/**
 *  开始请求，使用 delegate 方式使用这个方法
 */
- (void)start;

/**
 *  停止请求
 */
- (void)stop;

/**
 *  block回调方式
 *
 *  @param success 成功回调
 *  @param failure 失败回调
 */
- (void)startWithBlockSuccess:(YXYRequestCompletionBlock)success
                      failure:(YXYRequestFailureBlock)failure;


/**
 block回调方式
 
 @param success 成功回调
 @param failure 失败回调
 @param finished 请求完成后的回调
 */
- (void)startWithBlockSuccess:(YXYRequestCompletionBlock)success
                      failure:(YXYRequestFailureBlock)failure
                     finished:(YXYRequestFinishedBlock)finished;



/**
 *  block回调方式
 *
 *  @param progress 进度回调
 *  @param success  成功回调
 *  @param failure  失败回调
 */
- (void)startWithBlockProgress:(void (^)(NSProgress *progress))progress
                       success:(YXYRequestCompletionBlock)success
                       failure:(YXYRequestFailureBlock)failure;


/**
 block回调方式
 
 @param progress 进度回调
 @param success 成功回调
 @param failure 失败回调
 @param finished 请求完成后的回调
 */
- (void)startWithBlockProgress:(void (^)(NSProgress *progress))progress
                       success:(YXYRequestCompletionBlock)success
                       failure:(YXYRequestFailureBlock)failure
                      finished:(YXYRequestFinishedBlock)finished;

- (void)clearCompletionBlock;

@end
