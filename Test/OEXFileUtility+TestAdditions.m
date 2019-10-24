//
//  OEXFileUtility+TestAdditions.m
//  edX
//
//  Created by Akiva Leffert on 3/4/16.
//  Copyright © 2016 edX. All rights reserved.
//

#import "OEXFileUtility+TestAdditions.h"

#import "OEXFileUtility.h"
#import "OCMock.h"

@interface OEXFileUtility (TestExposure)

+ (NSString*)savedFilesRootPath;

@end

@implementation OEXFileUtility (TestAdditions)

+ (void)routeUserDataToTempPath {
    NSString* dataPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
    NSLog(@"Saving test data to path: %@", dataPath);
    id mock = OCMClassMock([OEXFileUtility class]);
    id stub = [mock stub];
    [stub savedFilesRootPath];
    [stub andReturn:dataPath];
}

+ (NSString*)testDataPath {
    return [self savedFilesRootPath];
}

@end
