//
//  OEXRegistrationViewController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//
#import "OEXRegistrationViewController.h"

#import <Masonry/Masonry.h>

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "NSArray+OEXFunctional.h"
#import "NSError+OEXKnownErrors.h"
#import "NSJSONSerialization+OEXSafeAccess.h"
#import "NSMutableDictionary+OEXSafeAccess.h"

#import "OEXAnalytics.h"
#import "OEXAuthentication.h"
#import "OEXConfig.h"
#import "OEXExternalAuthProvider.h"
#import "OEXExternalRegistrationOptionsView.h"
#import "OEXFacebookAuthProvider.h"
#import "OEXFacebookConfig.h"
#import "OEXFlowErrorViewController.h"
#import "OEXGoogleAuthProvider.h"
#import "OEXGoogleConfig.h"
#import "OEXHTTPStatusCodes.h"
#import "OEXRegistrationAgreementController.h"
#import "OEXRegistrationDescription.h"
#import "OEXRegistrationFieldControllerFactory.h"
#import "OEXRegistrationFieldError.h"
#import "OEXRegistrationFormField.h"
#import "OEXRegistrationStyles.h"
#import "OEXRegisteringUserDetails.h"
#import "OEXRouter.h"
#import "OEXStyles.h"
#import "OEXUserLicenseAgreementViewController.h"
#import "OEXUsingExternalAuthHeadingView.h"

@implementation OEXRegistrationViewControllerEnvironment

- (id)initWithAnalytics:(OEXAnalytics *)analytics config:(OEXConfig *)config router:(OEXRouter *)router {
    self = [super init];
    if(self != nil) {
        _analytics = analytics;
        _config = config;
        _router = router;
    }
    return self;
}

@end

NSString* const OEXExternalRegistrationWithExistingAccountNotification = @"OEXExternalRegistrationWithExistingAccountNotification";

@interface OEXRegistrationViewController () <OEXExternalRegistrationOptionsViewDelegate>

@property (strong, nonatomic) OEXRegistrationDescription* registrationDescription;

/// Contents are id <OEXRegistrationFieldController>
@property (strong, nonatomic) NSArray* fieldControllers;

@property (strong, nonatomic) IBOutlet UIScrollView* scrollView;
@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UIView *mockNavigationBarView;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;

// Used in auth from an external provider
@property (strong, nonatomic) UIView* currentHeadingView;
@property (strong, nonatomic) id <OEXExternalAuthProvider> externalProvider;
@property (copy, nonatomic) NSString* externalAccessToken;

@property (strong, nonatomic) UIButton* registerButton;
@property (strong, nonatomic) UILabel* agreementLabel;
@property (strong, nonatomic) UIButton* agreementLink;
@property (strong, nonatomic) UIButton* toggleOptionalFieldsButton;
@property (strong, nonatomic) UIImageView* optionalFieldsSeparator;
@property (strong, nonatomic) UIActivityIndicatorView* progressIndicator;

@property (assign, nonatomic) BOOL isShowingOptionalFields;

@property (strong, nonatomic) OEXRegistrationStyles* styles;

@property (strong, nonatomic) OEXRegistrationViewControllerEnvironment* environment;

@end

@implementation OEXRegistrationViewController

- (id)initWithRegistrationDescription:(OEXRegistrationDescription*)description environment:(OEXRegistrationViewControllerEnvironment *)environment {
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil) {
        self.registrationDescription = description;
        self.styles = [[OEXRegistrationStyles alloc] init];
    }
    return self;
}

- (id)initWithEnvironment:(OEXRegistrationViewControllerEnvironment *)environment {
    return [self initWithRegistrationDescription: [[self class] registrationFormDescription] environment:environment];
}

+ (OEXRegistrationDescription*)registrationFormDescription {
    NSString* filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"registration" ofType:@"json"];
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    NSAssert(data != nil, @"Could not load registration.json");
    NSError* error;
    id json = [NSJSONSerialization oex_JSONObjectWithData:data error:&error];
    NSAssert(error == nil, @"Could not parse registration.json");
    return [[OEXRegistrationDescription alloc] initWithDictionary:json];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self makeFieldControllers];
    [self initializeViews];
    [self refreshFormFields];
    
    [[OEXStyles sharedStyles] applyMockNavigationBarStyleToView:self.mockNavigationBarView label:self.titleLabel leftIconButton:self.closeButton];
    //By default we only shows required fields
    self.isShowingOptionalFields = NO;
}

//Currently using asset file only to get from description
- (void)makeFieldControllers {
    self.fieldControllers = [self.registrationDescription.registrationFormFields
                             oex_map:^id < OEXRegistrationFieldController > (OEXRegistrationFormField* formField) {
        id <OEXRegistrationFieldController> fieldController = [OEXRegistrationFieldControllerFactory registrationFieldViewController:formField];
        if(formField.fieldType == OEXRegistrationFieldTypeAgreement) {
            // These don't have explicit representations in the apps
            return nil;
        }
        return fieldController;
    }];
}

// This method will set default ui.

- (void)initializeViews {
    NSString* regularFont = @"OpenSans";
    NSString* semiboldFont = @"OpenSans-Semibold";

    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.topItem.title = @"";
    self.automaticallyAdjustsScrollViewInsets = NO;
    // set the custom navigation view properties

    NSString* platform = [[OEXConfig sharedConfig] platformName];
    self.titleLabel.text = [Strings registrationSignUpForPlatformWithPlatformName:platform];
    [self.titleLabel setFont:[UIFont fontWithName:semiboldFont size:20.f]];

    ////Create and initalize 'btnCreateAccount' button
    self.registerButton = [[UIButton alloc] init];
    
    [self.registerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.registerButton setTitle:[Strings registrationCreateMyAccount] forState:UIControlStateNormal];
    [self.registerButton addTarget:self action:@selector(createAccount:) forControlEvents:UIControlEventTouchUpInside];
    [self.registerButton setBackgroundImage:[UIImage imageNamed:@"bt_signin_active.png"] forState:UIControlStateNormal];

    ////Create progrssIndicator as subview to btnCreateAccount
    self.progressIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [self.registerButton addSubview:self.progressIndicator];
    [self.progressIndicator hidesWhenStopped];
    self.optionalFieldsSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"separator3"]];
    //Initialize label above agreement view
    self.agreementLabel = [[UILabel alloc] init];
    self.agreementLabel.font = [UIFont fontWithName:regularFont size:10.f];
    self.agreementLabel.textAlignment = NSTextAlignmentCenter;
    self.agreementLabel.numberOfLines = 0;
    self.agreementLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.agreementLabel.text = [Strings registrationAgreementMessageWithPlatformName:platform];
    self.agreementLink = [[UIButton alloc] init];
    [self.agreementLink setTitle:[Strings registrationAgreementButtonTitleWithPlatformName:platform] forState:UIControlStateNormal];
    [self.agreementLink.titleLabel setFont:[UIFont fontWithName:semiboldFont size:10]];
    [self.agreementLink setTitleColor:[UIColor colorWithRed:0.16 green:0.44 blue:0.84 alpha:1] forState:UIControlStateNormal];
    [self.agreementLink addTarget:self action:@selector(agreementButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    //This button will show and hide optional fields
    self.toggleOptionalFieldsButton = [[UIButton alloc] init];
    [self.toggleOptionalFieldsButton setBackgroundColor:[UIColor whiteColor]];
    [self.toggleOptionalFieldsButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.toggleOptionalFieldsButton setTitle:[Strings registrationShowOptionalFields]  forState:UIControlStateNormal];
    [self.toggleOptionalFieldsButton.titleLabel setFont:[UIFont fontWithName:semiboldFont size:14.0]];

    [self.toggleOptionalFieldsButton addTarget:self action:@selector(toggleOptionalFields:) forControlEvents:UIControlEventTouchUpInside];

    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] init];
    [tapGesture addTarget:self action:@selector(scrollViewTapped:)];
    [self.scrollView addGestureRecognizer:tapGesture];
    
    NSMutableArray* providers = [[NSMutableArray alloc] init];
    if(self.environment.config.googleConfig.enabled) {
        [providers addObject:[[OEXGoogleAuthProvider alloc] init]];
    }
    if(self.environment.config.facebookConfig.enabled) {
        [providers addObject:[[OEXFacebookAuthProvider alloc] init]];
    }
    if(providers.count > 0) {
        OEXExternalRegistrationOptionsView* headingView = [[OEXExternalRegistrationOptionsView alloc] initWithFrame:CGRectZero providers:providers];
        headingView.delegate = self;
        [self useHeadingView:headingView];
    }
    
    self.closeButton.accessibilityLabel = [Strings close];
}

- (void)useHeadingView:(UIView*)headingView {
    [self.currentHeadingView removeFromSuperview];
    self.currentHeadingView = headingView;
    [self.scrollView addSubview:self.currentHeadingView];
    [self.view setNeedsUpdateConstraints];
    [self.view setNeedsLayout];
}

- (IBAction)navigateBack:(id)sender {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Scrolling on keyboard hide and show
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameChanged:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // This  will remove observer for keyboard
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldFilterField:(OEXRegistrationFormField*)field {
    return self.externalProvider != nil && [field.name isEqualToString:@"password"];
}

- (void)refreshFormFields {
    for(id <OEXRegistrationFieldController>fieldController in self.fieldControllers) {
        // Add view to scroll view if field is not optional and it is not agreement field.
        UIView* view = fieldController.view;
        if(fieldController.field.isRequired && ![self shouldFilterField:fieldController.field]) {
            [self.scrollView addSubview:view];
            [view setNeedsLayout];
            [view layoutIfNeeded];
        }
        else {
            [view removeFromSuperview];
        }
    }

    // Actually show the optional fields if necessary
    if(self.isShowingOptionalFields) {
        for(id <OEXRegistrationFieldController>fieldController in self.fieldControllers) {
            if(![fieldController field].isRequired && ![self shouldFilterField:fieldController.field]) {
                UIView* view = fieldController.view;
                [self.scrollView addSubview:view];
                [view setNeedsLayout];
                [view layoutIfNeeded];
            }
        }
    }
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)updateViewConstraints {
    CGFloat margin = self.styles.formMargin;
    [self.currentHeadingView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scrollView);
        make.leading.equalTo(self.scrollView.mas_leading).offset(margin);
        make.trailing.equalTo(self.scrollView.mas_trailing).offset(margin);
        make.width.mas_equalTo(self.scrollView.bounds.size.width - 40);
    }];
    [super updateViewConstraints];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Add space if the heading view won't do it for us
    NSInteger topSpacing = self.currentHeadingView == nil ? 10 : 0;
    NSInteger horizontalSpacing = self.styles.formMargin;
    NSInteger offset = 0;
    CGFloat width = self.scrollView.frame.size.width;
    NSInteger contentWidth = width - 2 * horizontalSpacing;
    
    // Force the heading view to layout, so we get its height
    [self.currentHeadingView setNeedsLayout];
    [self.currentHeadingView layoutIfNeeded];
    
    // Then do it again since we may have updated the preferred size of some text
    [self.currentHeadingView setNeedsLayout];
    
    //Setting offset as topspacing
    CGSize size = [self.currentHeadingView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    offset = topSpacing + size.height;
    
    for(id <OEXRegistrationFieldController>fieldController in self.fieldControllers) {
        UIView* view = fieldController.view;
        // Add view to scroll view if field is not optional and it is not agreement field.
        if([fieldController field].isRequired && view.superview != nil) {
            [view layoutIfNeeded];
            [view setFrame:CGRectMake(0, offset, width, view.frame.size.height)];
            offset = offset + view.frame.size.height;
        }
    }
    
    //Add the optional field toggle
    
    CGFloat buttonWidth = 150;
    CGFloat buttonHeight = 30;
    [self.scrollView addSubview:self.optionalFieldsSeparator];
    [self.toggleOptionalFieldsButton setFrame:CGRectMake(self.view.frame.size.width / 2 - buttonWidth / 2, offset, buttonWidth, buttonHeight)];
    [self.scrollView addSubview:self.toggleOptionalFieldsButton];
    self.optionalFieldsSeparator.frame = CGRectMake(horizontalSpacing, self.toggleOptionalFieldsButton.center.y, contentWidth, 1);
    self.optionalFieldsSeparator.center = self.toggleOptionalFieldsButton.center;
    
    offset = offset + buttonHeight + 10;
    
    // Actually show the optional fields if necessary
    for(id <OEXRegistrationFieldController>fieldController in self.fieldControllers) {
        UIView* view = fieldController.view;
        if(![fieldController field].isRequired && view.superview != nil) {
            [view layoutIfNeeded];
            [view setFrame:CGRectMake(0, offset, width, view.frame.size.height)];
            [self.scrollView addSubview:view];
            offset = offset + view.frame.size.height;
        }
    }
    
    [self.registerButton setFrame:CGRectMake(horizontalSpacing, offset, contentWidth, 40)];

    const int progressIndicatorCenterX = [self isRTL] ? 40 : self.registerButton.frame.size.width - 40;

        self.progressIndicator.center = CGPointMake(progressIndicatorCenterX, self.registerButton.frame.size.height / 2);
    
    [self.scrollView addSubview:self.registerButton];
    offset = offset + 40;
    
    NSInteger buttonLabelSpacing = 10;
    
    [self.agreementLabel setFrame:CGRectMake(horizontalSpacing, offset + buttonLabelSpacing, width - 2 * horizontalSpacing, 20)];
    [self.scrollView addSubview:self.agreementLabel];
    offset = offset + self.agreementLabel.frame.size.height;
    [self.scrollView addSubview:self.agreementLink];
    [self.agreementLink setFrame:CGRectMake(horizontalSpacing, offset, contentWidth, 40)];
    offset = offset + self.agreementLink.frame.size.height;
    [self.scrollView setContentSize:CGSizeMake(width, offset)];
}

//This method will hide and unhide optional fields
//using isRequired flag for corresponding field.

- (void)toggleOptionalFields:(id)sender {
    self.isShowingOptionalFields = !self.isShowingOptionalFields;
    if(self.isShowingOptionalFields) {
        [self.toggleOptionalFieldsButton setTitle:[Strings registrationHideOptionalFields] forState:UIControlStateNormal];
    }
    else {
        [self.toggleOptionalFieldsButton setTitle:[Strings registrationShowOptionalFields] forState:UIControlStateNormal];
    }

    [self refreshFormFields];
}

#pragma mark ExternalRegistrationOptionsDelegate

- (void)optionsView:(OEXExternalRegistrationOptionsView *)view choseProvider:(id<OEXExternalAuthProvider>)provider {
    [provider authorizeServiceFromController:self requestingUserDetails:YES withCompletion:^(NSString *accessToken, OEXRegisteringUserDetails *userProfile, NSError *error) {
        if(error == nil) {
            [view beginIndicatingActivity];
            self.view.userInteractionEnabled = NO;
            [self attemptExternalLoginWithProvider:provider token:accessToken completion:^(NSData* data, NSHTTPURLResponse* response, NSError *error) {
                [view endIndicatingActivity];
                self.view.userInteractionEnabled = YES;
                if(response.statusCode == OEXHTTPStatusCode200OK) {
                    [self.delegate registrationViewControllerDidRegister:self completion: ^{
                        // Need to show on login screen that we already had an account
                        [[NSNotificationCenter defaultCenter] postNotificationName:OEXExternalRegistrationWithExistingAccountNotification object:provider.displayName];
                    }];
                }
                else {
                    // No account already, so continue registration process
                    UIView* headingView = [[OEXUsingExternalAuthHeadingView alloc] initWithFrame:CGRectZero serviceName:provider.displayName];
                    [self useHeadingView:headingView];
                    [self receivedFields:userProfile fromProvider:provider withAccessToken:accessToken];
                }
            }];
        }
        else if([error oex_isNoInternetConnectionError]){
            [view endIndicatingActivity];
            [[OEXFlowErrorViewController sharedInstance] showNoConnectionErrorOnView:self.view];
        }
        else {
            [view endIndicatingActivity];
            // Do nothing. Typically this happens because the user hits cancel and so they know it didn't work already
        }
    }];
}

- (void)receivedFields:(OEXRegisteringUserDetails*)profile fromProvider:(id <OEXExternalAuthProvider>)provider withAccessToken:(NSString*)accessToken {
    self.externalAccessToken = accessToken;
    self.externalProvider = provider;
    // Long term, we should update the registration.json description to provide this mapping.
    // We will need to do this if we ever transition to fetching that from the server
    for(id <OEXRegistrationFieldController> controller in self.fieldControllers) {
        if([[controller field].name isEqualToString:@"email"]) {
            [controller takeValue:profile.email];
        }
        if([[controller field].name isEqualToString:@"name"]) {
            [controller takeValue:profile.name];
        }
        if([[controller field].name isEqualToString:@"year_of_birth"]) {
            [controller takeValue:profile.birthYear];
        }
    }
    [self refreshFormFields];
}

- (void)attemptExternalLoginWithProvider:(id <OEXExternalAuthProvider>)provider token:(NSString*)token completion:(void(^)(NSData* data, NSHTTPURLResponse* response, NSError* error))completion {
    [OEXAuthentication requestTokenWithProvider:provider externalToken:token completion:completion];
}

#pragma mark IBAction

- (IBAction)createAccount:(id)sender {
    // Clear error for all views
    [self.fieldControllers makeObjectsPerformSelector:@selector(handleError:) withObject:nil];
    // Dictionary for registration parameters
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    BOOL hasError = NO;

    for(id <OEXRegistrationFieldController> controller in self.fieldControllers) {
        if([controller isValidInput]) {
            if([controller hasValue]) {
                [parameters safeSetObject:[controller currentValue] forKey:[controller field].name];
            }
        }
        else if(![self shouldFilterField:controller.field]){
            hasError = YES;
        }
    }

    if(hasError) {
        [self showProgress:NO];
        [self refreshFormFields];
        return;
    }
    //Setting parameter 'honor_code'='true'
    [parameters setObject:@"true" forKey:@"honor_code"];

    //As user is agree to the license setting 'terms_of_service'='true'
    [parameters setObject:@"true" forKey:@"terms_of_service"];
    
    if(self.externalProvider != nil) {
        [parameters safeSetObject:self.externalAccessToken forKey: @"access_token"];
        [parameters safeSetObject:self.externalProvider.backendName forKey:@"provider"];
        [parameters safeSetObject:self.environment.config.oauthClientID forKey:@"client_id"];
    }

    __weak id weakSelf = self;
    [self showProgress:YES];

    [self.environment.analytics trackRegistrationWithProvider:self.externalProvider.backendName];

    [OEXAuthentication registerUserWithParameters:parameters completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
        if(!error) {
            NSDictionary* dictionary = [NSJSONSerialization oex_JSONObjectWithData:data error:&error];
            OEXLogInfo(@"REGISTRATION", @"Register user response ==>> %@", dictionary);
            NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
            
            void(^completion)(NSData*, NSURLResponse*, NSError*) = ^(NSData* data, NSURLResponse* response, NSError* error){
                NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
                if(httpResp.statusCode == OEXHTTPStatusCode200OK) {
                    [self.delegate registrationViewControllerDidRegister:weakSelf completion:nil];
                }
                else if([error oex_isNoInternetConnectionError]) {
                    [[OEXFlowErrorViewController sharedInstance] showNoConnectionErrorOnView:self.view];
                }
                [self showProgress:NO];
            };
            
            if(httpResp.statusCode == OEXHTTPStatusCode200OK) {
                if(self.externalProvider == nil) {
                    NSString* username = parameters[@"username"];
                    NSString* password = parameters[@"password"];
                    [OEXAuthentication requestTokenWithUser:username password:password completionHandler:completion];
                }
                else {
                    [self attemptExternalLoginWithProvider:self.externalProvider token:self.externalAccessToken completion:completion];
                }
                
            }
            else {
                NSMutableDictionary* controllers = [[NSMutableDictionary alloc] init];
                for(id <OEXRegistrationFieldController> controller in self.fieldControllers) {
                    [controllers safeSetObject:controller forKey:controller.field.name];
                    [controller handleError:nil];
                }
                [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString* fieldName, NSArray* errorInfos, BOOL* stop) {
                    id <OEXRegistrationFieldController> controller = controllers[fieldName];
                    NSArray* errorStrings = [errorInfos oex_map:^id (NSDictionary* info) {
                        return [[OEXRegistrationFieldError alloc] initWithDictionary:info].userMessage;
                    }];
                    
                    NSString* errors = [errorStrings componentsJoinedByString:@" "];
                    [controller handleError:errors];
                }];
                [self showProgress:NO];
                [self refreshFormFields];
            }
        }
        else {
            if([error oex_isNoInternetConnectionError]) {
                NSString* title = [Strings networkNotAvailableTitle];
                NSString* message = [Strings networkNotAvailableMessage];
                [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:title message:message onViewController:self.view shouldHide:YES];
            }
            [self showProgress:NO];
        }
    }];
}

- (void)scrollViewTapped:(id)sender {
    [self.view endEditing:YES];
}

- (void)agreementButtonTapped:(id)sender {
    NSURL* url = [[NSBundle mainBundle] URLForResource:@"Terms-and-Services" withExtension:@"htm"];
    OEXUserLicenseAgreementViewController* viewController = [[OEXUserLicenseAgreementViewController alloc] initWithContentURL:url];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)showProgress:(BOOL)status {
    if(status) {
        [self.progressIndicator startAnimating];
        [self.registerButton setTitle:[Strings registrationCreatingAccount] forState:UIControlStateNormal];
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }
    else {
        [self.progressIndicator stopAnimating];
        [self.registerButton setTitle:[Strings registrationCreateMyAccount] forState:UIControlStateNormal];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

#pragma mark - Scolling on Keyboard Hide/Show

// Called when the UIKeyboardDidChangeFrameNotification is sent.
- (void)keyboardFrameChanged:(NSNotification*)notification {
    CGRect globalFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect localFrame = [self.view convertRect:globalFrame fromView:nil];
    CGRect intersection = CGRectIntersection(localFrame, self.view.bounds);
    CGFloat keyboardHeight = intersection.size.height;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardHeight, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}


- (BOOL) isRTL {
    return [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}

@end

@implementation OEXRegistrationViewController (Testing)

- (OEXRegistrationDescription*)t_registrationFormDescription {
    return self.registrationDescription;
}

- (NSUInteger)t_visibleFieldCount {
    NSIndexSet* visibleIndexes = [self.fieldControllers indexesOfObjectsPassingTest:^BOOL (id < OEXRegistrationFieldController > controller, NSUInteger idx, BOOL* stop) {
        return controller.view.superview != nil;
    }];
    return visibleIndexes.count;
}

- (void)t_toggleOptionalFields {
    [self toggleOptionalFields:nil];
}

@end
