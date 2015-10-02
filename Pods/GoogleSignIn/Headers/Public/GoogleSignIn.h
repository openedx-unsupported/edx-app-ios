//
//  GoogleSignIn.h
//  Google Sign-In iOS SDK
//
//  Copyright 2015 Google Inc.
//
//  Use of this SDK is subject to the Google APIs Terms of Service:
//  https://developers.google.com/terms/
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
#error "Google Sign-In requires iOS SDK 9.0 or above. Please update to the latest Xcode at https://developer.apple.com/xcode/"
#endif

#import "GIDAuthentication.h"
#import "GIDGoogleUser.h"
#import "GIDProfileData.h"
#import "GIDSignIn.h"
#import "GIDSignInButton.h"
#import "UIViewController+SignIn.h"
