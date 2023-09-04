//
//  OEXFileUtility+TestAdditions.h
//  edX
//
//  Created by Akiva Leffert on 3/4/16.
//  Copyright © 2016 edX. All rights reserved.
//

#import "OEXFileUtility.h"

@interface OEXFileUtility (TestAdditions)

+ (void)routeUserDataToTempPath;
+ (NSString*)testDataPath;

@end
