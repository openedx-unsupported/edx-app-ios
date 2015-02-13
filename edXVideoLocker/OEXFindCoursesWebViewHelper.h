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
-(void)webViewHelper:(OEXFindCoursesWebViewHelper *)webViewHelper shouldOpenURLString:(NSString *)urlString;
-(void)webViewHelper:(OEXFindCoursesWebViewHelper *)webViewHelper userEnrolledWithCourseID:(NSString *)courseID emailOptIn:(NSString *)emailOptIn;
@end

@interface OEXFindCoursesWebViewHelper : NSObject

@property (nonatomic) BOOL isWebViewLoaded;

-(instancetype)initWithWebView:(UIWebView *)webView delegate:(id <OEXFindCoursesWebViewHelperDelegate>)delegate;

-(void)loadWebViewWithURLString:(NSString *)urlString;
@end
