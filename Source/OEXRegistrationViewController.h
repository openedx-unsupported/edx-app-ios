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
@class NetworkManager;

@protocol OEXRegistrationViewControllerDelegate <NSObject>

- (void)registrationViewControllerDidRegister:(OEXRegistrationViewController*)controller completion:(nullable void(^)(void))completion;

@end

@interface OEXRegistrationViewControllerEnvironment : NSObject

- (id)initWithAnalytics:(OEXAnalytics*)analytics config:(OEXConfig*)config networkManager:(NetworkManager*)networkManager router:(nullable OEXRouter*)router;

@property (strong, nonatomic) OEXAnalytics* analytics;
@property (strong, nonatomic) OEXConfig* config;
@property (weak, nonatomic, nullable) OEXRouter* router;
@property (strong, nonatomic) NetworkManager* networkManager;

@end

@interface OEXRegistrationViewController : UIViewController

- (id)initWithRegistrationDescription:(OEXRegistrationDescription*)description environment:(nullable OEXRegistrationViewControllerEnvironment*)environment;
/// Same as initWithRegistrationDescription:environment but with a registration description read from the app bundle
- (id)initWithEnvironment:(nullable OEXRegistrationViewControllerEnvironment*)environment;

@property (weak, nonatomic, nullable) id <OEXRegistrationViewControllerDelegate> delegate;
@property (strong, nonatomic) OEXRegistrationViewControllerEnvironment* environment;

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
