//
//  OEXFileUtility.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 14/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXFileUtility.h"
#import "OEXUserDetails.h"
#import "OEXSession.h"
#pragma mark JSON Data

@implementation OEXFileUtility

+ (NSData*)dataForURLString:(NSString*)URLString {
    NSString* filePath = [OEXFileUtility completeFilePathForUrl:URLString];

    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData* data = [NSData dataWithContentsOfFile:filePath];
        return data;
    }
    return nil;
}

+ (NSData*)resumeDataForURLString:(NSString*)URLString {
    NSString* filePath = [OEXFileUtility completeFilePathForUrl:URLString];

    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData* data = [NSData dataWithContentsOfFile:filePath];
        return data;
    }
    return nil;
}

+ (void)updateData:(NSData*)data ForURLString:(NSString*)URLString {
    //File path
    NSString* filePath = [OEXFileUtility completeFilePathForUrl:URLString];
    [OEXFileUtility writeData:data atFilePath:filePath];
}

// This is purely for migration
// Do not use unless you are deliberately planning to add files that persist through backups
+ (NSString*)documentsPath {
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return path;
}

+ (NSString*)applicationSupportPath {
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    return path;
}

// We used to save files here. However, according to the documentation marking files in Documents
// as not to be backed up does not work right. Since our data is not meant to be backed up
// since it all syncs from the server anyway, we no longer use this folder
+ (NSString*)legacySavedFilesRootPath {
    return [self documentsPath];
}

+ (NSString*)savedFilesRootPath {
    return [self applicationSupportPath];
}

+ (NSString*)pathForUserName:(NSString*)userName {
    return [[OEXFileUtility savedFilesRootPath] stringByAppendingPathComponent:userName];
}

+ (NSString*)pathForUserNameCreatingIfNecessary:(NSString*)userName {
    if(userName == nil) {
        return nil;
    }
    NSString* userDirectory = [self pathForUserName:userName];

    NSFileManager* fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:userDirectory]) {
        NSError* error = nil;
        NSString* legacyUserDirectory = [[OEXFileUtility legacySavedFilesRootPath] stringByAppendingPathComponent:userName];

        // We used to store our files in a different location
        // Before creating a folder, check if we have a legacy one we can just move
        if([fileManager fileExistsAtPath:legacyUserDirectory]) {
            if(![fileManager moveItemAtPath:legacyUserDirectory toPath:userDirectory error:&error]) {
                NSAssert(NO, @"Error migrating user directory: %@", error);
            }
        }
        if(![fileManager createDirectoryAtPath:userDirectory
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&error]) {
            NSAssert(NO, @"Error creating user directory: %@", error);
        }
    }

    NSError* error = nil;
    if(![[NSURL fileURLWithPath:userDirectory]
         setResourceValue: @YES forKey: NSURLIsExcludedFromBackupKey error: &error]) {
        ELog(@"ERROR : On disabling backup : %@", [error description]);
    }
    return userDirectory;
}

+ (NSString*)userDirectory {
    return [self pathForUserNameCreatingIfNecessary:[[OEXSession sharedSession] currentUser].username];
}

+ (NSString*)completeFilePathForUrl:(NSString*)url {
    return [self completeFilePathForUrl:url userName:[[OEXSession sharedSession] currentUser].username];
}

+ (NSString*)completeFilePathForUrl:(NSString*)url userName:(NSString*)username {
    if(username != nil) {
        NSString* userPath = [self pathForUserNameCreatingIfNecessary:username];
        NSString* tail = [NSString stringWithFormat:@"Videos/%lu", (unsigned long)[url hash]];
        return [userPath stringByAppendingPathComponent:tail];
    }
    return nil;
}

+ (BOOL )writeData:(NSData*)data atFilePath:(NSString*)filePath {
    //check if file already exists, delete it
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError* error;
        if([[NSFileManager defaultManager] isDeletableFileAtPath:filePath]) {
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if(!success) {
                //NSLog(@"Error removing file at path: %@", error.localizedDescription);
            }
        }
    }

    //write new file
    if(![data writeToFile:filePath atomically:YES]) {
        ELog(@"There was a problem saving resume data to file ==>> %@", filePath);
        return NO;
    }

    return YES;
}

+ (NSString*)localFilePathForVideoUrl:(NSString*)videoUrl {
    NSString* filepath = [[OEXFileUtility completeFilePathForUrl:videoUrl] stringByAppendingPathExtension:@"mp4"];

    return filepath;
}

@end

@implementation OEXFileUtility (Testing)

+ (NSString*)t_legacyPathForUserName:(NSString*)userName {
    return [[OEXFileUtility legacySavedFilesRootPath] stringByAppendingPathComponent:userName];
}

+ (NSString*)t_pathForUserName:(NSString*)userName {
    return [self pathForUserName:userName];
}

@end