//
//  LastAccessed.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 27/11/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

@import CoreData;

@interface LastAccessed : NSManagedObject

@property (nonatomic, retain, nullable) NSString* timestamp;
@property (nonatomic, retain, nullable) NSString* subsection_id;
@property (nonatomic, retain, nullable) NSString* course_id;
@property (nonatomic, retain, nullable) NSString* subsection_name;

@end
