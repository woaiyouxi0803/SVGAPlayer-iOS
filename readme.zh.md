# SVGAPlayer
### JXPlus 内容

### 2.5.7.5 
圆角处理增加maxDimension限制
try避免奔溃imageWithData崩溃

### 2.5.7.4 修改可能的崩溃
SVGAVectorLayer
Svga.pbobjc.m加头文件

### 2.5.7.3 修复圆角图片替换方法名问题

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
## 2.5.0 版本

该版本增加了对遮罩图层和遮罩图片动态替换的支持。<br>
请参阅此处 [Dynamic · Matte Layer](https://github.com/yyued/SVGAPlayer-iOS/wiki/Dynamic-%C2%B7-Matte-Layer)

该版本增加了对音频进度切换的支持。

## 2.3.5 版本

该版本修正了 SVGAPlayer `clearsAfterStop 默认值为 YES`，请检查代码，修正不需要 clear 的 SVGAPlayer。

该版本修正了 SVGAPlayer 无法在 iOS 13.1 上播放异常的问题，请尽快升级。

## 介绍

`SVGAPlayer` 是一个轻量的动画渲染库。你可以使用[工具](http://svga.io/designer.html)从 `Adobe Animate CC` 或者 `Adobe After Effects` 中导出动画文件，然后使用 `SVGAPlayer` 在移动设备上渲染并播放。

`SVGAPlayer-iOS` 使用原生 CoreAnimation 库渲染动画，为你提供高性能、低开销的动画体验。

如果你想要了解更多细节，请访问[官方网站](http://svga.io/)。

## 用法

我们在这里介绍 `SVGAPlayer-iOS` 的用法。想要知道如何导出动画，点击[这里](http://svga.io/designer.html)。

### 使用 CocoaPods 安装依赖

添加依赖 'SVGAPlayer', '~> 2.3' 到 Podfile 文件中:

target 'MyApp' do
  pod 'SVGAPlayer', '~> 2.3'
end

然后在终端执行 `pod install`。

### 放置 svga 文件

SVGAPlayer 可以从应用包，或者远端服务器上加载动画文件。

### 代码

#### 创建一个 `SVGAPlayer` 实例

```objectivec
SVGAPlayer *player = [[SVGAPlayer alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
[self.view addSubview:player]; // Add subview by yourself.
```

#### 创建一个 `SVGAParser` 实例，使用以下方法从应用包中加载动画。
```objectivec
SVGAParser *parser = [[SVGAParser alloc] init];
[parser parseWithNamed:@"posche" inBundle:nil completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
    
} failureBlock:nil];
```

#### 创建一个 `SVGAParser` 实例，使用以下方法从远端服务器中加载动画。

```objectivec
SVGAParser *parser = [[SVGAParser alloc] init];
[parser parseWithURL:[NSURL URLWithString:@"https://github.com/yyued/SVGA-Samples/blob/master/posche.svga?raw=true"] completionBlock:^(SVGAVideoEntity * _Nullable videoItem) {
    
} failureBlock:nil];
```

#### 将 videoItem 赋值给 `SVGAPlayer`，然后播放动画。

```objectivec
[parser parseWithURL:[NSURL URLWithString:@"https://github.com/yyued/SVGA-Samples/blob/master/posche.svga?raw=true"] completionBlock:^(SVGAVideoEntity * _Nullable videoItem) {
    if (videoItem != nil) {
        player.videoItem = videoItem;
        [player startAnimation];
    }
} failureBlock:nil];
```

### 缓存

`SVGAParser` 使用 `NSURLSession` 请求远端数据，你需要通过以下方式缓存动画文件。

#### HTTP 结果头部信息

如果服务器返回的头部信息包含 cache-control / etag / expired 这些键值，这个请求会被合理地缓存到本地。

#### 自行缓存 NSData

如果你没有办法控制服务器返回的头部信息，你可以自行获取对应的 svga 文件 `NSData` 数据，然后使用 `SVGAParser` 解析这些数据。

## 功能示例

* [使用位图替换指定元素。](https://github.com/yyued/SVGAPlayer-iOS/wiki/Dynamic-Image)
* [在指定元素上绘制文本。](https://github.com/yyued/SVGAPlayer-iOS/wiki/Dynamic-Text)
* [隐藏指定元素。](https://github.com/yyued/SVGAPlayer-iOS/wiki/Dynamic-Hidden)
* [在指定元素上自由绘制。](https://github.com/yyued/SVGAPlayer-iOS/wiki/Dynamic-Drawer)

## APIs

请参阅此处 [https://github.com/yyued/SVGAPlayer-iOS/wiki/APIs](https://github.com/yyued/SVGAPlayer-iOS/wiki/APIs)

## CHANGELOG

请参阅此处 [CHANGELOG](./CHANGELOG.md)
