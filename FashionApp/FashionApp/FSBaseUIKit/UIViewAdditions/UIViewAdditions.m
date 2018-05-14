
#import "UIViewAdditions.h"
#import <objc/runtime.h>

///////////////////////////////////////////////////////////////////////////////////////////////////
// This code for synthesizing touch events is derived from:
// http://cocoawithlove.com/2008/10/synthesizing-touch-event-on-iphone.html

@interface GSEventFake : NSObject {
  @public
  int ignored1[5];
  float x;
  float y;
  int ignored2[24];
}
@end

@implementation GSEventFake
@end

@interface UIEventFake : NSObject {
  @public
  CFTypeRef _event;
  NSTimeInterval _timestamp;
  NSMutableSet* _touches;
  CFMutableDictionaryRef _keyedTouches;
}
@end

@implementation UIEventFake
@end

@interface UITouch (TTCategory)

- (id)initInView:(UIView *)view location:(CGPoint)location;
- (void)changeToPhase:(UITouchPhase)phase;

@end

@implementation UITouch (TTCategory)

- (id)initInView:(UIView *)view location:(CGPoint)location 
{
	if (self = [super init])
	{
	}
	return self;
}

- (void)changeToPhase:(UITouchPhase)phase {

}

@end

@implementation UIEvent (TTCategory)

- (id)initWithTouch:(UITouch *)touch {
  if (self = [super init]) {
    UIEventFake *selfFake = (UIEventFake*)self;
    selfFake->_touches = [NSMutableSet setWithObject:touch];
    selfFake->_timestamp = [NSDate timeIntervalSinceReferenceDate];

    CGPoint location = [touch locationInView:touch.window];
    GSEventFake* fakeGSEvent = [[GSEventFake alloc] init];
    fakeGSEvent->x = location.x;
    fakeGSEvent->y = location.y;
    selfFake->_event = (__bridge CFTypeRef)(fakeGSEvent);

    CFMutableDictionaryRef dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 2,
      &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue(dict, (__bridge const void *)(touch.view), (__bridge const void *)(selfFake->_touches));
    CFDictionaryAddValue(dict, (__bridge const void *)(touch.window), (__bridge const void *)(selfFake->_touches));
    selfFake->_keyedTouches = dict;
  }
  return self;
}

@end

@implementation UIView (TTCategory)

- (CGFloat)left {
  return self.frame.origin.x;
}

- (void)setLeft:(CGFloat)x {
  CGRect frame = self.frame;
  frame.origin.x = x;
  self.frame = frame;
}

- (CGFloat)top {
  return self.frame.origin.y;
}

- (void)setTop:(CGFloat)y {
  CGRect frame = self.frame;
  frame.origin.y = y;
  self.frame = frame;
}

- (CGFloat)right {
  return self.frame.origin.x + self.frame.size.width;
}

- (void)setRight:(CGFloat)right {
  CGRect frame = self.frame;
  frame.origin.x = right - frame.size.width;
  self.frame = frame;
}

- (CGFloat)bottom {
  return self.frame.origin.y + self.frame.size.height;
}

- (void)setBottom:(CGFloat)bottom {
  CGRect frame = self.frame;
  frame.origin.y = bottom - frame.size.height;
  self.frame = frame;
}

- (CGFloat)centerX {
  return self.center.x;
}

- (void)setCenterX:(CGFloat)centerX {
  self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)centerY {
  return self.center.y;
}

- (void)setCenterY:(CGFloat)centerY {
  self.center = CGPointMake(self.center.x, centerY);
}

- (CGFloat)width {
  return self.frame.size.width;
}

- (void)setWidth:(CGFloat)width {
  CGRect frame = self.frame;
  frame.size.width = width;
  self.frame = frame;
}

- (CGFloat)height {
  return self.frame.size.height;
}

- (void)setHeight:(CGFloat)height {
  CGRect frame = self.frame;
  frame.size.height = height;
  self.frame = frame;
}

- (CGFloat)screenX {
  CGFloat x = 0;
  for (UIView* view = self; view; view = view.superview) {
    x += view.left;
  }
  return x;
}

- (CGFloat)screenY {
  CGFloat y = 0;
  for (UIView* view = self; view; view = view.superview) {
    y += view.top;
  }
  return y;
}

- (CGFloat)screenViewX {
  CGFloat x = 0;
  for (UIView* view = self; view; view = view.superview) {
      x += view.left;

    if ([view isKindOfClass:[UIScrollView class]]) {
      UIScrollView* scrollView = (UIScrollView*)view;
      x -= scrollView.contentOffset.x;
    }
  }
  
  return x;
}

- (CGFloat)screenViewY {
  CGFloat y = 0;
  for (UIView* view = self; view; view = view.superview) {
    y += view.top;

    if ([view isKindOfClass:[UIScrollView class]]) {
      UIScrollView* scrollView = (UIScrollView*)view;
      y -= scrollView.contentOffset.y;
    }
  }
  return y;
}

- (CGRect)screenFrame {
  return CGRectMake(self.screenViewX, self.screenViewY, self.width, self.height);
}

- (CGPoint)offsetFromView:(UIView*)otherView {
  CGFloat x = 0, y = 0;
  for (UIView* view = self; view && view != otherView; view = view.superview) {
    x += view.left;
    y += view.top;
  }
  return CGPointMake(x, y);
}

- (void)setX:(CGFloat)x
{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}
- (CGFloat)x
{
    return self.frame.origin.x;
}
- (void)setY:(CGFloat)y
{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}
- (CGFloat)y
{
    return self.frame.origin.y;
}
- (void)setSize:(CGSize)size
{
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}
- (CGSize)size
{
    return self.frame.size;
}
- (void)setOrigin:(CGPoint)origin
{
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}
- (CGPoint)origin
{
    return self.frame.origin;
}
- (CGFloat)bottomFromSuperView{
    return self.superview.height - self.y - self.height;
}

//- (CGFloat)orientationWidth {
//  //return UIDeviceOrientationIsLandscape(TTDeviceOrientation())
//    //? self.height : self.width;
//}
//
//- (CGFloat)orientationHeight {
//  //return UIDeviceOrientationIsLandscape(TTDeviceOrientation())
//    //? self.width : self.height;
//}

- (UIScrollView*)findFirstScrollView {
  if ([self isKindOfClass:[UIScrollView class]])
    return (UIScrollView*)self;
  
  for (UIView* child in self.subviews) {
    UIScrollView* it = [child findFirstScrollView];
    if (it)
      return it;
  }
  
  return nil;
}

- (UIView*)firstViewOfClass:(Class)cls {
  if ([self isKindOfClass:cls])
    return self;
  
  for (UIView* child in self.subviews) {
    UIView* it = [child firstViewOfClass:cls];
    if (it)
      return it;
  }
  
  return nil;
}

- (UIView*)firstParentOfClass:(Class)cls {
  if ([self isKindOfClass:cls]) {
    return self;
  } else if (self.superview) {
    return [self.superview firstParentOfClass:cls];
  } else {
    return nil;
  }
}

- (UIView*)findChildWithDescendant:(UIView*)descendant {
  for (UIView* view = descendant; view && view != self; view = view.superview) {
    if (view.superview == self) {
      return view;
    }
  }
  
  return nil;
}

- (void)removeSubviews {
  while (self.subviews.count) {
    UIView* child = self.subviews.lastObject;
      if(child)
      {
          child.hidden = YES;
          [child removeFromSuperview];
      }
  }
}

- (void)simulateTapAtPoint:(CGPoint)location {
  UITouch *touch = [[UITouch alloc] initInView:self location:location];

  UIEvent *eventDown = [[UIEvent alloc] initWithTouch:touch];
  [touch.view touchesBegan:[NSSet setWithObject:touch] withEvent:eventDown];

  [touch changeToPhase:UITouchPhaseEnded];

  UIEvent *eventUp = [[UIEvent alloc] initWithTouch:touch];
  [touch.view touchesEnded:[NSSet setWithObject:touch] withEvent:eventUp];
}
- (void)viewAddTopLine
{
    UIView *line = [[UIView alloc] initWithFrame:CGRectIntegral(CGRectMake(0, 0, self.width, 1/[UIScreen mainScreen].scale))];
    line.backgroundColor = [UIColor blackColor];//[UIColor colorWithHexValue:0xd8d8dc];
    [self addSubview:line];
}
- (void)viewAddTopLine:(CGFloat)aOffsetx
{
    UIView *line = [[UIView alloc] initWithFrame:CGRectIntegral(CGRectMake(aOffsetx, 0, self.width-aOffsetx, 1/[UIScreen mainScreen].scale))];
    line.backgroundColor = [UIColor blackColor];//[UIColor colorWithHexValue:0xd8d8dc];
    [self addSubview:line];
}
- (void)viewAddMiddleLine:(CGFloat)aOffsetx
{
    UIView *line = [[UIView alloc] initWithFrame:CGRectIntegral(CGRectMake(aOffsetx, 0, self.width-aOffsetx*2, 1/[UIScreen mainScreen].scale))];
    line.backgroundColor = [UIColor blackColor];//[UIColor colorWithHexValue:0xd8d8dc];
    [self addSubview:line];
}
- (void)viewAddBottomLine
{
    UIView *line = [[UIView alloc] initWithFrame:CGRectIntegral(CGRectMake(0, self.height-1/[UIScreen mainScreen].scale, kMainScreenWidth, 1/[UIScreen mainScreen].scale))];
    line.backgroundColor = RGBCOLOR(238, 238, 238);
    [self addSubview:line];
}
- (UIView *)getViewLine:(CGRect)aRect
{
    UIView *line = [[UIView alloc] initWithFrame:CGRectIntegral(aRect)];
    line.backgroundColor = [UIColor blackColor];//[UIColor colorWithHexValue:0xd8d8dc];
    return line;
}
-(UILabel*) labelWithFrame:(CGRect)frame
                      text:(NSString*)text
                  textFont:(UIFont*)font
                 textColor:(UIColor*)color
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectIntegral(frame)];
    label.backgroundColor = [UIColor clearColor];
    label.text = text;
    label.font = font;
    label.textColor = color;
    return label;
}
- (UIButton *) buttonWithFrame:(CGRect)frame
                     titleFont:(UIFont *)aFont
            titleStateNorColor:(UIColor *)atitleColor
                 titleStateNor:(NSString *)aTitle
{
    UIButton *bt = [[UIButton alloc] initWithFrame:CGRectIntegral(frame)];
    bt.titleLabel.font = aFont;
    [bt setTitleColor:atitleColor forState:UIControlStateNormal];
    [bt setTitle:aTitle forState:UIControlStateNormal];
    bt.backgroundColor = [UIColor clearColor];
    return bt;
}
- (void)addTarget:(id)target
           action:(SEL)action;
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:target
                                                                         action:action];
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:tap];
}
//- (UIView *)tableviewFootView:(CGRect)aRect
//{
//    UILabel *label = [self labelWithFrame:aRect text:@"网络异常,请检查后重试！" textFont:kFont13 textColor:kGrayColor];
//    label.textAlignment = NSTextAlignmentCenter;
//    return label;
//}


static char PresentedViewAddress;   //被Present的View
static char PresentingViewAddress;  //正在Present其他视图的view
#define AnimateDuartion .25f
- (void)presentView:(UIView*)view animated:(BOOL)animated complete:(void(^)(void)) complete{
    if (!self.window) {
        return;
    }
    [self.window addSubview:view];
    objc_setAssociatedObject(self, &PresentedViewAddress, view, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(view, &PresentingViewAddress, self, OBJC_ASSOCIATION_RETAIN);
    if (animated) {
        [self doAlertAnimate:view complete:complete];
    }else{
        view.center = self.window.center;
    }
}

- (UIView *)presentedView{
    UIView * view =  objc_getAssociatedObject(self, &PresentedViewAddress);
    return view;
}

- (void)dismissPresentedView:(BOOL)animated complete:(void(^)(void)) complete{
    UIView * view =  objc_getAssociatedObject(self, &PresentedViewAddress);
    if (animated) {
        [self doHideAnimate:view complete:complete];
    }else{
        [view removeFromSuperview];
        [self cleanAssocaiteObject];
    }
}

- (void)hideSelf:(BOOL)animated complete:(void(^)(void)) complete{
    UIView * baseView =  objc_getAssociatedObject(self, &PresentingViewAddress);
    if (!baseView) {
        return;
    }
    [baseView dismissPresentedView:animated complete:complete];
    [self cleanAssocaiteObject];
}


- (void)onPressBkg:(id)sender{
    [self dismissPresentedView:YES complete:nil];
}

#pragma mark - Animation
- (void)doAlertAnimate:(UIView*)view complete:(void(^)(void)) complete{
    CGRect bounds = view.bounds;
    // 放大
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
    scaleAnimation.duration  = AnimateDuartion;
    scaleAnimation.fromValue = [NSValue valueWithCGRect:CGRectMake(0, 0, 1, 1)];
    scaleAnimation.toValue   = [NSValue valueWithCGRect:bounds];
    
    // 移动
    CABasicAnimation *moveAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    moveAnimation.duration   = AnimateDuartion;
    moveAnimation.fromValue  = [NSValue valueWithCGPoint:[self.superview convertPoint:self.center toView:nil]];
    moveAnimation.toValue    = [NSValue valueWithCGPoint:self.window.center];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.beginTime				= CACurrentMediaTime();
    group.duration				= AnimateDuartion;
    group.animations			= [NSArray arrayWithObjects:scaleAnimation,moveAnimation,nil];
    group.timingFunction		= [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
//    group.delegate                = self;
    group.fillMode				= kCAFillModeForwards;
    group.removedOnCompletion	= NO;
    group.autoreverses			= NO;
    
    [self hideAllSubView:view];
    
    [view.layer addAnimation:group forKey:@"groupAnimationAlert"];
    
    __weak UIView * wself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(AnimateDuartion * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        view.layer.bounds    = bounds;
        view.layer.position  = wself.superview.center;
        [wself showAllSubView:view];
        if (complete) {
            complete();
        }
    });
    
}

- (void)doHideAnimate:(UIView*)alertView complete:(void(^)(void)) complete{
    if (!alertView) {
        return;
    }
    // 缩小
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
    scaleAnimation.duration = AnimateDuartion;
    scaleAnimation.toValue  = [NSValue valueWithCGRect:CGRectMake(0, 0, 1, 1)];
    
    CGPoint position   = self.center;
    // 移动
    CABasicAnimation *moveAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    moveAnimation.duration = AnimateDuartion;
    moveAnimation.toValue  = [NSValue valueWithCGPoint:[self.superview convertPoint:self.center toView:nil]];
    
    CAAnimationGroup *group   = [CAAnimationGroup animation];
    group.beginTime           = CACurrentMediaTime();
    group.duration            = AnimateDuartion;
    group.animations          = [NSArray arrayWithObjects:scaleAnimation,moveAnimation,nil];
    group.timingFunction      = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
//    group.delegate            = self;
    group.fillMode            = kCAFillModeForwards;
    group.removedOnCompletion = NO;
    group.autoreverses        = NO;
    
    
    alertView.layer.bounds    = self.bounds;
    alertView.layer.position  = position;
    alertView.layer.needsDisplayOnBoundsChange = YES;
    
    [self hideAllSubView:alertView];
    alertView.backgroundColor = [UIColor clearColor];
    
    [alertView.layer addAnimation:group forKey:@"groupAnimationHide"];
    
    __weak UIView * wself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(AnimateDuartion * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alertView removeFromSuperview];
        [wself cleanAssocaiteObject];
        [wself showAllSubView:alertView];
        if (complete) {
            complete();
        }
    });
}


static char *HideViewsAddress = "hideViewsAddress";
- (void)hideAllSubView:(UIView*)view{
    for (UIView * subView in view.subviews) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        if (subView.hidden) {
            [array addObject:subView];
        }
        objc_setAssociatedObject(self, &HideViewsAddress, array, OBJC_ASSOCIATION_RETAIN);
        subView.hidden = YES;
    }
}

- (void)showAllSubView:(UIView*)view{
    NSMutableArray *array = objc_getAssociatedObject(self,&HideViewsAddress);
    for (UIView * subView in view.subviews) {
        subView.hidden = [array containsObject:subView];
    }
}

- (void)cleanAssocaiteObject{
    objc_setAssociatedObject(self,&PresentedViewAddress,nil,OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self,&PresentingViewAddress,nil,OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self,&HideViewsAddress,nil, OBJC_ASSOCIATION_RETAIN);
}

- (void)makeCenterToastActivity
{
//    if([self respondsToSelector:@selector(makeToastActivity:)])
//    {
//        [self hideToastActivity];
//        [self performSelector:@selector(makeToastActivity:) withObject:CSToastPositionCenter];
//    }
}
@end
