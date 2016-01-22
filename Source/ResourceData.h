//
//  ResourceData.h
//  TestCore
//
//  Created by Rahul Varma on 12/11/14.
//  Copyright (c) 2014-2016 edX, Inc. All rights reserved.
//

@import CoreData;

NS_ASSUME_NONNULL_BEGIN

@interface ResourceData : NSManagedObject

@property (nonatomic, retain) NSDate* downloadCompleteDate;
@property (nonatomic, retain) NSNumber* downloadState;
@property (nonatomic, retain) NSNumber* lastPlayedProgress;
@property (nonatomic, retain) NSNumber* playedState;
@property (nonatomic, retain) NSString* resourceDownloadURL;
@property (nonatomic, retain) NSString* resourceTitle;
@property (nonatomic, retain) NSString* resource_id;

// Do not start using this. It may have bad data, since we were storing paths
// we no longer use. We should remove it next time we do a core data migration
@property (nonatomic, retain) NSString* resourceFilePath __deprecated;

@end

NS_ASSUME_NONNULL_END
