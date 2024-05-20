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
- (UIImage*)jx_2RoundedCorner {
    CGFloat w = self.size.width;
    CGFloat h = self.size.height;
    
    CGFloat radius = MIN(w, h) / 2.0;
    CGRect frame = CGRectMake(0, 0, 2 * radius, 2 * radius);

    UIImage *image = nil;
    UIGraphicsBeginImageContext(frame.size);
    [[UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:radius] addClip];
    [self drawInRect:frame];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
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
        NSURL *url = [NSURL URLWithString:imageName];
        [JXCacheURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            [NSOperationQueue.mainQueue addOperationWithBlock:^{
                if (error) {
                    if ([self.delegate respondsToSelector:@selector(svgaPlayerDidFinishedAnimation:)]) {
                        [self.delegate svgaPlayerDidFinishedAnimation:nil];
                    }
                    return;
                }
                [sharedParser parseWithData:data cacheKey:[self cacheKey:url] completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
                    [self setVideoItem:videoItem];
                    if (self.autoPlay) {
                        [self startAnimation];
                    }
                } failureBlock:^(NSError * _Nonnull error) {
                    if ([self.delegate respondsToSelector:@selector(svgaPlayerDidFinishedAnimation:)]) {
                        [self.delegate svgaPlayerDidFinishedAnimation:nil];
                    }
                }];
            }];
        }];
    }
    else {
        [sharedParser parseWithNamed:imageName inBundle:nil completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
            [self setVideoItem:videoItem];
            if (self.autoPlay) {
                [self startAnimation];
            }
        } failureBlock:^(NSError * _Nonnull error) {
            if ([self.delegate respondsToSelector:@selector(svgaPlayerDidFinishedAnimation:)]) {
                [self.delegate svgaPlayerDidFinishedAnimation:nil];
            }
        }];
    }
}


- (void)setImageWithURL:(NSURL *)URL forKey:(NSString *)aKey {
    [[JXCacheURLSession.sharedSession dataTaskWithURL:URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil && data != nil) {
            UIImage *image = [UIImage imageWithData:data];
            if (image != nil) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self setImage:image forKey:aKey];
                }];
            }
        }
    }] resume];
}

#pragma mark - 设置圆角
- (void)r_setImage:(UIImage *)image forKey:(NSString *)aKey {
    [self setImage:[image jx_2RoundedCorner] forKey:aKey];
}

- (void)r_setImageWithURL:(NSURL *)URL forKey:(NSString *)aKey {
    [[JXCacheURLSession.sharedSession dataTaskWithURL:URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil && data != nil) {
            UIImage *image = [UIImage imageWithData:data];
            if (image != nil) {
                image = [image jx_2RoundedCorner];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self setImage:image forKey:aKey];
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
                    
                    CGFloat duration = ((CGFloat)self.videoItem.frames) /self.videoItem.FPS;
                    if (duration - 2 > 0) {
                        animation.duration = duration - 2;
                        animation.beginTime = CACurrentMediaTime() + 1;
                    } else {
                        animation.duration = duration;
                        animation.beginTime = CACurrentMediaTime();
                    }
                    
                    animation.repeatCount = 0;
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
    super.videoItem = videoItem;
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

#pragma mark - 复制
- (nonnull NSString *)cacheKey:(NSURL *)URL {
    return [self MD5String:URL.absoluteString];
}

- (nullable NSString *)cacheDirectory:(NSString *)cacheKey {
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    return [cacheDir stringByAppendingFormat:@"/%@", cacheKey];
}

- (NSString *)MD5String:(NSString *)str {
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
