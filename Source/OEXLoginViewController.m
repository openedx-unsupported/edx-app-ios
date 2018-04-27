//
//  OEXLoginViewController.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

@import edXCore;

#import "OEXLoginViewController.h"
#import "edX-Swift.h"
#import <Masonry/Masonry.h>
#import "NSString+OEXValidation.h"
#import "NSJSONSerialization+OEXSafeAccess.h"
#import "OEXAnalytics.h"
#import "OEXAppDelegate.h"
#import "OEXCustomButton.h"
#import "OEXCustomLabel.h"
#import "OEXAuthentication.h"
#import "OEXFBSocial.h"
#import "OEXExternalAuthOptionsView.h"
#import "OEXFacebookAuthProvider.h"
#import "OEXFacebookConfig.h"
#import "OEXGoogleAuthProvider.h"
#import "OEXGoogleConfig.h"
#import "OEXGoogleSocial.h"
#import "OEXInterface.h"
#import "OEXNetworkConstants.h"
#import "OEXNetworkUtility.h"
#import "OEXSession.h"
#import "OEXUserDetails.h"
#import "OEXUserLicenseAgreementViewController.h"
#import "Reachability.h"
#import "OEXStyles.h"

#define USER_EMAIL @"USERNAME"

@interface OEXLoginViewController () <AgreementTextViewDelegate>
{
    CGPoint originalOffset;     // store the offset of the scrollview.
    UITextField* activeField;   // assign textfield object which is in active state.

}
@property (nonatomic, strong) NSString* str_ForgotEmail;
@property (nonatomic, strong) NSString* signInID;
@property (nonatomic, strong) NSString* signInPassword;
@property (nonatomic, assign) BOOL reachable;
@property (strong, nonatomic) IBOutlet UIView* externalAuthContainer;
@property (weak, nonatomic, nullable) IBOutlet OEXCustomLabel* lbl_OrSignIn;
@property(nonatomic, strong) IBOutlet UIImageView* seperatorLeft;
@property(nonatomic, strong) IBOutlet UIImageView* seperatorRight;
// For Login Design change
// Manage on Constraints
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_MapTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_UsernameTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_PasswordTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_UserGreyTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_PassGreyTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_ActivityIndTop;

@property (weak, nonatomic, nullable) IBOutlet UITextField* tf_EmailID;
@property (weak, nonatomic, nullable) IBOutlet UITextField* tf_Password;
@property (weak, nonatomic, nullable) IBOutlet UIButton* btn_TroubleLogging;
@property (weak, nonatomic, nullable) IBOutlet UIButton* btn_Login;
@property (weak, nonatomic, nullable) IBOutlet UIScrollView* scroll_Main;
@property (weak, nonatomic, nullable) IBOutlet UIImageView* img_Map;
@property (weak, nonatomic, nullable) IBOutlet UIImageView* img_Logo;
@property (weak, nonatomic) IBOutlet AgreementTextView *agreementTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *agreementTextViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *agreementTextViewTop;
@property (weak, nonatomic, nullable) IBOutlet UIActivityIndicatorView* activityIndicator;
@property (strong, nonatomic) IBOutlet UILabel* versionLabel;
@property (nonatomic, assign) id <OEXExternalAuthProvider> authProvider;
@property (nonatomic) OEXTextStyle *placeHolderStyle;

@end

@implementation OEXLoginViewController

- (void)layoutSubviews {
    if(!([self isFacebookEnabled] || [self isGoogleEnabled])) {
        self.lbl_OrSignIn.hidden = YES;
        self.seperatorLeft.hidden = YES;
        self.seperatorRight.hidden = YES;
        self.agreementTextViewTop.constant = -30;
    }

    if(IS_IPHONE_4) {
        self.constraint_MapTop.constant = 70;
        self.constraint_UsernameTop.constant = 20;
        self.constraint_UserGreyTop.constant = 20;
        self.constraint_PasswordTop.constant = 8;
        self.constraint_PassGreyTop.constant = 8;
        self.constraint_ActivityIndTop.constant = 43;
    }
    else {
        self.constraint_MapTop.constant = 90;
        self.constraint_UsernameTop.constant = 25;
        self.constraint_UserGreyTop.constant = 25;
        self.constraint_PasswordTop.constant = 12;
        self.constraint_PassGreyTop.constant = 12;
        self.constraint_ActivityIndTop.constant = 55;
    }
}


#pragma mark - NSURLConnection Delegtates

#pragma mark - Init

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.view setUserInteractionEnabled:NO];
}
- (BOOL)isFacebookEnabled {
    return ![OEXNetworkUtility isOnZeroRatedNetwork] && [self.environment.config facebookConfig].enabled;
}

- (BOOL)isGoogleEnabled {
    return ![OEXNetworkUtility isOnZeroRatedNetwork] && [self.environment.config googleConfig].enabled;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:[Strings signInText]];

    NSMutableArray* providers = [[NSMutableArray alloc] init];
    if([self isGoogleEnabled]) {
        [providers addObject:[[OEXGoogleAuthProvider alloc] init]];
    }
    if([self isFacebookEnabled]) {
        [providers addObject:[[OEXFacebookAuthProvider alloc] init]];
    }

    __weak __typeof(self) owner = self;
    OEXExternalAuthOptionsView* externalAuthOptions = [[OEXExternalAuthOptionsView alloc] initWithFrame:self.externalAuthContainer.bounds providers:providers tapAction:^(id<OEXExternalAuthProvider> provider) {
        [owner externalLoginWithProvider:provider];
    }];
    [self.externalAuthContainer addSubview:externalAuthOptions];
    [externalAuthOptions mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.externalAuthContainer);
    }];

    [self.lbl_OrSignIn setText:[Strings orSignInWith]];
    [self.lbl_OrSignIn setTextColor:[UIColor colorWithRed:60.0 / 255.0 green:64.0 / 255.0 blue:69.0 / 255.0 alpha:1.0]];
    
    if (self.environment.config.isRegistrationEnabled) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_cancel"] style:UIBarButtonItemStylePlain target:self action:@selector(navigateBack)];
        closeButton.accessibilityLabel = [Strings close];
        closeButton.accessibilityIdentifier = @"LoginViewController:close-bar-button-item";
        self.navigationItem.leftBarButtonItem = closeButton;
    }
    
    [self setExclusiveTouch];

    if ([self isRTL]) {
        [self.btn_TroubleLogging setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    }
    
    self.tf_EmailID.textAlignment = NSTextAlignmentNatural;
    self.tf_Password.textAlignment = NSTextAlignmentNatural;
    self.img_Logo.isAccessibilityElement = YES;
    self.img_Logo.accessibilityLabel = [[OEXConfig sharedConfig] platformName];
    
    NSString* environmentName = self.environment.config.environmentName;
    if(environmentName.length > 0) {
        NSString* appVersion = [NSBundle mainBundle].oex_buildVersionString;
        self.versionLabel.text = [Strings versionDisplayWithNumber:appVersion environment:environmentName];
    }
    else {
        self.versionLabel.text = @"";
    }
    
    _placeHolderStyle = [[OEXTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeBase color:[[OEXStyles sharedStyles] neutralDark]];
    [self setAccessibilityIdentifiers];
    [self setUpAgreementTextView];
}

-(void) setUpAgreementTextView {
    [self.agreementTextView setupFor:AgreementTypeSignIn];
    self.agreementTextView.agreementDelegate = self;
    // To adjust textView according to its content size.
    self.agreementTextViewHeight.constant = self.agreementTextView.contentSize.height + [self.environment.styles standardHorizontalMargin];
}

    //setting accessibility identifiers for developer automation use
- (void)setAccessibilityIdentifiers {
    self.img_Logo.accessibilityIdentifier = @"LoginViewController:logo-image-view";
    self.tf_EmailID.accessibilityIdentifier = @"LoginViewController:email-text-field";
    self.tf_Password.accessibilityIdentifier = @"LoginViewController:password-text-field";
    self.agreementTextView.accessibilityIdentifier = @"LoginViewController:agreement-text-view";
    self.externalAuthContainer.accessibilityIdentifier = @"LoginViewController:external-auth-container-view";
    self.seperatorLeft.accessibilityIdentifier = @"LoginViewController:left-seperator-image-view";
    self.seperatorRight.accessibilityIdentifier = @"LoginViewController:right-seperator-image-view";
    self.btn_TroubleLogging.accessibilityIdentifier = @"LoginViewController:trouble-logging-button";
    self.btn_Login.accessibilityIdentifier = @"LoginViewController:login-button";
    self.scroll_Main.accessibilityIdentifier = @"LoginViewController:main-scroll-view";
    self.img_Map.accessibilityIdentifier = @"LoginViewController:map-image-view";
    self.activityIndicator.accessibilityIdentifier = @"LoginViewController:activity-indicator";
    self.versionLabel.accessibilityIdentifier = @"LoginViewController:version-label";
    self.lbl_OrSignIn.accessibilityIdentifier = @"LoginViewController:sign-in-label";
}

- (void)navigateBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setExclusiveTouch {
    self.btn_Login.exclusiveTouch = YES;
    self.btn_TroubleLogging.exclusiveTouch = YES;
    self.view.multipleTouchEnabled = NO;
    self.view.exclusiveTouch = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    //Analytics Screen record
    [[OEXAnalytics sharedAnalytics] trackScreenWithName:@"Login"];

    OEXAppDelegate* appD = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.reachable = [appD.reachability isReachable];

    [self.view setUserInteractionEnabled:YES];
    self.view.exclusiveTouch = YES;

    // Scrolling on keyboard hide and show
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSignInToDefaultState:) name:UIApplicationDidBecomeActiveNotification object:nil];

    //Tap to dismiss keyboard
    UIGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(tappedToDismiss)];
    [self.view addGestureRecognizer:tapGesture];

    //To set all the components tot default property
    [self layoutSubviews];
    [self setToDefaultProperties];
}

- (NSString*)signInButtonText {
    return [Strings signInText];
}

- (void)handleActivationDuringLogin {
    if(self.authProvider != nil) {
        [self.btn_Login applyButtonStyleWithStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[self signInButtonText]];
        [self.activityIndicator stopAnimating];
        [self.view setUserInteractionEnabled:YES];

        self.authProvider = nil;
    }
}

- (void)setSignInToDefaultState:(NSNotification*)notification {
    OEXFBSocial *facebookManager = [[OEXFBSocial alloc]init];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if([self.authProvider isKindOfClass:[OEXGoogleAuthProvider class]] && ![[OEXGoogleSocial sharedInstance] handledOpenUrl]) {
        [[OEXGoogleSocial sharedInstance] clearHandler];
        [self handleActivationDuringLogin];
    }
    else if(![facebookManager isLogin] && [self.authProvider isKindOfClass:[OEXFacebookAuthProvider class]]) {
        [self handleActivationDuringLogin];
    }

    self.authProvider = nil;
    [[OEXGoogleSocial sharedInstance] setHandledOpenUrl:NO];
}

- (void)setToDefaultProperties {
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tf_EmailID.attributedPlaceholder = [_placeHolderStyle attributedStringWithText:[Strings usernamePlaceholder]];
    self.tf_Password.attributedPlaceholder = [_placeHolderStyle attributedStringWithText:[Strings passwordPlaceholder]];
    self.tf_EmailID.text = @"";
    self.tf_Password.text = @"";
    self.tf_EmailID.accessibilityLabel = nil;
    self.tf_Password.accessibilityLabel = nil;
    OEXTextStyle *forgotButtonStyle = [[OEXTextStyle alloc] initWithWeight:OEXTextWeightBold size:OEXTextSizeBase color:[self.environment.styles primaryBaseColor]];
    [self.btn_TroubleLogging setAttributedTitle:[forgotButtonStyle attributedStringWithText:[Strings troubleInLoginButton]] forState:UIControlStateNormal];

    [self.btn_Login applyButtonStyleWithStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[self signInButtonText]];
    [self.activityIndicator stopAnimating];

    NSString* username = [[NSUserDefaults standardUserDefaults] objectForKey:USER_EMAIL];

    if(username) {
        _tf_EmailID.text = username;
        _tf_EmailID.accessibilityLabel = [Strings usernamePlaceholder];
    }
}

- (void)reachabilityDidChange:(NSNotification*)notification {
    id <Reachability> reachability = [notification object];

    if([reachability isReachable]) {
        self.reachable = YES;
    }
    else {
        self.reachable = NO;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view setUserInteractionEnabled:YES];
        });
        [self.btn_Login applyButtonStyleWithStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[self signInButtonText]];

        [self.activityIndicator stopAnimating];
    }
}

#pragma mark AgreementTextViewDelegate
- (void)agreementTextView:(AgreementTextView *)textView didSelect:(NSURL *)url {
    OEXUserLicenseAgreementViewController* viewController = [[OEXUserLicenseAgreementViewController alloc] initWithContentURL:url];
    [self presentViewController:viewController animated:YES completion:nil];
}

#pragma mark IBActions
- (IBAction)troubleLoggingClicked:(id)sender {
    if(self.reachable) {
        [[UIAlertController alloc] showInViewController:self title:[Strings resetPasswordTitle] message:[Strings resetPasswordPopupText] preferredStyle:UIAlertControllerStyleAlert cancelButtonTitle:[Strings cancel] destructiveButtonTitle:nil otherButtonsTitle:@[[Strings ok]] tapBlock:^(UIAlertController* alertController, UIAlertAction* alertAction, NSInteger buttonIndex) {
            if ( buttonIndex == 1 ) {
                UITextField* emailTextField = alertController.textFields.firstObject;
                if (!emailTextField || [emailTextField.text length] == 0 || ![emailTextField.text oex_isValidEmailAddress]) {
                    [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorTitle] message:[Strings invalidEmailMessage] onViewController:self.navigationController];
                }
                else {
                    self.str_ForgotEmail = emailTextField.text;
                    [self presentViewController:[UIAlertController alertControllerWithTitle:[Strings resetPasswordTitle] message:[Strings waitingForResponse] preferredStyle:UIAlertControllerStyleAlert] animated:YES completion:^{
                        [self resetPassword];
                    }];
                }
            }
        } textFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.keyboardType = UIKeyboardTypeEmailAddress;
            if([self.tf_EmailID.text length] > 0) {
                [textField setAttributedPlaceholder:[_placeHolderStyle attributedStringWithText:[Strings emailAddressPrompt]]];
                textField.text = self.tf_EmailID.text;
            }
        }];
    }
    else {
        // error
        
        [[UIAlertController alloc] showAlertWithTitle:[Strings networkNotAvailableTitle]
                                              message:[Strings networkNotAvailableMessageTrouble]
                                     onViewController:self];
    }
}

- (IBAction)loginClicked:(id)sender {
    [self.view setUserInteractionEnabled:NO];

    if(!self.reachable) {
        [[UIAlertController alloc] showAlertWithTitle:[Strings networkNotAvailableTitle]
                                              message:[Strings networkNotAvailableMessage]
                                     onViewController:self.navigationController
                                                            ];
        
        [self.view setUserInteractionEnabled:YES];

        return;
    }

    //Validation
    if([self.tf_EmailID.text length] == 0) {
        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorLoginTitle]
                                                                message:[Strings enterEmail]
                                                       onViewController:self.navigationController
                                                            ];

        [self.view setUserInteractionEnabled:YES];
    }
    else if([self.tf_Password.text length] == 0) {
        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorLoginTitle]
                                                                message:[Strings enterPassword]
                                                       onViewController:self.navigationController
                                                            ];

        [self.view setUserInteractionEnabled:YES];
    }
    else {
        self.signInID = _tf_EmailID.text;
        self.signInPassword = _tf_Password.text;

        [OEXAuthentication requestTokenWithUser:_signInID
                                       password:_signInPassword
                              completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
            [self handleLoginResponseWith:data response:response error:error];
        } ];

        [self.view setUserInteractionEnabled:NO];
        [self.activityIndicator startAnimating];
        [self.btn_Login applyButtonStyleWithStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[Strings signInButtonTextOnSignIn]];
    }
}

- (void)handleLoginResponseWith:(NSData*)data response:(NSURLResponse*)response error:(NSError*)error {
    [[OEXGoogleSocial sharedInstance] clearHandler];

    [self.view setUserInteractionEnabled:YES];

    if(!error) {
        NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
        if(httpResp.statusCode == 200) {
            [self loginSuccessful];
        }
        else if(httpResp.statusCode == OEXHTTPStatusCode426UpgradeRequired) {
            [self showUpdateRequiredMessage];
        }
        else if(httpResp.statusCode >= 400 && httpResp.statusCode <= 500) {
            NSString* errorStr = [Strings invalidUsernamePassword];
                [self loginFailedWithErrorMessage:errorStr title:nil];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
            });
        }
    }
    else {
        [self loginHandleLoginError:error];
    }
    self.authProvider = nil;
}

- (void)externalLoginWithProvider:(id <OEXExternalAuthProvider>)provider {
    self.authProvider = provider;
    if(!self.reachable) {
        [[UIAlertController alloc] showAlertWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessage]
                                                       onViewController:self.navigationController
                                                            ];
        self.authProvider = nil;
        return;
    }
    
    OEXURLRequestHandler handler = ^(NSData* data, NSHTTPURLResponse* response, NSError* error) {
        if(!response) {
            [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
            return;
        }
        
        [self handleLoginResponseWith:data response:response error:error];
        self.authProvider = nil;
    };
    
    [provider authorizeServiceFromController:self
                       requestingUserDetails:NO
                              withCompletion:^(NSString* accessToken, OEXRegisteringUserDetails* details, NSError* error) {
                                  if(accessToken) {
                                      [OEXAuthentication requestTokenWithProvider:provider externalToken:accessToken completion:handler];
                                  }
                                  else {
                                      handler(nil, nil, error);
                                  }
                              }];

    [self.view setUserInteractionEnabled:NO];
    [self.activityIndicator startAnimating];
    [self.btn_Login applyButtonStyleWithStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[Strings signInButtonTextOnSignIn]];
}

- (void)loginHandleLoginError:(NSError*)error {
    if(error.code == -1003 || error.code == -1009 || error.code == -1005) {
        [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
    }
    else {
        if(error.code == 401) {
            [[OEXGoogleSocial sharedInstance] clearHandler];

            // MOB - 1110 - Social login error if the user's account is not linked with edX.
            if(self.authProvider != nil) {
                [self loginFailedWithServiceName: self.authProvider.displayName];
            }
        }
        else {
            [self loginFailedWithErrorMessage:[error localizedDescription] title: nil];
        }
    }
}

- (void)loginFailedWithServiceName:(NSString*)serviceName {
    NSString* platform = self.environment.config.platformName;
    NSString* destination = self.environment.config.platformDestinationName;
    NSString* title = [Strings serviceAccountNotAssociatedTitleWithService:serviceName platformName:platform];
    NSString* message = [Strings serviceAccountNotAssociatedMessageWithService:serviceName platformName:platform destinationName:destination];
    [self loginFailedWithErrorMessage:message title:title];
}

- (void)loginFailedWithErrorMessage:(NSString*)errorStr title:(NSString*)title {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if(title) {
        [[UIAlertController alloc] showAlertWithTitle:title
                                      message:errorStr
                             onViewController:self.navigationController];
    }
    else {
        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorLoginTitle]
                                      message:errorStr
                             onViewController:self.navigationController];
    }

    [self.activityIndicator stopAnimating];
    [self.btn_Login applyButtonStyleWithStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[self signInButtonText]];

    [self.view setUserInteractionEnabled:YES];

    [self tappedToDismiss];
}

- (void) showUpdateRequiredMessage {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.activityIndicator stopAnimating];
    [self.btn_Login applyButtonStyleWithStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[self signInButtonText]];
    [self.view setUserInteractionEnabled:YES];
    [self tappedToDismiss];
    
    UIAlertController *alertController = [[UIAlertController alloc] showAlertWithTitle:nil message:[Strings versionUpgradeOutDatedLoginMessage] cancelButtonTitle:[Strings cancel] onViewController:self];
    
    [alertController addButtonWithTitle:[Strings versionUpgradeUpdate] actionBlock:^(UIAlertAction * _Nonnull action) {
        NSURL *url = _environment.config.appUpgradeConfig.iOSAppStoreURL;
        if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }];
}

- (void)loginSuccessful {
    //set global auth

    if([_tf_EmailID.text length] > 0) {
        // Set the language to blank
        [OEXInterface setCCSelectedLanguage:@""];
        [[NSUserDefaults standardUserDefaults] setObject:_tf_EmailID.text forKey:USER_EMAIL];
        // Analytics User Login
        [[OEXAnalytics sharedAnalytics] trackUserLogin:[self.authProvider backendName] ?: @"Password"];
    }
    [self tappedToDismiss];
    [self.activityIndicator stopAnimating];

    //Launch next view
    [self didLogin];
}

- (void)didLogin {
    [self.delegate loginViewControllerDidLogin:self];
}

#pragma mark UI

- (void)tappedToDismiss {
    [_tf_EmailID resignFirstResponder];
    [_tf_Password resignFirstResponder];
}

- (void)resetPassword {
    [OEXAuthentication resetPasswordWithEmailId:self.str_ForgotEmail completionHandler:^(NSData *data, NSURLResponse *response, NSError* error)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             [self dismissViewControllerAnimated:YES completion:^{
                 
                 if(!error) {
                     NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                     if(httpResp.statusCode == 200) {
                         [[UIAlertController alloc]
                          showAlertWithTitle:[Strings resetPasswordConfirmationTitle]
                          message:[Strings resetPasswordConfirmationMessage] onViewController:self.navigationController];
                     }
                     else if(httpResp.statusCode <= 400 && httpResp.statusCode < 500) {
                         NSDictionary* dictionary = [NSJSONSerialization oex_JSONObjectWithData:data error:nil];
                         NSString* responseStr = [[dictionary objectForKey:@"email"] firstObject];
                         [[UIAlertController alloc]
                          showAlertWithTitle:[Strings floatingErrorTitle]
                          message:responseStr onViewController:self.navigationController];
                     }
                     else if(httpResp.statusCode >= 500) {
                         NSString* responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                         [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorTitle] message:responseStr onViewController:self.navigationController];
                         
                     }
                 }
                 else {
                     [[UIAlertController alloc]
                      showAlertWithTitle:[Strings floatingErrorTitle] message:[error localizedDescription] onViewController:self.navigationController];
                 }
             }];
         });
     }];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* touch = [touches anyObject];
    if([[touch view] isKindOfClass:[UIButton class]]) {
        [self.view setUserInteractionEnabled:NO];
    }
}

#pragma mark TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    if(textField == self.tf_EmailID) {
        [self.tf_Password becomeFirstResponder];
    }
    else {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.btn_Login);
        [textField resignFirstResponder];
    }

    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([textField isEqual:_tf_EmailID] && [textField.text isEqualToString:@""] && string.length > 0) {
        textField.accessibilityLabel = [Strings usernamePlaceholder];
    }
    else if([textField isEqual:_tf_EmailID] && [string isEqualToString:@""] && textField.text.length == 1) {
        textField.accessibilityLabel = nil;
    }
    
    
    if ([textField isEqual:_tf_Password] && [textField.text isEqualToString:@""] && string.length > 0) {
        textField.accessibilityLabel = [Strings passwordPlaceholder];
    }
    else if([textField isEqual:_tf_Password] && [string isEqualToString:@""] && textField.text.length == 1) {
        textField.accessibilityLabel = nil;
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField*)textField {
    activeField = textField;
}

#pragma mark - Scolling on Keyboard Hide/Show

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification {
    // Calculating the height of the keyboard and the scrolling offset of the textfield
    // And scrolling on the calculated offset to make it visible

    NSDictionary* info = [aNotification userInfo];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbRect = [self.view convertRect:kbRect toView:nil];
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbRect.size.height, 0.0);
    self.scroll_Main.contentInset = contentInsets;
    self.scroll_Main.scrollIndicatorInsets = contentInsets;
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbRect.size.height;
    aRect.size.height -= activeField.frame.size.height;
    CGPoint fieldOrigin = activeField.frame.origin;
    fieldOrigin.y -= self.scroll_Main.contentOffset.y;
    fieldOrigin = [self.view convertPoint:fieldOrigin toView:self.view.superview];
    originalOffset = self.scroll_Main.contentOffset;
    if(!CGRectContainsPoint(aRect, fieldOrigin) ) {
        [self.scroll_Main scrollRectToVisible:CGRectMake(activeField.frame.origin.x, activeField.frame.origin.y, activeField.frame.size.width, activeField.frame.size.height) animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scroll_Main.contentInset = contentInsets;
    self.scroll_Main.scrollIndicatorInsets = contentInsets;
    [self.scroll_Main setContentOffset:originalOffset animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView;
{
    if(scrollView == self.scroll_Main) {
        originalOffset = scrollView.contentOffset;
    }
}

- (BOOL) isRTL {
    return [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}

- (BOOL) shouldAutorotate {
    return false;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
