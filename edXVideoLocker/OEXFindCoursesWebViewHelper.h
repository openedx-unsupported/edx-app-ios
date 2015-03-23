//
//  OEXFindCoursesWebViewHelper.h
//  edXVideoLocker
//
//  Created by Abhradeep on 02/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXFindCoursesWebViewHelper;

@protocol OEXFindCoursesWebViewHelperDelegate <NSObject>
- (BOOL)webViewHelper:(OEXFindCoursesWebViewHelper*)webViewHelper shouldLoadURLWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType;
@end

@interface OEXFindCoursesWebViewHelper : NSObject
@property (nonatomic) BOOL isWebViewLoaded;
@property (nonatomic, weak) UIActivityIndicatorView* progressIndicator;
- (instancetype)initWithWebView:(UIWebView*)webView delegate:(id <OEXFindCoursesWebViewHelperDelegate>)delegate;

- (void)loadWebViewWithURLString:(NSString*)urlString;
@end
