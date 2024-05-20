//
//  JXSVGAImageView.h
//  DDitto
//
//  Created by loong on 2024/5/15.
//

#import "SVGAPlayer.h"
#import "SVGAParser.h"

NS_ASSUME_NONNULL_BEGIN

@interface JXSVGAImageView : SVGAPlayer
/// 本地svga名/ http的URL
@property (nonatomic, copy) IBInspectable NSString *imageName;
/// 设置imageName后自动播放, 默认true
@property (nonatomic, assign) IBInspectable BOOL autoPlay;

/// 圆角图片替换
- (void)jx_r_setImage:(UIImage *)image forKey:(NSString *)aKey;
/// 圆角图片替换
- (void)jx_r_setImageWithURL:(NSURL *)URL forKey:(NSString *)aKey;

/// 区分文字滚动右到左
@property (nonatomic, assign) BOOL jx_RTLText;

/// 根据size区分contentMode (videoItem.videoSize.width < videoItem.videoSize.height) ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit
@property (nonatomic, assign) BOOL jx_autoContentMode;



@end

NS_ASSUME_NONNULL_END
