//
//  OEXLoginViewController.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXLoginViewController.h"

#import "edX-Swift.h"

#import "NSString+OEXFormatting.h"
#import "NSString+OEXValidation.h"
#import "NSJSONSerialization+OEXSafeAccess.h"

#import "OEXAnalytics.h"
#import "OEXAppDelegate.h"
#import "OEXConfig.h"
#import "OEXCustomButton.h"
#import "OEXCustomLabel.h"
#import "OEXAuthentication.h"
#import "OEXFBSocial.h"
#import "OEXFacebookAuthProvider.h"
#import "OEXFacebookConfig.h"
#import "OEXFlowErrorViewController.h"
#import "OEXGoogleAuthProvider.h"
#import "OEXGoogleConfig.h"
#import "OEXGoogleSocial.h"
#import "OEXInterface.h"
#import "OEXNetworkConstants.h"
#import "OEXNetworkUtility.h"
#import "OEXRouter.h"
#import "OEXSession.h"
#import "OEXUserDetails.h"
#import "OEXUserLicenseAgreementViewController.h"
#import "Reachability.h"
#import "OEXStyles.h"

#define USER_EMAIL @"USERNAME"

@interface OEXLoginViewController () <NSURLSessionDelegate, UIAlertViewDelegate>
{
    CGPoint originalOffset;     // store the offset of the scrollview.
    UITextField* activeField;   // assign textfield object which is in active state.

    NSMutableData* receivedData;
    BOOL isSocialLoginClicked;
}
@property (nonatomic, strong) NSString* str_ForgotEmail;
@property (nonatomic, strong) NSString* signInID;
@property (nonatomic, strong) NSString* signInPassword;
@property (nonatomic, assign) BOOL reachable;
@property (weak, nonatomic) IBOutlet UIView* view_EULA;
@property (weak, nonatomic) IBOutlet UIWebView* webview_EULA;
@property (weak, nonatomic) IBOutlet UIButton* btn_Close;
@property (weak, nonatomic) IBOutlet OEXCustomButton* btn_OpenEULA;
@property (weak, nonatomic) IBOutlet UIImageView* img_SeparatorEULA;
@property (weak, nonatomic) IBOutlet OEXCustomButton* btn_Facebook;
@property (weak, nonatomic) IBOutlet OEXCustomButton* btn_Google;
@property (weak, nonatomic) IBOutlet OEXCustomLabel* lbl_OrSignIn;
@property (weak, nonatomic) IBOutlet UIView *mockNavBar;
@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property(nonatomic, strong) NSString* strLoggedInWith;
@property(nonatomic, strong) IBOutlet UIImageView* seperatorLeft;
@property(nonatomic, strong) IBOutlet UIImageView* seperatorRight;
// For Login Design change
// Manage on Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_MapTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_UsernameTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_PasswordTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_ForgotTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_SignInTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_SignTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_separatorTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_FBTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_BySigningTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_EULATop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_LogoTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_UserGreyTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_PassGreyTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_LeftSepTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_RightSepTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_GoogleTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_ActivityIndTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_httpBottom;

@property (weak, nonatomic) IBOutlet UITextField* tf_EmailID;
@property (weak, nonatomic) IBOutlet UITextField* tf_Password;
@property (weak, nonatomic) IBOutlet UIButton* btn_TroubleLogging;
@property (weak, nonatomic) IBOutlet UIButton* btn_Login;
@property (weak, nonatomic) IBOutlet UIButton* btn_SignUp;
@property (weak, nonatomic) IBOutlet UIScrollView* scroll_Main;
@property (weak, nonatomic) IBOutlet UIImageView* img_Map;
@property (weak, nonatomic) IBOutlet UIImageView* img_Logo;
@property (weak, nonatomic) IBOutlet UIImageView* img_Separator;
@property (weak, nonatomic) IBOutlet UILabel* lbl_Redirect;
@property (weak, nonatomic) IBOutlet UILabel* lbl_RedirectLink;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* activityIndicator;

- (IBAction)signUpClicked:(id)sender;
- (IBAction)troubleLoggingClicked:(id)sender;
- (IBAction)loginClicked:(id)sender;
- (IBAction)facebookClicked:(id)sender;
- (IBAction)googleClicked:(id)sender;

@property (nonatomic, assign) BOOL handleFacebookSchema;
@property (nonatomic, assign) BOOL handleGoogleSchema;

@end

@implementation OEXLoginViewController

- (void)layoutSubviews {
    self.btn_Facebook.hidden = ![self isFacebookEnabled];
    self.btn_Google.hidden = ![self isGoogleEnabled];
    if(!([self isFacebookEnabled] || [self isGoogleEnabled])) {
        self.lbl_OrSignIn.hidden = YES;
        self.seperatorLeft.hidden = YES;
        self.seperatorRight.hidden = YES;
    }

    if(IS_IPHONE_4) {
        self.constraint_MapTop.constant = 70;
        self.constraint_LogoTop.constant = 58;
        self.constraint_UsernameTop.constant = 20;
        self.constraint_UserGreyTop.constant = 20;
        self.constraint_PasswordTop.constant = 8;
        self.constraint_PassGreyTop.constant = 8;
        self.constraint_ForgotTop.constant = 8;
        self.constraint_SignInTop.constant = 13;
        self.constraint_ActivityIndTop.constant = 43;
        self.constraint_SignTop.constant = 9;

        if([self isGoogleEnabled] || [self isFacebookEnabled]) {
            self.constraint_LeftSepTop.constant = 18;
            self.constraint_RightSepTop.constant = 18;
            self.constraint_FBTop.constant = 3;
            self.constraint_GoogleTop.constant = 3;
            self.constraint_BySigningTop.constant = 69;
            self.constraint_EULATop.constant = 73;
        }
        else {
            self.lbl_OrSignIn.hidden = YES;
            self.seperatorLeft.hidden = YES;
            self.seperatorRight.hidden = YES;
            self.constraint_LeftSepTop.constant = 18;
            self.constraint_RightSepTop.constant = 18;
            self.constraint_FBTop.constant = 3;
            self.constraint_GoogleTop.constant = 3;
            self.constraint_BySigningTop.constant = 18;
            self.constraint_EULATop.constant = 23;
        }
    }
    else {
        self.constraint_MapTop.constant = 90;
        self.constraint_LogoTop.constant = 80;
        self.constraint_UsernameTop.constant = 25;
        self.constraint_UserGreyTop.constant = 25;
        self.constraint_PasswordTop.constant = 12;
        self.constraint_PassGreyTop.constant = 12;
        self.constraint_ForgotTop.constant = 12;
        self.constraint_SignInTop.constant = 20;
        self.constraint_ActivityIndTop.constant = 55;
        self.constraint_SignTop.constant = 15;
        if([self isGoogleEnabled] || [self isFacebookEnabled]) {
            self.constraint_LeftSepTop.constant = 25;
            self.constraint_RightSepTop.constant = 25;
            self.constraint_FBTop.constant = 10;
            self.constraint_GoogleTop.constant = 10;
            self.constraint_BySigningTop.constant = 85;
            self.constraint_EULATop.constant = 88;
        }
        else {
            self.constraint_BySigningTop.constant = 25;
            self.constraint_EULATop.constant = 30;
        }
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
    OEXConfig* config = [OEXConfig sharedConfig];
    OEXFacebookConfig* facebookConfig = [config facebookConfig];
    return ![OEXNetworkUtility isOnZeroRatedNetwork] && facebookConfig.enabled;
}

- (BOOL)isGoogleEnabled {
    OEXConfig* config = [OEXConfig sharedConfig];
    OEXGoogleConfig* googleConfig = [config googleConfig];
    return ![OEXNetworkUtility isOnZeroRatedNetwork] && googleConfig.enabled;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.titleLabel.text = [Strings loginSignInToPlatformWithPlatformName:[[OEXConfig sharedConfig] platformName]];
    [self.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:20]];

    [self.btn_TroubleLogging setTitle:[Strings troubleInLoginButton] forState:UIControlStateNormal];
    
    [self.btn_Facebook setTitle:[Strings facebook] forState:UIControlStateNormal];
    [self.btn_Google setTitle:[Strings google] forState:UIControlStateNormal];
    [self.lbl_OrSignIn setText:[Strings orSignInWith]];
    [self.lbl_OrSignIn setTextColor:[UIColor colorWithRed:60.0 / 255.0 green:64.0 / 255.0 blue:69.0 / 255.0 alpha:1.0]];

    //Set Up mock nav bar
    [[OEXStyles sharedStyles] applyMockNavigationBarStyleToView:self.mockNavBar label:self.titleLabel leftIconButton: self.btn_Close];
    
    self.btn_Close.accessibilityLabel = [Strings close];
    
    [self setExclusiveTouch];

    //Analytics Screen record
    [[OEXAnalytics sharedAnalytics] trackScreenWithName:@"Login"];
    
    if ([self isRTL]) {
        [self.btn_Facebook setBackgroundImage:[UIImage imageNamed:@"bt_facebook_RTL"] forState:UIControlStateNormal];
        [self.btn_Facebook setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 30)];
        [self.btn_Google setBackgroundImage:[UIImage imageNamed:@"bt_google_RTL"] forState:UIControlStateNormal];
        [self.btn_Google setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 30)];
        [self.btn_TroubleLogging setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    }
    
    self.tf_EmailID.textAlignment = NSTextAlignmentNatural;
    self.tf_Password.textAlignment = NSTextAlignmentNatural;
}

- (IBAction)navigateBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setExclusiveTouch {
    self.btn_SignUp.exclusiveTouch = YES;
    self.btn_OpenEULA.exclusiveTouch = YES;
    self.btn_Google.exclusiveTouch = YES;
    self.btn_Facebook.exclusiveTouch = YES;
    self.btn_Login.exclusiveTouch = YES;
    self.btn_TroubleLogging.exclusiveTouch = YES;
    self.view.multipleTouchEnabled = NO;
    self.view.exclusiveTouch = YES;
}

- (void)hideEULA:(BOOL)hide {
    //EULA
    [self.webview_EULA.scrollView setContentOffset:CGPointMake(0, 0)];
    self.view_EULA.hidden = hide;
    self.webview_EULA.hidden = hide;
    self.img_SeparatorEULA.hidden = hide;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    OEXAppDelegate* appD = [[UIApplication sharedApplication] delegate];
    self.reachable = [appD.reachability isReachable];

    [self.view setUserInteractionEnabled:YES];
    self.view.exclusiveTouch = YES;

    self.lbl_RedirectLink.hidden = YES; // This has been removed from design for GA

    //EULA
    [self hideEULA:YES];

    // Scrolling on keyboard hide and show
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSignInToDefaultState:) name:UIApplicationDidBecomeActiveNotification object:nil];

    //Hide navigation bar
    self.navigationController.navigationBarHidden = YES;

    //Tap to dismiss keyboard
    UIGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(tappedToDismiss)];
    [self.view addGestureRecognizer:tapGesture];

    //To set all the components tot default property
    [self layoutSubviews];
    [self setToDefaultProperties];
}

- (NSString*)signInButtonText {
    return [[Strings signInButtonText] oex_uppercaseStringInCurrentLocale];
}

- (void)handleActivationDuringLogin {
    if(isSocialLoginClicked) {
        [self.btn_TroubleLogging setTitleColor:[UIColor colorWithRed:31.0 / 255.0 green:159.0 / 255.0 blue:217.0 / 255.0 alpha:1.0] forState:UIControlStateNormal];
        [self.btn_OpenEULA setTitleColor:[UIColor colorWithRed:31.0 / 255.0 green:159.0 / 255.0 blue:217.0 / 255.0 alpha:1.0] forState:UIControlStateNormal];

        [self.btn_Login setTitle:[self signInButtonText] forState:UIControlStateNormal];
        [self.activityIndicator stopAnimating];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view setUserInteractionEnabled:YES];
        });

        isSocialLoginClicked = NO;
    }
}

- (void)setSignInToDefaultState:(NSNotification*)notification {
    OEXFBSocial *facebookManager = [[OEXFBSocial alloc]init];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if(self.handleGoogleSchema && ![[OEXGoogleSocial sharedInstance] handledOpenUrl]) {
        [[OEXGoogleSocial sharedInstance] clearHandler];
        [self handleActivationDuringLogin];
    }
    else if(![facebookManager isLogin] && self.handleFacebookSchema) {
        [self handleActivationDuringLogin];
    }

    self.handleFacebookSchema = NO;
    self.handleGoogleSchema = NO;
    [[OEXGoogleSocial sharedInstance] setHandledOpenUrl:NO];
}

- (void)setToDefaultProperties {
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tf_EmailID.placeholder = [Strings usernamePlaceholder];
    self.tf_Password.placeholder = [Strings passwordPlaceholder];
    self.tf_EmailID.text = @"";
    self.tf_Password.text = @"";

    self.lbl_Redirect.text = [Strings redirectText];
    [self.btn_TroubleLogging setTitleColor:[UIColor colorWithRed:31.0 / 255.0 green:159.0 / 255.0 blue:217.0 / 255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.btn_OpenEULA setTitleColor:[UIColor colorWithRed:31.0 / 255.0 green:159.0 / 255.0 blue:217.0 / 255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.btn_OpenEULA setTitle:[Strings registrationAgreementButtonTitleWithPlatformName:[[OEXConfig sharedConfig] platformName]] forState:UIControlStateNormal];

    [self.btn_Login setTitle:[self signInButtonText] forState:UIControlStateNormal];
    [self.activityIndicator stopAnimating];

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

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view setUserInteractionEnabled:YES];
        });
        [self.btn_Login setTitle:[self signInButtonText] forState:UIControlStateNormal];

        [self.activityIndicator stopAnimating];

        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessage]
                                                       onViewController:self.view
                                                             shouldHide:YES];
    }
}

- (IBAction)buttonTouchedDown:(id)sender {
    //[self.view setUserInteractionEnabled:NO];
}

- (void)loadEULA:(NSString*)resourse {
    [self.webview_EULA loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:resourse ofType:@"htm"] isDirectory:NO]]];
}

- (BOOL)webView:(UIWebView*)inWeb shouldStartLoadWithRequest:(NSURLRequest*)inRequest navigationType:(UIWebViewNavigationType)inType {
    if(inType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    return YES;
}

#pragma mark IBActions
- (IBAction)openEULA:(id)sender {
    NSURL* url = [[NSBundle mainBundle] URLForResource:@"Terms-and-Services" withExtension:@"htm"];
    OEXUserLicenseAgreementViewController* viewController = [[OEXUserLicenseAgreementViewController alloc] initWithContentURL:url];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (IBAction)closeEULA:(id)sender {
    [self hideEULA:YES];
}

- (IBAction)signUpClicked:(id)sender {
    [self loadEULA:@"NEW_USER"];
    [self hideEULA:NO];
    [[OEXAnalytics sharedAnalytics] trackUserDoesNotHaveAccount];
}

- (IBAction)troubleLoggingClicked:(id)sender {
    if(self.reachable) {
        [self.view setUserInteractionEnabled:NO];

        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings resetPasswordTitle]
                                                        message:[Strings resetPasswordPopupText]
                                                       delegate:self
                                              cancelButtonTitle:[Strings cancel]
                                              otherButtonTitles:[Strings ok], nil];

        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField* textfield = [alert textFieldAtIndex:0];
        textfield.keyboardType = UIKeyboardTypeEmailAddress;

        if([self.tf_EmailID.text length] > 0) {
            UITextField* tf = [alert textFieldAtIndex:0];
            [[alert textFieldAtIndex:0] setPlaceholder:[Strings emailAddressPrompt]];
            tf.text = self.tf_EmailID.text;
        }

        alert.tag = 1001;
        [alert show];
    }
    else {
        // error
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings networkNotAvailableTitle]
                                                        message:[Strings networkNotAvailableMessageTrouble]
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[Strings ok], nil];
        [alert show];
    }
}

- (IBAction)loginClicked:(id)sender {
    [self.view setUserInteractionEnabled:NO];

    if(!self.reachable) {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessage]
                                                       onViewController:self.view
                                                             shouldHide:YES];

        [self.view setUserInteractionEnabled:YES];

        return;
    }

    //Validation
    if([self.tf_EmailID.text length] == 0) {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings floatingErrorLoginTitle]
                                                                message:[Strings enterEmail]
                                                       onViewController:self.view
                                                             shouldHide:YES];

        [self.view setUserInteractionEnabled:YES];
    }
    else if([self.tf_Password.text length] == 0) {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings floatingErrorLoginTitle]
                                                                message:[Strings enterPassword]
                                                       onViewController:self.view
                                                             shouldHide:YES];

        [self.view setUserInteractionEnabled:YES];
    }
    else {
        self.signInID = _tf_EmailID.text;
        self.signInPassword = _tf_Password.text;
        self.strLoggedInWith = @"Password";

        [OEXAuthentication requestTokenWithUser:_signInID
                                       password:_signInPassword
                              completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
            [self handleLoginResponseWith:data response:response error:error];
        } ];

        [self.view setUserInteractionEnabled:NO];
        [self.activityIndicator startAnimating];
        [self.btn_Login setTitle:[[Strings signInButtonTextOnSignIn] oex_uppercaseStringInCurrentLocale] forState:UIControlStateNormal];
        [self.btn_Login setBackgroundImage:[UIImage imageNamed:@"bt_signin_active.png"] forState:UIControlStateNormal];
    }
}

- (void)handleLoginResponseWith:(NSData*)data response:(NSURLResponse*)response error:(NSError*)error {
    [[OEXGoogleSocial sharedInstance] clearHandler];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view setUserInteractionEnabled:YES];
    });

    if(!error) {
        NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
        if(httpResp.statusCode == 200) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loginSuccessful];
            });
        }
        else if(httpResp.statusCode >= 400 && httpResp.statusCode <= 500) {
            NSString* errorStr = [Strings invalidUsernamePassword];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loginFailedWithErrorMessage:errorStr title:nil];
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
            });
        }
    }
    else {
        [self performSelectorOnMainThread:@selector(loginHandleLoginError:) withObject:error waitUntilDone:NO];
    }
}

// TODO: Factor this to have an array of auth providers and use OEXExternalRegistrationOptionsView
// to display them instead of casing out the buttons
- (IBAction)facebookClicked:(id)sender {
    isSocialLoginClicked = YES;
    self.handleFacebookSchema = YES;
    self.strLoggedInWith = @"Facebook";
    [self externalLoginWithProvider:[[OEXFacebookAuthProvider alloc] init]];
}

- (IBAction)googleClicked:(id)sender {
    isSocialLoginClicked = YES;
    self.handleGoogleSchema = YES;
    self.strLoggedInWith = @"Google";
    [self externalLoginWithProvider:[[OEXGoogleAuthProvider alloc] init]];
}

- (void)externalLoginWithProvider:(id <OEXExternalAuthProvider>)provider {
    if(!self.reachable) {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessage]
                                                       onViewController:self.view
                                                             shouldHide:YES];
        self.handleFacebookSchema = NO;
        self.handleGoogleSchema = NO;
        self.strLoggedInWith = @"";
        return;
    }
    
    OEXURLRequestHandler handler = ^(NSData* data, NSHTTPURLResponse* response, NSError* error) {
        if(!response) {
            [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
            return;
        }
        self.handleFacebookSchema = NO;
        self.handleGoogleSchema = NO;
        
        [self handleLoginResponseWith:data response:response error:error];
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
    [self.btn_Login setTitle:[[Strings signInButtonTextOnSignIn] oex_uppercaseStringInCurrentLocale] forState:UIControlStateNormal];
    [self.btn_Login setBackgroundImage:[UIImage imageNamed:@"bt_signin_active.png"] forState:UIControlStateNormal];
}

- (void)loginHandleLoginError:(NSError*)error {
    if(error.code == -1003 || error.code == -1009 || error.code == -1005) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
        });
    }
    else {
        if(error.code == 401) {
            [[OEXGoogleSocial sharedInstance] clearHandler];

            // MOB - 1110 - Social login error if the user's account is not linked with edX.
            if([self.strLoggedInWith isEqualToString:@"Facebook"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loginFailedWithServiceName: [Strings facebook]];
                });
            }
            else if([self.strLoggedInWith isEqualToString:@"Google"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loginFailedWithServiceName: [Strings google]];
                });
            }
        }
        else {
            //            [self performSelectorOnMainThread:@selector(loginFailed:) withObject:[error localizedDescription] waitUntilDone:NO ];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self loginFailedWithErrorMessage:[error localizedDescription] title: nil];
            });
        }
    }
}

- (void)loginFailedWithServiceName:(NSString*)serviceName {
    NSString* platform = [[OEXConfig sharedConfig] platformName];
    NSString* destination = [[OEXConfig sharedConfig] platformDestinationName];
    NSString* title = [Strings serviceAccountNotAssociatedTitleWithService:serviceName platformName:platform];
    NSString* message = [Strings serviceAccountNotAssociatedMessageWithService:serviceName platformName:platform destinationName:destination];
    [self loginFailedWithErrorMessage:message title:title];
}

- (void)loginFailedWithErrorMessage:(NSString*)errorStr title:(NSString*)title {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if(title) {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:title
                                                                message:errorStr onViewController:self.view shouldHide:YES];
    }
    else {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings floatingErrorLoginTitle]
                                                                message:errorStr
                                                       onViewController:self.view
                                                             shouldHide:YES];
    }

    [self.activityIndicator stopAnimating];
    [self.btn_Login setTitle:[self signInButtonText] forState:UIControlStateNormal];

    [self.view setUserInteractionEnabled:YES];

    self.strLoggedInWith = @"";

    [self tappedToDismiss];
}

- (void)loginSuccessful {
    //set global auth

    if([_tf_EmailID.text length] > 0) {
        // Set the language to blank
        [OEXInterface setCCSelectedLanguage:@""];
        [[NSUserDefaults standardUserDefaults] setObject:_tf_EmailID.text forKey:USER_EMAIL];
        // Analytics User Login
        if(self.strLoggedInWith) {
            [[OEXAnalytics sharedAnalytics] trackUserLogin:self.strLoggedInWith];
        }
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

#pragma mark UIAlertView Delegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.view setUserInteractionEnabled:YES];

    if(alertView.tag == 1001) {
        UITextField* EmailtextField = [alertView textFieldAtIndex:0];

        if(buttonIndex == 1) {
            if([EmailtextField.text length] == 0 || ![EmailtextField.text oex_isValidEmailAddress]) {
                [[OEXFlowErrorViewController sharedInstance]
                 showErrorWithTitle:[Strings floatingErrorTitle]
                            message:[Strings invalidEmailMessage] onViewController:self.view shouldHide:YES];
            }
            else {
                self.str_ForgotEmail = [[NSString alloc] init];

                self.str_ForgotEmail = EmailtextField.text;

                [self.view setUserInteractionEnabled:NO];

                [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings resetPasswordTitle]
                                                                        message:[Strings waitingForResponse]
                                                               onViewController:self.view shouldHide:NO];
                [self resetPassword];
            }
        }
    }
}

- (void)resetPassword {
    [OEXAuthentication resetPasswordWithEmailId:self.str_ForgotEmail completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
                [self.view setUserInteractionEnabled:YES];
                [[OEXFlowErrorViewController sharedInstance] animationUp];

                if(!error) {
                    NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
                    if(httpResp.statusCode == 200) {
                        [[[UIAlertView alloc] initWithTitle:[Strings resetPasswordConfirmationTitle]
                                                    message:[Strings resetPasswordConfirmationMessage]

                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:[Strings ok], nil] show];
                    }
                    else if(httpResp.statusCode <= 400 && httpResp.statusCode < 500) {
                        NSDictionary* dictionary = [NSJSONSerialization oex_JSONObjectWithData:data error:nil];
                        NSString* responseStr = [[dictionary objectForKey:@"email"] firstObject];
                        [[OEXFlowErrorViewController sharedInstance]
                         showErrorWithTitle:[Strings floatingErrorTitle]
                                    message:responseStr onViewController:self.view shouldHide:YES];
                    }
                    else if(httpResp.statusCode > 500) {
                        NSString* responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        [[OEXFlowErrorViewController sharedInstance]
                         showErrorWithTitle:[Strings floatingErrorTitle]
                                    message:responseStr onViewController:self.view shouldHide:YES];
                    }
                }
                else {
                    [[OEXFlowErrorViewController sharedInstance]
                     showErrorWithTitle:[Strings floatingErrorTitle]
                                message:[error localizedDescription] onViewController:self.view shouldHide:YES];
                }
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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}


@end
