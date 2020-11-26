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

@interface OEXLoginViewController () <AgreementTextViewDelegate, InterfaceOrientationOverriding, MFMailComposeViewControllerDelegate>
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

@property (weak, nonatomic, nullable) IBOutlet LogistrationTextField* tf_EmailID;
@property (weak, nonatomic, nullable) IBOutlet LogistrationTextField* tf_Password;
@property (weak, nonatomic, nullable) IBOutlet UIButton* btn_TroubleLogging;
@property (weak, nonatomic, nullable) IBOutlet UIButton* btn_Login;
@property (weak, nonatomic, nullable) IBOutlet UIScrollView* scroll_Main;
@property (weak, nonatomic, nullable) IBOutlet UIImageView* img_Map;
@property (weak, nonatomic, nullable) IBOutlet UIImageView* img_Logo;
@property (weak, nonatomic, nullable) IBOutlet UILabel* usernameTitleLabel;
@property (weak, nonatomic, nullable) IBOutlet UILabel* passwordTitleLabel;
@property (weak, nonatomic) IBOutlet AgreementTextView *agreementTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *agreementTextViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *agreementTextViewTop;
@property (weak, nonatomic, nullable) IBOutlet UIActivityIndicatorView* activityIndicator;
@property (strong, nonatomic) IBOutlet UILabel* versionLabel;
@property (nonatomic, assign) id <OEXExternalAuthProvider> authProvider;
@property (nonatomic) OEXTextStyle *placeHolderStyle;
@property (weak, nonatomic) IBOutlet UIView *logo_container;

@end

@implementation OEXLoginViewController

- (void)layoutSubviews {
    if(!([self isFacebookEnabled] || [self isGoogleEnabled])) {
        self.lbl_OrSignIn.hidden = YES;
        self.seperatorLeft.hidden = YES;
        self.seperatorRight.hidden = YES;
        self.agreementTextViewTop.constant = -30;
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

- (BOOL)isMicrosoftEnabled {
    return [self.environment.config microsoftConfig].enabled;
}

- (BOOL)isAppleEnabled {
    return self.environment.config.isAppleSigninEnabled;
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

    if([self isMicrosoftEnabled]) {
        [providers addObject:[[OEXMicrosoftAuthProvider alloc] init]];
    }
    
    if([self isAppleEnabled]) {
        [providers addObject:[[AppleAuthProvider alloc] init]];
    }
    
    __weak __typeof(self) owner = self;
    
    OEXExternalAuthOptionsView* externalAuthOptions = [[OEXExternalAuthOptionsView alloc] initWithFrame:self.externalAuthContainer.bounds providers:providers accessibilityLabel:[Strings signInPrompt] tapAction:^(id<OEXExternalAuthProvider> provider) {
        [owner externalLoginWithProvider:provider];
    }];
    [self.externalAuthContainer addSubview:externalAuthOptions];
    [externalAuthOptions mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.externalAuthContainer);
    }];

    [self.lbl_OrSignIn setText:[Strings orSignInWith]];
    [self.lbl_OrSignIn setTextColor:[[OEXStyles sharedStyles] neutralBlack]];
    [self.lbl_OrSignIn setIsAccessibilityElement:false];
    
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
    self.logo_container.isAccessibilityElement = YES;
    self.logo_container.accessibilityLabel = [[OEXConfig sharedConfig] platformName];
    self.logo_container.accessibilityHint = [Strings accessibilityImageVoiceOverHint];
    
    NSString* environmentName = self.environment.config.environmentName;
    if(environmentName.length > 0) {
        NSString* appVersion = [NSBundle mainBundle].oex_buildVersionString;
        self.versionLabel.text = [Strings versionDisplayWithNumber:appVersion environment:environmentName];
    }
    else {
        self.versionLabel.text = @"";
    }
    
    _placeHolderStyle = [[OEXTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeBase color:[[OEXStyles sharedStyles] neutralBlackT]];
    [self setAccessibilityIdentifiers];
    [self setUpAgreementTextView];
}

-(void) setUpAgreementTextView {
    [self.agreementTextView setupFor:AgreementTypeSignIn config:self.environment.config];
    self.agreementTextView.agreementDelegate = self;
    // To adjust textView according to its content size.
    self.agreementTextViewHeight.constant = self.agreementTextView.contentSize.height + [self.environment.styles standardHorizontalMargin];
}

    //setting accessibility identifiers for developer automation use
- (void)setAccessibilityIdentifiers {
    self.logo_container.accessibilityIdentifier = @"LoginViewController:logo-image-view";
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
        [self setLoginDefaultState];
    }
}

- (void)setSignInToDefaultState:(NSNotification*)notification {
    OEXFBSocial *facebookManager = [[OEXFBSocial alloc]init];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if([self.authProvider isKindOfClass:[OEXGoogleAuthProvider class]] && ![[OEXGoogleSocial sharedInstance] handledOpenUrl]) {
        [self handleActivationDuringLogin];
    }
    else if(![facebookManager isLogin] && [self.authProvider isKindOfClass:[OEXFacebookAuthProvider class]]) {
        [self handleActivationDuringLogin];
    }
    [[OEXGoogleSocial sharedInstance] setHandledOpenUrl:NO];
}

- (void)setToDefaultProperties {
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.usernameTitleLabel.attributedText = [_placeHolderStyle attributedStringWithText:[NSString stringWithFormat:@"%@ %@",[Strings usernameTitleText],[Strings asteric]]];
    self.passwordTitleLabel.attributedText = [_placeHolderStyle attributedStringWithText:[NSString stringWithFormat:@"%@ %@",[Strings passwordTitleText],[Strings asteric]]];
    self.tf_EmailID.text = @"";
    self.tf_Password.text = @"";
    // We made adjustsFontSizeToFitWidth as true to fix the dynamic type text
    self.usernameTitleLabel.adjustsFontSizeToFitWidth = true;
    self.passwordTitleLabel.adjustsFontSizeToFitWidth = true;
    self.usernameTitleLabel.isAccessibilityElement = false;
    self.passwordTitleLabel.isAccessibilityElement = false;
    self.tf_EmailID.accessibilityLabel = [Strings usernameTitleText];
    self.tf_Password.accessibilityLabel = [Strings passwordTitleText];
    self.tf_EmailID.accessibilityHint = [Strings accessibilityRequiredInput];
    self.tf_Password.accessibilityHint = [Strings accessibilityRequiredInput];
    OEXTextStyle *forgotButtonStyle = [[OEXTextStyle alloc] initWithWeight:OEXTextWeightBold size:OEXTextSizeBase color:[self.environment.styles infoBase]];
    [self.btn_TroubleLogging setAttributedTitle:[forgotButtonStyle attributedStringWithText:[Strings troubleInLoginButton]] forState:UIControlStateNormal];

    [self setLoginDefaultState];

    NSString* username = [[NSUserDefaults standardUserDefaults] objectForKey:USER_EMAIL];

    if(username) {
        _tf_EmailID.text = username;
    }
}

- (void)reachabilityDidChange:(NSNotification*)notification {
    id <Reachability> reachability = [notification object];

    if([reachability isReachable]) {
        self.reachable = YES;
    }
    else {
        self.reachable = NO;
        [self setLoginDefaultState];
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

        [self setLoginInProgressState];
    }
}

- (void) setLoginInProgressState {
    [self.view setUserInteractionEnabled:NO];
    [self.activityIndicator startAnimating];
    [self.btn_Login applyButtonStyleWithStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[Strings signInButtonTextOnSignIn]];
}

- (void) setLoginDefaultState {
    [self.view setUserInteractionEnabled:YES];
    [self.activityIndicator stopAnimating];
    [self.btn_Login applyButtonStyleWithStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[self signInButtonText]];
}

- (void)handleLoginResponseWith:(NSData*)data response:(NSURLResponse*)response error:(NSError*)error {
    [[OEXGoogleSocial sharedInstance] clearHandler];

    if(!error) {
        NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
        if(httpResp.statusCode == 200) {
            [self loginSuccessful];
        }
        else if(httpResp.statusCode == OEXHTTPStatusCode426UpgradeRequired) {
            [self showUpdateRequiredMessage];
        }
        else if (httpResp.statusCode == OEXHTTPStatusCode400BadRequest && self.authProvider != nil) {
            NSString *errorMessage = [Strings authProviderErrorWithAuthProvider:self.authProvider.displayName platformName:self.environment.config.platformName];
            [self loginFailedWithErrorMessage:errorMessage title:nil];
        }
        else if (httpResp.statusCode == OEXHTTPStatusCode403Forbidden && self.authProvider != nil) {
            [self showDisabledUserMessage];
        }
        else if(httpResp.statusCode >= 400 && httpResp.statusCode < 500) {
                [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
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
    __block BOOL isFailure = false;
    __block OEXLoginViewController *blockSelf = self;
    if(!self.reachable) {
        [[UIAlertController alloc] showAlertWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessage]
                                                       onViewController:self.navigationController
                                                            ];
        self.authProvider = nil;
        isFailure = true;
        return;
    }
    
    OEXURLRequestHandler handler = ^(NSData* data, NSHTTPURLResponse* response, NSError* error) {
        if(!response) {
            [blockSelf loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
            isFailure = true;
            return;
        }
        
        [self handleLoginResponseWith:data response:response error:error];
        self.authProvider = nil;
    };
    
    [provider authorizeServiceFromController:self
                       requestingUserDetails:NO
                              withCompletion:^(NSString* accessToken, OEXRegisteringUserDetails* details, NSError* error) {
                                  if(accessToken) {
                                      [blockSelf setLoginInProgressState];
                                      blockSelf.environment.session.thirdPartyAuthAccessToken = accessToken;
                                      [OEXAuthentication requestTokenWithProvider:provider externalToken:accessToken completion:handler];
                                  }
                                  else {
                                      handler(nil, nil, error);
                                  }
                              }];

    if (isFailure == false) {
        [self setLoginInProgressState];
    }

    isFailure = false;
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

    [self.view setUserInteractionEnabled:YES];
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

    [self setLoginDefaultState];

    [self tappedToDismiss];
}

- (void) showDisabledUserMessage {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self setLoginDefaultState];
    [self tappedToDismiss];

    UIAlertController *alertController = [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorLoginTitle] message:[Strings authProviderDisabledUserError] cancelButtonTitle:[Strings cancel] onViewController:self];

    __block OEXLoginViewController *blockSelf = self;
    [alertController addButtonWithTitle:[Strings customerSupport] actionBlock:^(UIAlertAction * _Nonnull action) {
        [blockSelf launchEmailComposer];
    }];
}

- (void) showUpdateRequiredMessage {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self setLoginDefaultState];
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
    return true;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

#pragma mark - Email and MFMailComposeViewControllerDelegate methods
- (void) launchEmailComposer {
    if (![MFMailComposeViewController canSendMail]) {
        [[UIAlertController alloc] showAlertWithTitle:[Strings emailAccountNotSetUpTitle] message:[Strings emailAccountNotSetUpMessage] onViewController:self.navigationController];
        return;
    }

    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    mailComposer.mailComposeDelegate = self;
    mailComposer.navigationBar.tintColor = [[OEXStyles sharedStyles] navigationItemTintColor];
    [mailComposer setSubject:[Strings accountDisabled]];
    [mailComposer setMessageBody:[EmailTemplates supportEmailMessageTemplate] isHTML:false];

    NSString *fbAddress = self.environment.config.feedbackEmailAddress;
    if (fbAddress) {
        [mailComposer setToRecipients:[NSArray arrayWithObject:fbAddress]];
    }

    [self presentViewController:mailComposer animated:true completion:nil];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end

