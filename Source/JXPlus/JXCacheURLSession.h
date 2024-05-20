//
//  JXCacheURLSession.h
//  DDitto
//
//  Created by loong on 2024/5/15.
//

#import <Foundation/Foundation.h>
#import <YYCache/YYCache.h>

NS_ASSUME_NONNULL_BEGIN

@interface JXCacheURLSession : NSObject

@property (nonatomic, strong) YYCache *yycache;

@property (class, readonly, strong) JXCacheURLSession *sharedSession;

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (NS_SWIFT_SENDABLE ^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
