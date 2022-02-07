#import "ABKUIURLUtils.h"
#import "ABKUIUtils.h"
#import "ABKModalWebViewController.h"
#import "Appboy.h"

@interface ABKUIURLUtils ()

+ (NSString *)trim:(NSString *)string;

@end

@implementation ABKUIURLUtils

+ (BOOL)URLDelegate:(id<ABKURLDelegate>)urlDelegate
         handlesURL:(NSURL *)url
        fromChannel:(ABKChannel)channel
         withExtras:(NSDictionary *)extras {
  if (![ABKUIURLUtils URLDelegateIsValid:urlDelegate]) {
    NSLog(@"Not handling URL %@ with invalid ABKURLDelegate %@.",
          url.absoluteString, urlDelegate);
    return NO;
  }
  if ([urlDelegate handleAppboyURL:url fromChannel:channel withExtras:extras]) {
    NSLog(@"Handled URL %@ with external ABKURLDelegate %@.",
          url.absoluteString, urlDelegate);
    return YES;
  }
  return NO;
}

+ (BOOL)URLDelegateIsValid:(id<ABKURLDelegate>)urlDelegate {
  return [urlDelegate respondsToSelector:@selector(handleAppboyURL:fromChannel:withExtras:)];
}

+ (BOOL)URL:(NSURL *)url shouldOpenInWebView:(BOOL)openUrlInWebView {
  if ([ABKUIUtils objectIsValidAndNotEmpty:url.absoluteString] && openUrlInWebView) {
    if ([ABKUIURLUtils URLHasValidWebScheme:url]) {
      return YES;
    } else {
      NSLog(@"Unsupported web URL scheme received: %@. Not opening URL in web view.", url.absoluteString);
    }
  }
  return NO;
}

+ (BOOL)URLHasValidWebScheme:(NSURL *)url {
  return ([ABKUIUtils string:[url.scheme lowercaseString] isEqualToString:@"http"] ||
          [ABKUIUtils string:[url.scheme lowercaseString] isEqualToString:@"https"]);
}

+ (BOOL)URLHasSystemScheme:(NSURL *)url {
  static dispatch_once_t once;
  static NSSet<NSString *> *systemSchemes;
  dispatch_once(&once, ^{
    systemSchemes = [NSSet setWithArray:@[
      @"mailto",
      @"tel",
      @"facetime",
      @"facetime-audio",
      @"sms"
    ]];
  });

  return [systemSchemes containsObject:[url.scheme lowercaseString]];
}

+ (void)openURLWithSystem:(NSURL *)url {
  if (![NSThread isMainThread]) {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self openURL:url];
    });
  } else {
    [self openURL:url];
  }
}

+ (void)openURL:(NSURL *)url {
  if (@available(iOS 13.0, *)) {
    UIWindowScene *windowScene = ABKUIUtils.activeWindowScene;
    if (windowScene) {
      [windowScene openURL:url options:nil completionHandler:nil];
      return;
    }
  }
  
  if (@available(iOS 10.0, *)) {
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    return;
  }
  
  [[UIApplication sharedApplication] openURL:url];
}

+ (UIViewController *)topmostViewControllerWithRootViewController:(UIViewController *)viewController {
  while (viewController.presentedViewController) {
    viewController = viewController.presentedViewController;
  }
  return viewController;
}

+ (void)displayModalWebViewWithURL:(NSURL *)URL
             topmostViewController:(UIViewController *)topmostViewController {
  ABKModalWebViewController *webViewController = [[ABKModalWebViewController alloc] init];
  webViewController.url = URL;
  [topmostViewController presentViewController:webViewController animated:YES completion:nil];
}

+ (NSURL *)getEncodedURIFromString:(NSString *)uriString {
  if (![ABKUIUtils objectIsValidAndNotEmpty:uriString]) {
    return nil;
  }
  uriString = [ABKUIURLUtils trim:uriString];
  NSURL *parsedUrl = [NSURL URLWithString:uriString];
  // If the uriString is an invalid uri, e.g. an uri with unicode, URLWithString: will return nil.
  if (!parsedUrl) {
    // When the uriString has unicode, we have to escape those characters
    uriString = [uriString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    parsedUrl = [NSURL URLWithString:uriString];
  }
  return parsedUrl;
}

+ (NSString *)trim:(NSString *)string {
  if ([string isKindOfClass:[NSString class]]) {
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  }

  NSLog(@"Calling `trim` with invalid class: %@, value: %@. Returning nil.",
        [string class], string);
  return nil;
}

@end
