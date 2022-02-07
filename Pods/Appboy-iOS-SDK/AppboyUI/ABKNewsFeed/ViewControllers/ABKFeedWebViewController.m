#import "ABKFeedWebViewController.h"
#import "ABKNoConnectionLocalization.h"
#import "ABKUIUtils.h"

static NSString *const EstimatedProgressKeyPath = @"estimatedProgress";
static NSString *const LocalizedNoConnectionKey = @"Appboy.no-connection.message";

@implementation ABKFeedWebViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.edgesForExtendedLayout = UIRectEdgeNone;
  self.webView.navigationDelegate = self;
  
  self.webView = [self getWebView];
  self.view = self.webView;
  
  [self setupProgressBar];
  
  if (self.showDoneButton) {
    UIBarButtonItem *closeBarButton = [self getDoneBarButtonItem];
    [self.navigationItem setRightBarButtonItem:closeBarButton];
  }
  
  [self.webView addObserver:self
                 forKeyPath:EstimatedProgressKeyPath
                    options:NSKeyValueObservingOptionNew
                    context:nil];
  
  [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
  if ([ABKUIUtils string:EstimatedProgressKeyPath isEqualToString:keyPath]) {
    if (self.webView.estimatedProgress == 1.0) {
      [UIView animateWithDuration:1 animations:^{
        self.progressBar.alpha = 0.0;
      }];
    } else if (self.webView.estimatedProgress < 1.0) {
      self.progressBar.alpha = 1.0;
      [self.progressBar setProgress:self.webView.estimatedProgress animated:YES];
    }
  }
}

- (void)dealloc {
  [self.webView removeObserver:self forKeyPath:EstimatedProgressKeyPath];
}

#pragma mark - Customization Methods

/*!
 * @discussion Returns a WKWebView object, whose navigationDelegate is this ABKFeedWebViewController instance.
 *
 * If you want to do any customization to the WKWebView, please override this method in an ABKFeedWebViewController
 * category and return the customized WKWebView. All instances of ABKFeedWebViewController will then
 * call the category's `getWebView` implementation instead of this method.
 *
 */
- (WKWebView *)getWebView {
  WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero];
  webView.navigationDelegate = self;
  return webView;
}

/*!
 *
 * @discussion Creates a UIProgressView and puts it on top of the web view.
 *
 * If you want to do any customization to the progress bar, please override this method in an ABKFeedWebViewController
 * category and set up the progress bar. All instances of ABKFeedWebViewController will then
 * call the category's `setupProgressBar:` implementation instead of this method.
 *
 */
- (void)setupProgressBar{
  UIProgressView *progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
  progressBar.alpha = 0;
  self.progressBar = progressBar;
  
  [self.view addSubview:self.progressBar];
  self.progressBar.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressBar
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.topLayoutGuide
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0
                                                         constant:0.0]];
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[progressBar]|"
                                                                    options:NSLayoutFormatDirectionLeadingToTrailing
                                                                    metrics:nil
                                                                      views:@{@"progressBar" : self.progressBar}]];
}

/*!
 * @discussion Returns the Done UIBarButtonItem, which allows the user to dismiss the modal web view.
 *
 * If you want to do any customization to the Done button, please override this method in an ABKFeedWebViewController
 * category and return the customized UIBarButtonItem. All instances of ABKFeedWebViewController will then
 * call the category's `getDoneBarButtonItem` implementation instead of this method.
 *
 */
- (UIBarButtonItem *)getDoneBarButtonItem {
  return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                       target:self
                                                       action:@selector(closeButtonPressed:)];
}

- (void)closeButtonPressed:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WKNavigationDelegate methods

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  NSString *urlString = [[navigationAction.request.mainDocumentURL absoluteString] lowercaseString];
  NSArray *stringComponents = [urlString componentsSeparatedByString:@":"];
  if ([stringComponents[1] hasPrefix:@"//itunes.apple.com"]  ||
      (![stringComponents[0] isEqual:@"http"] &&
       ![stringComponents[0] isEqual:@"https"])) {
        // Dismiss the modal web view and let the system handle the deep links
    if ([[UIApplication sharedApplication] openURL:navigationAction.request.URL]) {
      decisionHandler(WKNavigationActionPolicyCancel);
      [self.navigationController popViewControllerAnimated:NO];
      return;
    }
  }
  decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
  self.progressBar.alpha = 0.0;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
      withError:(NSError *)error{
  self.progressBar.alpha = 0.0;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  
  // Display localized "No Connection" message
  UILabel *label = [[UILabel alloc] init];
  label.textAlignment = NSTextAlignmentCenter;
  label.numberOfLines = 0;
  NSString *localizedNoConectionMessage = NSLocalizedString(@"Appboy.no-connection.message",
                                                            @"No connection error message for URL loading failure");
  if (localizedNoConectionMessage.length == 0 || [ABKUIUtils string:LocalizedNoConnectionKey isEqualToString:localizedNoConectionMessage]) {
    localizedNoConectionMessage = [ABKNoConnectionLocalization getNoConnectionLocalizedString];
  }
  label.text = localizedNoConectionMessage;
  [self.webView addSubview:label];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  [self.webView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[noConnectionLabel]-10-|"
                                                                       options:NSLayoutFormatDirectionLeadingToTrailing
                                                                       metrics:nil
                                                                         views:@{@"noConnectionLabel" : label}]];
  [self.webView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[noConnectionLabel]|"
                                                                       options:NSLayoutFormatAlignAllCenterY
                                                                       metrics:nil
                                                                         views:@{@"noConnectionLabel" : label}]];
}

@end
