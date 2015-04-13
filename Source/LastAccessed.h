//
//  LastAccessed.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 27/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface LastAccessed : NSManagedObject

@property (nonatomic, retain) NSString* timestamp;
@property (nonatomic, retain) NSString* subsection_id;
@property (nonatomic, retain) NSString* course_id;
@property (nonatomic, retain) NSString* subsection_name;

@end
