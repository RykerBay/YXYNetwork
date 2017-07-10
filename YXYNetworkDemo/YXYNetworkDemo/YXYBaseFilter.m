//
//  YXYBaseFilter.m
//  YXYNetworkDemo
//
//  Created by DuWei on 2017/7/10.
//  Copyright © 2017年 CSCW. All rights reserved.
//

#import "YXYBaseFilter.h"

@implementation YXYBaseFilter

#pragma mark - YXYProcessProtocol

- (BOOL)validResponseObject:(id)responseObject
{
    //TODO: 检查是否返回了数据且数据是否正确
    if (!responseObject && ![responseObject isKindOfClass:[NSDictionary class]] && ![responseObject[@"success"] boolValue]) {
        
        return NO;
    }
    else
        return YES;
}


@end
