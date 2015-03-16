//
//  OEXRegistrationViewController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//
#import "OEXRegistrationViewController.h"

#import "NSArray+OEXFunctional.h"
#import "NSJSONSerialization+OEXSafeAccess.h"
#import "NSMutableDictionary+OEXSafeAccess.h"

#import "OEXAuthentication.h"
#import "OEXFlowErrorViewController.h"
#import "OEXHTTPStatusCodes.h"
#import "OEXRegistrationAgreementController.h"
#import "OEXRegistrationDescription.h"
#import "OEXRegistrationFieldControllerFactory.h"
#import "OEXRegistrationFieldError.h"
#import "OEXRegistrationFormField.h"
#import "OEXRouter.h"
#import "OEXUserLicenseAgreementViewController.h"

@interface OEXRegistrationViewController ()

@property (strong, nonatomic) OEXRegistrationDescription* registrationDescription;

/// Contents are id <OEXRegistrationFieldController>
@property (strong, nonatomic) NSArray* fieldControllers;

@property(strong,nonatomic) IBOutlet UIScrollView *scrollView;
@property(strong,nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) UIButton* registerButton;
@property (strong, nonatomic) UILabel* agreementLabel;
@property (strong, nonatomic) UIButton* agreementLink;
@property (strong, nonatomic) UIButton *toggleOptionalFieldsButton;
@property (strong, nonatomic) UIImageView *optionalFieldsSeparator;
@property (strong, nonatomic) UIActivityIndicatorView *progressIndicator;

@property (assign, nonatomic) BOOL isShowingOptionalFields;

@end

@implementation OEXRegistrationViewController

- (id)initWithRegistrationDescription:(OEXRegistrationDescription*)description {
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil) {
        self.registrationDescription = description;
    }
    return self;
}

- (id)initWithDefaultRegistrationDescription {
    return [self initWithRegistrationDescription: [[self class] registrationFormDescription]];
}

+ (OEXRegistrationDescription*)registrationFormDescription {
    NSString *filePath=[[NSBundle bundleForClass:[self class]] pathForResource:@"registration" ofType:@"json"];
    NSData *data=[NSData dataWithContentsOfFile:filePath];
    NSAssert(data != nil, @"Could not load registration.json");
    NSError  *error;
    id json = [NSJSONSerialization oex_JSONObjectWithData:data error:&error];
    NSAssert(error == nil, @"Could not parse registration.json");
    return [[OEXRegistrationDescription alloc] initWithDictionary:json];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self makeFieldControllers];
    [self initializeViews];
    [self refreshFormFields];
    
    //By default we only shows required fields
    self.isShowingOptionalFields = NO;
}


//Currently using asset file only to get from description
-(void)makeFieldControllers {
    self.fieldControllers = [self.registrationDescription.registrationFormFields
                             oex_map:^id <OEXRegistrationFieldController>(OEXRegistrationFormField* formField) {
                                 id <OEXRegistrationFieldController> fieldController = [OEXRegistrationFieldControllerFactory registrationFieldViewController:formField];
                                 if(formField.fieldType==OEXRegistrationFieldTypeAgreement){
                                     // These don't have explicit representations in the apps
                                     return nil;
                                 }
                                 return fieldController;
                             }];
}

// This method will set default ui.

-(void)initializeViews
{
    NSString *regularFont=@"OpenSans";
    NSString *semiboldFont=@"OpenSans-Semibold";
    
    self.navigationController.navigationBarHidden=YES;
    self.navigationController.navigationBar.topItem.title = @"";
    self.automaticallyAdjustsScrollViewInsets = NO;
    // set the custom navigation view properties
    
    self.titleLabel.text = OEXLocalizedString(@"REGISTRATION_SIGN_UP_FOR_EDX", nil);
    [self.titleLabel setFont:[UIFont fontWithName:semiboldFont size:20.f]];
    
    ////Create and initalize 'btnCreateAccount' button
    self.registerButton = [[UIButton alloc] init];
    [self.registerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.registerButton setTitle:OEXLocalizedString(@"REGISTRATION_CREATE_MY_ACCOUNT", nil) forState:UIControlStateNormal];
    [self.registerButton addTarget:self action:@selector(createAccount:) forControlEvents:UIControlEventTouchUpInside];
    [self.registerButton setBackgroundImage:[UIImage imageNamed:@"bt_signin_active.png"] forState:UIControlStateNormal];
    
    ////Create progrssIndicator as subview to btnCreateAccount
    self.progressIndicator=[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0,0,20,20)];
    [self.registerButton addSubview:self.progressIndicator];
    [self.progressIndicator hidesWhenStopped];
    self.optionalFieldsSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"separator3"]];
    //Initialize label above agreement view
    self.agreementLabel=[[UILabel alloc] init];
    self.agreementLabel.font=[UIFont fontWithName:regularFont size:10.f];
    self.agreementLabel.textAlignment=NSTextAlignmentCenter;
    self.agreementLabel.numberOfLines=0;
    self.agreementLabel.lineBreakMode=NSLineBreakByWordWrapping;
    self.agreementLabel.text=OEXLocalizedString(@"REGISTRATION_AGREEMENT_MESSAGE", nil);
    self.agreementLink=[[UIButton alloc] init];
    [self.agreementLink setTitle:OEXLocalizedString(@"REGISTRATION_AGREEMENT_BUTTON_TITLE", nil) forState:UIControlStateNormal];
    [self.agreementLink.titleLabel setFont:[UIFont fontWithName:semiboldFont size:10]];
    [self.agreementLink setTitleColor:[UIColor colorWithRed:0.16 green:0.44 blue:0.84 alpha:1] forState:UIControlStateNormal];
    [self.agreementLink addTarget:self action:@selector(agreementButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    //This button will show and hide optional fields
    self.toggleOptionalFieldsButton =[[UIButton alloc] init];
    [self.toggleOptionalFieldsButton setBackgroundColor:[UIColor whiteColor]];
    [self.toggleOptionalFieldsButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.toggleOptionalFieldsButton setTitle:OEXLocalizedString(@"REGISTRATION_SHOW_OPTIONAL_FIELDS", nil)  forState:UIControlStateNormal];
    [self.toggleOptionalFieldsButton.titleLabel setFont:[UIFont fontWithName:semiboldFont size:14.0]];
    
    [self.toggleOptionalFieldsButton addTarget:self action:@selector(toggleOptionalFields:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc] init];
    [tapGesture addTarget:self action:@selector(scrollViewTapped:)];
    [self.scrollView addGestureRecognizer:tapGesture];
    
}


-(IBAction)navigateBack:(id)sender{
    [[OEXRouter sharedRouter] popAnimationFromBottomFromController:self];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // Scrolling on keyboard hide and show
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameChanged:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
}

-(void)viewDidDisappear:(BOOL)animated{
    
    // This  will remove observer for keyboard
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

-(void)refreshFormFields {
    NSInteger topSpacing=10;
    NSInteger horizontalSpacing=20;
    NSInteger offset=0;
    CGFloat witdth=self.scrollView.frame.size.width;
    NSInteger contentWidth=witdth-2*horizontalSpacing;
    
    // Remove all views from scroll view
    for (UIView *view in [self.scrollView subviews]) {
        [view removeFromSuperview];
    }
    
    //Setting offset as topspacing
    offset=topSpacing;
    
    for(id<OEXRegistrationFieldController>fieldController in self.fieldControllers) {
        // Add view to scroll view if field is not optional and it is not agreement field.
        if([fieldController field].isRequired){
            UIView *view=[fieldController view];
            [view layoutIfNeeded];
            [view setFrame:CGRectMake(0,offset,witdth,view.frame.size.height)];
            [self.scrollView addSubview:view];
            offset=offset+view.frame.size.height;
        }
    }
    
    //Add the optional field toggle
    
    CGFloat buttonWidth=150;
    CGFloat buttonHeight=30;
    [self.scrollView addSubview:self.optionalFieldsSeparator];
    [self.toggleOptionalFieldsButton setFrame:CGRectMake(self.view.frame.size.width/2 - buttonWidth/2,offset, buttonWidth, buttonHeight)];
    [self.scrollView addSubview:self.toggleOptionalFieldsButton];
    self.optionalFieldsSeparator.frame = CGRectMake(horizontalSpacing, self.toggleOptionalFieldsButton.center.y, contentWidth, 1);
    self.optionalFieldsSeparator.center= self.toggleOptionalFieldsButton.center;
    
    offset = offset + buttonHeight + 10;
    
    // Actually show the optional fields if necessary
    if(self.isShowingOptionalFields) {
        for(id<OEXRegistrationFieldController>fieldController in self.fieldControllers) {
            if(![fieldController field].isRequired){
                UIView *view=[fieldController view];
                [view layoutIfNeeded];
                [view setFrame:CGRectMake(0,offset,witdth,view.frame.size.height)];
                [self.scrollView addSubview:view];
                offset=offset+view.frame.size.height;
            }
        }
    }
    
    
    
    [self.registerButton setFrame:CGRectMake(horizontalSpacing, offset,contentWidth, 40)];
    self.progressIndicator.center=CGPointMake(self.registerButton.frame.size.width-40 ,self.registerButton.frame.size.height/2);
    [self.scrollView addSubview:self.registerButton];
    offset=offset+40;
    
    NSInteger buttonLabelSpacing=10;
    
    [self.agreementLabel setFrame:CGRectMake(horizontalSpacing,offset+buttonLabelSpacing,witdth-2*horizontalSpacing,20)];
    [self.scrollView addSubview:self.agreementLabel];
    offset=offset+self.agreementLabel.frame.size.height;
    [self.scrollView addSubview:self.agreementLink];
    [self.agreementLink setFrame:CGRectMake(horizontalSpacing, offset,contentWidth,40)];
    offset=offset+self.agreementLink.frame.size.height;
    [self.scrollView setContentSize:CGSizeMake(witdth,offset)];
    
}


//This method will hide and unhide optional fields
//using isRequired flag for corresponding field.

- (void)toggleOptionalFields:(id)sender {
    self.isShowingOptionalFields = !self.isShowingOptionalFields;
    if(self.isShowingOptionalFields) {
        [self.toggleOptionalFieldsButton setTitle:OEXLocalizedString(@"REGISTRATION_HIDE_OPTIONAL_FIELDS", nil)  forState:UIControlStateNormal];
    }
    else {
        [self.toggleOptionalFieldsButton setTitle:OEXLocalizedString(@"REGISTRATION_SHOW_OPTIONAL_FIELDS", nil)  forState:UIControlStateNormal];
    }
    
    [self refreshFormFields];
}

#pragma mark IBAction

-(IBAction)createAccount:(id)sender{
    
    // Clear error for all views
    [self.fieldControllers makeObjectsPerformSelector:@selector(handleError:) withObject:nil];
    // Dictionary for registration parameters
    NSMutableDictionary *parameters=[NSMutableDictionary dictionary];
    BOOL hasError=NO;
    
    for (id<OEXRegistrationFieldController> controller in self.fieldControllers) {
        if([controller isValidInput]){
            if([controller hasValue]){
                [parameters setObject:[controller currentValue] forKey:[controller field].name];
            }
        }else{
            hasError = true;
        }
    }
    
    if(hasError){
        [self showProgress:NO];
        [self refreshFormFields];
        return;
    }
    //Setting parameter 'honor_code'='true'
    [parameters setObject:@"true" forKey:@"honor_code"];
    
    //As user is agree to the license setting 'terms_of_service'='true'
    [parameters setObject:@"true" forKey:@"terms_of_service"];
    
    __weak id weakSelf=self;
    [self showProgress:YES];
    [OEXAuthentication registerUserWithParameters:parameters completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSDictionary *dictionary =[NSJSONSerialization  oex_JSONObjectWithData:data error:&error];
            ELog(@"Registration response ==>> %@",dictionary);
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
            if(httpResp.statusCode == OEXHTTPStatusCode200OK) {
                NSString *username = parameters[@"username"];
                NSString *password = parameters[@"password"];
                [OEXAuthentication requestTokenWithUser:username password:password completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                    if(httpResp.statusCode == OEXHTTPStatusCode200OK) {
                        if([self.navigationController topViewController]==weakSelf){
                            [[OEXRouter sharedRouter] showLoginScreenFromController:weakSelf animated:NO];
                        }
                    }
                    [self showProgress:NO];
                }];
            }
            else {
                NSMutableDictionary* controllers = [[NSMutableDictionary alloc] init];
                for(id <OEXRegistrationFieldController> controller in self.fieldControllers) {
                    [controllers safeSetObject:controller forKey:controller.field.name];
                    [controller handleError:nil];
                }
                [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString* fieldName, NSArray* errorInfos, BOOL *stop) {
                    id <OEXRegistrationFieldController> controller = controllers[fieldName];
                    NSArray* errorStrings = [errorInfos oex_map:^id(NSDictionary* info) {
                        return [[OEXRegistrationFieldError alloc] initWithDictionary:info].userMessage;
                    }];
                    
                    NSString* errors = [errorStrings componentsJoinedByString:@" "];
                    [controller handleError:errors];
                    [self refreshFormFields];
                }];
                [self showProgress:NO];
            }
        }
        else{
            [self showProgress:NO];
        }
    }];
}

-(void)scrollViewTapped:(id)sender{
    [self.view endEditing:YES];
}

-(void)agreementButtonTapped:(id)sender{
    NSURL *url=[[NSBundle mainBundle] URLForResource:@"Terms-and-Services" withExtension:@"htm"];
    OEXUserLicenseAgreementViewController *viewController=[[OEXUserLicenseAgreementViewController alloc] initWithContentURL:url];
    [self presentViewController:viewController animated:YES completion:nil];
    
}



-(void)showProgress:(BOOL)status{
    if(status){
        [self.progressIndicator startAnimating];
        [self.registerButton setTitle:OEXLocalizedString(@"REGISTRATION_CREATING_ACCOUNT", nil) forState:UIControlStateNormal];
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }else{
        [self.progressIndicator stopAnimating];
        [self.registerButton setTitle:OEXLocalizedString(@"REGISTRATION_CREATE_MY_ACCOUNT", nil) forState:UIControlStateNormal];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
    
}


#pragma mark - Scolling on Keyboard Hide/Show

// Called when the UIKeyboardDidChangeFrameNotification is sent.
- (void)keyboardFrameChanged:(NSNotification*)notification
{
    CGRect globalFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect localFrame = [self.view convertRect:globalFrame fromView:nil];
    CGRect intersection = CGRectIntersection(localFrame, self.view.bounds);
    CGFloat keyboardHeight = intersection.size.height;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardHeight, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

@end


@implementation OEXRegistrationViewController (Testing)

- (OEXRegistrationDescription*)t_registrationFormDescription {
    return self.registrationDescription;
}

- (NSUInteger)t_visibleFieldCount {
    NSIndexSet* visibleIndexes = [self.fieldControllers indexesOfObjectsPassingTest:^BOOL(id <OEXRegistrationFieldController> controller, NSUInteger idx, BOOL *stop) {
        return controller.view.superview != nil;
    }];
    return visibleIndexes.count;
}

- (void)t_toggleOptionalFields {
    [self toggleOptionalFields:nil];
}

@end
