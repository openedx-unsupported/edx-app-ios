//
//  OEXMetaClassHelpers.h
//  edX
//
//  Created by Akiva Leffert on 4/6/16.
//  Copyright © 2016 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXMetaClassHelpers : NSObject

// Calls the no argument init method of the class with the given name
// Should really only be used for testing or debugging
+ (id)instanceOfClassNamed:(NSString*)name;

@end
