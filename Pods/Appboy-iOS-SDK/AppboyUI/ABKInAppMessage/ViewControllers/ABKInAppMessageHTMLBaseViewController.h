#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "ABKInAppMessageViewController.h"

NS_ASSUME_NONNULL_BEGIN
static NSString *const ABKInAppMessageHTMLFileName = @"message.html";

@interface ABKInAppMessageHTMLBaseViewController : ABKInAppMessageViewController <WKNavigationDelegate, WKUIDelegate>

/*!
 * The WKWebView used to parse and display the HTML.
 */
@property (nonatomic) WKWebView *webView;

/*!
 * The constraints for top and bottom between view and the super view.
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

/*!
 * The flag specifying if body clicks should be registered automatically. Defaults to NO.
 */
@property (assign, nonatomic, readonly) BOOL automaticBodyClicksEnabled;

@end
NS_ASSUME_NONNULL_END
