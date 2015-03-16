//
//  ResourceData.h
//  TestCore
//
//  Created by Rahul Varma on 12/11/14.
//  Copyright (c) 2014 edX, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ResourceData : NSManagedObject

@property (nonatomic, retain) NSDate* downloadCompleteDate;
@property (nonatomic, retain) NSNumber* downloadState;
@property (nonatomic, retain) NSNumber* lastPlayedProgress;
@property (nonatomic, retain) NSNumber* playedState;
@property (nonatomic, retain) NSString* resourceDownloadURL;
@property (nonatomic, retain) NSString* resourceFilePath;
@property (nonatomic, retain) NSString* resourceTitle;
@property (nonatomic, retain) NSString* resource_id;

@end
