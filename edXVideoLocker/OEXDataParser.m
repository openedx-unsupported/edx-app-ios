//
//  OEXDataParser.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXDataParser.h"

#import "NSArray+OEXSafeAccess.h"
#import "NSObject+OEXReplaceNull.h"

#import "OEXAppDelegate.h"
#import "OEXCourse.h"
#import "OEXHelperVideoDownload.h"
#import "OEXLatestUpdates.h"
#import "OEXNetworkConstants.h"
#import "OEXNetworkInterface.h"
#import "OEXInterface.h"
#import "OEXUserCourseEnrollment.h"
#import "OEXUserDetails.h"
#import "OEXVideoPathEntry.h"
#import "OEXVideoSummary.h"

@interface OEXDataParser ()
{
    OEXAppDelegate *appD;
}

@property (nonatomic, weak) OEXInterface * dataInterface;
@property (nonatomic, strong) NSMutableArray *arr_VideoSummary;

@end

@implementation OEXDataParser

- (void)deactivate
{
    ELog(@"deactivate -1");
    [self.arr_VideoSummary removeAllObjects];
}

- (id)initWithDataInterface:(OEXInterface *)dataInterface
{
    self = [super init];
    
    appD = (OEXAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    self.dataInterface = dataInterface;
    
    return self;
}

- (id)parsedObjectWithData:(NSData *)data forURLString:(NSString *)URLString
{
    if (!data) {
        //NSLog(@"Empty data sent for parsing!");
        return nil;
    }
    
    if ([URLString isEqualToString:[_dataInterface URLStringForType:URL_USER_DETAILS]]) {
        return [self getUserDetails:data];
    }
    else if ([URLString isEqualToString:[_dataInterface URLStringForType:URL_COURSE_ENROLLMENTS]]) {
        return [self getUserCourseEnrollmentList:data];
    }
    else if ([URLString rangeOfString:URL_VIDEO_SUMMARY].location != NSNotFound) {
        return [self getVideoSummaryList:data ForURLString:URLString];
    }else if ([URLString rangeOfString:URL_COURSE_ANNOUNCEMENTS].location != NSNotFound) {
        return [self getAnnouncements:data];
    }else if ([URLString rangeOfString:URL_COURSE_HANDOUTS].location != NSNotFound) {
        return [self getHandouts:data];
    }
    
    return nil;
}


-(NSArray *)getAnnouncements:(NSData *)receivedData {
    NSError *error;
    id array = [NSJSONSerialization JSONObjectWithData:receivedData options:0 error:&error];
    if([array isKindOfClass:[NSArray class]]){
        return [array oex_replaceNullsWithEmptyStrings];
    }
    return [NSArray array];
}

-(NSString*)getHandouts:(NSData *)receivedData {
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:receivedData options:0 error:&error];
    NSDictionary *dictResponse = nil;
    if ([dict isKindOfClass:[NSDictionary class]]) {
        dictResponse=[dict oex_replaceNullsWithEmptyStrings];
    }
    
    if (!dictResponse || ![dictResponse objectForKey:@"handouts_html"]) {
        return @"<p>Sorry, There is currently no data available for this section</p>";;
    }
    
    
    NSString *htmlString=[dictResponse objectForKey:@"handouts_html"];
    
    return htmlString;
    
}

- (NSDictionary*)getCourseInfo:(NSData *)receivedData {
	
	NSError *error;
    NSDictionary * obj = [NSJSONSerialization JSONObjectWithData:receivedData options:0 error:&error];
    if (!obj || ![obj objectForKey:@"overview"]) {
        NSDictionary * tempDict = @{@"overview": @"<p>Sorry, There is currently no data available for this section</p>"};
        return tempDict;
    }
    
    return obj;
    
}

- (OEXUserDetails*)getUserDetails:(NSData *)receivedData
{
    /*
     {
     "id":4,
     "username":"staff",
     "email":"staff@example.com",
     "name":"staff",
     "course_enrollments":"http://mobile.m.sandbox.edx.org/public_api/users/staff/course_enrollments/",
     "url":"http://mobile.m.sandbox.edx.org/public_api/users/staff"
     }
     */
    
    //    NSString *response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    //    //NSLog(@"RESPONSE : %@", response);
    
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:receivedData options:0 error:&error];
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *dictResponse = [dict oex_replaceNullsWithEmptyStrings];
    
    OEXUserDetails *obj_userdetails = [[OEXUserDetails alloc] init];
    obj_userdetails.userId = [dictResponse objectForKey:@"id"];
    obj_userdetails.username = [dictResponse objectForKey:@"username"];
    obj_userdetails.email = [dictResponse objectForKey:@"email"];
    obj_userdetails.name = [dictResponse objectForKey:@"name"];
    obj_userdetails.course_enrollments = [dictResponse objectForKey:@"course_enrollments"];
    obj_userdetails.url = [dictResponse objectForKey:@"url"];
    
    return obj_userdetails;
}

- (id)getUserCourseEnrollmentList:(NSData *)receivedData
{
    
    /*
     http://mobile.m.sandbox.edx.org/public_api/users/staff?format=json
     [
     {
     "created":"2014-04-18T17:10:11Z",
     "mode":"honor",
     "is_active":true,
     "course":{
     "latest_updates":{
     "video":null
     },
     "start":"1970-01-01T05:00:00Z",
     "course_image":"/c4x/edX/Open_DemoX/asset/images_course_image.jpg",
     "end":null,
     "name":"edX Demonstration Course",
     "org":"edX",
     "video_outline":"http://mobile.m.sandbox.edx.org/public_api/video_outlines/edX+Open_DemoX+edx_demo_course",
     "id":"edX+Open_DemoX+edx_demo_course",
     "number":"Open_DemoX"
     }
     }
     ]
     */
    
    
//    NSString *response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
//    NSLog(@"\n\n\n\ngetUserCourseEnrollmentList RESPONSE : %@", response);
    
    
    NSError *error;
    NSArray *arrResponse = [NSJSONSerialization JSONObjectWithData:receivedData options:0 error:&error];
    
    NSMutableArray *arr_CourseEnrollmentObjetcs = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dict in arrResponse)
    {
        // parse level - 1
        if (![dict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSDictionary *dictResponse = [dict oex_replaceNullsWithEmptyStrings];
        
        OEXUserCourseEnrollment *obj_usercourse = [[OEXUserCourseEnrollment alloc] init];
        obj_usercourse.created = [dictResponse objectForKey:@"created"];
        obj_usercourse.mode = [dictResponse objectForKey:@"mode"];
        obj_usercourse.is_active = [[dictResponse objectForKey:@"is_active"] boolValue];
        
        // Inner course dictionary parse
        // parse level - 2
        NSDictionary *dictCourse = [dictResponse objectForKey:@"course"];
        OEXCourse *obj_Course = [[OEXCourse alloc] init];
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];

        obj_Course.startDate=[formater dateFromString:[dictCourse objectForKey:@"start"]];
        obj_Course.endDate=[formater dateFromString:[dictCourse objectForKey:@"end"]];
        obj_Course.start = [appD convertDate:[dictCourse objectForKey:@"start"]];
        obj_Course.course_image_url = [dictCourse objectForKey:@"course_image"];
        obj_Course.end = [appD convertDate:[dictCourse objectForKey:@"end"]];
        obj_Course.name = [dictCourse objectForKey:@"name"];
        
        
        obj_Course.org = [dictCourse objectForKey:@"org"];
        obj_Course.video_outline = [dictCourse objectForKey:@"video_outline"];
        obj_Course.course_id = [dictCourse objectForKey:@"id"];
        obj_Course.number = [dictCourse objectForKey:@"number"];
        obj_Course.course_updates = [dictCourse objectForKey:@"course_updates"];
        obj_Course.course_handouts = [dictCourse objectForKey:@"course_handouts"];
        obj_Course.course_about = [dictCourse objectForKey:@"course_about"];
        
        
        // assigning the object to memeber of its parent level object class
        obj_usercourse.course = obj_Course;
        
        
        // Inner LatestUpdate dictionary parse
        // parse level - 3
        
        NSDictionary *dictlatestupdate = [dictCourse objectForKey:@"latest_updates"];
        OEXLatestUpdates *obj_LatestUpdate = [[OEXLatestUpdates alloc] init];
        obj_LatestUpdate.video = [dictlatestupdate objectForKey:@"video"];
        
        // assigning the object to memeber of the parent level object class
        obj_Course.latest_updates = obj_LatestUpdate;
        
        
        // check start date is greater than current date
        
        obj_Course.isStartDateOld = [appD isDateOld:[dictCourse objectForKey:@"start"]];
        
        
       
        if ([obj_Course.end length]>0)
            obj_Course.isEndDateOld = [appD isDateOld:[dictCourse objectForKey:@"end"]];
        
        
        // array populated with objects and returned
        if (obj_usercourse.is_active)
        {
            [arr_CourseEnrollmentObjetcs addObject:obj_usercourse];
        }
        
        
    }
    
    return arr_CourseEnrollmentObjetcs;
}

- (NSDictionary*)getVideoSummaryList:(NSData *)receivedData ForURLString:(NSString *)URLString
{
    
    /*
    [ {
        "section_url":"http://mobile3.m.sandbox.edx.org/courses/HarvardX/AmPoX.1/2014_T3/courseware/b5ec7e78a16c4391860d0f42ef489d01/baff5efb14644722a4c955fd10e81639/",
        "path":[
                    {
                        "category":"chapter",
                        "name":"Week 0: User's guide ",
                        "id":"i4x://HarvardX/AmPoX.1/chapter/b5ec7e78a16c4391860d0f42ef489d01"
                    },
                    {
                        "category":"sequential",
                        "name":"About This Course",
                        "id":"i4x://HarvardX/AmPoX.1/sequential/baff5efb14644722a4c955fd10e81639"
                    },
                    {
                        "category":"vertical",
                        "name":"About Poetry in America",
                        "id":"i4x://HarvardX/AmPoX.1/vertical/48faa0d4309f4e49bbdb74fc35019cd5"
                    }
                ],
        "unit_url":"http://mobile3.m.sandbox.edx.org/courses/HarvardX/AmPoX.1/2014_T3/courseware/b5ec7e78a16c4391860d0f42ef489d01/baff5efb14644722a4c955fd10e81639/1",
        "named_path":[
                      "Week 0: User's guide ",
                      "About This Course"
                      ],
        "summary":{
            "category":"video",
            "video_thumbnail_url":null,
            "language":"en",
            "name":"Introduction to Poetry in America",
            "video_url":"http://edx-course-videos.s3.amazonaws.com/HARAMPX1/HARAMPX1T314-V006100_MB2.mp4",
            "duration":1224.74,
            "transcripts":{
                "en":"http://mobile3.m.sandbox.edx.org/api/mobile/v0.5/video_outlines/transcripts/HarvardX/AmPoX.1/2014_T3/c1d1047455d44f939d2c0185daf94075/en"
            },
            "id":"i4x://HarvardX/AmPoX.1/video/c1d1047455d44f939d2c0185daf94075",
            "size":81154761
        }
    }
     ]
     
     */
    
    
    
//    NSString *response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
//    NSLog(@"\n\n\n\ngetVideoSummaryList Response \n %@ ",response);
    
    [appD.dict_VideoSummary removeObjectForKey:URLString];
    
    NSMutableArray *arrSummary = [[NSMutableArray alloc] init];
    
    
    NSError *error;
    NSArray *arrResponse = [NSJSONSerialization JSONObjectWithData:receivedData options:0 error:&error];
    
    for (NSDictionary *dict in arrResponse)
    {
        if (![dict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        NSDictionary *dictResponse = [dict oex_replaceNullsWithEmptyStrings];
        OEXVideoSummary *summaryList = [[OEXVideoSummary alloc] initWithDictionary:dictResponse];
        if(summaryList.chapterPathEntry.entryID != nil && summaryList.sectionPathEntry.entryID != nil) {
            [arrSummary addObject:summaryList];
        }
    }
    
    [appD.dict_VideoSummary setObject:arrSummary forKey:URLString];
    
    return appD.dict_VideoSummary;
}


- (NSString *)getOpenInBrowserLink
{
    
    NSString *str_link = [[NSString alloc] init];
    for (OEXVideoSummary *objVideo in [appD.dict_VideoSummary objectForKey:appD.str_COURSE_OUTLINE_URL])
    {
        str_link = objVideo.sectionURL;
    }
    
    return str_link;
}


- (NSArray*)chaptersForURLString:(NSString *)URL
{
    // To get all the chapter data
    NSMutableArray *chapterEntries = [[NSMutableArray alloc] init];
    
    for (OEXVideoSummary *objVideo in [appD.dict_VideoSummary objectForKey:URL])
    {
        OEXVideoPathEntry* chapterPathEntry = objVideo.chapterPathEntry;
        if (![chapterEntries containsObject:chapterPathEntry]) {
            [chapterEntries oex_safeAddObject: chapterPathEntry];
        }
    }
    
    return chapterEntries;
}


- (NSArray*)sectionsForChapterID:(NSString *)chapterID URLString:(NSString *)URL
{
    // To get the sections for the given chapter name
    NSMutableArray *sectionEntries = [[NSMutableArray alloc] init];
    
    for (OEXVideoSummary *objVideo in [appD.dict_VideoSummary objectForKey:URL])
    {
        OEXVideoPathEntry* chapterEntry = objVideo.chapterPathEntry;
        if ([chapterEntry.entryID isEqualToString:chapterID]) {
            OEXVideoPathEntry* sectionEntry = objVideo.sectionPathEntry;
            if (![sectionEntries containsObject:sectionEntry]) {
                [sectionEntries addObject: sectionEntry];
            }
            
        }
    }
    
    return sectionEntries;
}



#pragma mark - Return video objects of a course

- (NSMutableArray *)getVideosOfCourseWithURLString:(NSString *)URL
{
    // Get the data from the URL
    NSData * data = [_dataInterface resourceDataForURLString:URL downloadIfNotAvailable:NO];
    if (data)
    {
        OEXDataParser *objparser = [[OEXDataParser alloc] initWithDataInterface:_dataInterface];
        [objparser getVideoSummaryList:data ForURLString:URL];
    }
    else
        [_dataInterface downloadWithRequestString:URL forceUpdate:YES];
    
    // Return this array of course video objects.
    NSMutableArray *arr_Videos = [[NSMutableArray alloc] init];
    
    for (OEXVideoSummary *objVideo in [appD.dict_VideoSummary objectForKey:URL])
    {
        OEXHelperVideoDownload *obj_helperVideo = [[OEXHelperVideoDownload alloc] init];
        obj_helperVideo.summary = objVideo;
        obj_helperVideo.filePath = [OEXFileUtility completeFilePathForUrl:obj_helperVideo.summary.videoURL];
        
        [arr_Videos addObject:obj_helperVideo];
    }
    
    return arr_Videos;
}



@end
