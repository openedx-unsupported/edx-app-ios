//
//  OEXLoginViewController.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXLoginViewController.h"

#import "NSString+OEXValidation.h"

#import "OEXAppDelegate.h"
#import "OEXCustomButton.h"
#import "OEXCustomLabel.h"
#import "OEXAuthentication.h"
#import "OEXConfig.h"
#import "OEXInterface.h"
#import "OEXFBSocial.h"
#import "OEXFlowErrorViewController.h"
#import "OEXGoogleSocial.h"
#import "OEXNetworkConstants.h"
#import "Reachability.h"
#import "SWRevealViewController.h"
#import "OEXUserDetails.h"


#define SIGN_IN_TEXT  NSLocalizedString(@"SIGN_IN_BUTTON_TEXT", nil)
#define USER_EMAIL @"USERNAME"

//const NSString *facebook=@"Facebook";
//const NSString *google=@"Google";
//const NSString *password=@"Password";

@interface OEXLoginViewController ()<NSURLSessionDelegate>
{
    CGPoint originalOffset; // store the offset of the scrollview.
    UITextField *activeField; // assign textfield object which is in active state.
    
    NSMutableData *receivedData;
    NSURLConnection *connectionSRT;
    BOOL isSocialLoginClicked;
}
@property (nonatomic, strong) NSString *str_CSRFToken;
@property (nonatomic, strong) NSString *str_ForgotEmail;
@property (nonatomic, strong) NSString * signInID;
@property (nonatomic, strong) NSString * signInPassword;
@property (nonatomic, assign) BOOL reachable;
@property (weak, nonatomic) IBOutlet UIView *view_EULA;
@property (weak, nonatomic) IBOutlet UIWebView *webview_EULA;
@property (weak, nonatomic) IBOutlet UIButton *btn_Close;
@property (weak, nonatomic) IBOutlet OEXCustomButton *btn_OpenEULA;
@property (weak, nonatomic) IBOutlet UIImageView *img_SeparatorEULA;
@property (strong, nonatomic) UIImageView *imgOverlay;
@property (weak, nonatomic) IBOutlet OEXCustomButton *btn_Facebook;
@property (weak, nonatomic) IBOutlet OEXCustomButton *btn_Google;
@property (weak, nonatomic) IBOutlet OEXCustomLabel *lbl_OrSignIn;
@property (strong, nonatomic)IBOutlet UILabel *titleLabel;
@property(nonatomic,strong)NSString *strLoggedInWith;
// For Login Design change
// Manage on Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_MapTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_UsernameTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_PasswordTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_ForgotTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_SignInTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_SignTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_separatorTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_FBTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_BySigningTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_EULATop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_LogoTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_UserGreyTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_PassGreyTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_LeftSepTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_RightSepTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_GoogleTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_ActivityIndTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_httpBottom;

@property (weak, nonatomic) IBOutlet UITextField *tf_EmailID;
@property (weak, nonatomic) IBOutlet UITextField *tf_Password;
@property (weak, nonatomic) IBOutlet UIButton *btn_TroubleLogging;
@property (weak, nonatomic) IBOutlet UIButton *btn_Login;
@property (weak, nonatomic) IBOutlet UIButton *btn_SignUp;
@property (weak, nonatomic) IBOutlet UIScrollView *scroll_Main;
@property (weak, nonatomic) IBOutlet UIImageView *img_Map;
@property (weak, nonatomic) IBOutlet UIImageView *img_Logo;
@property (weak, nonatomic) IBOutlet UIImageView *img_Separator;
@property (weak, nonatomic) IBOutlet UILabel *lbl_Redirect;
@property (weak, nonatomic) IBOutlet UILabel *lbl_RedirectLink;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (IBAction)signUpClicked:(id)sender;
- (IBAction)troubleLoggingClicked:(id)sender;
- (IBAction)loginClicked:(id)sender;
- (IBAction)facebookClicked:(id)sender;
- (IBAction)googleClicked:(id)sender;

@property (nonatomic) BOOL isSocialURLDelegateCalled;
@property (nonatomic, assign) BOOL handleFacebookSchema;
@property (nonatomic, assign) BOOL handleGoogleSchema;

@end

@implementation OEXLoginViewController



- (void)layoutSubviews
{
    if (IS_IPHONE_4)
    {
        self.constraint_MapTop.constant = 25;
        self.constraint_LogoTop.constant = 58;
        self.constraint_UsernameTop.constant = 20;
        self.constraint_UserGreyTop.constant = 20;
        self.constraint_PasswordTop.constant = 8;
        self.constraint_PassGreyTop.constant = 8;
        self.constraint_ForgotTop.constant = 8;
        self.constraint_SignInTop.constant = 13;
        self.constraint_ActivityIndTop.constant = 43;
        self.constraint_SignTop.constant = 9;
        self.constraint_LeftSepTop.constant = 18;
        self.constraint_RightSepTop.constant = 18;
        self.constraint_FBTop.constant = 3;
        self.constraint_GoogleTop.constant = 3;
        self.constraint_BySigningTop.constant = 69;
        self.constraint_EULATop.constant = 73;
        self.constraint_httpBottom.constant = 12;
    }
    else
    {
        self.constraint_MapTop.constant = 50;
        self.constraint_LogoTop.constant = 80;
        self.constraint_UsernameTop.constant = 25;
        self.constraint_UserGreyTop.constant = 25;
        self.constraint_PasswordTop.constant = 12;
        self.constraint_PassGreyTop.constant = 12;
        self.constraint_ForgotTop.constant = 12;
        self.constraint_SignInTop.constant = 20;
        self.constraint_ActivityIndTop.constant = 55;
        self.constraint_SignTop.constant = 15;
        self.constraint_LeftSepTop.constant = 25;
        self.constraint_RightSepTop.constant = 25;
        self.constraint_FBTop.constant = 10;
        self.constraint_GoogleTop.constant = 10;
        self.constraint_BySigningTop.constant = 85;
        self.constraint_EULATop.constant = 88;
        self.constraint_httpBottom.constant = 20;
    }
    
}




#pragma mark -
#pragma mark - NSURLConnection Delegtates


- (void)callWebLoginURL
{
    NSURL *url = [NSURL URLWithString:URL_LOGIN relativeToURL:[NSURL URLWithString:[OEXConfig sharedConfig].apiHostURL]];
    //    NSLog(@"REQUEST : %@", url);
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:75.0f];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    connectionSRT = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    
    [connectionSRT start];
    
    if(connectionSRT)
    {
        receivedData = [NSMutableData data];
    }
    else
    {
        
    }
}



- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (!receivedData)
    {
        // no store yet, make one
        receivedData = [[NSMutableData alloc] initWithData:data];
    }
    else
    {
        // append to previous chunks
        [receivedData appendData:data];
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.str_CSRFToken = [[NSString alloc] init];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if ([response respondsToSelector:@selector(allHeaderFields)])
    {
        
        //  csrftoken=YBEPiZpyRIlSlw7GZS74bQNUR2FWdVCb; expires=Mon, 21-Sep-2015 10:10:27 GMT; Max-Age=31449600; Path=/
        
        NSArray *parse = [[[httpResponse allHeaderFields] objectForKey:@"Set-Cookie"] componentsSeparatedByString:@";"];
        
        for (int i = 0; i < [parse count]; i++)
        {
            if ([[parse objectAtIndex:i] hasPrefix:@"csrftoken="])
            {
                self.str_CSRFToken = [parse objectAtIndex:i];
                break;
            }
        }
        
        
        //        NSLog(@"header CSRF Token : %@",_str_CSRFToken);
        
    }
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //    NSString *response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    //    NSLog(@"============================================================\n");
    //    NSLog(@"RESPONSE : %@", self.str_CSRFToken);
    
    if ([self.str_CSRFToken length]>0)
    {
        [self resetPassword];
    }
    else
    {
        [self.view setUserInteractionEnabled:YES];
    }
    
}

// and error occured
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    //    NSLog(@"error : %@", [error description]);
    connectionSRT = nil;
}



#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


-(void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.view setUserInteractionEnabled:NO];
    
    if (IS_IOS8)
        [self performSelector:@selector(hideOverlay) withObject:nil afterDelay:0.5];
}


-(void)viewDidAppear:(BOOL)animated{
    
}

- (void)hideOverlay
{
    self.imgOverlay.hidden = YES;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
     self.titleLabel.text = NSLocalizedString(@"LOGIN_SIGN_IN_TO_EDX", nil);
    [self.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:20]];
    
    [self.btn_TroubleLogging setTitle:NSLocalizedString(@"TROUBLE_IN_LOGIN", nil) forState:UIControlStateNormal];
    [self.btn_Facebook setTitle:NSLocalizedString(@"FACEBOOK", nil) forState:UIControlStateNormal];
    [self.btn_Google setTitle:NSLocalizedString(@"GOOGLE", nil) forState:UIControlStateNormal];
    [self.lbl_OrSignIn setText:NSLocalizedString(@"OR_SIGN_IN_WITH", nil)];
    [self.lbl_OrSignIn setTextColor:[UIColor colorWithRed:60.0/255.0 green:64.0/255.0 blue:69.0/255.0 alpha:1.0]];
    
    if([OEXAuthentication isUserLoggedIn])
    {
        if (IS_IOS8)
        {
            self.imgOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            [self.imgOverlay setImage:[UIImage imageNamed:@"splash9640x1136.png"]];
            [self.view addSubview:self.imgOverlay];
            self.imgOverlay.hidden = NO;
        }
        [self launchReavealViewController];
    }
    
    [self setExclusiveTouch];

    //Analytics Screen record
    [[OEXAnalytics sharedAnalytics] trackScreenWithName:@"Login"];

}

-(IBAction)navigateBack:(id)sender{
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)setExclusiveTouch{
    
    self.btn_SignUp.exclusiveTouch=YES;
    self.btn_OpenEULA.exclusiveTouch=YES;
    self.btn_Google.exclusiveTouch=YES;
    self.btn_Facebook.exclusiveTouch=YES;
    self.btn_Login.exclusiveTouch=YES;
    self.btn_TroubleLogging.exclusiveTouch=YES;
    self.view.multipleTouchEnabled=NO;
    self.view.exclusiveTouch=YES;
    
}

- (void)hideEULA:(BOOL)hide
{
    //EULA
    [self.webview_EULA.scrollView setContentOffset:CGPointMake(0, 0)];
    self.view_EULA.hidden = hide;
    self.webview_EULA.hidden = hide;
    self.btn_Close.hidden = hide;
    self.img_SeparatorEULA.hidden = hide;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    OEXAppDelegate *appD=[[UIApplication sharedApplication] delegate];
    self.reachable=[appD.reachability isReachable];
    
    [self.view setUserInteractionEnabled:YES];
    self.view.exclusiveTouch=YES;
    
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
    UIGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(tappedToDismiss)];
    [self.view addGestureRecognizer:tapGesture];
    
    //To set all the components tot default property
    [self layoutSubviews];
    [self setToDefaultProperties];
    
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"LaunchReveal"])
    {
        // Analytics Device Properties
        SWRevealViewController *revealController=[segue destinationViewController];
        OEXAppDelegate *appD=[UIApplication sharedApplication].delegate;
        appD.revealController=revealController;
        
    }
}

- (void)handleActivationDuringLogin {
    if (isSocialLoginClicked)
    {
        [self.btn_Login setBackgroundImage:[UIImage imageNamed:@"bt_signin_default.png"] forState:UIControlStateNormal];
        [self.btn_TroubleLogging setTitleColor:[UIColor colorWithRed:31.0/255.0 green:159.0/255.0 blue:217.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [self.btn_OpenEULA setTitleColor:[UIColor colorWithRed:31.0/255.0 green:159.0/255.0 blue:217.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        
        [self.btn_Login setTitle:SIGN_IN_TEXT forState:UIControlStateNormal];
        [self.activityIndicator stopAnimating];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view setUserInteractionEnabled:YES];
        });
        
        isSocialLoginClicked=NO;
    }
}

- (void)setSignInToDefaultState:(NSNotification *)notification
{
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if(!self.isSocialURLDelegateCalled && self.handleGoogleSchema) {
        [[OEXGoogleSocial sharedInstance]clearHandler];
        [self handleActivationDuringLogin];
    }
    else if(!self.isSocialURLDelegateCalled && (![[OEXFBSocial sharedInstance] isLogin]&& self.handleFacebookSchema)) {
        [[OEXFBSocial sharedInstance]clearHandler];
        [self handleActivationDuringLogin];
    }
    self.isSocialURLDelegateCalled=NO;
    self.handleFacebookSchema=NO;
    self.handleGoogleSchema=NO;
    

    
}

- (void)setToDefaultProperties
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tf_EmailID.placeholder = NSLocalizedString(@"USERNAME_PLACEHOLDER", nil);
    self.tf_Password.placeholder = NSLocalizedString(@"PASSWORD_PLACEHOLDER", nil);
    self.tf_EmailID.text = @"";
    self.tf_Password.text = @"";
    
    self.lbl_Redirect.text = NSLocalizedString(@"REDIRECT_TEXT", nil);
    
    [self.btn_Login setBackgroundImage:[UIImage imageNamed:@"bt_signin_default.png"] forState:UIControlStateNormal];
    [self.btn_TroubleLogging setTitleColor:[UIColor colorWithRed:31.0/255.0 green:159.0/255.0 blue:217.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.btn_OpenEULA setTitleColor:[UIColor colorWithRed:31.0/255.0 green:159.0/255.0 blue:217.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    
    [self.btn_Login setTitle:SIGN_IN_TEXT forState:UIControlStateNormal];
    [self.activityIndicator stopAnimating];
    
    NSString* username=[[NSUserDefaults standardUserDefaults] objectForKey:USER_EMAIL];
    
    if(username)
        _tf_EmailID.text=username;
    
}



- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = (Reachability *)[notification object];
    
    if ([reachability isReachable])
    {
        self.reachable = YES;
    } else
    {
        self.reachable = NO;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view setUserInteractionEnabled:YES];
        });
        [self.btn_Login setBackgroundImage:[UIImage imageNamed:@"bt_signin_default.png"] forState:UIControlStateNormal];
        [self.btn_Login setTitle:SIGN_IN_TEXT forState:UIControlStateNormal];

        [self.activityIndicator stopAnimating];
        
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"NETWORK_NOT_AVAILABLE_TITLE", nil)
                                                             message:NSLocalizedString(@"NETWORK_NOT_AVAILABLE_MESSAGE", nil)
                                                    onViewController:self.view
                                                          shouldHide:YES];
        
    }
}


-(IBAction)buttonTouchedDown:(id)sender
{
    //[self.view setUserInteractionEnabled:NO];
}



- (void)loadEULA:(NSString *)resourse
{
    [self.webview_EULA loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:resourse ofType:@"htm"]isDirectory:NO]]];
}




-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
    if ( inType == UIWebViewNavigationTypeLinkClicked )
    {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    return YES;
}

#pragma mark IBActions
- (IBAction)openEULA:(id)sender
{
    [self loadEULA:@"EULA"];
    [self hideEULA:NO];
}

- (IBAction)closeEULA:(id)sender
{
    [self hideEULA:YES];
}

- (IBAction)signUpClicked:(id)sender
{
    [self loadEULA:@"NEW_USER"];
    [self hideEULA:NO];
    
    [[OEXAnalytics sharedAnalytics] trackUserDoesNotHaveAccount];
    
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_SIGN_UP]];
//    [self.view setUserInteractionEnabled:YES];
}


- (IBAction)troubleLoggingClicked:(id)sender
{
    if (self.reachable)
    {
        
        [self.view setUserInteractionEnabled:NO];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"RESET_PASSWORD_TITLE", nil)
                                                        message:NSLocalizedString(@"RESET_PASSWORD_POPUP_TEXT", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                              otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *textfield=[alert textFieldAtIndex:0];
        textfield.keyboardType=UIKeyboardTypeEmailAddress;
        
        if ([self.tf_EmailID.text length] > 0)
        {
            UITextField *tf = [alert textFieldAtIndex:0];
            [[alert textFieldAtIndex:0] setPlaceholder:@"E-mail address"];
            tf.text = self.tf_EmailID.text;
        }
        
        alert.tag = 1001;
        [alert show];
        
    }
    else
    {
        // error
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NETWORK_NOT_AVAILABLE_TITLE", nil)
                                                        message:NSLocalizedString(@"NETWORK_NOT_AVAILABLE_MESSAGE_TROUBLE", nil)
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        [alert show];
    }
}

- (IBAction)loginClicked:(id)sender
{
    [self.view setUserInteractionEnabled:NO];
    
    if (!self.reachable)
    {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"NETWORK_NOT_AVAILABLE_TITLE", nil)
                                                             message:NSLocalizedString(@"NETWORK_NOT_AVAILABLE_MESSAGE", nil)
                                                    onViewController:self.view
                                                          shouldHide:YES];
        
        [self.view setUserInteractionEnabled:YES];
        
        return;
    }
    
    //Validation
    if ([self.tf_EmailID.text length] == 0)
    {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"FLOATING_ERROR_LOGIN_TITLE", nil)
                                                             message:NSLocalizedString(@"ENTER_EMAIL", nil)                                                    onViewController:self.view
                                                          shouldHide:YES];
        
        [self.view setUserInteractionEnabled:YES];
        
        
    }
    else if ([self.tf_Password.text length] == 0)
    {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"FLOATING_ERROR_LOGIN_TITLE", nil)
                                                             message:NSLocalizedString(@"ENTER_PASSWORD", nil) onViewController:self.view shouldHide:YES];
        
        [self.view setUserInteractionEnabled:YES];
    }
    else
    {
        self.signInID = _tf_EmailID.text;
        self.signInPassword = _tf_Password.text;
        self.strLoggedInWith=@"Password";

        [OEXAuthentication requestTokenWithUser:_signInID
                                       password:_signInPassword
                              CompletionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                  [self handleLoginResponseWith:data response:response error:error];
                              } ];
        
        [self.view setUserInteractionEnabled:NO];
        [self.activityIndicator startAnimating];
        [self.btn_Login setTitle:NSLocalizedString(@"SIGN_IN_BUTTON_TEXT_ON_SIGINING", nil)  forState:UIControlStateNormal];
        [self.btn_Login setBackgroundImage:[UIImage imageNamed:@"bt_signin_active.png"] forState:UIControlStateNormal];
        
    }
}

-(void)handleLoginResponseWith:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error{
    
    [[OEXGoogleSocial sharedInstance]clearHandler];
    [[OEXFBSocial sharedInstance]clearHandler];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view setUserInteractionEnabled:YES];
    });
    
    if (!error) {
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
        if (httpResp.statusCode == 200) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self loginSuccessful];
                
            });
            
        }else if(httpResp.statusCode >=400 && httpResp.statusCode <= 500){
            
            NSString *errorStr=NSLocalizedString(@"INVALID_USERNAME_PASSWORD", nil );
//            [self performSelectorOnMainThread:@selector(loginFailed:) withObject:errorStr waitUntilDone:NO ];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loginFailed:errorStr Title:nil];
            });
            
        }else{
            
//            [self performSelectorOnMainThread:@selector(loginFailed:) withObject:NSLocalizedString(@"INVALID_USERNAME_PASSWORD", nil ) waitUntilDone:NO ];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loginFailed:NSLocalizedString(@"INVALID_USERNAME_PASSWORD", nil ) Title:nil];
            });

        }
    }
    else {

        [self performSelectorOnMainThread:@selector(loginHandleLoginError:) withObject:error waitUntilDone:NO];
        
    }
}


- (IBAction)facebookClicked:(id)sender
{
    isSocialLoginClicked=YES;
    [self.view setUserInteractionEnabled:NO];
     [self socialLoginWith:OEXFacebookLogin];
}

- (IBAction)googleClicked:(id)sender
{
    isSocialLoginClicked=YES;
    [self.view setUserInteractionEnabled:NO];
    [self socialLoginWith:OEXGoogleLogin];
}


-(void)socialLoginWith:(OEXSocialLoginType)type{
 
    [self.view setUserInteractionEnabled:NO];
    if (!self.reachable){
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"NETWORK_NOT_AVAILABLE_TITLE", nil)
                                                             message:NSLocalizedString(@"NETWORK_NOT_AVAILABLE_MESSAGE", nil)
                                                    onViewController:self.view
                                                          shouldHide:YES];
        [self.view setUserInteractionEnabled:YES];
        return;
    }
//#warning solve MOB-1115 here.

    self.isSocialURLDelegateCalled=NO;
    if(type==OEXFacebookLogin){
        self.handleFacebookSchema=YES;
    }else{
        self.handleGoogleSchema=YES;
    }
    
    [OEXAuthentication socialLoginWith:type completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!response) {
//            [self performSelectorOnMainThread:@selector(loginFailed:) withObject:NSLocalizedString(@"INVALID_USERNAME_PASSWORD", nil ) waitUntilDone:NO ];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loginFailed:NSLocalizedString(@"INVALID_USERNAME_PASSWORD", nil ) Title:nil];
            });

            return ;
        }
        self.handleFacebookSchema=NO;
        self.handleGoogleSchema=NO;

        if(type==OEXFacebookLogin)
        {
            self.strLoggedInWith=@"Facebook";
        }else{
            self.strLoggedInWith=@"Google";
        }
        
        [self handleLoginResponseWith:data response:response error:error];
    }];
    
    [self.view setUserInteractionEnabled:NO];
    [self.activityIndicator startAnimating];
    [self.btn_Login setTitle:NSLocalizedString(@"SIGN_IN_BUTTON_TEXT_ON_SIGINING", nil)  forState:UIControlStateNormal];
    [self.btn_Login setBackgroundImage:[UIImage imageNamed:@"bt_signin_active.png"] forState:UIControlStateNormal];
    
}

-(void)loginHandleLoginError:(NSError *)error{
    
    if (error.code == -1003 || error.code == -1009 || error.code == -1005)
    {
//        [self performSelectorOnMainThread:@selector(loginFailed:) withObject:NSLocalizedString(@"INVALID_USERNAME_PASSWORD", nil ) waitUntilDone:NO ];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loginFailed:NSLocalizedString(@"INVALID_USERNAME_PASSWORD", nil ) Title:nil];
        });

    }
    else
    {
        if(error.code==401)
        {
            [[OEXFBSocial sharedInstance]clearHandler];
            [[OEXGoogleSocial sharedInstance]clearHandler];
            
            // MOB - 1110 - Social login error if the user's account is not linked with edX.
            if ([self.strLoggedInWith isEqualToString:@"Facebook"])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loginFailed: NSLocalizedString(@"FACEBOOK_ACCOUNT_NOT_ASSOCIATED_MESSAGE", nil )
                                Title: NSLocalizedString(@"FACEBOOK_ACCOUNT_NOT_ASSOCIATED_TITLE", nil ) ];
                });
    
            }
            else if ([self.strLoggedInWith isEqualToString:@"Google"])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loginFailed: NSLocalizedString(@"GOOGLE_ACCOUNT_NOT_ASSOCIATED_MESSAGE", nil )
                                Title: NSLocalizedString(@"GOOGLE_ACCOUNT_NOT_ASSOCIATED_TITLE", nil ) ];
                });
    
            }
            
        }
        else
        {
//            [self performSelectorOnMainThread:@selector(loginFailed:) withObject:[error localizedDescription] waitUntilDone:NO ];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loginFailed:[error localizedDescription]  Title:nil];
            });

        }

    }
}



-(void)loginFailed:(NSString *)errorStr Title:(NSString *)title
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
    
    if (title)
    {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:title
                                                                message:errorStr onViewController:self.view shouldHide:YES];
    }
    else
    {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"FLOATING_ERROR_LOGIN_TITLE", nil)
                                                         message:errorStr onViewController:self.view shouldHide:YES];
    }
    
    [self.activityIndicator stopAnimating];
    [self.btn_Login setBackgroundImage:[UIImage imageNamed:@"bt_signin_default.png"] forState:UIControlStateNormal];
    [self.btn_Login setTitle:SIGN_IN_TEXT forState:UIControlStateNormal];
    
    [self.view setUserInteractionEnabled:YES];
    
    self.strLoggedInWith = @"";
    
    [self tappedToDismiss];
    
}

- (void)loginSuccessful {
    //set global auth

      if([_tf_EmailID.text length]>0)
        {
            // Set the language to blank
            [OEXInterface setCCSelectedLanguage:@""];
            [[NSUserDefaults standardUserDefaults] setObject:_tf_EmailID.text forKey:USER_EMAIL];
            // Analytics User Login
            if(self.strLoggedInWith)
                [[OEXAnalytics sharedAnalytics] trackUserLogin:self.strLoggedInWith];
        }
    [self tappedToDismiss];
    [self.activityIndicator stopAnimating];
    [self.btn_Login setBackgroundImage:[UIImage imageNamed:@"bt_signin_default.png"] forState:UIControlStateNormal];
    [self launchReavealViewController];
    //Launch next view
}

-(void)launchReavealViewController{
    
    OEXUserDetails *objUser = [OEXAuthentication getLoggedInUser];
    if(objUser){
        [[OEXInterface sharedInterface] activateIntefaceForUser:objUser];
        [[OEXInterface sharedInterface] loggedInUser:objUser];
        [[OEXAnalytics sharedAnalytics] identifyUser:objUser];
        //Init background downloads
        [[OEXInterface sharedInterface] startAllBackgroundDownloads];
        [self performSegueWithIdentifier:@"LaunchReveal" sender:self];
    }

}


#pragma mark UI

- (void)tappedToDismiss
{
    [_tf_EmailID resignFirstResponder];
    [_tf_Password resignFirstResponder];
}

#pragma mark UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    [self.view setUserInteractionEnabled:YES];
    
    
    if (alertView.tag == 1001)
    {
        UITextField *EmailtextField = [alertView textFieldAtIndex:0];
        
        if (buttonIndex == 1)
        {
            if ([EmailtextField.text length]==0 || ![EmailtextField.text oex_isValidEmailAddress])
            {
                [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"FLOATING_ERROR_TITLE", nil)
                                                                     message:NSLocalizedString(@"INVALID_EMAIL_MESSAGE", nil)
                                                            onViewController:self.view shouldHide:YES];
            }
            else
            {
                self.str_ForgotEmail = [[NSString alloc] init];
                
                self.str_ForgotEmail = EmailtextField.text;
                
                [self.view setUserInteractionEnabled:NO];
                
                [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"RESET_PASSWORD_TITLE", nil)
                                                                     message:NSLocalizedString(@"WAITING_FOR_RESPONSE", nil)
                                                            onViewController:self.view shouldHide:NO];
                
                // Call edX Login URL before the Reset Password API
                // To get the CSRFToken from the response header and pass to Reset Password API
                
                [self callWebLoginURL];
                
                
            }
        }
        
    }
    
}



- (void)resetPassword
{
    [OEXAuthentication resetPasswordWithEmailId:self.str_ForgotEmail CSRFToken:self.str_CSRFToken completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
     {
         
         [self.view setUserInteractionEnabled:YES];
         
         NSDictionary *dictionary =[NSJSONSerialization  JSONObjectWithData:data options:kNilOptions error:nil];
         ELog(@"dictionary : %@", dictionary);
         
         if (!error)
         {
             NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 
                 if (httpResp.statusCode == 200)
                 {
                     
                     [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"RESET_PASSWORD_CONFIRMATION_TITLE",nil)
                                                 message:NSLocalizedString(@"RESET_PASSWORD_CONFIRMATION_MESSAGE",nil)
                       
                                                delegate:self
                                       cancelButtonTitle:nil
                                       otherButtonTitles:@"OK", nil] show];
                     
                     
                     
                 }else if (httpResp.statusCode<=400 && httpResp.statusCode <500){
                     
                     
                     NSDictionary *dictionary =[NSJSONSerialization  JSONObjectWithData:data options:kNilOptions error:nil];
                     NSString *responseStr = [[dictionary objectForKey:@"email"] firstObject];
                     
                     [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"FLOATING_ERROR_TITLE", nil)message:responseStr onViewController:self.view shouldHide:YES];
                     
                     
                 }else if ( httpResp.statusCode > 500){
                     
                     NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                     [[OEXFlowErrorViewController sharedInstance]showErrorWithTitle:NSLocalizedString(@"FLOATING_ERROR_TITLE", nil)
                                                                         message:responseStr onViewController:self.view shouldHide:YES];
                     
                 }
             });
             
             
         }else{
             
             [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"FLOATING_ERROR_TITLE", nil) message:[error localizedDescription] onViewController:self.view shouldHide:YES];
             
             
         }
         
     }];
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    UITouch *touch=[touches anyObject];
    
    if([[touch view] isKindOfClass:[UIButton class]]){
        [self.view setUserInteractionEnabled:NO];
    }
    
}



#pragma mark TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    if (textField == self.tf_EmailID)
    {
        [self.tf_Password becomeFirstResponder];
    }
    else
        [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    activeField = textField;
}



#pragma mark - Scolling on Keyboard Hide/Show

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
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
    if (!CGRectContainsPoint(aRect, fieldOrigin) ) {
        [self.scroll_Main scrollRectToVisible:CGRectMake(activeField.frame.origin.x, activeField.frame.origin.y, activeField.frame.size.width, activeField.frame.size.height) animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scroll_Main.contentInset = contentInsets;
    self.scroll_Main.scrollIndicatorInsets = contentInsets;
    [self.scroll_Main setContentOffset:originalOffset animated:YES];
    
}



- (void)scrollViewDidScroll:(UIScrollView *) scrollView;
{
    if (scrollView == self.scroll_Main)
        originalOffset = scrollView.contentOffset;
}




@end
