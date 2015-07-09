//
//  OEXFrontTableViewCell.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 09/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXFrontTableViewCell.h"
#import "OEXImageCache.h"
#import "OEXConfig.h"
#import "OEXCourse.h"

@implementation OEXFrontTableViewCell

- (void)prepareForReuse {
    self.course = nil;
}

- (void)awakeFromNib {
    self.view_Parent.layer.cornerRadius = 5;
    self.view_Parent.layer.masksToBounds = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setImageToImageView:) name:OEXImageDownloadCompleteNotification object:nil];
    
    [self.lbl_Title setTextAlignment:NSTextAlignmentNatural];
    [self.lbl_Subtitle setTextAlignment:NSTextAlignmentNatural];
    if ([self isRTL]) {
        [self.lbl_Starting setTextAlignment:NSTextAlignmentLeft];
    }
    
}

- (void)setImageToImageView:(NSNotification*)notification {
    NSDictionary* dictObj = (NSDictionary*)notification.object;
    UIImage* image = [dictObj objectForKey:OEXNotificationUserInfoObjectImageKey];
    NSString* downloadImageURL = [dictObj objectForKey:OEXNotificationUserInfoObjectImageURLKey];
    if(image) {
        NSString* imgURLString = [NSString stringWithFormat:@"%@%@", [OEXConfig sharedConfig].apiHostURL, self.course.course_image_url];
        if([imgURLString isEqualToString:downloadImageURL]) {
            self.img_Course.image = image;
        }
    }
}

- (void)setCourseImage {
    NSString* imgURLString = [NSString stringWithFormat:@"%@%@", [OEXConfig sharedConfig].apiHostURL, self.course.course_image_url];
    if(imgURLString) {
        OEXImageCache* imageCache = [OEXImageCache sharedInstance];
        [imageCache getImage:imgURLString];
    }
}

- (BOOL) isRTL {
    return [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
