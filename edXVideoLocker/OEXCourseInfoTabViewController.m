//
//  OEXCourseInfoTabViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXCourseInfoTabViewController.h"
#import "OEXCourse.h"
#import "OEXAnnouncement.h"
#import "OEXStyles.h"
#import "OEXConfig.h"
#import "OEXDateFormatting.h"
#import "OEXInterface.h"
#import <CoreImage/CoreImage.h>

static const CGFloat OEXCourseInfoBlurRadius = 5;

@interface OEXCourseInfoTabViewController () <UIWebViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *img_Course;
@property (strong, nonatomic) IBOutlet UILabel *lbl_Subtitle;
@property (strong, nonatomic) IBOutlet UILabel *lbl_Title;
@property (strong, nonatomic) UIWebView *announcementsWebView;
@property (strong, nonatomic) IBOutlet UILabel *announcementsLabel;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) OEXCourse *course;
@property (strong, nonatomic) UIActivityIndicatorView *webActivityIndicator;
@property (strong, nonatomic) IBOutlet UILabel *announcementsNotAvailableLabel;
@end

@implementation OEXCourseInfoTabViewController

-(instancetype)initWithCourse:(OEXCourse *)aCourse{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.course = aCourse;
    }
    return self;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self computeBlurredCourseImage];
    });
    
    if (self.course) {
        self.lbl_Title.text = self.course.name;
        
        NSString *startEndDateString = nil;
        if ([self.course.latest_updates.video length]==0){
            if (self.course.isStartDateOld){
                NSString* formattedEndDate = [OEXDateFormatting formatAsMonthDayString: self.course.end];
                if(formattedEndDate){
                    if (self.course.isEndDateOld){
                        startEndDateString = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"ENDED", nil) , formattedEndDate];
                    }
                    else{
                        if (self.course.end == nil){
                            startEndDateString = [NSString stringWithFormat:@"%@ - %@",NSLocalizedString(@"ENDING", nil) ,formattedEndDate];
                        }
                    }
                }
            }
            else{
                if (self.course.start){
                    NSString* formattedStartDate = [OEXDateFormatting formatAsMonthDayString:self.course.start];
                    if (formattedStartDate) {
                        startEndDateString = [NSString stringWithFormat:@"%@ - %@",NSLocalizedString(@"STARTING", nil), formattedStartDate];
                    }
                }
            }
        }
        
        if (startEndDateString) {
            self.lbl_Subtitle.text = [NSString stringWithFormat:@"%@ | %@ | %@" , self.course.org, self.course.number, startEndDateString];
        }
        else{
            self.lbl_Subtitle.text = [NSString stringWithFormat:@"%@ | %@" , self.course.org, self.course.number];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self addAnnouncementsWebView];
    [self scrollToTop];
}

-(void)scrollToTop{
    [self.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    self.announcementsWebView.scrollView.contentOffset = CGPointMake(0, self.announcementsWebView.scrollView.contentOffset.y);
}

-(void)computeBlurredCourseImage{
    CIImage *courseImage = nil;
        NSString *imgURLString = [NSString stringWithFormat:@"%@%@", [OEXConfig sharedConfig].apiHostURL, self.course.course_image_url];
        NSData * imageData = [[OEXInterface sharedInterface] resourceDataForURLString:imgURLString downloadIfNotAvailable:NO];
        
        if (imageData && imageData.length>0){
            courseImage = [CIImage imageWithData:imageData];
        }
        else{
            courseImage = [CIImage imageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Splash_map" withExtension:@"png"]];
        }

    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:courseImage forKey:kCIInputImageKey];
    [filter setValue:@(OEXCourseInfoBlurRadius) forKey:kCIInputRadiusKey];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    // cut off the edges since they blur with transparent pixels and so look weird otherwise
    CGRect extent = CGRectInset([courseImage extent], 2 * OEXCourseInfoBlurRadius, 2 * OEXCourseInfoBlurRadius);
    CGImageRef cgImage = [context createCGImage:result fromRect:extent];
    UIImage *blurredImage = [UIImage imageWithCGImage:cgImage];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.img_Course.image = blurredImage;
    });
}

-(void)addAnnouncementsWebView{
    if (!self.announcementsWebView) {
        self.scrollView.frame = self.view.bounds;
        CGFloat announcementsWebViewOriginY = self.announcementsLabel.frame.origin.y+self.announcementsLabel.frame.size.height;
        self.announcementsWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, announcementsWebViewOriginY, self.scrollView.frame.size.width, self.scrollView.frame.size.height-announcementsWebViewOriginY)];

        self.announcementsWebView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
        self.announcementsWebView.delegate = self;
        self.announcementsWebView.scrollView.delegate = self;
        
        self.announcementsNotAvailableLabel.text = NSLocalizedString(@"ANNOUNCEMENT_UNAVAILABLE", nil);
        self.announcementsNotAvailableLabel.frame = self.announcementsWebView.frame;
        [self.scrollView addSubview:self.announcementsNotAvailableLabel];
        
        [self.scrollView addSubview:self.announcementsWebView];
        self.announcementsWebView.hidden = YES;
        self.scrollView.contentSize = self.view.bounds.size;
        
    }
}

-(void)useAnnouncements:(NSArray*)announcements {
    if (announcements.count<1) {
        return;
    }
    self.announcementsNotAvailableLabel.hidden = YES;
    NSMutableString* html = [[NSMutableString alloc] init];
    [announcements enumerateObjectsUsingBlock:^(OEXAnnouncement* announcement, NSUInteger idx, BOOL *stop) {
        [html appendFormat:@"<div class=\"announcement-header\">%@</div>", announcement.heading];
        [html appendString:@"<hr class=\"announcement\"/>"];
        [html appendString:announcement.content];
        if(idx + 1 < announcements.count) {
            [html appendString:@"<div class=\"announcement-separator\"/></div>"];
        }
    }];
    NSString* displayHTML = [OEXStyles styleHTMLContent:html];
    [self.announcementsWebView loadHTMLString:displayHTML baseURL:[NSURL URLWithString:[OEXConfig sharedConfig].apiHostURL]];
    
    self.announcementsWebView.hidden = YES;
    if (self.webActivityIndicator) {
        [self.webActivityIndicator removeFromSuperview];
    }
    if (!self.webActivityIndicator) {
        self.webActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    [self.scrollView addSubview:self.webActivityIndicator];
    self.webActivityIndicator.frame = self.announcementsWebView.frame;
    [self.webActivityIndicator startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    if (!webView.loading) {
        webView.hidden = NO;
        [self.webActivityIndicator removeFromSuperview];
        CGRect webViewFrame = webView.frame;
        CGFloat initialHeight = webViewFrame.size.height;
        webViewFrame.size.height = 1;
        webView.frame = webViewFrame;
        CGSize fittingSize = [webView sizeThatFits:CGSizeZero];
        webViewFrame.size.height = fittingSize.height;
        webView.frame = webViewFrame;
        CGFloat finalHeight = webViewFrame.size.height;
        CGSize scrollContectSize = self.scrollView.contentSize;
        scrollContectSize.height = scrollContectSize.height-initialHeight+finalHeight;
        self.scrollView.contentSize = scrollContectSize;
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView.contentOffset.y > 0  ||  scrollView.contentOffset.y < 0 ){
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
    }
}

-(IBAction)viewCourseHandoutsTapped:(id)sender{
    [self.delegate courseInfoTabViewControllerUserTappedOnViewHandouts:self];
}

@end
