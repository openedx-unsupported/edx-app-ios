//
//  EDXAnnouncementsView.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/3/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "EDXAnnouncementsView.h"

#import "EDXAnnouncement.h"
#import "EDXConfig.h"
#import "EDXEnvironment.h"
#import "EDXStyles.h"


@interface EDXAnnouncementsView ()

@property (strong, nonatomic) UIWebView* contentView;

@end

@implementation EDXAnnouncementsView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self != nil) {
        self.contentView = [[UIWebView alloc] initWithFrame:self.bounds];
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.contentView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
        [self addSubview:self.contentView];
    }
    return self;
}

- (void)useAnnouncements:(NSArray*)announcements {
    NSMutableString* html = [[NSMutableString alloc] init];
    [announcements enumerateObjectsUsingBlock:^(EDXAnnouncement* announcement, NSUInteger idx, BOOL *stop) {
        [html appendFormat:@"<div class=\"announcement-header\">%@</div>", announcement.heading];
        [html appendString:@"<hr class=\"announcement\"/>"];
        [html appendString:announcement.content];
        if(idx + 1 < announcements.count) {
            [html appendString:@"<div class=\"announcement-separator\"/></div>"];
        }
    }];
    NSString* displayHTML = [EDXStyles styleHTMLContent:html];
    [self.contentView loadHTMLString:displayHTML baseURL:[NSURL URLWithString:[EDXEnvironment shared].config.apiHostURL]];
}

@end
