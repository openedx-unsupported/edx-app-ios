#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ABKURLDelegate.h"

@interface ABKUIURLUtils : NSObject

+ (BOOL)URLDelegate:(id<ABKURLDelegate>)urlDelegate
         handlesURL:(NSURL *)url
        fromChannel:(ABKChannel)channel
         withExtras:(NSDictionary *)extras;
+ (BOOL)URL:(NSURL *)url shouldOpenInWebView:(BOOL)openUrlInWebView;
+ (BOOL)URLHasSystemScheme:(NSURL *)url;
+ (void)openURLWithSystem:(NSURL *)url;
+ (UIViewController *)topmostViewControllerWithRootViewController:(UIViewController *)viewController;
+ (void)displayModalWebViewWithURL:(NSURL *)url
             topmostViewController:(UIViewController *)topmostViewController;
+ (NSURL *)getEncodedURIFromString:(NSString *)uriString;
@end
