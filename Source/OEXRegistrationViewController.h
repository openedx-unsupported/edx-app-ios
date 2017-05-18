//
//  OEXRegistrationViewController.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class OEXAnalytics;
@class OEXRegistrationDescription;
@class OEXRegistrationViewController;
@class OEXConfig;
@class OEXRouter;
@class RouterEnvironment;
@class NetworkManager;
@class LoadStateViewController;
@class OEXStream;

@protocol OEXRegistrationViewControllerDelegate <NSObject>

- (void)registrationViewControllerDidRegister:(OEXRegistrationViewController*)controller completion:(nullable void(^)(void))completion;

@end

@interface OEXRegistrationViewController : UIViewController

- (id)initWithEnvironment:(nullable RouterEnvironment*)environment;

@property (weak, nonatomic, nullable) id <OEXRegistrationViewControllerDelegate> delegate;
@property (strong, nonatomic) RouterEnvironment* environment;
@property (strong, nonatomic) OEXRegistrationDescription* registrationDescription;
@property (strong, nonatomic) LoadStateViewController *loadController;
@property (strong, nonatomic) id stream;

- (void)makeFieldControllers;
- (void)refreshFormFields;

@end

// Only use from within tests
@interface OEXRegistrationViewController (Testing)
- (OEXRegistrationDescription*)t_registrationFormDescription;
- (NSUInteger)t_visibleFieldCount;
- (void)t_toggleOptionalFields;
- (void)t_registerWithParameters:(NSDictionary*)parameters;
@end

/// Fires when we attempt to register with an external account, but the user already has
/// an account linked to that external account
/// The notification's object will be the name of the external service
extern NSString* const OEXExternalRegistrationWithExistingAccountNotification;

NS_ASSUME_NONNULL_END
