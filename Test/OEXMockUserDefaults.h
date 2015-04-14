//
//  OEXMockUserDefaults.h
//  edX
//
//  Created by Akiva Leffert on 4/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>


// Simplified version of NSUserDefaults for testing that does not persist its data
@interface OEXMockUserDefaults : NSObject

// Only supports objects for now, but we should add the wrappers from NSUserDefaults as we need them
- (id)objectForKey:(NSString*)key;
- (void)setObject:(id)object forKey:(NSString*)key;

- (void)synchronize;

@end
