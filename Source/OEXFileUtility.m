//
//  OEXFileUtility.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 14/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXFileUtility.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "OEXUserDetails.h"
#import "OEXSession.h"
#import "NSString+OEXCrypto.h"

@implementation OEXFileUtility

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
// WARNING: DO NOT ADD NEW USES
+ (NSString*)legacySavedFilesRootPath {
    return [self documentsPath];
}

+ (NSString*)savedFilesRootPath {
    return [self applicationSupportPath];
}

+ (NSString*)pathForUserName:(NSString*)userName {
    NSString *userNewPath = [[OEXFileUtility savedFilesRootPath] stringByAppendingPathComponent:userName.oex_md5];
    if (![[NSFileManager defaultManager] fileExistsAtPath:userNewPath]) {
        NSString *oldPath = [[OEXFileUtility savedFilesRootPath] stringByAppendingPathComponent:userName];
        if([[NSFileManager defaultManager] fileExistsAtPath:oldPath]) {
            NSError* error = nil;
            if(![[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:userNewPath error:&error]) {
                NSAssert(error == nil, @"Error migrating file");
            }
        }
    }
    
    return userNewPath;
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
        OEXLogError(@"STORAGE", @"Error disabling backup : %@", [error description]);
    }
    return userDirectory;
}

+ (NSString*)userDirectory {
    return [self pathForUserNameCreatingIfNecessary:[[OEXSession sharedSession] currentUser].username];
}

+ (NSString*)filePathForRequestKey:(NSString*)url {
    return [self filePathForRequestKey:url username:[[OEXSession sharedSession] currentUser].username];
}

+ (NSString*)filePathForRequestKey:(NSString*)url username:(NSString*)username {
    if(username != nil && url != nil) {
        NSString* userPath = [self pathForUserNameCreatingIfNecessary:username];
        NSString* containerPath = [userPath stringByAppendingPathComponent:@"Responses"];
        
        NSError* error = nil;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:containerPath withIntermediateDirectories:YES attributes:nil error:&error] ) {
            NSAssert(!error, @"Error creating directory: %@", error.localizedDescription);
        }
        
        NSString* totalPath = [containerPath stringByAppendingPathComponent:url.oex_md5];
        
        // We used to use just the regular old Cocoa hash function for file paths.
        // This is not a good idea since that makes no guarantees about likelihood of collisions
        // or whether it will change. It's also different on different architectures.
        
        
        // we were using Videos path to save downloaded videos but later decided to move videos to responses folder.
        // Now the migration of videos is completed from "Videos" to "Resources" so removing videos folder
        NSString* videosPath = [userPath stringByAppendingPathComponent:@"Videos"];
        if([[NSFileManager defaultManager] fileExistsAtPath:videosPath]) {
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:videosPath error:&error];
            if (!success) {
                NSAssert(!success, @"Error deleting videos directory: %@", error.localizedDescription);
            }
        }
        
        
        return totalPath;
    }
    return nil;
}

+ (NSURL*)fileURLForRequestKey:(NSString*)key username:(NSString*)username {
    NSString* path = [self filePathForRequestKey:key username:username];
    if(path == nil) {
        return nil;
    }
    else {
        return [NSURL fileURLWithPath:[self filePathForRequestKey:key username:username]];
    }
}


+ (NSString*)filePathForVideoURL:(NSString*)videoUrl username:(nullable NSString *)username {
    NSString* filepath = [[OEXFileUtility filePathForRequestKey:videoUrl username:username] stringByAppendingPathExtension:@"mp4"];
    return filepath;
}

+ (void)nukeUserData {
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[self savedFilesRootPath] error:&error];
    NSAssert(error == nil || error.code == NSFileNoSuchFileError, @"Error nuking all user data");
}

+ (void) nukeUserPIIData {
    [OEXFileUtility deleteUserFilesExceptVideos:[self pathForUserName:[[OEXSession sharedSession] currentUser].username]];
}

+ (void) deleteUserFilesExceptVideos:(NSString *) directory {
    BOOL isDirectory = NO;
    NSError* error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *filesList= [fileManager contentsOfDirectoryAtPath:directory error:nil];
    for (NSString *file in filesList) {
        NSString *completePath = [directory stringByAppendingPathComponent:file];
        BOOL isFileExist = [fileManager fileExistsAtPath:completePath isDirectory:&isDirectory];
        if (isFileExist && isDirectory) {
            [OEXFileUtility deleteUserFilesExceptVideos:completePath];
        }
        else {
            if ([OEXFileUtility canDeleteFile:file]) {
                [[NSFileManager defaultManager] removeItemAtPath:completePath error:&error];
            }
        }
    }
    
     NSAssert(error == nil || error.code == NSFileNoSuchFileError, @"Error nuking all user data");
}

+ (BOOL) canDeleteFile:(NSString *) file {
    NSString *fileExtension = [[file pathExtension] lowercaseString];
    if ([fileExtension isEqualToString:@"mp4"] || [fileExtension containsString:@"sqlite"]) {
        return NO;
    }
    
    return YES;
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
