//
//  OEXFindCourseInterstitialViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 28/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFindCourseInterstitialViewController.h"

@interface OEXFindCourseInterstitialViewController ()
@property (nonatomic, weak) IBOutlet UILabel *topLabel;
@property (nonatomic, weak) IBOutlet UILabel *bottomLabel;

-(IBAction)openInBrowserTapped:(id)sender;
-(IBAction)closeTapped:(id)sender;
@end

@implementation OEXFindCourseInterstitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.topLabel.text = NSLocalizedString(@"INTERSTITIAL_TOP_LABEL", nil);
    self.topLabel.font = [UIFont fontWithName:@"OpenSans" size:self.topLabel.font.pointSize];
    
    NSString *bottomLabelText = NSLocalizedString(@"INTERSTITIAL_BOTTOM_LABEL", nil);
    NSString *bottomLabelBoldText = NSLocalizedString(@"INTERSTITIAL_BOTTOM_LABEL_BOLD_PART", nil);
    
    NSMutableAttributedString *bottomLabelAttributedText = [[NSMutableAttributedString alloc] initWithString:bottomLabelText];
    [bottomLabelAttributedText setAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans" size:self.bottomLabel.font.pointSize]} range:[bottomLabelText rangeOfString:bottomLabelText]];
    [bottomLabelAttributedText setAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans-Semibold" size:self.bottomLabel.font.pointSize]} range:[bottomLabelText rangeOfString:bottomLabelBoldText]];
    self.bottomLabel.attributedText = bottomLabelAttributedText;
}

-(IBAction)openInBrowserTapped:(id)sender{
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialViewControllerDidChooseToOpenInBrowser:)]) {
        [self.delegate interstitialViewControllerDidChooseToOpenInBrowser:self];
    }
}

-(IBAction)closeTapped:(id)sender{
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialViewControllerDidClose:)]) {
        [self.delegate interstitialViewControllerDidClose:self];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
