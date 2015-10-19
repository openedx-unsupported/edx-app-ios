//
//  OEXCourseInfoTabViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXCourseInfoTabViewController.h"

#import <CoreImage/CoreImage.h>

#import "edX-Swift.h"

#import "NSString+OEXFormatting.h"

#import "OEXAnnouncement.h"
#import "OEXConfig.h"
#import "OEXCourse.h"
#import "OEXDateFormatting.h"
#import "OEXInterface.h"
#import "OEXLatestUpdates.h"
#import "OEXPushSettingsManager.h"
#import "OEXStyles.h"
#import "OEXSwitchStyle.h"

@implementation OEXCourseInfoTabViewControllerEnvironment

- (id)initWithConfig:(OEXConfig *)config
 pushSettingsManager:(OEXPushSettingsManager *)pushSettingsManager
              styles:(OEXStyles *)styles {
    self = [super init];
    if(self != nil) {
        _config = config;
        _pushSettingsManager = pushSettingsManager;
        _styles = styles;
    }
    return self;
}

@end

static const CGFloat OEXCourseInfoBlurRadius = 5;

@interface OEXCourseInfoTabViewController () <UIWebViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) OEXCourseInfoTabViewControllerEnvironment* environment;

@property (strong, nonatomic) IBOutlet UIImageView* img_Course;
@property (strong, nonatomic) IBOutlet UILabel* lbl_Subtitle;
@property (strong, nonatomic) IBOutlet UILabel* lbl_Title;
@property (strong, nonatomic) UIWebView* announcementsWebView;
@property (strong, nonatomic) IBOutlet UILabel* announcementsLabel;
@property (strong, nonatomic) IBOutlet UILabel* handoutsLabel;
@property (strong, nonatomic) IBOutlet UILabel* notificationsLabel;
@property (strong, nonatomic) IBOutlet UIScrollView* scrollView;
@property (strong, nonatomic) UIActivityIndicatorView* webActivityIndicator;
@property (strong, nonatomic) IBOutlet UILabel* announcementsNotAvailableLabel;
@property (strong, nonatomic) IBOutlet UIView* announcementBackgroundView;
@property (strong, nonatomic) IBOutlet UISwitch* notificationsToggle;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* notificationsHeightConstraint;

@property (strong, nonatomic) OEXCourse* course;

@end

@implementation OEXCourseInfoTabViewController

- (id)initWithCourse:(OEXCourse*)course environment:(OEXCourseInfoTabViewControllerEnvironment*)environment {
    self = [super initWithNibName:nil bundle:nil];
    if(self) {
        self.environment = environment;
        self.course = course;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView* separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.announcementBackgroundView.frame.size.width, 1)];
    [separator setBackgroundColor:[UIColor blackColor]];
    separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.announcementBackgroundView addSubview:separator];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self computeBlurredCourseImage];
    });
    
    self.announcementsLabel.text = [Strings courseAnnouncements];
    self.handoutsLabel.text = [Strings viewHandouts];
    self.notificationsLabel.text = [Strings notificationsEnabled];
    
    [self.environment.styles.standardSwitchStyle applyToSwitch: self.notificationsToggle];
    
    if(![self.environment.config pushNotificationsEnabled]) {
        self.notificationsHeightConstraint.constant = 0;
    }
    self.notificationsToggle.on = ![self.environment.pushSettingsManager isPushDisabledForCourseWithID:self.course.course_id];

    if(self.course) {
        self.lbl_Title.text = self.course.name;

        NSString* startEndDateString = nil;
        if([self.course.latest_updates.video length] == 0) {
            if(self.course.isStartDateOld) {
                NSString* formattedEndDate = [OEXDateFormatting formatAsMonthDayString: self.course.end];
                if(formattedEndDate) {
                    if(self.course.isEndDateOld) {
                        startEndDateString = [Strings courseEndedWithEndDate:formattedEndDate];
                    }
                    else {
                        if(self.course.end == nil) {
                            startEndDateString = [Strings courseEndedWithEndDate:formattedEndDate];
                        }
                    }
                }
            }
            else {
                if(self.course.start_display_info.date) {
                    NSString* formattedStartDate = [OEXDateFormatting formatAsMonthDayString:self.course.start_display_info.date];
                    if(formattedStartDate) {
                        startEndDateString = [Strings startingWithStartDate:formattedStartDate];
                    }
                }
            }
        }

        if(startEndDateString) {
            self.lbl_Subtitle.text = [NSString stringWithFormat:@"%@ | %@ | %@", self.course.org, self.course.number, startEndDateString];
        }
        else {
            self.lbl_Subtitle.text = [NSString stringWithFormat:@"%@ | %@", self.course.org, self.course.number];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addAnnouncementsWebView];
    [self scrollToTop];
}

- (void)scrollToTop {
    [self.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    self.announcementsWebView.scrollView.contentOffset = CGPointMake(0, self.announcementsWebView.scrollView.contentOffset.y);
}

- (void)computeBlurredCourseImage {
    CIImage* courseImage = nil;
    NSString* imgURLString = [NSString stringWithFormat:@"%@%@", self.environment.config.apiHostURL, self.course.course_image_url];
    NSData* imageData = [[OEXInterface sharedInterface] resourceDataForURLString:imgURLString downloadIfNotAvailable:NO];

    if(imageData && imageData.length > 0) {
        courseImage = [CIImage imageWithData:imageData];
    }
    else {
        courseImage = [CIImage imageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Splash_map" withExtension:@"png"]];
    }

    CIContext* context = [CIContext contextWithOptions:nil];
    CIFilter* filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:courseImage forKey:kCIInputImageKey];
    [filter setValue:@(OEXCourseInfoBlurRadius) forKey:kCIInputRadiusKey];
    CIImage* result = [filter valueForKey:kCIOutputImageKey];

    // cut off the edges since they blur with transparent pixels and so look weird otherwise
    CGRect extent = CGRectInset([courseImage extent], 2 * OEXCourseInfoBlurRadius, 2 * OEXCourseInfoBlurRadius);
    CGImageRef cgImage = [context createCGImage:result fromRect:extent];
    UIImage* blurredImage = [UIImage imageWithCGImage:cgImage];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.img_Course.image = blurredImage;
    });
    CGImageRelease(cgImage);
}

- (void)addAnnouncementsWebView {
    if(!self.announcementsWebView) {
        self.scrollView.frame = self.view.bounds;
        CGFloat announcementsWebViewOriginY = CGRectGetMaxY([self.scrollView convertRect:self.notificationsLabel.bounds fromView:self.notificationsLabel]);
        self.announcementsWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, announcementsWebViewOriginY, self.scrollView.frame.size.width, self.scrollView.frame.size.height - announcementsWebViewOriginY)];

        self.announcementsWebView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
        self.announcementsWebView.delegate = self;
        self.announcementsWebView.scrollView.delegate = self;

        self.announcementsNotAvailableLabel.text = [Strings announcementUnavailable];
        self.announcementsNotAvailableLabel.frame = self.announcementsWebView.frame;
        [self.scrollView addSubview:self.announcementsNotAvailableLabel];

        [self.scrollView addSubview:self.announcementsWebView];
        self.announcementsWebView.hidden = YES;
        self.scrollView.contentSize = self.view.bounds.size;
    }
}

- (void)useAnnouncements:(NSArray*)announcements {
    if(announcements.count < 1) {
        return;
    }
    self.announcementsNotAvailableLabel.hidden = YES;
    NSMutableString* html = [[NSMutableString alloc] init];
    [announcements enumerateObjectsUsingBlock:^(OEXAnnouncement* announcement, NSUInteger idx, BOOL* stop) {
        [html appendFormat:@"<div class=\"announcement-header\">%@</div>", announcement.heading];
        [html appendString:@"<hr class=\"announcement\"/>"];
        [html appendString:announcement.content];
        if(idx + 1 < announcements.count) {
            [html appendString:@"<div class=\"announcement-separator\"/></div>"];
        }
    }];
    NSString* displayHTML = [self.environment.styles styleHTMLContent:html];
    [self.announcementsWebView loadHTMLString:displayHTML baseURL:[NSURL URLWithString:self.environment.config.apiHostURL]];

    self.announcementsWebView.hidden = YES;
    if(self.webActivityIndicator) {
        [self.webActivityIndicator removeFromSuperview];
    }
    if(!self.webActivityIndicator) {
        self.webActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    [self.scrollView addSubview:self.webActivityIndicator];
    self.webActivityIndicator.frame = self.announcementsWebView.frame;
    [self.webActivityIndicator startAnimating];
}

// Ensure external links open in a web browser
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    if(navigationType != UIWebViewNavigationTypeOther) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
    if(!webView.loading) {
        webView.hidden = NO;
        [self.webActivityIndicator removeFromSuperview];
        CGRect webViewFrame = webView.frame;
        webViewFrame.origin.y = CGRectGetMaxY([self.scrollView convertRect:self.notificationsLabel.bounds fromView:self.notificationsLabel]);
        CGFloat initialHeight = webViewFrame.size.height;
        webViewFrame.size.height = 1;
        webView.frame = webViewFrame;
        CGSize fittingSize = [webView sizeThatFits:CGSizeZero];
        webViewFrame.size.height = fittingSize.height;
        webView.frame = webViewFrame;
        CGFloat finalHeight = webViewFrame.size.height;
        CGSize scrollContentSize = self.scrollView.contentSize;
        scrollContentSize.height = scrollContentSize.height - initialHeight + finalHeight;
        self.scrollView.contentSize = scrollContentSize;
    }
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    if(scrollView.contentOffset.y > 0 || scrollView.contentOffset.y < 0) {
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
    }
}

- (IBAction)viewCourseHandoutsTapped:(id)sender {
    [self.delegate courseInfoTabViewControllerUserTappedOnViewHandouts:self];
}

- (IBAction)toggledNotifications:(UISwitch*)sender {
    [self.environment.pushSettingsManager setPushDisabled:!self.notificationsToggle.on forCourseID:self.course.course_id];
}

@end
