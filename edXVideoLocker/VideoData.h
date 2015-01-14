//
//  VideoData.h
//  TestCore
//
//  Created by Rahul Varma on 12/11/14.
//  Copyright (c) 2014 Clarice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface VideoData : NSManagedObject

@property (nonatomic, retain) NSString * chapter_name;
@property (nonatomic, retain) NSNumber * dm_id;
@property (nonatomic, retain) NSNumber * download_state;
@property (nonatomic, retain) NSDate * downloadCompleteDate;
@property (nonatomic, retain) NSString * duration;
@property (nonatomic, retain) NSString * enrollment_id;
@property (nonatomic, retain) NSString * filepath;
@property (nonatomic, retain) NSNumber * is_registered;
@property (nonatomic, retain) NSNumber * last_played_offset;
@property (nonatomic, retain) NSNumber * played_state;
@property (nonatomic, retain) NSString * section_name;
@property (nonatomic, retain) NSString * size;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * unit_url;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * video_id;
@property (nonatomic, retain) NSString * video_url;

@end
