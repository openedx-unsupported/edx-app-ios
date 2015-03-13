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

static NSString *const CancelButtonImage=@"ic_cancel@3x.png";

@interface OEXRegistrationViewController ()
{
    OEXRegistrationDescription *registrationDescriptions;
    OEXRegistrationDescription *description;
    //array: id <OEXRegistrationFieldController>object
    NSMutableArray *fieldControllers;
    //array :OEXRegistrationAgreementController
    NSMutableArray *agreementControllers;
    // Register button
    UIButton *btnCreateAccount;
    //Label for agreement
    UILabel  *labelAgreement;
    // Show hide optional fields
    UIButton  *btnAgreement;
    
    BOOL showOptionalfields;
    UIButton *btnShowOptionalFields;
    UIImageView *separator;
    UIActivityIndicatorView *progressIndicator;
}
@property(weak,nonatomic)IBOutlet UIScrollView *scrollView;
@property(weak,nonatomic)IBOutlet UILabel *titleLabel;
@property(weak,nonatomic)IBOutlet UILabel *btnBack;
@end

@implementation OEXRegistrationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    agreementControllers=[[NSMutableArray alloc] init];
    fieldControllers=[[NSMutableArray alloc] init];
    [self getFormDescription];
    [self initializeViews];
    //By default we only shows required fields
    showOptionalfields=NO;
}

//Currently using asset file only to get from description
-(void)getFormDescription{
    NSString *filePath=[[NSBundle bundleForClass:[self class]]  pathForResource:@"registration" ofType:@"json"];
    NSData *data=[NSData dataWithContentsOfFile:filePath];
    NSError  *error;
    if(data){
        id json=[NSJSONSerialization oex_JSONObjectWithData:data error:&error];
        if(error){
            NSAssert(NO, @"Could not parse JSON");
        }
        description=[[OEXRegistrationDescription alloc] initWithDictionary:json];
        for (OEXRegistrationFormField *formField in description.registrationFormFields) {
            id<OEXRegistrationFieldController>fieldController=[OEXRegistrationFieldControllerFactory registrationFieldViewController:formField];
            if(fieldController){
                if(formField.fieldType==OEXRegistrationFieldTypeAgreement){
                    [agreementControllers addObject:fieldController];
                    continue;
                }
                [fieldControllers addObject:fieldController];
            }
        }
    }
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
    btnCreateAccount=[[UIButton alloc] init];
    [btnCreateAccount setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btnCreateAccount setTitle:OEXLocalizedString(@"REGISTRATION_CREATE_MY_ACCOUNT", nil) forState:UIControlStateNormal];
    [btnCreateAccount addTarget:self action:@selector(createAccount:) forControlEvents:UIControlEventTouchUpInside];
    [btnCreateAccount setBackgroundImage:[UIImage imageNamed:@"bt_signin_active.png"] forState:UIControlStateNormal];
    
    ////Create progrssIndicator as subview to btnCreateAccount
    progressIndicator=[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0,0,20,20)];
    [btnCreateAccount addSubview:progressIndicator];
    [progressIndicator hidesWhenStopped];
    separator=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"separator3"]];
    //Initialize label above agreement view
    labelAgreement=[[UILabel alloc] init];
    labelAgreement.font=[UIFont fontWithName:regularFont size:10.f];
    labelAgreement.textAlignment=NSTextAlignmentCenter;
    labelAgreement.numberOfLines=0;
    labelAgreement.lineBreakMode=NSLineBreakByWordWrapping;
    labelAgreement.text=OEXLocalizedString(@"REGISTRATION_AGREEMENT_MESSAGE", nil);
    btnAgreement=[[UIButton alloc] init];
    [btnAgreement setTitle:OEXLocalizedString(@"REGISTRATION_AGREEMENT_BUTTON_TITLE", nil) forState:UIControlStateNormal];
    [btnAgreement.titleLabel setFont:[UIFont fontWithName:semiboldFont size:10]];
    [btnAgreement setTitleColor:[UIColor colorWithRed:0.16 green:0.44 blue:0.84 alpha:1] forState:UIControlStateNormal];
    [btnAgreement addTarget:self action:@selector(buttonAgreementTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    //This button will show and hide optional fields
    btnShowOptionalFields=[[UIButton alloc] init];
    [btnShowOptionalFields setBackgroundColor:[UIColor whiteColor]];
    [btnShowOptionalFields setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [btnShowOptionalFields setTitle:OEXLocalizedString(@"REGISTRATION_SHOW_OPTIONAL_FIELDS", nil)  forState:UIControlStateNormal];
    [btnShowOptionalFields.titleLabel setFont:[UIFont fontWithName:semiboldFont size:14.0]];
    
    [btnShowOptionalFields addTarget:self action:@selector(toggleOptionalFields:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tapgesture=[[UITapGestureRecognizer alloc] init];
    [tapgesture addTarget:self action:@selector(scrollViewTapped:)];
    [self.scrollView addGestureRecognizer:tapgesture];
    
}


-(IBAction)navigateBack:(id)sender{
    [[OEXRouter sharedRouter] popAnimationFromBottomFromController:self];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // Scrolling on keyboard hide and show
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameChanged:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
    [self refreshFormField];
}


-(void)viewDidDisappear:(BOOL)animated{
    
    // This  will remove observer for keyboard
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}


//This method refresh  registration form
-(void)refreshFormField{
    
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
    
    for(id<OEXRegistrationFieldController>fieldController in fieldControllers) {
        
        // Add view to scroll view if field is not optional and it is not agreement field.
        if([fieldController field].isRequired){
            UIView *view=[fieldController view];
            [view layoutIfNeeded];
            [view setFrame:CGRectMake(0,offset,witdth,view.frame.size.height)];
            [self.scrollView addSubview:view];
            offset=offset+view.frame.size.height;
        }
    }
    
    //Add button btnShowOptionalFields after reuired fields
    //This button will show and hide optional fileds
    
    CGFloat buttonWidth=150;
    CGFloat buttonHeight=30;
    [self.scrollView addSubview:separator];
    [btnShowOptionalFields setFrame:CGRectMake(self.view.frame.size.width/2 - buttonWidth/2,offset, buttonWidth, buttonHeight)];
    [self.scrollView addSubview:btnShowOptionalFields];
    separator.frame=CGRectMake(horizontalSpacing,btnShowOptionalFields.center.y ,contentWidth, 1);
    separator.center=btnShowOptionalFields.center;
    
    offset=offset+buttonHeight+10;
    
    //If showOptionalfields==YES  add optional fileds below the button
    if(showOptionalfields){
        for(id<OEXRegistrationFieldController>fieldController in fieldControllers) {
            if(![fieldController field].isRequired){
                UIView *view=[fieldController view];
                [view layoutIfNeeded];
                [view setFrame:CGRectMake(0,offset,witdth,view.frame.size.height)];
                [self.scrollView addSubview:view];
                offset=offset+view.frame.size.height;
            }
        }
    }
    
    
    
    [btnCreateAccount setFrame:CGRectMake(horizontalSpacing, offset,contentWidth, 40)];
    progressIndicator.center=CGPointMake(btnCreateAccount.frame.size.width-40 ,btnCreateAccount.frame.size.height/2);
    [self.scrollView addSubview:btnCreateAccount];
    offset=offset+40;
    
    NSInteger buttonLabelSpacing=10;
    
    [labelAgreement setFrame:CGRectMake(horizontalSpacing,offset+buttonLabelSpacing,witdth-2*horizontalSpacing,20)];
    [self.scrollView addSubview:labelAgreement];
    offset=offset+labelAgreement.frame.size.height;
    [self.scrollView addSubview:btnAgreement];
    [btnAgreement setFrame:CGRectMake(horizontalSpacing, offset,contentWidth,40)];
    offset=offset+btnAgreement.frame.size.height;
    [self.scrollView setContentSize:CGSizeMake(witdth,offset)];
    
}


//This method will hide and unhide optional fields
//using isRequired flag for corresponding field.

-(IBAction)toggleOptionalFields:(id)sender{
    
    showOptionalfields=!showOptionalfields;
    if(showOptionalfields){
        [btnShowOptionalFields setTitle:OEXLocalizedString(@"REGISTRATION_HIDE_OPTIONAL_FIELDS", nil)  forState:UIControlStateNormal];
    }else{
        [btnShowOptionalFields setTitle:OEXLocalizedString(@"REGISTRATION_SHOW_OPTIONAL_FIELDS", nil)  forState:UIControlStateNormal];
    }
    
    [self refreshFormField];
}

#pragma mark IBAction

-(IBAction)createAccount:(id)sender{
    
       // Clear error for all views
    [fieldControllers makeObjectsPerformSelector:@selector(handleError:) withObject:nil];
    // Dictionary for registration parameters
    NSMutableDictionary *parameters=[NSMutableDictionary dictionary];
    BOOL hasError=NO;
    
    for (id<OEXRegistrationFieldController> controller in fieldControllers) {
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
        [self refreshFormField];
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
                for(id <OEXRegistrationFieldController> controller in fieldControllers) {
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
                    [self refreshFormField];
                }];
                [self showProgress:NO];
            }
        }
        else{
            [self showProgress:NO];
        }
    }];
}

-(IBAction)scrollViewTapped:(id)sender{
    [self.view endEditing:YES];
}

-(IBAction)buttonAgreementTapped:(id)sender{
    NSURL *url=[[NSBundle mainBundle] URLForResource:@"Terms-and-Services" withExtension:@"htm"];
    OEXUserLicenseAgreementViewController *viewController=[[OEXUserLicenseAgreementViewController alloc] initWithContentURL:url];
    [self presentViewController:viewController animated:YES completion:nil];
    
}



-(void)showProgress:(BOOL)status{
    if(status){
        [progressIndicator startAnimating];
        [btnCreateAccount setTitle:OEXLocalizedString(@"REGISTRATION_CREATING_ACCOUNT", nil) forState:UIControlStateNormal];
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }else{
        [progressIndicator stopAnimating];
        [btnCreateAccount setTitle:OEXLocalizedString(@"REGISTRATION_CREATE_MY_ACCOUNT", nil) forState:UIControlStateNormal];
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
