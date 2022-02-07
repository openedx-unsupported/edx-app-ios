#import "ABKInAppMessageHTMLBaseViewController.h"
#import "ABKInAppMessageView.h"
#import "ABKUIUtils.h"
#import "ABKInAppMessageWindowController.h"
#import "ABKInAppMessageWebViewBridge.h"

static NSString *const ABKBlankURLString = @"about:blank";
static NSString *const ABKHTMLInAppButtonIdKey = @"abButtonId";
static NSString *const ABKHTMLInAppAppboyKey = @"appboy";
static NSString *const ABKHTMLInAppCloseKey = @"close";
static NSString *const ABKHTMLInAppFeedKey = @"feed";
static NSString *const ABKHTMLInAppCustomEventKey = @"customEvent";
static NSString *const ABKHTMLInAppCustomEventQueryParamNameKey = @"name";
static NSString *const ABKHTMLInAppExternalOpenKey = @"abExternalOpen";
static NSString *const ABKHTMLInAppDeepLinkKey = @"abDeepLink";
static NSString *const ABKHTMLInAppJavaScriptExtension = @"js";

@interface ABKInAppMessageHTMLBaseViewController () <ABKInAppMessageWebViewBridgeDelegate>

@property (nonatomic) ABKInAppMessageWebViewBridge *webViewBridge;

@end

@implementation ABKInAppMessageHTMLBaseViewController

#pragma mark - Properties

- (BOOL)automaticBodyClicksEnabled {
  return NO;
}

#pragma mark - View Lifecycle

- (void)loadView {
  // View needs to be an ABKInAppMessageView to ensure touches register as per custom logic
  // in ABKInAppMessageWindow. The frame is set in `beforeMoveInAppMessageViewOnScreen`.
  self.view = [[ABKInAppMessageView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.view.translatesAutoresizingMaskIntoConstraints = NO;
  
  NSLayoutConstraint *leadConstraint = [self.view.leadingAnchor constraintEqualToAnchor:self.view.superview.leadingAnchor];
  NSLayoutConstraint *trailConstraint = [self.view.trailingAnchor constraintEqualToAnchor:self.view.superview.trailingAnchor];

  // Top and bottom constants will be populated with the actual frame sizes after
  // the HTML content is fully loaded in `beforeMoveInAppMessageViewOnScreen`
#if TARGET_OS_MACCATALYST
  // Within safe zone
  self.topConstraint = [self.view.topAnchor constraintEqualToAnchor:self.view.superview.layoutMarginsGuide.topAnchor];
  self.bottomConstraint = [self.view.bottomAnchor constraintEqualToAnchor:self.view.superview.layoutMarginsGuide.bottomAnchor];
#else
  // Extends to the edges of the screen
  self.topConstraint = [self.view.topAnchor constraintEqualToAnchor:self.view.superview.topAnchor];
  self.bottomConstraint = [self.view.bottomAnchor constraintEqualToAnchor:self.view.superview.bottomAnchor];
#endif

  [self.view.superview addConstraints:@[leadConstraint, trailConstraint, self.topConstraint, self.bottomConstraint]];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.edgesForExtendedLayout = UIRectEdgeNone;
  WKWebViewConfiguration *webViewConfiguration = [[WKWebViewConfiguration alloc] init];
  webViewConfiguration.allowsInlineMediaPlayback = YES;
  webViewConfiguration.suppressesIncrementalRendering = YES;
  if (@available(iOS 10.0, *)) {
    webViewConfiguration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;
  } else {
    webViewConfiguration.requiresUserActionForMediaPlayback = YES;
  }
  
  ABKInAppMessageWindowController *parentViewController =
    (ABKInAppMessageWindowController *)self.parentViewController;
  if ([parentViewController.inAppMessageUIDelegate respondsToSelector:@selector(setCustomWKWebViewConfiguration)]) {
    webViewConfiguration = [parentViewController.inAppMessageUIDelegate setCustomWKWebViewConfiguration];
  }

  WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:webViewConfiguration];
  self.webView = webView;
  
  self.webViewBridge = [[ABKInAppMessageWebViewBridge alloc] initWithWebView:webView
                                                                inAppMessage:(ABKInAppMessageHTML *)self.inAppMessage appboyInstance:[Appboy sharedInstance]];
  self.webViewBridge.delegate = self;

  self.webView.allowsLinkPreview = NO;
  self.webView.navigationDelegate = self;
  self.webView.UIDelegate = self;
  self.webView.scrollView.bounces = NO;
  
  // Handle resizing during orientation changes
  self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  if (@available(iOS 11.0, *)) {
    // Cover status bar when showing HTML IAMs
    [self.webView.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
  }
  if (((ABKInAppMessageHTMLBase *)self.inAppMessage).assetsLocalDirectoryPath != nil) {
    NSString *localPath = [((ABKInAppMessageHTMLBase *)self.inAppMessage).assetsLocalDirectoryPath absoluteString];
    // Here we must use fileURLWithPath: to add the "file://" scheme, otherwise the webView won't recognize the
    // base URL and won't load the zip file resources.
    NSURL *html = [NSURL fileURLWithPath:[localPath stringByAppendingPathComponent:ABKInAppMessageHTMLFileName]];
    NSString *fullPath = [localPath stringByAppendingPathComponent:ABKInAppMessageHTMLFileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
      NSLog(@"Can't find HTML at path %@, with file name %@. Aborting display.", [NSURL fileURLWithPath:localPath], ABKInAppMessageHTMLFileName);
      [self hideInAppMessage:NO];
    }
    [self.webView loadFileURL:html allowingReadAccessToURL:[NSURL fileURLWithPath:localPath]];
  } else {
    [self.webView loadHTMLString:self.inAppMessage.message baseURL:nil];
  }
  [self.view addSubview:self.webView];

  // Sets an observer for UIKeyboardWillHideNotification. This is a workaround for the
  // keyboard dismissal bug in iOS 12+ WKWebView filed here
  // https://bugs.webkit.org/show_bug.cgi?id=192564. The workaround is also from the post.
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Superclass methods

- (BOOL)prefersStatusBarHidden {
  return YES;
}

#pragma mark - NSNotificationCenter selectors

- (void)keyboardWillHide {
  [self.webView setNeedsLayout];
}

#pragma mark - WKDelegate methods

- (WKWebView *)webView:(WKWebView *)webView
createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
   forNavigationAction:(WKNavigationAction *)navigationAction
        windowFeatures:(WKWindowFeatures *)windowFeatures {
  if (navigationAction.targetFrame == nil) {
    [webView loadRequest:navigationAction.request];
  }
  return nil;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  NSURL *url = navigationAction.request.URL;
  
  // Handle normal html resource loading
  
  NSString *assetPath = ((ABKInAppMessageHTMLBase *)self.inAppMessage).assetsLocalDirectoryPath.absoluteString;
  BOOL isHandledByWebView =
    !url ||
    [ABKUIUtils string:url.absoluteString isEqualToString:ABKBlankURLString] ||
    [ABKUIUtils string:url.path isEqualToString:assetPath] ||
    [ABKUIUtils string:url.lastPathComponent isEqualToString:ABKInAppMessageHTMLFileName];
  
  if (isHandledByWebView) {
    decisionHandler(WKNavigationActionPolicyAllow);
    return;
  }
  
  // Handle Braze specific actions
  NSDictionary *queryParams = [self queryParameterDictionaryFromURL:url];
  NSString *buttonId = [self parseButtonIdFromQueryParams:queryParams];
  ABKInAppMessageWindowController *parentViewController =
    (ABKInAppMessageWindowController *)self.parentViewController;
  
  [self setClickActionBasedOnURL:url];
  parentViewController.clickedHTMLButtonId = buttonId;
  
  // - Delegate handling
  if ([self delegateHandlesHTMLButtonClick:parentViewController.inAppMessageUIDelegate
                                       URL:url
                                  buttonId:buttonId]) {
    decisionHandler(WKNavigationActionPolicyCancel);
    return;
  }
  
  // - Custom event handling
  if ([self isCustomEventURL:url]) {
    [self handleCustomEventWithQueryParams:queryParams];
    decisionHandler(WKNavigationActionPolicyCancel);
    return;
  }
  
  // - Body click handling
  if (![ABKUIUtils objectIsValidAndNotEmpty:buttonId]) {
    if (self.automaticBodyClicksEnabled) {
      parentViewController.inAppMessageIsTapped = YES;
      NSLog(@"In-app message body click registered. Automatic body clicks are enabled.");
    } else {
      NSLog(@"In-app message body click not registered. Automatic body clicks are disabled.");
    }
  }
  
  [parentViewController inAppMessageClickedWithActionType:self.inAppMessage.inAppMessageClickActionType
                                                      URL:url
                                         openURLInWebView:[self getOpenURLInWebView:queryParams]];
  decisionHandler(WKNavigationActionPolicyCancel);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
  self.webView.backgroundColor = [UIColor clearColor];
  self.webView.opaque = NO;
  if (self.inAppMessage.animateIn) {
    [UIView animateWithDuration:InAppMessageAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                      self.topConstraint.constant = 0;
                      self.bottomConstraint.constant = 0;
                      [self.view.superview layoutIfNeeded];
                    }
                     completion:^(BOOL finished){
                    }];
  } else {
    self.topConstraint.constant = 0;
    self.bottomConstraint.constant = 0;
    [self.view.superview layoutIfNeeded];
  }
  
  // Disable touch callout from displaying link information
  [self.webView evaluateJavaScript:@"document.documentElement.style.webkitTouchCallout='none';" completionHandler:nil];
}

- (void)webView:(WKWebView *)webView
runJavaScriptAlertPanelWithMessage:(nonnull NSString *)message
                  initiatedByFrame:(nonnull WKFrameInfo *)frame
                 completionHandler:(nonnull void (^)(void))completionHandler {
  [self presentAlertWithMessage:message
               andConfiguration:^(UIAlertController *alert) {
    // Action labels matches Safari implementation
    // Close
    [alert addAction:[UIAlertAction actionWithTitle:@"Close"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
      completionHandler();
    }]];
  }];
}

- (void)webView:(WKWebView *)webView
runJavaScriptConfirmPanelWithMessage:(NSString *)message
                    initiatedByFrame:(WKFrameInfo *)frame
                   completionHandler:(void (^)(BOOL))completionHandler {
  [self presentAlertWithMessage:message andConfiguration:^(UIAlertController *alert) {
    // Action labels matches Safari implementation
    // Cancel
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
      completionHandler(NO);
    }]];
    
    // OK
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
      completionHandler(YES);
    }]];
  }];
}

- (void)webView:(WKWebView *)webView
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
                          defaultText:(NSString *)defaultText
                     initiatedByFrame:(WKFrameInfo *)frame
                    completionHandler:(void (^)(NSString * _Nullable))completionHandler {
  [self presentAlertWithMessage:prompt
               andConfiguration:^(UIAlertController *alert) {
    // Action labels matches Safari implementation
    // Text field
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
      textField.text = defaultText;
    }];
    
    // Cancel
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
      completionHandler(nil);
    }]];
    
    // OK
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
      completionHandler(alert.textFields[0].text);
    }]];
  }];
}

- (BOOL)isCustomEventURL:(NSURL *)url {
  return ([ABKUIUtils string:url.scheme.lowercaseString isEqualToString:ABKHTMLInAppAppboyKey] &&
          [ABKUIUtils string:url.host isEqualToString:ABKHTMLInAppCustomEventKey]);
}

- (BOOL)getOpenURLInWebView:(NSDictionary *)queryParams {
  if ([queryParams[ABKHTMLInAppDeepLinkKey] boolValue] | [queryParams[ABKHTMLInAppExternalOpenKey] boolValue]) {
    return NO;
  }
  return self.inAppMessage.openUrlInWebView;
}

#pragma mark - Delegate

- (BOOL)delegateHandlesHTMLButtonClick:(id<ABKInAppMessageUIDelegate>)delegate
                                   URL:(NSURL *)url
                              buttonId:(NSString *)buttonId {
  if ([delegate respondsToSelector:@selector(onInAppMessageHTMLButtonClicked:clickedURL:buttonID:)]) {
    if ([delegate onInAppMessageHTMLButtonClicked:(ABKInAppMessageHTMLBase *)self.inAppMessage
                                       clickedURL:url
                                         buttonID:buttonId]) {
      NSLog(@"No in-app message click action will be performed by Braze as in-app message delegate %@ returned YES in onInAppMessageHTMLButtonClicked:", delegate);
      return YES;
    }
  }
  return NO;
}

#pragma mark - Custom Event Handling

- (void)handleCustomEventWithQueryParams:(NSDictionary *)queryParams {
  NSString *customEventName = [self parseCustomEventNameFromQueryParams:queryParams];
  NSMutableDictionary *eventProperties = [self parseCustomEventPropertiesFromQueryParams:queryParams];
  [[Appboy sharedInstance] logCustomEvent:customEventName withProperties:eventProperties];
}

- (NSString *)parseCustomEventNameFromQueryParams:(NSDictionary *)queryParams {
  return queryParams[ABKHTMLInAppCustomEventQueryParamNameKey];
}

- (NSMutableDictionary *)parseCustomEventPropertiesFromQueryParams:(NSDictionary *)queryParams {
  NSMutableDictionary *eventProperties = [queryParams mutableCopy];
  [eventProperties removeObjectForKey:ABKHTMLInAppCustomEventQueryParamNameKey];
  return eventProperties;
}

#pragma mark - Button Click Handling

- (NSString *)parseButtonIdFromQueryParams:(NSDictionary *)queryParams {
  return queryParams[ABKHTMLInAppButtonIdKey];
}

// Set the inAppMessage's click action type based on given URL. It's going to be three types:
// * URL is appboy://close: set click action to be ABKInAppMessageNoneClickAction
// * URL is appboy://feed: set click action to be ABKInAppMessageDisplayNewsFeed
// * URL is anything else: set click action to be ABKInAppMessageRedirectToURI and the uri is the URL.
- (void)setClickActionBasedOnURL:(NSURL *)url {
  if ([ABKUIUtils string:url.scheme.lowercaseString isEqualToString:ABKHTMLInAppAppboyKey]) {
    if ([ABKUIUtils string:url.host.lowercaseString isEqualToString:ABKHTMLInAppCloseKey]) {
      [self.inAppMessage setInAppMessageClickAction:ABKInAppMessageNoneClickAction withURI:nil];
      return;
    } else if ([ABKUIUtils string:url.host.lowercaseString isEqualToString:ABKHTMLInAppFeedKey]) {
      [self.inAppMessage setInAppMessageClickAction:ABKInAppMessageDisplayNewsFeed withURI:nil];
      return;
    }
  }
  [self.inAppMessage setInAppMessageClickAction:ABKInAppMessageRedirectToURI withURI:url];
}

#pragma mark - Utility Methods

- (NSDictionary *)queryParameterDictionaryFromURL:(NSURL *)url {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
  for (NSURLQueryItem *queryItem in components.queryItems) {
    dict[queryItem.name] = queryItem.value;
  }

  return [dict copy];
}

- (void)presentAlertWithMessage:(NSString *)message
               andConfiguration:(void (^)(UIAlertController *alert))configure {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];
  configure(alert);
  [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Animation

- (void)beforeMoveInAppMessageViewOnScreen {
  self.topConstraint.constant = self.view.frame.size.height;
  self.bottomConstraint.constant = self.view.frame.size.height;
}

- (void)moveInAppMessageViewOnScreen {
  // Do nothing - moving the in-app message is handled in didFinishNavigation
  // though that logic should probably be gated by a call here. In a perfect world,
  // ABKInAppMessageWindowController would "request" VC's to show themselves,
  // and the VC's would report when they were shown so ABKInAppMessageWindowController
  // could log impressions.
}

- (void)beforeMoveInAppMessageViewOffScreen {
  self.topConstraint.constant = self.view.frame.size.height;
  self.bottomConstraint.constant = self.view.frame.size.height;
}

- (void)moveInAppMessageViewOffScreen {
  [self.view.superview layoutIfNeeded];
}

#pragma mark - ABKInAppMessageWebViewBridgeDelegate

- (void)webViewBridge:(ABKInAppMessageWebViewBridge *)webViewBridge
  receivedClickAction:(ABKInAppMessageClickActionType)clickAction {
  ABKInAppMessageWindowController *parentViewController =
    (ABKInAppMessageWindowController *)self.parentViewController;
  
  [self.inAppMessage setInAppMessageClickAction:clickAction withURI:nil];
  [parentViewController inAppMessageClickedWithActionType:self.inAppMessage.inAppMessageClickActionType
                                                      URL:nil
                                         openURLInWebView:false];
}

@end
