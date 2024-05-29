# SVGAPlayer

[简体中文](./readme.zh.md)

### JXPlus 内容
### 2.5.7.2 修复url下载bug

1. 新增JXSVGAImageViewDelegate，拓展两个代理

 1.1/// 新增error处理，没实现会走svgaPlayerDidFinishedAnimation
 
`- (void)svgaPlayer:(JXSVGAImageView *)player error:(NSError *)error;`

/// 替换元素error

`- (void)svgaPlayer:(JXSVGAImageView *)player forKeyError:(NSError *)error;`


2. 新增jx_autoPlayShow，设置imageName后自动hidden置false,  默认true


### 2.5.7.1 新增文字滚动时间调整
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

### 2.5.7 JXPlus 内容
1. JXSVGAImageView, 使用JXCacheURLSession代替NSURLSession，依赖YYCache实现缓存
2. 新增两个jx_r_替换图片的圆角方法
3. 使用jx_RTLText区分文字滚动右到左
4. jx_autoContentMode 根据size区分contentMode(videoItem.videoSize.width < videoItem.videoSize.height) ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit
## 支持本项目

1. 轻点 GitHub Star，让更多人看到该项目。

## 2.5.0 Released

This version add Support for matte layer and dynamic matte bitmap.<br>
Head on over to [Dynamic · Matte Layer](https://github.com/yyued/SVGAPlayer-iOS/wiki/Dynamic-%C2%B7-Matte-Layer)

This version add Support for audio step to frame & percentage.

## 2.3.5 Released

This version fixed SVGAPlayer `clearsAfterStop defaults too YES`, Please check your player when it doesn't need to be cleared.

This version fixed SVGAPlayer render issue on iOS 13.1, upgrade to this version ASAP.

## Introduce

SVGAPlayer is a light-weight animation renderer. You use [tools](http://svga.io/designer.html) to export `svga` file from `Adobe Animate CC` or `Adobe After Effects`, and then use SVGAPlayer to render animation on mobile application.

`SVGAPlayer-iOS` render animation natively via iOS CoreAnimation Framework, brings you a high-performance, low-cost animation experience.

If wonder more information, go to this [website](http://svga.io/).

## Usage

Here introduce `SVGAPlayer-iOS` usage. Wonder exporting usage? Click [here](http://svga.io/designer.html).

### Install Via CocoaPods

You want to add pod 'SVGAPlayer', '~> 2.3' similar to the following to your Podfile:

target 'MyApp' do
  pod 'SVGAPlayer', '~> 2.3'
end

Then run a `pod install` inside your terminal, or from CocoaPods.app.

### Locate files

SVGAPlayer could load svga file from application bundle or remote server.

### Using code

#### Create a `SVGAPlayer` instance.

```objectivec
SVGAPlayer *player = [[SVGAPlayer alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
[self.view addSubview:player]; // Add subview by yourself.
```

#### Create a `SVGAParser` instance, parse from bundle like this.
```objectivec
SVGAParser *parser = [[SVGAParser alloc] init];
[parser parseWithNamed:@"posche" inBundle:nil completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
    
} failureBlock:nil];
```

#### Create a `SVGAParser` instance, parse from remote server like this.

```objectivec
SVGAParser *parser = [[SVGAParser alloc] init];
[parser parseWithURL:[NSURL URLWithString:@"https://github.com/yyued/SVGA-Samples/blob/master/posche.svga?raw=true"] completionBlock:^(SVGAVideoEntity * _Nullable videoItem) {
    
} failureBlock:nil];
```

#### Set videoItem to `SVGAPlayer`, play it as you want.

```objectivec
[parser parseWithURL:[NSURL URLWithString:@"https://github.com/yyued/SVGA-Samples/blob/master/posche.svga?raw=true"] completionBlock:^(SVGAVideoEntity * _Nullable videoItem) {
    if (videoItem != nil) {
        player.videoItem = videoItem;
        [player startAnimation];
    }
} failureBlock:nil];
```

### Cache

`SVGAParser` use `NSURLSession` request remote data via network. You may use following ways to control cache.

#### Response Header

Server response SVGA files in Body, and response header either. response header has cache-control / etag / expired keys, all these keys telling NSURLSession how to handle cache.

#### Request NSData By Yourself

If you couldn't fix Server Response Header, You should build NSURLRequest with CachePolicy by yourself, and fetch NSData.

Deliver NSData to SVGAParser, as usual.

## Features

Here are many feature samples.

* [Replace an element with Bitmap.](https://github.com/yyued/SVGAPlayer-iOS/wiki/Dynamic-Image)
* [Add text above an element.](https://github.com/yyued/SVGAPlayer-iOS/wiki/Dynamic-Text)
* [Hides an element dynamicaly.](https://github.com/yyued/SVGAPlayer-iOS/wiki/Dynamic-Hidden)
* [Use a custom drawer for element.](https://github.com/yyued/SVGAPlayer-iOS/wiki/Dynamic-Drawer)

## APIs

Head on over to [https://github.com/yyued/SVGAPlayer-iOS/wiki/APIs](https://github.com/yyued/SVGAPlayer-iOS/wiki/APIs)

## CHANGELOG

Head on over to [CHANGELOG](./CHANGELOG.md)
