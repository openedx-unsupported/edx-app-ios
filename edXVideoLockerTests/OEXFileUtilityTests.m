//
//  OEXFileUtilityTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface OEXFileUtilityTests : XCTestCase

@property (copy, nonatomic) NSString* username;

@end

@implementation OEXFileUtilityTests

- (void)setUp {
    self.username = [NSUUID UUID].UUIDString;
}

- (void)tearDown {
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[OEXFileUtility pathForUserNameCreatingIfNecessary:self.username] error:&error];
    XCTAssertNil(error);
}

- (BOOL)pathIsExcludedFromBackup:(NSString*)path {
    NSError* error = nil;
    NSDictionary* values = [[NSURL fileURLWithPath:path] resourceValuesForKeys:@[NSURLIsExcludedFromBackupKey] error:&error];
    XCTAssertNil(error);
    return [values[NSURLIsExcludedFromBackupKey] boolValue];
}

- (void)testUserDirectoryMigration {
    NSString* legacyDirectory = [OEXFileUtility t_legacyPathForUserName:self.username];
    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:legacyDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    XCTAssertNil(error);
    
    NSString* directory = [OEXFileUtility pathForUserNameCreatingIfNecessary:self.username];
    
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:legacyDirectory]);
    XCTAssertTrue([self pathIsExcludedFromBackup:directory]);
}

- (void)testUserDirectoryCreation {
    NSString* directory = [OEXFileUtility pathForUserNameCreatingIfNecessary:self.username];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:directory]);
    XCTAssertTrue([self pathIsExcludedFromBackup:directory]);
}

- (void)testUserDirectoryAlreadyExists {
    NSString* existingPath = [OEXFileUtility t_pathForUserName:self.username];
    // shouldn't affect anything
    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:existingPath withIntermediateDirectories:YES attributes:nil error:&error];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:existingPath]);
    XCTAssertNil(error);
    
    NSString* path = [OEXFileUtility pathForUserNameCreatingIfNecessary:self.username];
    XCTAssertEqualObjects(existingPath, path);
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path]);
    
    XCTAssertTrue([self pathIsExcludedFromBackup:path]);
}


@end
