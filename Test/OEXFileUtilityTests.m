//
//  OEXFileUtilityTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NSArray+OEXFunctional.h"
#import "OEXFileUtility.h"

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

- (void)testNilPath {
    XCTAssertNil([OEXFileUtility pathForUserNameCreatingIfNecessary:nil]);
    XCTAssertNil([OEXFileUtility filePathForRequestKey:nil]);
    XCTAssertNil([OEXFileUtility filePathForRequestKey:nil username:self.username]);
    XCTAssertNil([OEXFileUtility filePathForRequestKey:@"foo" username:nil]);
    XCTAssertNil([OEXFileUtility fileURLForRequestKey:nil username:self.username]);
    XCTAssertNil([OEXFileUtility fileURLForRequestKey:@"foo" username:nil]);
    XCTAssertNil([OEXFileUtility fileURLForRequestKey:nil username:self.username]);
    XCTAssertNil([OEXFileUtility fileURLForRequestKey:@"foo" username:nil]);
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

- (void) testVideosDirectoryDeletion  {
    NSString *videosPath = [[OEXFileUtility t_pathForUserName:self.username] stringByAppendingPathComponent:@"Videos"];
    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:videosPath withIntermediateDirectories:YES attributes:nil error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:videosPath]);
    
    [[NSFileManager defaultManager] removeItemAtPath:videosPath error:&error];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:videosPath]);
    XCTAssertNil(error);
}


- (void)testUserDirectoryCreation {
    NSString* directory = [OEXFileUtility pathForUserNameCreatingIfNecessary:self.username];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:directory]);
    XCTAssertTrue([self pathIsExcludedFromBackup:directory]);
}

- (void)testUserDirectoryNoParent {
    // Do a little save and restore dance so that existing user data isn't affected
    // We need to not have /Application Support/ so we can make sure the user directory gets created properly
    // even if that's not there
    NSString* libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString* applicationSupportPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString* tempPath = [libraryPath stringByAppendingPathComponent:self.username];
    
    NSError* error = nil;
    [[NSFileManager defaultManager] moveItemAtPath:applicationSupportPath toPath:tempPath error:&error];
    XCTAssertNil(error);
    
    NSString* directory = [OEXFileUtility pathForUserNameCreatingIfNecessary:self.username];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:directory]);
    
    // Clean up by moving original directory back
    [[NSFileManager defaultManager] removeItemAtPath:applicationSupportPath error:&error];
    XCTAssertNil(error);
    [[NSFileManager defaultManager] moveItemAtPath:tempPath toPath:applicationSupportPath error:&error];
    XCTAssertNil(error);
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

- (void)testNukeData {
    NSArray<NSString*>* users = @[[NSUUID UUID].UUIDString, [NSUUID UUID].UUIDString, [NSUUID UUID].UUIDString];
    NSArray<NSString*>* paths = [users oex_map:^(NSString* user){
        return [OEXFileUtility pathForUserNameCreatingIfNecessary:user];
    }];

    [OEXFileUtility nukeUserData];

    for(NSString* path in paths) {
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:path]);
    }
}

@end
