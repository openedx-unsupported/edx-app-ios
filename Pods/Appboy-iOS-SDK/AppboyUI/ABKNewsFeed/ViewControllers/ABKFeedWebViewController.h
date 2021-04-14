#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface ABKFeedWebViewController : UIViewController <WKNavigationDelegate>

/*!
 * The URL the modal web view controller should open. Please note that this is the initial URL and
 * won't be updated if the initial URL re-directs to another URL.
 */
@property NSURL *url;

/*!
 * The WKWebView which displays the web page.
 */
@property (nonatomic) IBOutlet WKWebView *webView;

/*!
 * The UIProgressView which shows the web view loading process. It will be on top of the web view and
 * will disappear as soon as the page is loaded.
 */
@property (nonatomic) IBOutlet UIProgressView *progressBar;

/*!
 * The property tells the web view controller to add a Done button or not. The default value is NO.
 * Please set this property before displaying the web view controller.
 */
@property (nonatomic) BOOL showDoneButton;

@end
