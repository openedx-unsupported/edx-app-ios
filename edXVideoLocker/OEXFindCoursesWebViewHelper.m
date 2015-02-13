//
//  OEXFindCoursesWebViewHelper.m
//  edXVideoLocker
//
//  Created by Abhradeep on 02/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFindCoursesWebViewHelper.h"
#import "OEXEnrollmentConfig.h"
#import "OEXConfig.h"

static NSString const *OEXCourseInfoLinkPathIDPlaceholder = @"{path_id}";

static NSString const *OEXFindCourseURLScheme = @"edxapp";

static NSString const *OEXCourseInfoURLHost = @"course_info";
static NSString const *OEXCourseInfoURLPathIDKey = @"path_id";

static NSString const *OEXCourseEnrollURLHost = @"enroll";
static NSString const *OEXCourseEnrollURLCourseIDKey = @"course_id";
static NSString const *OEXCourseEnrollURLEmailOptInKey = @"email_opt_in";

@interface OEXFindCoursesWebViewHelper () <UIWebViewDelegate>{
    
}

@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, weak) id <OEXFindCoursesWebViewHelperDelegate> delegate;
@property (nonatomic, strong) NSString *courseInfoTemplate;
@property (nonatomic, strong) NSString *webViewURLHost;

@end

@implementation OEXFindCoursesWebViewHelper

-(instancetype)initWithWebView:(UIWebView *)aWebView delegate:(id <OEXFindCoursesWebViewHelperDelegate>)aDelegate{
    self = [super init];
    if (self) {
        self.webView = aWebView;
        _webView.delegate = self;
        self.delegate = aDelegate;
        self.isWebViewLoaded = NO;
        self.courseInfoTemplate = [[[OEXConfig sharedConfig] courseEnrollmentConfig] courseInfoURLTemplate];
    }
    return self;
}

-(void)loadWebViewWithURLString:(NSString *)urlString{
    _webView.hidden = NO;
    NSURL *url = [NSURL URLWithString:urlString];
    self.webViewURLHost = [url host];
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}


#pragma mark - UIWebViewDelegate methods
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    if (navigationType ==  UIWebViewNavigationTypeLinkClicked) {
        if ([request.URL.scheme isEqualToString:(NSString *)OEXFindCourseURLScheme]) {
            if ([request.URL.host isEqualToString:(NSString *)OEXCourseInfoURLHost]) {
                NSDictionary *queryParameters = [self queryDictionaryForURL:request.URL];
                NSString *path_id = [queryParameters[OEXCourseInfoURLPathIDKey] stringByReplacingOccurrencesOfString:@"course/" withString:@""];
                NSString *courseInfoURLString = [self.courseInfoTemplate stringByReplacingOccurrencesOfString:(NSString *)OEXCourseInfoLinkPathIDPlaceholder withString:path_id];
                [_delegate webViewHelper:self shouldOpenURLString:courseInfoURLString];
                return NO;
            }
            else if ([request.URL.host isEqualToString:(NSString *)OEXCourseEnrollURLHost]){
                NSDictionary *queryParameters = [self queryDictionaryForURL:request.URL];
                NSString *courseID = queryParameters[OEXCourseEnrollURLCourseIDKey];
                NSString *emailOptIn = queryParameters[OEXCourseEnrollURLEmailOptInKey];
                [_delegate webViewHelper:self userEnrolledWithCourseID:courseID emailOptIn:emailOptIn];
                return NO;
            }
        }
    }
    
    if (![[request.mainDocumentURL host] isEqualToString:self.webViewURLHost]){
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    
    return YES;
}

-(NSDictionary *)queryDictionaryForURL:(NSURL *)url{
    NSString *queryString = [url query];
    NSMutableDictionary *queryDictionary = [[NSMutableDictionary alloc] init];
    for (NSString *param in [queryString componentsSeparatedByString:@"&"]) {
        NSArray *keyValuePair = [param componentsSeparatedByString:@"="];
        if([keyValuePair count] < 2){
            continue;
        }
        [queryDictionary setObject:[keyValuePair objectAtIndex:1] forKey:[keyValuePair objectAtIndex:0]];
    }
    return queryDictionary;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    if (!webView.loading) {
        self.isWebViewLoaded = YES;
    }
}

@end
