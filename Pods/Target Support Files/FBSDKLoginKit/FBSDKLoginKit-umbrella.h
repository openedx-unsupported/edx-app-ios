#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FBSDKCoreKitImport.h"
#import "FBSDKDeviceLoginCodeInfo.h"
#import "FBSDKDeviceLoginManager.h"
#import "FBSDKDeviceLoginManagerResult.h"
#import "FBSDKLoginButton.h"
#import "FBSDKLoginConfiguration.h"
#import "FBSDKLoginConstants.h"
#import "FBSDKLoginKit.h"
#import "FBSDKLoginManager.h"
#import "FBSDKLoginManagerLoginResult.h"
#import "FBSDKLoginTooltipView.h"
#import "FBSDKReferralCode.h"
#import "FBSDKReferralManager.h"
#import "FBSDKReferralManagerResult.h"
#import "FBSDKTooltipView.h"

FOUNDATION_EXPORT double FBSDKLoginKitVersionNumber;
FOUNDATION_EXPORT const unsigned char FBSDKLoginKitVersionString[];

