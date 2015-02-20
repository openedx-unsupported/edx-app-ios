//
//  OEXRegistrationViewController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationViewController.h"
#import "OEXRegistrationDescription.h"
#import "OEXRegistrationFormField.h"
#import "OEXRegistrationDescription.h"
#import "OEXRegistrationFieldControllerFactory.h"
#import "OEXAuthentication.h"
#import "OEXRouter.h"
#import "OEXRegistrationAgreementController.h"
#import "OEXUserLicenseAgreementViewController.h"
#import "OEXFlowErrorViewController.h"
static NSString *const CancelButtonImage=@"ic_cancel@3x.png";

@interface OEXRegistrationViewController ()<OEXRegistrationAgreementControllerDelegate>
{
    OEXRegistrationDescription *registrationDescriptions;
    OEXRegistrationDescription *description;
    
    ////array: id <OEXRegistrationFieldController>object
    NSMutableArray *fieldControllers;
    
    //
    NSMutableArray *agreementControllers;
    // Register button
    UIButton *btnCreateAccount;
    
    //Label for agreement
    UILabel  *labelAgreement;
    
    // Show hide optional fields
    BOOL showOptionalfields;
    UIButton *btnShowOptionalFields;
    
    UIImageView *separator;
    
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
        id json=[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if(!error){
            description=[[OEXRegistrationDescription alloc] initWithDictionary:json];
        }else{
            NSAssert(NO, @"Could not parse JSON");
        }
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
    // set the custom navigation view properties
    
    self.titleLabel.text = NSLocalizedString(@"REGISTRATION_SIGN_UP_FOR_EDX", nil);
    [self.titleLabel setFont:[UIFont fontWithName:semiboldFont size:20.f]];
    
    btnCreateAccount=[[UIButton alloc] init];
    [btnCreateAccount setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btnCreateAccount setTitle:NSLocalizedString(@"REGISTRATION_CREATE_MY_ACCOUNT", nil) forState:UIControlStateNormal];
    [btnCreateAccount addTarget:self action:@selector(createAccount:) forControlEvents:UIControlEventTouchUpInside];
    [btnCreateAccount setBackgroundImage:[UIImage imageNamed:@"bt_signin_active.png"] forState:UIControlStateNormal];
    
    labelAgreement=[[UILabel alloc] init];
    labelAgreement.font=[UIFont fontWithName:regularFont size:10.f];
    labelAgreement.textAlignment=NSTextAlignmentCenter;
    labelAgreement.text=NSLocalizedString(@"REGISTRATION_AGREEMENT_MESSAGE", nil);
    
    separator=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"separator3"]];
    
    btnShowOptionalFields=[[UIButton alloc] init];
    [btnShowOptionalFields setBackgroundColor:[UIColor whiteColor]];
    [btnShowOptionalFields setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [btnShowOptionalFields setTitle:NSLocalizedString(@"REGISTRATION_SHOW_OPTIONAL_FIELDS", nil)  forState:UIControlStateNormal];
    [btnShowOptionalFields.titleLabel setFont:[UIFont fontWithName:semiboldFont size:14.0]];
    
    [btnShowOptionalFields addTarget:self action:@selector(showHideOptionalfields:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tapgesture=[[UITapGestureRecognizer alloc] init];
    [tapgesture addTarget:self action:@selector(scrollViewTapped:)];
    
    [self.scrollView addGestureRecognizer:tapgesture];
}


-(IBAction)navigateBack:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self refreshFormField];
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


//This method refresh  registration form
-(void)refreshFormField{
    
    NSInteger topSpacing=0;
    NSInteger horizontalSpacing=20;
    NSInteger offset=0;
    NSInteger spacing=0;
    
    CGFloat witdth=self.scrollView.frame.size.width;
    
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
     separator.frame=CGRectMake(horizontalSpacing,btnShowOptionalFields.center.y ,witdth-2*horizontalSpacing, 1);
    separator.center=btnShowOptionalFields.center;
    
    offset=offset+buttonHeight+spacing;
    
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
    
    [btnCreateAccount setFrame:CGRectMake(20, offset,witdth-2*horizontalSpacing, 40)];
    [self.scrollView addSubview:btnCreateAccount];
    offset=offset+40;
    
    [labelAgreement setFrame:CGRectMake(0,offset,witdth,30)];
    [self.scrollView addSubview:labelAgreement];
    
    offset=offset+labelAgreement.frame.size.height;
    
    
    for(id<OEXRegistrationFieldController>fieldController in agreementControllers) {
        if([fieldController field].isRequired){
            UIView *view=[fieldController view];
            [(OEXRegistrationAgreementController *)fieldController setDelegate:self];
            [view layoutIfNeeded];
            [view setFrame:CGRectMake(0,offset,witdth,view.frame.size.height)];
            [self.scrollView addSubview:view];
            offset=offset+view.frame.size.height;
        }
    }
    
    [self.scrollView setContentSize:CGSizeMake(witdth,offset)];
    
}


//This method will hide and unhide optional fields
//using isRequired flag for corresponding field.

-(IBAction)showHideOptionalfields:(id)sender{
    
    showOptionalfields=!showOptionalfields;
    if(showOptionalfields){
        [btnShowOptionalFields setTitle:NSLocalizedString(@"REGISTRATION_HIDE_OPTIONAL_FIELDS", nil)  forState:UIControlStateNormal];
    }else{
        [btnShowOptionalFields setTitle:NSLocalizedString(@"REGISTRATION_SHOW_OPTIONAL_FIELDS", nil)  forState:UIControlStateNormal];
    }
    
    [self refreshFormField];
}


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
        return;
    }
    
    //Setting parameter 'honor_code'='true'
    [parameters setObject:@"true" forKey:@"honor_code"];
    
    //As user is agree to the license setting 'terms_of_service'='true'
    [parameters setObject:@"true" forKey:@"terms_of_service"];
    
    
    __weak id weakSelf=self;
    [OEXAuthentication registerUserWithParameters:parameters completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSDictionary *dictionary =[NSJSONSerialization  JSONObjectWithData:data options:kNilOptions error:nil];
            ELog(@"Registration response ==>> %@",dictionary);
           // NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                BOOL success=[dictionary[@"success"] boolValue];
                if(success){
                    NSString *username= parameters[@"username"];
                    NSString *password=parameters[@"password"];
                    [OEXAuthentication requestTokenWithUser:username password:password CompletionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(weakSelf ){
                                if([self.navigationController topViewController]==weakSelf){
                                    [[OEXRouter sharedRouter] showLoginScreenFromController:weakSelf];
                                }
                            }
                        });
                        
                    }];
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                    NSString *errorMessage=dictionary[@"value"];
                    if(errorMessage){
                        
                    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"Oops!", nil)
                                                                            message:errorMessage
                                                                   onViewController:self.view
                                                                         shouldHide:YES];
                        
                        [self.view setUserInteractionEnabled:YES];
                    }
                    
                 });
            }
        }
    }];
}

-(IBAction)scrollViewTapped:(id)sender{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}


-(void)aggreementViewDidTappedForController:(OEXRegistrationAgreementController *)controller{
    
    
    NSLog(@"agreement url ==>> %@",controller.field.agreement.url);
    
    OEXUserLicenseAgreementViewController *viewController=[[OEXUserLicenseAgreementViewController alloc] init];
    viewController.agreement=controller.field.agreement;
    [self presentViewController:viewController animated:YES completion:nil];
    
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
