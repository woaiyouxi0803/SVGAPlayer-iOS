//
//  JXSVGAImageView.m
//  DDitto
//
//  Created by loong on 2024/5/15.
//

#import "JXSVGAImageView.h"
#import "JXCacheURLSession.h"
//#import "SVGAParser.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <CommonCrypto/CommonDigest.h>

#import "SVGAVideoEntity.h"
#import "SVGAVideoSpriteEntity.h"
#import "SVGAVideoSpriteFrameEntity.h"
#import "SVGAContentLayer.h"
#import "SVGABitmapLayer.h"
#import "SVGAVectorLayer.h"
#import "SVGAAudioLayer.h"
#import "SVGAAudioEntity.h"

@implementation UIImage (JXRoundedCorner)
//- (UIImage*)jx_2RoundedCorner {
//    CGFloat w = self.size.width;
//    CGFloat h = self.size.height;
//
//    CGFloat radius = MIN(w, h) / 2.0;
//    CGRect frame = CGRectMake(0, 0, 2 * radius, 2 * radius);
//
//    UIImage *image = nil;
//    UIGraphicsBeginImageContext(frame.size);
//    [[UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:radius] addClip];
//    [self drawInRect:frame];
//    image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return image;
//}
- (UIImage *)jx_2RoundedCorner {
    CGFloat w = self.size.width;
    CGFloat h = self.size.height;
    
    // 如果图像尺寸过大，先进行缩放
    CGFloat maxDimension = 300.0; // 最大尺寸限制
    if (w > maxDimension || h > maxDimension) {
        CGFloat scale = MIN(maxDimension / w, maxDimension / h);
        w *= scale;
        h *= scale;
    }
    
    CGFloat radius = MIN(w, h) / 2.0;
    CGRect frame = CGRectMake(0, 0, 2 * radius, 2 * radius);

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:frame.size];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:radius];
        [path addClip];
        [self drawInRect:frame];
    }];

    return image;
}
@end



@interface JXSVGAImageView()
@property (nonatomic, strong) CALayer *drawLayer;
@property (nonatomic, strong) NSArray<SVGAAudioLayer *> *audioLayers;

@property (nonatomic, copy) NSArray *contentLayers;
@property (nonatomic, copy) NSDictionary<NSString *, UIImage *> *dynamicObjects;
@property (nonatomic, copy) NSDictionary<NSString *, NSAttributedString *> *dynamicTexts;
@property (nonatomic, copy) NSDictionary<NSString *, SVGAPlayerDynamicDrawingBlock> *dynamicDrawings;
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> *dynamicHiddens;

@end


static SVGAParser *sharedParser;
@implementation JXSVGAImageView

+ (void)load {
    sharedParser = [SVGAParser new];
}

#pragma mark - 重写缓存

- (void)setImageName:(NSString *)imageName {
    _imageName = imageName;
    if ([imageName hasPrefix:@"http://"] || [imageName hasPrefix:@"https://"]) {
        if ([self jx_playCacheKey_SVGA:imageName]) {//使用CacheKey
            return;
        }
        NSURL *url = [NSURL URLWithString:imageName];
        [[JXCacheURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            [NSOperationQueue.mainQueue addOperationWithBlock:^{
                if (error) {
#ifdef DEBUG
                    NSLog(@"setImageName JXCacheURLSession error:%@", error);
#endif
                    if ([self.delegate respondsToSelector:@selector(svgaPlayer:error:)]) {
                        [self.delegate svgaPlayer:self error:error];
                    } else if ([self.delegate respondsToSelector:@selector(svgaPlayerDidFinishedAnimation:)]) {
                        [self.delegate svgaPlayerDidFinishedAnimation:nil];
                    }
                    return;
                }
                [sharedParser parseWithData:data cacheKey:[JXSVGAImageView MD5String:url.absoluteString] completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
                    [self setVideoItem:videoItem];
                    if (self.autoPlay) {
                        [self startAnimation];
                    }
                } failureBlock:^(NSError * _Nonnull error) {
#ifdef DEBUG
                    NSLog(@"setImageName parseWithData error:%@", error);
#endif
                    if ([self.delegate respondsToSelector:@selector(svgaPlayer:error:)]) {
                        [self.delegate svgaPlayer:self error:error];
                    } else if ([self.delegate respondsToSelector:@selector(svgaPlayerDidFinishedAnimation:)]) {
                        [self.delegate svgaPlayerDidFinishedAnimation:nil];
                    }
                }];
            }];
        }] resume];
    }
    else {
        [sharedParser parseWithNamed:imageName inBundle:nil completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
            [self setVideoItem:videoItem];
            if (self.autoPlay) {
                [self startAnimation];
            }
        } failureBlock:^(NSError * _Nonnull error) {
#ifdef DEBUG
            NSLog(@"setImageName parseWithNamed error:%@", error);
#endif
            if ([self.delegate respondsToSelector:@selector(svgaPlayer:error:)]) {
                [self.delegate svgaPlayer:self error:error];
            } else if ([self.delegate respondsToSelector:@selector(svgaPlayerDidFinishedAnimation:)]) {
                [self.delegate svgaPlayerDidFinishedAnimation:nil];
            }
        }];
    }
}

#pragma mark - 使用CacheKey
- (BOOL)jx_playCacheKey_SVGA:(NSString *)url {
    if (url == nil) {
        return false;
    }
    SVGAVideoEntity *videoItem = [SVGAVideoEntity readCache:[JXSVGAImageView MD5String:url]];
    if (videoItem) {
#ifdef DEBUG
//        NSLog(@"jx_playCacheKey_SVGA");
#endif
        [self setVideoItem:videoItem];
        [NSOperationQueue.mainQueue addBarrierBlock:^{
            [self stepToFrame:0 andPlay:self.autoPlay];
        }];
        return true;
    }
    return false;
}


- (void)setImageWithURL:(NSURL *)URL forKey:(NSString *)aKey {
    [[JXCacheURLSession.sharedSession dataTaskWithURL:URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil && data != nil) {
            UIImage *image = [UIImage imageWithData:data];
            if (image != nil) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self setImage:image forKey:aKey];
                }];
            } else {
#ifdef DEBUG
                NSLog(@"setImageWithURL JXCacheURLSession error:%@", error);
#endif
                if ([self.delegate respondsToSelector:@selector(svgaPlayer:forKeyError:)]) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        NSError *error1 = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{@"func":@"setImageWithURL:forKey:", @"aKey": aKey?: @"", @"URL": URL.description?:@"", @"error": error}];
                        [self.delegate svgaPlayer:self forKeyError:error1];
                    }];
                }
            }
        }
    }] resume];
}

#pragma mark - 设置圆角
- (void)jx_r_setImage:(UIImage *)image forKey:(NSString *)aKey {
    [self setImage:[image jx_2RoundedCorner] forKey:aKey];
}

- (void)jx_r_setImageWithURL:(NSURL *)URL forKey:(NSString *)aKey {
    [[JXCacheURLSession.sharedSession dataTaskWithURL:URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil && data != nil) {
            UIImage *image;
            @try {
                image = [UIImage imageWithData:data];
            } @catch (NSException *exception) {
                
            } @finally {

            }
            if (image != nil) {
                image = [image jx_2RoundedCorner];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self setImage:image forKey:aKey];
                }];
            }
        } else {
#ifdef DEBUG
            NSLog(@"r_setImageWithURL JXCacheURLSession error:%@", error);
#endif
            if ([self.delegate respondsToSelector:@selector(svgaPlayer:forKeyError:)]) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    NSError *error1 = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{@"func":@"r_setImageWithURL:forKey:", @"aKey": aKey?: @"", @"URL": URL.description?:@"", @"error": error}];
                    [self.delegate svgaPlayer:self forKeyError:error1];
                }];
            }
        }
    }] resume];
}


#pragma mark - 初始化
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self initPlayer];
    }
    return self;
}

- (void)initPlayer {
    self.contentMode = UIViewContentModeTop;
    self.jx_autoPlayShow = true;
    self.jx_textRepeatCount = 0;
    self.jx_textBeginStayTime = 1.0;
    self.jx_textDuration = 0.0;
    self.jx_textRate = 0.0;
    self.jx_textEndStayTime = 1.0;
    self.jx_autoContentMode = false;
    
    self.loops = 1;
    self.clearsAfterStop = YES;
    self.autoPlay = true;
}


- (void)draw {
    self.drawLayer = [[CALayer alloc] init];
    self.drawLayer.frame = CGRectMake(0, 0, self.videoItem.videoSize.width, self.videoItem.videoSize.height);
    self.drawLayer.masksToBounds = true;
    NSMutableDictionary *tempHostLayers = [NSMutableDictionary dictionary];
    NSMutableArray *tempContentLayers = [NSMutableArray array];
    
    [self.videoItem.sprites enumerateObjectsUsingBlock:^(SVGAVideoSpriteEntity * _Nonnull sprite, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage *bitmap;
        if (sprite.imageKey != nil) {
            NSString *bitmapKey = [sprite.imageKey stringByDeletingPathExtension];
            if (self.dynamicObjects[bitmapKey] != nil) {
                bitmap = self.dynamicObjects[bitmapKey];
            }
            else {
                bitmap = self.videoItem.images[bitmapKey];
            }
        }
        SVGAContentLayer *contentLayer = [sprite requestLayerWithBitmap:bitmap];
        contentLayer.imageKey = sprite.imageKey;
        [tempContentLayers addObject:contentLayer];
        if ([sprite.imageKey hasSuffix:@".matte"]) {
            CALayer *hostLayer = [[CALayer alloc] init];
            hostLayer.mask = contentLayer;
            tempHostLayers[sprite.imageKey] = hostLayer;
        } else {
            if (sprite.matteKey && sprite.matteKey.length > 0) {
                CALayer *hostLayer = tempHostLayers[sprite.matteKey];
                [hostLayer addSublayer:contentLayer];
                if (![sprite.matteKey isEqualToString:self.videoItem.sprites[idx - 1].matteKey]) {
                    [self.drawLayer addSublayer:hostLayer];
                }
            } else {
                [self.drawLayer addSublayer:contentLayer];
            }
        }
        if (sprite.imageKey != nil) {
            if (self.dynamicTexts[sprite.imageKey] != nil) {
                NSAttributedString *text = self.dynamicTexts[sprite.imageKey];
                CGSize bitmapSize = CGSizeMake(self.videoItem.images[sprite.imageKey].size.width * self.videoItem.images[sprite.imageKey].scale, self.videoItem.images[sprite.imageKey].size.height * self.videoItem.images[sprite.imageKey].scale);
                CGSize size = [text boundingRectWithSize:CGSizeMake(10000, bitmapSize.height)
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                 context:NULL].size;
                CATextLayer *textLayer = [CATextLayer layer];
                textLayer.contentsScale = [[UIScreen mainScreen] scale];
                [textLayer setString:self.dynamicTexts[sprite.imageKey]];
                
                contentLayer.bitmapLayer.masksToBounds = YES;
                contentLayer.textLayer = textLayer;
                if(bitmapSize.width - size.width < 10){
#pragma mark - 文字滚动
                    [contentLayer.bitmapLayer addSublayer:textLayer];
                    if ([textLayer animationForKey:@"kTextLayerAnimationKey"]) {
                        [textLayer removeAnimationForKey:@"kTextLayerAnimationKey"];
                    }
                    
                    CABasicAnimation *animation = [CABasicAnimation animation];
                    animation.keyPath = @"transform.translation.x";
                    animation.fromValue = @(0);
                    
                    CGFloat dx = (size.width - bitmapSize.width);
                    if (self.jx_RTLText == true) {
                        textLayer.frame = CGRectMake(-dx, (bitmapSize.height-size.height)/2, size.width, size.height);
                        animation.toValue = @(dx);
                    } else {
                        textLayer.frame = CGRectMake(0, (bitmapSize.height-size.height)/2, size.width, size.height);
                        animation.toValue = @(-dx);
                    }
                    
                    animation.beginTime = CACurrentMediaTime() + self.jx_textBeginStayTime;
                    if (self.jx_textDuration > 0) {
                        animation.duration = self.jx_textDuration;
                    } else if (self.jx_textRate > 0) {
                        animation.duration = size.width * self.jx_textRate;
                    } else {
                        /// 计算svga时长
                        CGFloat duration = ((CGFloat)self.videoItem.frames) /self.videoItem.FPS;
                        CGFloat jx_duration = duration - self.jx_textBeginStayTime - self.jx_textEndStayTime;
                        if (jx_duration > 0) {
                            animation.duration = jx_duration;
                        } else {
                            animation.duration = duration;
                        }
                    }
                    
                    animation.repeatCount = self.jx_textRepeatCount;
                    animation.removedOnCompletion = false;
                    animation.fillMode = kCAFillModeForwards;
                    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
                    [textLayer addAnimation:animation forKey:@"kTextLayerAnimationKey"];
                }else{
                    textLayer.frame = CGRectMake(0, 0, size.width, size.height);
                    [contentLayer addSublayer:textLayer];
                }
                [contentLayer resetTextLayerProperties:text];
            }
            if (self.dynamicHiddens[sprite.imageKey] != nil &&
                [self.dynamicHiddens[sprite.imageKey] boolValue] == YES) {
                contentLayer.dynamicHidden = YES;
            }
            if (self.dynamicDrawings[sprite.imageKey] != nil) {
                contentLayer.dynamicDrawingBlock = self.dynamicDrawings[sprite.imageKey];
            }
        }
    }];
    self.contentLayers = tempContentLayers;
    
    [self.layer addSublayer:self.drawLayer];
    NSMutableArray *audioLayers = [NSMutableArray array];
    [self.videoItem.audios enumerateObjectsUsingBlock:^(SVGAAudioEntity * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SVGAAudioLayer *audioLayer = [[SVGAAudioLayer alloc] initWithAudioItem:obj videoItem:self.videoItem];
        [audioLayers addObject:audioLayer];
    }];
    self.audioLayers = audioLayers;
    
    [self performSelector:@selector(update)];
    [self performSelector:@selector(resize)];
}

- (void)setVideoItem:(SVGAVideoEntity *)videoItem {
    if (videoItem != nil && self.jx_autoPlayShow) {
        self.hidden = false;
    }
    [super setVideoItem:videoItem];
    if (videoItem &&
        self.jx_autoContentMode) {
        self.contentMode = (videoItem.videoSize.width < videoItem.videoSize.height) ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit;
    }
}

#pragma mark - 必要的
- (NSDictionary *)dynamicObjects {
    if (_dynamicObjects == nil) {
        _dynamicObjects = @{};
    }
    return _dynamicObjects;
}

- (NSDictionary *)dynamicTexts {
    if (_dynamicTexts == nil) {
        _dynamicTexts = @{};
    }
    return _dynamicTexts;
}

- (NSDictionary *)dynamicHiddens {
    if (_dynamicHiddens == nil) {
        _dynamicHiddens = @{};
    }
    return _dynamicHiddens;
}

- (NSDictionary<NSString *,SVGAPlayerDynamicDrawingBlock> *)dynamicDrawings {
    if (_dynamicDrawings == nil) {
        _dynamicDrawings = @{};
    }
    return _dynamicDrawings;
}

#pragma mark - 改+方便外部使用
+ (SVGAParser *)jx_sharedParser {
    return sharedParser;
}

+ (NSString *)jx_cacheKey:(NSString *)urlStr {
    return [self MD5String:urlStr];
}

+ (nullable NSString *)jx_cacheDirectory:(NSString *)urlStr {
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    return [cacheDir stringByAppendingFormat:@"/%@", [self MD5String:urlStr]];
}

+ (NSString *)MD5String:(NSString *)str {
    const char *cstr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (CC_LONG)strlen(cstr), result);
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end
