//
//  OEXFindCourseInterstitialViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 28/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFindCourseInterstitialViewController.h"

@interface OEXFindCourseInterstitialViewController ()
@property (strong, nonatomic) IBOutlet UILabel *topLabel;
@property (strong, nonatomic) IBOutlet UILabel *bottomLabel;

-(IBAction)openInBrowserTapped:(id)sender;
-(IBAction)closeTapped:(id)sender;
@end

@implementation OEXFindCourseInterstitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.topLabel.text = OEXLocalizedString(@"INTERSTITIAL_TOP_LABEL", nil);
    self.topLabel.font = [UIFont fontWithName:@"OpenSans" size:self.topLabel.font.pointSize];
    
    NSString *bottomLabelText = OEXLocalizedString(@"INTERSTITIAL_BOTTOM_LABEL", nil);
    NSString *bottomLabelBoldText = OEXLocalizedString(@"INTERSTITIAL_BOTTOM_LABEL_BOLD_PART", nil);
    
    NSMutableAttributedString *bottomLabelAttributedText = [[NSMutableAttributedString alloc] initWithString:bottomLabelText];
    [bottomLabelAttributedText setAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans" size:self.bottomLabel.font.pointSize]} range:[bottomLabelText rangeOfString:bottomLabelText]];
    [bottomLabelAttributedText setAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans-Semibold" size:self.bottomLabel.font.pointSize]} range:[bottomLabelText rangeOfString:bottomLabelBoldText]];
    self.bottomLabel.attributedText = bottomLabelAttributedText;
}

-(IBAction)openInBrowserTapped:(id)sender{
    [self.delegate interstitialViewControllerDidChooseToOpenInBrowser:self];
}

-(IBAction)closeTapped:(id)sender{
    [self.delegate interstitialViewControllerDidClose:self];
}

@end
