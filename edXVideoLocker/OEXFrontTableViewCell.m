//
//  OEXFrontTableViewCell.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 09/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXFrontTableViewCell.h"
#import "OEXEnvironment.h"
#import "OEXConfig.h"
#import "OEXInterface.h"
#import "OEXDateFormatting.h"
@interface OEXFrontTableViewCell()
{
    OEXCourse *currentCourse;
    OEXInterface * dataInterface;
    
}
@end

@implementation OEXFrontTableViewCell

- (void)awakeFromNib
{
    self.view_Parent.layer.cornerRadius = 5;
    self.view_Parent.layer.masksToBounds = YES;
    //Listen to notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NOTIFICATION_URL_RESPONSE object:nil];
}

- (void)dataAvailable:(NSNotification *)notification {
    NSDictionary *userDetailsDict = (NSDictionary *)notification.userInfo;
    
    NSString * successString = [userDetailsDict objectForKey:NOTIFICATION_KEY_STATUS];
    NSString * URLString = [userDetailsDict objectForKey:NOTIFICATION_KEY_URL];
    
    if ([successString isEqualToString:NOTIFICATION_VALUE_URL_STATUS_SUCCESS])
    {
        if ([OEXInterface isURLForImage:URLString])
        {
            if(currentCourse)
            {
                
                dispatch_async(_imageQueue, ^{
                    UIImage *displayImage=nil;
                    
                    if ([URLString rangeOfString:currentCourse.course_image_url].location != NSNotFound)
                    {
                        NSData * imageData = [dataInterface resourceDataForURLString:[NSString stringWithFormat:@"%@%@", [OEXEnvironment shared].config.apiHostURL, currentCourse.course_image_url] downloadIfNotAvailable:NO];
                        if (imageData && imageData.length>0) {
                            
                            displayImage=[UIImage imageWithData:imageData];
                            currentCourse.imagCourse = displayImage;
                        }
                        
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // Update the UI
                        if(displayImage)
                        {
                            self.img_Course.image = displayImage;
                        }
                    });
                    
                });
                
            }
        }
    }
}


-(void)setData:(OEXCourse *)obj_course{
    
    currentCourse=obj_course;
    if(!dataInterface)
    {
        dataInterface = [OEXInterface sharedInterface];
    }
    
    self.lbl_Title.text = obj_course.name;
    
    self.lbl_Subtitle.text =  [NSString stringWithFormat:@"%@ | %@" , obj_course.org, obj_course.number]; // Show course ced
    
    
    // MOB - 448
    //Background image
    
    
    
    if (obj_course.imagCourse)
    {
        self.img_Course.image = obj_course.imagCourse;
    }
    else {
        UIImage *displayImage=nil;
        NSString *imgURLString = [NSString stringWithFormat:@"%@%@", [OEXEnvironment shared].config.apiHostURL, obj_course.course_image_url];
        NSData * imageData = [dataInterface resourceDataForURLString:imgURLString downloadIfNotAvailable:NO];
        
        if (imageData && imageData.length>0)
        {
            displayImage = [UIImage imageWithData:imageData];
            currentCourse.imagCourse=displayImage;
        }
        else
        {
            displayImage = [UIImage imageNamed:@"Splash_map.png"];
            [dataInterface downloadWithRequestString:[NSString stringWithFormat:@"%@%@", [OEXEnvironment shared].config.apiHostURL, obj_course.course_image_url]  forceUpdate:YES];
        }
        if(displayImage)
        {
            self.img_Course.image = displayImage;
        }
    }
    
    
    
    self.lbl_Starting.hidden = NO;
    self.img_Starting.hidden = NO;
    
    // If no new course content is available
    if ([obj_course.latest_updates.video length]==0)
    {
        self.img_NewCourse.hidden = YES;
        self.btn_NewCourseContent.hidden  = YES;
        
        // If both start and end dates are blank then show nothing.
        if (obj_course.start == nil && obj_course.end == nil)
        {
            self.img_Starting.hidden = YES;
            self.lbl_Starting.hidden = YES;
        }
        else
        {
            
            // If start date is older than current date
            if (obj_course.isStartDateOld)
            {
                
                NSString* formattedEndDate = [OEXDateFormatting formatAsMonthDayString: obj_course.endDate];
                
                // If Old date is older than current date
                if (obj_course.isEndDateOld)
                {
                    self.lbl_Starting.text = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"ENDED", nil) , formattedEndDate];
                    
                }
                else    // End date is newer than current date
                {
                    if (obj_course.end == nil)
                    {
                        self.img_Starting.hidden = YES;
                        self.img_NewCourse.hidden = YES;
                        self.btn_NewCourseContent.hidden = YES;
                        self.lbl_Starting.hidden = YES;
                    }
                    else {
                        self.lbl_Starting.text = [NSString stringWithFormat:@"%@ - %@",NSLocalizedString(@"ENDING", nil) ,formattedEndDate];
                    }
                    
                }
                
            }
            else    // Start date is newer than current date
            {
                if (obj_course.start == nil)
                {
                    self.img_Starting.hidden = YES;
                    self.img_NewCourse.hidden = YES;
                    self.btn_NewCourseContent.hidden = YES;
                    self.lbl_Starting.hidden = YES;
                }
                else {
                    NSString* formattedStartDate = [OEXDateFormatting formatAsMonthDayString:obj_course.startDate];
                    self.lbl_Starting.text = [NSString stringWithFormat:@"%@ - %@",NSLocalizedString(@"STARTING", nil), formattedStartDate];
                }
                
            }
            
        }
        
    }
    else
    {
        self.img_Starting.hidden = YES;
        self.lbl_Starting.hidden = YES;
        self.img_NewCourse.hidden = NO;
        self.btn_NewCourseContent.hidden = NO;
    }
    
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_URL_RESPONSE object:nil];
    _imageQueue=nil;
}

@end
