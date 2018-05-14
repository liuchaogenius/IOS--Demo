//
//  FSPublic.h
//  FashionApp
//
//  Created by 1 on 2018/4/10.
//  Copyright © 2018年 1. All rights reserved.
//

#ifndef FSPublic_h
#define FSPublic_h

#define  kFSAPPID 203864
#define  kWEIXINLoginAppid @"wxa4c083e3fcf06c80"
//#define  kWEXINAppSecret @"2de3d3a83645f9882747971ffb64203b"

#define  kQQLoginAPPID @"1105859480"

#define kUPLoadVideoAPPID  @"1254126712"

#define  kFSAPPSHORTVERSION  [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"]

#ifdef DEBUG
#define DebugLog(...)  printf("\n\t<%s line%d>\n%s\n", __FUNCTION__,__LINE__,[[NSString stringWithFormat:__VA_ARGS__] UTF8String])

#else
#define NSLog(...) {}
#define DebugLog(...) {}
#endif

#define kMainScreenHeight [UIScreen mainScreen].bounds.size.height
#define kMainScreenWidth   [UIScreen mainScreen].bounds.size.width

#define WeakSelf(type)  __weak typeof(type) weak##type = type;

#define StrongSelf(type)  __strong typeof(type) type = weak##type;

#define isNull(a) [a isKindOfClass:[NSNull class]]
#define kShortColor(r) [UIColor colorWithRed:r/256.0 green:r/256.0 blue:r/256.0 alpha:1]
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:r/256.0 green:g/256.0 blue:b/256.0 alpha:1]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:r/256.0 green:g/256.0 blue:b/256.0 alpha:a]
#define ShortColor(c)   [UIColor colorWithRed:(c)/255.0f green:(c)/255.0f blue:(c)/255.0f alpha:(1)]

#define QLog_InfoP(...) {}
#define QLog_Event(...) {}
#define QLog_Info(...) {}

//坐标适配
#define FIXSIZE(n) lrintf((n * [UIScreen mainScreen].bounds.size.width / 375.0f))

//字体相关
#define FONT_SIZE(f)            [UIFont systemFontOfSize:(FIXSIZE(f))]
#define FONT_BOLD_SIZE(f)       [UIFont boldSystemFontOfSize:(FIXSIZE(f))]
#define FONT_ITALIC_SIZE(f)     [UIFont italicSystemFontOfSize:(FIXSIZE(f))]

//图片相关
#define IMG_Name(imgName)        [UIImage imageNamed:(imgName)]

#define IMG_ImgWidth(img)        ((img).size.width)
#define IMG_ImgHeight(img)       ((img).size.height)

//IphoneX 用到的宏
// 判断是否是iPhone X
#define iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
// 状态栏高度
#define STATUS_BAR_HEIGHT (iPhoneX ? 44.f : 20.f)
// 导航栏高度
#define NAVIGATION_BAR_HEIGHT (iPhoneX ? 88.f : 64.f)
// tabBar高度
#define TAB_BAR_HEIGHT (iPhoneX ? (49.f+34.f) : 49.f)
// home indicator
#define HOME_INDICATOR_HEIGHT (iPhoneX ? 34.f : 0.f)

#endif /* FSPublic_h */
