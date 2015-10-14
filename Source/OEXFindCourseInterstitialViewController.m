//
//  OEXFindCourseInterstitialViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 28/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "edX-Swift.h"
#import "OEXFindCourseInterstitialViewController.h"

#import "OEXConfig.h"
#import "OEXEnrollmentConfig.h"

@interface OEXFindCourseInterstitialViewController ()
@property (strong, nonatomic) IBOutlet UILabel* bottomLabel;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UIButton *openInBrowserButton;
@property (strong, nonatomic) IBOutlet UILabel* topLabel;

- (IBAction)openInBrowserTapped:(id)sender;
- (IBAction)closeTapped:(id)sender;
@end

@implementation OEXFindCourseInterstitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.topLabel.text = [Strings noEnrollmentInterstitialTopLabel];
    self.topLabel.font = [UIFont fontWithName:@"OpenSans" size:self.topLabel.font.pointSize];

    NSString* bottomLabelText = [Strings noEnrollmentInterstitialBottomLabel];

    NSMutableAttributedString* bottomLabelAttributedText = [[NSMutableAttributedString alloc] initWithString:bottomLabelText];
    [bottomLabelAttributedText setAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans" size:self.bottomLabel.font.pointSize]} range:[bottomLabelText rangeOfString:bottomLabelText]];
    self.bottomLabel.attributedText = bottomLabelAttributedText;
    [self.closeButton setTitle:[Strings close] forState:UIControlStateNormal];
    
    [self.topLabel setTextAlignment:NSTextAlignmentNatural];
    [self.bottomLabel setTextAlignment:NSTextAlignmentNatural];
    
    [self.openInBrowserButton mirrorTextToAccessibilityLabel];
    [self.closeButton mirrorTextToAccessibilityLabel];
}

- (IBAction)openInBrowserTapped:(id)sender {
    OEXConfig* config = [OEXConfig sharedConfig];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[config courseEnrollmentConfig].externalSearchURL]];
}

- (IBAction)closeTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
