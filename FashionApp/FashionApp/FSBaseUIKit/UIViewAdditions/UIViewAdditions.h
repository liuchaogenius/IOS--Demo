#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface UIView (TTCategory)

@property(nonatomic) CGFloat left;
@property(nonatomic) CGFloat top;
@property(nonatomic) CGFloat right;
@property(nonatomic) CGFloat bottom;

@property(nonatomic) CGFloat width;
@property(nonatomic) CGFloat height;

@property(nonatomic) CGFloat centerX;
@property(nonatomic) CGFloat centerY;

@property(nonatomic,readonly) CGFloat screenX;
@property(nonatomic,readonly) CGFloat screenY;
@property(nonatomic,readonly) CGFloat screenViewX;
@property(nonatomic,readonly) CGFloat screenViewY;
@property(nonatomic,readonly) CGRect screenFrame;

@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign, readonly) CGFloat bottomFromSuperView;

//@property(nonatomic,readonly) CGFloat orientationWidth;
//@property(nonatomic,readonly) CGFloat orientationHeight;

- (UIScrollView*)findFirstScrollView;

- (UIView*)firstViewOfClass:(Class)cls;

- (UIView*)firstParentOfClass:(Class)cls;

- (UIView*)findChildWithDescendant:(UIView*)descendant;

/**
 * Removes all subviews.
 */
- (void)removeSubviews;

/**
 * WARNING: This depends on undocumented APIs and may be fragile.  For testing only.
 */
- (void)simulateTapAtPoint:(CGPoint)location;

- (CGPoint)offsetFromView:(UIView*)otherView;

- (void)viewAddTopLine;

- (void)viewAddTopLine:(CGFloat)aOffsetx;

- (void)viewAddMiddleLine:(CGFloat)aOffsetx;

- (UIView *)getViewLine:(CGRect)aRect;

//- (void)viewaddCircleLine;

- (void)viewAddBottomLine;

-(UILabel*) labelWithFrame:(CGRect)frame
                      text:(NSString*)text
                  textFont:(UIFont*)font
                 textColor:(UIColor*)color;

- (UIButton *) buttonWithFrame:(CGRect)frame
                     titleFont:(UIFont *)aFont
            titleStateNorColor:(UIColor *)atitleColor
                 titleStateNor:(NSString *)aTitle;

/**
 *  2.UIView 的点击事件
 *
 *  @param target   目标
 *  @param action   事件
 */

- (void)addTarget:(id)target
           action:(SEL)action;

//- (UIView *)tableviewFootView:(CGRect)aRect;

- (void)makeCenterToastActivity;

//弹出一个类似present效果的窗口
- (void)presentView:(UIView*)view animated:(BOOL)animated complete:(void(^)(void)) complete;

//获取一个view上正在被present的view
- (UIView *)presentedView;

- (void)dismissPresentedView:(BOOL)animated complete:(void(^)(void)) complete;

//这个是被present的窗口本身的方法
//如果自己是被present出来的，消失掉
- (void)hideSelf:(BOOL)animated complete:(void(^)(void)) complete;

@end
