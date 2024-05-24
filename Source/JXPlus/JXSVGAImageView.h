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

/// 根据size区分contentMode (videoItem.videoSize.width < videoItem.videoSize.height) ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit
@property (nonatomic, assign) BOOL jx_autoContentMode;


/// 文字滚动右到左
@property (nonatomic, assign) BOOL jx_RTLText;

/// 文字重复次数。默认0不重复
@property (nonatomic, assign) float jx_textRepeatCount;
/// 文字初始停留时间。默认1.0
@property (nonatomic, assign) CFTimeInterval jx_textBeginStayTime;

/// 文字滚动时间，默认0；设置后无视jx_textEndStayTime（优先级高1，动画结束不一定滚动完）
@property (nonatomic, assign) CFTimeInterval jx_textDuration;
/// 文字滚动速率，默认0；（优先级次高2，动画结束不一定滚动完，相当于jx_textDuration = 文字长度 * jx_textRate ）
@property (nonatomic, assign) CFTimeInterval jx_textRate;
/// 文字滚动结束后停留时间。默认1.0 （优先级最低3。 jx_textBeginStayTime + （自动计算）滚动时间 + jx_textEndStayTime = SVGA总动画时长，计算小于0则未滚动完）
@property (nonatomic, assign) CFTimeInterval jx_textEndStayTime;




@end

NS_ASSUME_NONNULL_END
