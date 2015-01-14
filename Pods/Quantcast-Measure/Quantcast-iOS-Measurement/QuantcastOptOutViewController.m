/*
 * © Copyright 2012-2014 Quantcast Corp.
 *
 * This software is licensed under the Quantcast Mobile App Measurement Terms of Service
 * https://www.quantcast.com/learning-center/quantcast-terms/mobile-app-measurement-tos
 * (the “License”). You may not use this file unless (1) you sign up for an account at
 * https://www.quantcast.com and click your agreement to the License and (2) are in
 * compliance with the License. See the License for the specific language governing
 * permissions and limitations under the License. Unauthorized use of this file constitutes
 * copyright infringement and violation of law.
 */
#if !__has_feature(objc_arc)
#error "Quantcast Measurement is designed to be used with ARC. Please turn on ARC or add '-fobjc-arc' to this file's compiler flags"
#endif // !__has_feature(objc_arc)

#import <QuartzCore/QuartzCore.h>
#import "QuantcastOptOutViewController.h"
#import "QuantcastOptOutDelegate.h"
#import "QuantcastMeasurement.h"
#import "QuantcastUtils.h"

@interface QuantcastMeasurement ()

-(void)setOptOutStatus:(BOOL)inOptOutStatus;

@end

@interface QuantcastOptOutViewController (){
    BOOL _originalOptOutStatus;
    UISwitch* _onOffSwitch;
}
@property (strong,nonatomic) QuantcastMeasurement* measurement;
@end

@implementation QuantcastOptOutViewController

-(id)initWithDelegate:(id<QuantcastOptOutDelegate>)inDelegate {
    self = [super init];
    if ( self ) {
        self.title = @"About Quantcast";
        self.delegate = inDelegate;
        
        _originalOptOutStatus = [QuantcastMeasurement sharedInstance].isOptedOut;
        
    }
    
    return self;
}

-(void)dealloc {
    _delegate = nil;
    
}

-(void)loadView{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    
    UIView* mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
    mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mainView.backgroundColor = [UIColor lightGrayColor];
    
    UITextView* aboutText = [[UITextView alloc] initWithFrame:CGRectMake(20, 15, mainView.frame.size.width-40, 300)];
    aboutText.autoresizingMask =  UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    aboutText.backgroundColor = [UIColor clearColor];
    aboutText.userInteractionEnabled = NO;
    NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
    if ( nil == appName ) {
        appName = @"app's";
    }
    aboutText.text = [NSString stringWithFormat:@"Quantcast helps us measure the usage of our app so we can better understand our audience.  Quantcast collects anonymous (non-personally identifiable) data from users across apps, such as details of app usage, the number of visits and duration, their device information, city, and settings, to provide this measurement and behavioral advertising.  A full description of Quantcast’s data collection and use practices can be found in its Privacy Policy, and you can opt out below.  Please also review our %@ privacy policy.", appName];
    aboutText.font = [UIFont systemFontOfSize:14];
    aboutText.dataDetectorTypes = UIDataDetectorTypeLink;
    [mainView addSubview:aboutText];
    
    UIView* switchContainer = [[UIView alloc]initWithFrame:CGRectMake(10, 347, mainView.frame.size.width-20, 48)];
    switchContainer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
    switchContainer.backgroundColor = [UIColor whiteColor];
    [switchContainer layer].cornerRadius  = 10.0f;
    [switchContainer layer].masksToBounds = YES;
    [switchContainer layer].borderColor = [UIColor grayColor].CGColor;
    [switchContainer layer].borderWidth = 1;
    
    UILabel* allowText = [[UILabel alloc] initWithFrame:CGRectMake(15, 13, 193, 21)];
    allowText.backgroundColor = [UIColor clearColor];
    allowText.font = [UIFont boldSystemFontOfSize:18];
    allowText.text = @"Allow Data Collection";
    [switchContainer addSubview:allowText];
    
    _onOffSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(211, 10, 79, 27)];
    _onOffSwitch.on = ![QuantcastMeasurement sharedInstance].isOptedOut;
    [_onOffSwitch addTarget:self action:@selector(optOutStatusChanged:) forControlEvents:UIControlEventValueChanged];
    [switchContainer addSubview:_onOffSwitch];
    
    [mainView addSubview:switchContainer];
    
    UIButton* review = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    review.frame = CGRectMake(10, 403, mainView.frame.size.width-20, 37);
    review.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
    [review setTitle:@"Review Quantcast Privacy Policy" forState:UIControlStateNormal];
    review.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [review addTarget:self action:@selector(reviewPrivacyPolicy:) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:review];
    
    
    self.view = mainView;
    
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
#pragma clang diagnostic pop
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Dialog Status

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ( nil != self.delegate && [self.delegate respondsToSelector:@selector(quantcastOptOutDialogWillAppear)] ) {
        [self.delegate quantcastOptOutDialogWillAppear];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ( nil != self.delegate && [self.delegate respondsToSelector:@selector(quantcastOptOutDialogDidAppear)] ) {
        [self.delegate quantcastOptOutDialogDidAppear];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ( nil != self.delegate && [self.delegate respondsToSelector:@selector(quantcastOptOutDialogWillDisappear)] ) {
        [self.delegate quantcastOptOutDialogWillDisappear];
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if ( nil != self.delegate && [self.delegate respondsToSelector:@selector(quantcastOptOutDialogDidDisappear)] ) {
        [self.delegate quantcastOptOutDialogDidDisappear];
    }
    
    if ( _originalOptOutStatus != !_onOffSwitch.on ) {
        
        [QuantcastMeasurement sharedInstance].isOptedOut = !_onOffSwitch.on;

        if ( nil != self.delegate && [self.delegate respondsToSelector:@selector(quantcastOptOutStatusDidChange:)] ) {
            [self.delegate quantcastOptOutStatusDidChange:[QuantcastMeasurement sharedInstance].isOptedOut];
        }
    }

}

#pragma mark - UI Interaction

-(void)optOutStatusChanged:(id)inSender {
    // nothing to do here. actual state change occures are on dismissal.
    
    
}

-(void)reviewPrivacyPolicy:(id)inSender {
    [[QuantcastMeasurement sharedInstance] displayQuantcastPrivacyPolicy:self];
}

-(void)done:(id)inSender {
    
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    else {
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [self dismissModalViewControllerAnimated:YES];
#pragma GCC diagnostic warning "-Wdeprecated-declarations"
    }
}

@end
