#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Appboy.h"

@interface ABKUIUtils : NSObject

/*!
 * The currently active UIWindowScene.
 */
@property (class, nonatomic, readonly) UIWindowScene *activeWindowScene API_AVAILABLE(ios(13.0));

/*!
 * The currently active application UIWindow.
 */
@property (class, nonatomic, readonly) UIWindow *activeApplicationWindow;

/*!
 * The currently active application UIViewController.
 */
@property (class, nonatomic, readonly) UIViewController *activeApplicationViewController;

/*!
 * The current application status bar hidden state.
 */
@property (class, readonly) BOOL applicationStatusBarHidden;

/*!
 * The current application status bar style.
 */
@property (class, readonly) UIStatusBarStyle applicationStatusBarStyle;

/*!
 * Given a class and a channel, this method searches across multiple locations and returns the appropriate
 * bundle.
 * @param bundleClass The class associated with the bundle.
 * @param channel The channel associated with the bundle.
 * @returns The bundle if available, nil otherwise.
 */
+ (NSBundle *)bundle:(Class)bundleClass channel:(ABKChannel)channel;

+ (NSString *)getLocalizedString:(NSString *)key inAppboyBundle:(NSBundle *)appboyBundle table:(NSString *)table;
+ (BOOL)objectIsValidAndNotEmpty:(id)object;
+ (Class)getModalFeedViewControllerClass;
+ (BOOL)isNotchedPhone;
+ (UIImage *)getImageWithName:(NSString *)name
                         type:(NSString *)type
               inAppboyBundle:(NSBundle *)appboyBundle;
+ (UIInterfaceOrientation)getInterfaceOrientation;
+ (CGSize)getStatusBarSize;
+ (UIColor *)dynamicColorForLightColor:(UIColor *)lightColor
                             darkColor:(UIColor *)darkColor;
+ (BOOL)string:(NSString *)string1 isEqualToString:(NSString *)string2;

/*!
 * Verifies that one of the responders in the responder chain is kind of class aClass.
 * @param responder The start of the UIResponder chain.
 * @param aClass The UIResponder subclass looked for in the responder chain.
 * @return YES if aClass is found in the responder chain, NO otherwise.
 */
+ (BOOL)responderChainOf:(UIResponder *)responder hasKindOfClass:(Class)aClass;

/*!
 * Verifies that one of the responders in the responder chain is prefixed by prefix.
 * @param responder The start of the UIResponder chain.
 * @param prefix The prefix looked for in the responder chain.
 * @return YES if a class prefixed by prefix is found in the responder chain, NO otherwise.
 */
+ (BOOL)responderChainOf:(UIResponder *)responder hasClassPrefixedWith:(NSString *)prefix;

/*!
 * Creates an instance of the font associated with the text style and scaled appropriately for the
 * user's selected content size category.
 *
 * @warning On iOS 10 / tvOS 10 and below, this method does not apply the text style to the
 * resulting font. The font size is chosen according to https://apple.co/3snncd9 (Large / Default).
 *
 * @param textStyle The text style to use
 * @param weight The weight of the font
 * @return The font corresponding to the text style with weight applied to it.
 */
+ (UIFont *)preferredFontForTextStyle:(UIFontTextStyle)textStyle weight:(UIFontWeight)weight;

@end
