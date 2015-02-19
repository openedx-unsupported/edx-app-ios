//
//  OEXHandoutsViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXHandoutsViewController.h"
#import "OEXStyles.h"
#import "OEXConfig.h"
#import "DACircularProgressView.h"
#import "OEXCustomNavigationView.h"
#import "Reachability.h"
#import "OEXInterface.h"
#import "OEXDownloadViewController.h"

#define kHandoutsScreenName @"Handouts"

@interface OEXHandoutsViewController ()

@property (strong, nonatomic) IBOutlet UILabel *handoutsUnavailableLabel;
@property (strong, nonatomic) NSString *handoutsString;

@end

@implementation OEXHandoutsViewController

-(instancetype)initWithHandoutsString:(NSString *)aHandoutsString{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.handoutsString = aHandoutsString;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.customNavView.lbl_TitleView.text = kHandoutsScreenName;
    [self.customNavView.btn_Back addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [[self.dataInterface progressViews] addObject:self.customProgressBar];
    [[self.dataInterface progressViews] addObject:self.showDownloadsButton];
    
    if (self.handoutsString.length > 0) {
        NSString* styledHandouts = [OEXStyles styleHTMLContent:self.handoutsString];
        [self.webView loadHTMLString:styledHandouts baseURL:[NSURL URLWithString:[OEXConfig sharedConfig].apiHostURL]];
    }
    else{
        self.handoutsUnavailableLabel.text = NSLocalizedString(@"HANDOUTS_UNAVAILABLE", nil);
        self.handoutsUnavailableLabel.hidden = NO;
        self.webView.hidden = YES;
    }
    
}

- (void)hideOfflineLabel:(BOOL)isOnline{
    self.customNavView.lbl_Offline.hidden = isOnline;
    self.customNavView.view_Offline.hidden = isOnline;
}

@end
