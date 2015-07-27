//
//  OEXRearTableViewController.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXRearTableViewController.h"

#import "NSBundle+OEXConveniences.h"
#import "NSString+OEXFormatting.h"

#import "OEXAnalytics.h"
#import "OEXAppDelegate.h"
#import "OEXCustomLabel.h"
#import "OEXConfig.h"
#import "OEXImageCache.h"
#import "OEXInterface.h"
#import "OEXMySettingsViewController.h"
#import "OEXMyVideosViewController.h"
#import "OEXNetworkConstants.h"
#import "OEXRouter.h"
#import "OEXSession.h"
#import "OEXStyles.h"
#import "OEXUserDetails.h"
#import "SWRevealViewController.h"

typedef NS_ENUM (NSUInteger, OEXRearViewOptions)
{
    MyCourse = 1,
    MyVideos,
    FindCourses,
    MySettings,
    SubmitFeedback,
};

@interface OEXRearTableViewController () < MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) OEXInterface* dataInterface;
@property (nonatomic, strong) IBOutlet UILabel* coursesLabel;
@property (nonatomic, strong) IBOutlet UILabel* videosLabel;
@property (nonatomic, strong) IBOutlet UILabel* findCoursesLabel;
@property (nonatomic, strong) IBOutlet UILabel* settingsLabel;
@property (nonatomic, strong) IBOutlet UILabel* submitFeedbackLabel;
@property (nonatomic, strong) IBOutlet UIButton* logoutButton;

@property (weak, nonatomic) IBOutlet OEXCustomLabel* userNameLabel;
@property (weak, nonatomic) IBOutlet OEXCustomLabel* userEmailLabel;
@property (weak, nonatomic) IBOutlet OEXCustomLabel* lbl_AppVersion;

@end

@implementation OEXRearTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //EdX Interface
    self.dataInterface = [OEXInterface sharedInterface];

    //Call API
    if([OEXSession sharedSession].currentUser) {
        self.userNameLabel.text = [OEXSession sharedSession].currentUser.name;
        self.userEmailLabel.text = [OEXSession sharedSession].currentUser.email;
    }

    NSString* environmentName = [[OEXConfig sharedConfig] environmentName];
    NSString* appVersion = [[NSBundle mainBundle] oex_shortVersionString];
    self.lbl_AppVersion.text = [NSString stringWithFormat:@"Version %@ %@", appVersion, environmentName];

    //UI
    [self.logoutButton setBackgroundImage:[UIImage imageNamed:@"bt_logout_active.png"] forState:UIControlStateHighlighted];

    //Listen to notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NOTIFICATION_URL_RESPONSE object:nil];

    self.coursesLabel.text = [OEXLocalizedString(@"MY_COURSES", nil) oex_uppercaseStringInCurrentLocale];
    self.videosLabel.text = [OEXLocalizedString(@"MY_VIDEOS", nil) oex_uppercaseStringInCurrentLocale];
    self.findCoursesLabel.text = [OEXLocalizedString(@"FIND_COURSES", nil) oex_uppercaseStringInCurrentLocale];
    self.settingsLabel.text = [OEXLocalizedString(@"MY_SETTINGS", nil) oex_uppercaseStringInCurrentLocale];
    self.submitFeedbackLabel.text = [OEXLocalizedString(@"SUBMIT_FEEDBACK", nil) oex_uppercaseStringInCurrentLocale];
    [self.logoutButton setTitle:[OEXLocalizedString(@"LOGOUT", nil) oex_uppercaseStringInCurrentLocale] forState:UIControlStateNormal];
    
    [self setNaturalTextAlignment];
    [self setAccessibilityLabels];
}

// Supporting RTL
- (void) setNaturalTextAlignment {
    [self.coursesLabel setTextAlignment:NSTextAlignmentNatural];
    [self.videosLabel setTextAlignment:NSTextAlignmentNatural];
    [self.findCoursesLabel setTextAlignment:NSTextAlignmentNatural];
    [self.settingsLabel setTextAlignment:NSTextAlignmentNatural];
    [self.submitFeedbackLabel setTextAlignment:NSTextAlignmentNatural];
    [self.userNameLabel setTextAlignment:NSTextAlignmentNatural];
    [self.userEmailLabel setTextAlignment:NSTextAlignmentNatural];
    
}

- (void)launchEmailComposer {
    if(![MFMailComposeViewController canSendMail]) {
        [[[UIAlertView alloc] initWithTitle:OEXLocalizedString(@"EMAIL_ACCOUNT_NOT_SET_UP_TITLE", nil)
                                    message:OEXLocalizedString(@"EMAIL_ACCOUNT_NOT_SET_UP_MESSAGE", nil)
                                   delegate:nil
                          cancelButtonTitle:[OEXLocalizedString(@"OK", nil) oex_uppercaseStringInCurrentLocale]
                          otherButtonTitles:nil] show];
    }
    else {
        MFMailComposeViewController* mailComposer = [[MFMailComposeViewController alloc] init];
        [mailComposer setMailComposeDelegate:self];
        [mailComposer.navigationBar setTintColor: [[OEXStyles sharedStyles] navigationItemTintColor]];
        [mailComposer setSubject:OEXLocalizedString(@"CUSTOMER_FEEDBACK", nil)];
        [mailComposer setMessageBody:@"" isHTML:NO];
        NSString* feedbackAddress = [OEXConfig sharedConfig].feedbackEmailAddress;
        if(feedbackAddress != nil) {
            [mailComposer setToRecipients:@[feedbackAddress]];
        }
        [self presentViewController:mailComposer animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark TableViewDelegate

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell* cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView*)tableView didHighlightRowAtIndexPath:(NSIndexPath*)indexPath NS_AVAILABLE_IOS(6_0){
    UITableViewCell* cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    UIView* seperatorImage = [cell.contentView viewWithTag:10];
    if(seperatorImage) {
        seperatorImage.hidden = YES;
    }
}
- (void)tableView:(UITableView*)tableView didUnhighlightRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell* cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    UIView* seperatorImage = [cell.contentView viewWithTag:10];
    if(seperatorImage) {
        [self performSelector:@selector(hideSeperatorImage:) withObject:seperatorImage afterDelay:0.5];
    }
}

- (void)hideSeperatorImage:(UIView*)view {
    view.hidden = NO;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    OEXRearViewOptions rearViewOptions = indexPath.row;

    switch(rearViewOptions)
    {
        case MyCourse:  // MY COURSES
            [self.view setUserInteractionEnabled:NO];
            [[OEXRouter sharedRouter]showMyCourses];
            break;

        case MyVideos:  // MY VIDEOS
            [self.view setUserInteractionEnabled:NO];
            [[OEXRouter sharedRouter]showMyVideos];
            break;

        case FindCourses:       // FIND COURSES
        {
            [self.view setUserInteractionEnabled:NO];
            [[OEXRouter sharedRouter] showFindCourses];
            
            [[OEXAnalytics sharedAnalytics] trackUserFindsCourses];
        }
        break;

        case MySettings: // MY SETTINGS
        {
            [self.view setUserInteractionEnabled:NO];
            SWRevealViewController* rvc = self.revealViewController;
            OEXMySettingsViewController* mySettingsViewController = [[OEXMySettingsViewController alloc] init];
            UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:mySettingsViewController];
            [rvc pushFrontViewController:nc animated:YES];
        }
        break;

        case SubmitFeedback:
            [self launchEmailComposer];
            break;

        default:
            break;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark edXInterface Delegate

- (void)dataAvailable:(NSNotification*)notification {
    NSDictionary* userDetailsDict = (NSDictionary*)notification.userInfo;

    NSString* successString = [userDetailsDict objectForKey:NOTIFICATION_KEY_STATUS];
    NSString* URLString = [userDetailsDict objectForKey:NOTIFICATION_KEY_URL];
    if([successString isEqualToString:NOTIFICATION_VALUE_URL_STATUS_SUCCESS] && [URLString isEqualToString:[_dataInterface URLStringForType:URL_USER_DETAILS]]) {
        self.userNameLabel.text = [OEXSession sharedSession].currentUser.username;
        self.userEmailLabel.text = [OEXSession sharedSession].currentUser.email;
    }
}

// TODO: Move this sign out logic somewhere more appropriate
- (IBAction)logoutClicked:(id)sender {
    // Analytics User Logout
    [[OEXAnalytics sharedAnalytics] trackUserLogout];
    // Analytics tagging
    [[OEXAnalytics sharedAnalytics] clearIdentifiedUser];
    UIButton* button = (UIButton*)sender;
    [button setBackgroundImage:[UIImage imageNamed:@"bt_logout_active.png"] forState:UIControlStateNormal];
    // Set the language to blank
    [OEXInterface setCCSelectedLanguage:@""];
    [self deactivate];
    [[OEXImageCache sharedInstance] clearImagesFromMainCacheMemory];
    NSLog(@"logoutClicked");
}

- (void)deactivate {
    [[OEXInterface sharedInterface] deactivateWithCompletionHandler:^{
        // TODO: Move this sign out logic somewhere more appropriate
        [[OEXSession sharedSession] closeAndClearSession];
        [[OEXRouter sharedRouter] showLoggedOutScreen];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.view setUserInteractionEnabled:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

- (void) setAccessibilityLabels {
    self.userNameLabel.accessibilityLabel = self.userNameLabel.text;
    self.userEmailLabel.accessibilityLabel = self.userEmailLabel.text;
    
    self.coursesLabel.accessibilityLabel = self.coursesLabel.text;
    self.coursesLabel.accessibilityHint = OEXLocalizedString(@"ACCESSIBILITY_SHOWS_MY_COURSES", nil);
    
    self.videosLabel.accessibilityLabel = self.videosLabel.text;
    self.videosLabel.accessibilityHint = OEXLocalizedString(@"SHOWS_MY_VIDEOS", nil);
    
    self.findCoursesLabel.accessibilityLabel = self.findCoursesLabel.text;
    self.findCoursesLabel.accessibilityHint = OEXLocalizedString(@"FINDS_COURSES", nil);
    
    self.settingsLabel.accessibilityLabel = self.settingsLabel.text;
    self.settingsLabel.accessibilityHint = OEXLocalizedString(@"SHOWS_SETTINGS", nil);
    
    self.submitFeedbackLabel.accessibilityLabel = self.submitFeedbackLabel.text;
    self.submitFeedbackLabel.accessibilityHint = OEXLocalizedString(@"SUBMITS_FEEDBACKS", nil);
    
}

@end
