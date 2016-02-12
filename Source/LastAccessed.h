//
//  LastAccessed.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 27/11/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

@import CoreData;

NS_ASSUME_NONNULL_BEGIN

@interface LastAccessed : NSManagedObject

@property (nonatomic, retain, nullable) NSString* timestamp;
@property (nonatomic, retain, nullable) NSString* subsection_id;
@property (nonatomic, retain, nullable) NSString* course_id;
@property (nonatomic, retain, nullable) NSString* subsection_name;

@end

NS_ASSUME_NONNULL_END
