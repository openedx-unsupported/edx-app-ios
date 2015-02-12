//
//  OEXFindCoursesWebViewHelper.m
//  edXVideoLocker
//
//  Created by Abhradeep on 02/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFindCoursesWebViewHelper.h"
#import "OEXEnrollmentConfig.h"

#define OEXCourseInfoLinkURLPrefix @"edxapp://course_info?path_id="
#define OEXCourseInfoLinkURLAlternatePrefix @"edxapp://view_course/course_path=course/"
#define OEXCourseInfoLinkPathIDPlaceholder @"{path_id}"
#define OEXCourseEnrollURLPrefix @"edxapp://enroll/"
#define OEXCourseEnrollURLCourseIDKey @"course_id"
#define OEXCourseEnrollURLEmailOptInKey @"email_opt_in"

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
        self.courseInfoTemplate = [[OEXEnrollmentConfig sharedEnrollmentConfig] courseInfoURLTemplate];
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
        NSString *linkURLPrefixString = nil;
        if ([[request.URL absoluteString] hasPrefix:OEXCourseInfoLinkURLPrefix]) {
            linkURLPrefixString = OEXCourseInfoLinkURLPrefix;
        }
        else if ([[request.URL absoluteString] hasPrefix:OEXCourseInfoLinkURLAlternatePrefix]){
            linkURLPrefixString = OEXCourseInfoLinkURLAlternatePrefix;
        }
        if (linkURLPrefixString) {
            NSString *path_id = [[[request URL] absoluteString] stringByReplacingOccurrencesOfString:linkURLPrefixString withString:@""];
            NSString *courseInfoURLString = [self.courseInfoTemplate stringByReplacingOccurrencesOfString:OEXCourseInfoLinkPathIDPlaceholder withString:path_id];
            [_delegate webViewHelper:self shouldOpenURLString:courseInfoURLString];
            return NO;
        }

        if ([[request.URL absoluteString] hasPrefix:OEXCourseEnrollURLPrefix]){
            NSString *expectedURLString = [[request.URL absoluteString] stringByReplacingOccurrencesOfString:@"edxapp://enroll/" withString:@"edxapp://enroll?"];
            NSURL *expectedURL = [NSURL URLWithString:expectedURLString];
            
            NSString *queryString = [expectedURL query];
            
            NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
            for (NSString *param in [queryString componentsSeparatedByString:@"&"]) {
                NSArray *keyValuePair = [param componentsSeparatedByString:@"="];
                if([keyValuePair count] < 2){
                    continue;
                }
                [parameters setObject:[keyValuePair objectAtIndex:1] forKey:[keyValuePair objectAtIndex:0]];
            }
            
            [_delegate webViewHelper:self userEnrolledWithCourseID:parameters[OEXCourseEnrollURLCourseIDKey] emailOptIn:parameters[OEXCourseEnrollURLEmailOptInKey]];
            return NO;
        }
    }
    
    if (![[request.mainDocumentURL host] isEqualToString:self.webViewURLHost]){
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{

}

- (void)webViewDidFinishLoad:(UIWebView *)webView{

}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    
}

-(void)dealloc{
    self.webView = nil;
    self.delegate = nil;
    self.courseInfoTemplate = nil;
    self.webViewURLHost = nil;
}

@end
