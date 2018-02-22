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
#import "OEXAuthentication.h"
#import "OEXExternalAuthProvider.h"
#import "OEXExternalRegistrationOptionsView.h"
#import "OEXFacebookAuthProvider.h"
#import "OEXFacebookConfig.h"
#import "OEXGoogleAuthProvider.h"
#import "OEXGoogleConfig.h"
#import "OEXHTTPStatusCodes.h"
#import "OEXRegistrationDescription.h"
#import "OEXRegistrationFieldError.h"
#import "OEXRegistrationFormField.h"
#import "OEXRegistrationStyles.h"
#import "OEXRegisteringUserDetails.h"
#import "OEXUserLicenseAgreementViewController.h"
#import "OEXUsingExternalAuthHeadingView.h"
#import "OEXRegistrationAgreement.h"


NSString* const OEXExternalRegistrationWithExistingAccountNotification = @"OEXExternalRegistrationWithExistingAccountNotification";

@interface OEXRegistrationViewController () <OEXExternalRegistrationOptionsViewDelegate>

/// Contents are id <OEXRegistrationFieldController>
@property (strong, nonatomic) NSArray* fieldControllers;

@property (strong, nonatomic) IBOutlet UIScrollView* scrollView;

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
@property (strong, nonatomic) OEXTextStyle *toggleButtonStyle;

@end

@implementation OEXRegistrationViewController

- (id)initWithEnvironment:(RouterEnvironment *)environment {
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil) {
        self.environment = environment;
        self.styles = [[OEXRegistrationStyles alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loadController = [[LoadStateViewController alloc] init];
    [self.loadController setupInControllerWithController:self contentView:self.scrollView];
    
    self.navigationController.navigationBarHidden = NO;
    
    [self setTitle:[Strings registerText]];
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_cancel"] style:UIBarButtonItemStylePlain target:self action:@selector(navigateBack:)];
    closeButton.accessibilityLabel = [Strings close];
    self.navigationItem.leftBarButtonItem = closeButton;
    
    //By default we only shows required fields
    self.isShowingOptionalFields = NO;
    
    self.toggleButtonStyle = [[OEXTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeBase color:[[OEXStyles sharedStyles] neutralDark]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(formFieldValueDidChange:) name:NOTIFICATION_REGISTRATION_FORM_FIELD_VALUE_DID_CHANGE object:nil];
    
    [self getFormFields];
}

-(void)formFieldValueDidChange: (NSNotification *)notification {
    [self refreshFormFields];
}

- (void)getFormFields {
    __weak typeof(self) weakSelf = self;
    
    [self getRegistrationFormDescriptionWithSuccess:^(OEXRegistrationDescription * _Nonnull response) {
        weakSelf.registrationDescription = response;
        [weakSelf makeFieldControllers];
        [weakSelf initializeViews];
        [weakSelf refreshFormFields];
    }];
}

//Currently using asset file only to get from description
- (void)makeFieldControllers {
    NSArray* fields = self.registrationDescription.registrationFormFields;
    self.fieldControllers = [fields oex_map:^id < OEXRegistrationFieldController > (OEXRegistrationFormField* formField)
                             {
                                 if(formField.fieldType != OEXRegistrationFieldTypeAgreement) {
                                     id <OEXRegistrationFieldController> fieldController = [RegistrationFieldControllerFactory registrationControllerOf:formField];
                                     return fieldController;
                                 }
                                 return nil;
                             }];
}

// This method will set default ui.

- (void)initializeViews {

    NSString* platform = self.environment.config.platformName;

    ////Create and initalize 'btnCreateAccount' button
    self.registerButton = [[UIButton alloc] init];
    
    [self.registerButton oex_addAction:^(id  _Nonnull control) {
        [self createAccount:nil];
    } forEvents:UIControlEventTouchUpInside];
    
    [self.registerButton applyButtonStyleWithStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[Strings registrationCreateMyAccount]];
    self.registerButton.accessibilityIdentifier = @"register";

    ////Create progrssIndicator as subview to btnCreateAccount
    self.progressIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [self.registerButton addSubview:self.progressIndicator];
    [self.progressIndicator hidesWhenStopped];
    self.optionalFieldsSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"separator3"]];
    //Initialize label above agreement view
    self.agreementLabel = [[UILabel alloc] init];
    self.agreementLabel.font = [self.environment.styles sansSerifOfSize:10.f];
    self.agreementLabel.textAlignment = NSTextAlignmentCenter;
    self.agreementLabel.numberOfLines = 0;
    self.agreementLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.agreementLabel.isAccessibilityElement = NO;
    self.agreementLabel.text = [Strings registrationAgreementMessage];
    self.agreementLink = [[UIButton alloc] init];
    [self.agreementLink setTitle:[Strings registrationAgreementButtonTitleWithPlatformName:platform] forState:UIControlStateNormal];
    [self.agreementLink.titleLabel setFont:[self.environment.styles semiBoldSansSerifOfSize:10]];
    [self.agreementLink setTitleColor:[UIColor colorWithRed:0.16 green:0.44 blue:0.84 alpha:1] forState:UIControlStateNormal];
    self.agreementLink.accessibilityTraits = UIAccessibilityTraitLink;
    self.agreementLink.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.agreementLink.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.agreementLink oex_addAction:^(id  _Nonnull control) {
        [self agreementButtonTapped:nil];
    } forEvents:UIControlEventTouchUpInside];
    self.agreementLink.accessibilityLabel = [NSString stringWithFormat:@"%@ %@",[Strings registrationAgreementMessage],[Strings registrationAgreementButtonTitleWithPlatformName:platform]];

    //This button will show and hide optional fields
    self.toggleOptionalFieldsButton = [[UIButton alloc] init];
    [self.toggleOptionalFieldsButton setBackgroundColor:[UIColor whiteColor]];
    [self.toggleOptionalFieldsButton setAttributedTitle: [self.toggleButtonStyle attributedStringWithText:[Strings registrationShowOptionalFields]] forState:UIControlStateNormal];
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
    //Analytics Screen record
    [self.environment.analytics trackScreenWithName:OEXAnalyticsScreenRegister];
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
    [self viewDidLayoutSubviews];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (void)updateViewConstraints {
    CGFloat margin = self.styles.formMargin;
    [self.currentHeadingView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scrollView);
        make.centerX.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView).offset(-2 * margin);
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
    
    BOOL isOptionalFieldPresent = NO;
    
    for(id <OEXRegistrationFieldController>fieldController in self.fieldControllers) {
        UIView* view = fieldController.view;
        // Add view to scroll view if field is not optional and it is not agreement field.
        if([fieldController field].isRequired && view.superview != nil) {
            [view layoutIfNeeded];
            [view setFrame:CGRectMake(0, offset, width, view.frame.size.height)];
            offset = offset + view.frame.size.height;
        }
        if(![fieldController field].isRequired) {
            isOptionalFieldPresent = YES;
        }
    }
    
    if (isOptionalFieldPresent) {
        //Add the optional field toggle
        CGFloat buttonWidth = 150;
        CGFloat buttonHeight = 30;
        [self.scrollView addSubview:self.optionalFieldsSeparator];
        [self.toggleOptionalFieldsButton setFrame:CGRectMake(self.view.frame.size.width / 2 - buttonWidth / 2, offset, buttonWidth, buttonHeight)];
        [self.scrollView addSubview:self.toggleOptionalFieldsButton];
        self.optionalFieldsSeparator.frame = CGRectMake(horizontalSpacing, self.toggleOptionalFieldsButton.center.y, contentWidth, 1);
        self.optionalFieldsSeparator.center = self.toggleOptionalFieldsButton.center;
        
        offset = offset + buttonHeight + 10;
    }
    
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
    NSString *attributedTitle = self.isShowingOptionalFields ? [Strings registrationHideOptionalFields] : [Strings registrationShowOptionalFields];
    [self.toggleOptionalFieldsButton setAttributedTitle: [self.toggleButtonStyle attributedStringWithText: attributedTitle] forState:UIControlStateNormal];
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
            [self showNoNetworkError];
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
            [controller setValue:profile.email];
        }
        if([[controller field].name isEqualToString:@"name"]) {
            [controller setValue:profile.name];
        }
        if([[controller field].name isEqualToString:@"year_of_birth"]) {
            [controller setValue:profile.birthYear];
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
                [parameters setSafeObject:[controller currentValue] forKey:[controller field].name];
            }
        }
        else if(![self shouldFilterField:controller.field]){
            hasError = YES;
        }
    }

    if(hasError) {
        [self showProgress:NO];
        [self refreshFormFields];
        [self showInputErrorAlert];
        return;
    }
    //Setting parameter 'honor_code'='true'
    [parameters setObject:@"true" forKey:@"honor_code"];

    //As user is agree to the license setting 'terms_of_service'='true'
    [parameters setObject:@"true" forKey:@"terms_of_service"];
    
    if(self.externalProvider != nil) {
        [parameters setSafeObject:self.externalAccessToken forKey: @"access_token"];
        [parameters setSafeObject:self.externalProvider.backendName forKey:@"provider"];
        [parameters setSafeObject:self.environment.config.oauthClientID forKey:@"client_id"];
    }

    [self registerWithParameters:parameters];

}

- (void) showInputErrorAlert {
    __weak typeof(self) weakSelf = self;
    
    [[UIAlertController alloc] showAlertWithTitle:[Strings registrationErrorAlertTitle] message:[Strings registrationErrorAlertMessage] cancelButtonTitle:[Strings ok] onViewController:self tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger index) {
        for(id <OEXRegistrationFieldController> controller in weakSelf.fieldControllers) {
            if(![controller isValidInput]) {
                    [[controller accessibleInputField] becomeFirstResponder];
                    break;
            }
        }
    }];
}

- (void) showNoNetworkError {
    [[UIAlertController alloc] showAlertWithTitle:[Strings networkNotAvailableTitle] message:[Strings networkNotAvailableMessage] onViewController:self];
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
        [self.registerButton applyButtonStyleWithStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[Strings registrationCreatingAccount]];
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }
    else {
        [self.progressIndicator stopAnimating];
        [self.registerButton applyButtonStyleWithStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[Strings registrationCreateMyAccount]];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
}

- (BOOL) shouldAutorotate {
    return false;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
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

- (void)t_registerWithParameters:(NSDictionary*)parameters {
    [self registerWithParameters:parameters];
}

@end
