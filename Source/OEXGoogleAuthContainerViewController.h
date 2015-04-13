//
//  OEXGoogleAuthContainerViewController.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/8/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

// The whole existence of this class is sort of unfortunate.
// We'd like to use Google's standard login system which takes you to the
// Google Plus App, Chrome, Safari (in that order) but Apple is requiring
// us to use an in app web view.

@interface OEXGoogleAuthContainerViewController : UIViewController

- (id)initWithAuthorizationURL:(NSURL*)url;

@end
