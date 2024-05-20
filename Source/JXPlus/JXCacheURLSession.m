//
//  JXCacheURLSession.m
//  DDitto
//
//  Created by loong on 2024/5/15.
//

#import "JXCacheURLSession.h"

@implementation JXCacheURLSession

+ (JXCacheURLSession *)sharedSession {
    static JXCacheURLSession *instance = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

/// @param zone 一般传null
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedSession];
}

/// 防止有人使用copy 单例对象
- (id)copyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark - 缓存
- (YYCache *)yycache {
    if (!_yycache) {
        _yycache = [[YYCache alloc] initWithName:@"URL"];
    }
    return _yycache;
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (NS_SWIFT_SENDABLE ^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    
    NSString *cacheKey = url.description;
    
    NSData *cacheData = (NSData *)[self.yycache objectForKey:cacheKey];
    if (cacheData && completionHandler) {
        completionHandler(cacheData, nil, nil);
        return nil;
    }
    
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil && data != nil) {
            [self.yycache setObject:data forKey:cacheKey];
        }
        !completionHandler ? : completionHandler(data, response, error);
    }];
    return task;
}

@end
