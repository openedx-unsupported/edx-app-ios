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

// WARNING: DO NOT ADD NEW USES OF THIS.
// It is deprecated and should only be used for migrations.
+ (NSString*)legacyPathForURL:(NSString*)url userName:(NSString*)username creatingIfNecessary:(BOOL)create {
    NSString* userPath = [self pathForUserNameCreatingIfNecessary:username];
    NSString* containerPath = [userPath stringByAppendingPathComponent:@"Videos"];
    NSError* error = nil;
    if(create && ![[NSFileManager defaultManager] createDirectoryAtPath:containerPath withIntermediateDirectories:YES attributes:nil error:&error] ) {
        NSAssert(@"Error creating directory: %@", error.localizedDescription);
    }
    // XXX using ``hash`` for anything without then checking equality of the originals is bad
    NSString* totalPath = [containerPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu", (unsigned long)[url hash]]];
    return totalPath;
}

+ (NSString*)filePathForRequestKey:(NSString*)url username:(NSString*)username {
    if(username != nil && url != nil) {
        NSString* userPath = [self pathForUserNameCreatingIfNecessary:username];
        NSString* containerPath = [userPath stringByAppendingPathComponent:@"Responses"];
        
        NSError* error = nil;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:containerPath withIntermediateDirectories:YES attributes:nil error:&error] ) {
            NSAssert(@"Error creating directory: %@", error.localizedDescription);
        }
        
        NSString* totalPath = [containerPath stringByAppendingPathComponent:url.oex_md5];
        
        // We used to use just the regular old Cocoa hash function for file paths.
        // This is not a good idea since that makes no guarantees about likelihood of collisions
        // or whether it will change. It's also different on different architectures.
        
        // So if we still have a file using the old path, move it to an md5 based path.
        // Added 6/19/2015. Probably safe to remove this migration mid to late 2016.
        NSString* oldTotalPath = [self legacyPathForURL:url userName:username creatingIfNecessary:false];

        if([[NSFileManager defaultManager] fileExistsAtPath:oldTotalPath]) {
            NSError* error = nil;
            if(![[NSFileManager defaultManager] moveItemAtPath:oldTotalPath toPath:totalPath error:&error]) {
                NSAssert(error == nil, @"Error migrating file");
            }
        }
        
        // It used to be that videos specifically sometimes had .mp4 at the end of their paths
        // instead of just a hash. This handles that extra case, by looking at the old format
        // name file and migrating that as well.
        NSString* pathExtension = [url pathExtension];
        if(pathExtension.length > 0) {
            NSString* extendedOldTotalPath = [oldTotalPath stringByAppendingPathExtension:pathExtension];
            if([[NSFileManager defaultManager] fileExistsAtPath:extendedOldTotalPath]) {
                NSError* error = nil;
                if(![[NSFileManager defaultManager] moveItemAtPath:extendedOldTotalPath toPath:totalPath error:&error]) {
                    NSAssert(error == nil, @"Error migrating file");
                }
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

@end

@implementation OEXFileUtility (Testing)

+ (NSString*)t_legacyPathForUserName:(NSString*)userName {
    return [[OEXFileUtility legacySavedFilesRootPath] stringByAppendingPathComponent:userName];
}

+ (NSString*)t_pathForUserName:(NSString*)userName {
    return [self pathForUserName:userName];
}

+ (NSString*)t_legacyPathForURL:(NSString*)url userName:(NSString*)userName {
    return [self legacyPathForURL:url userName:userName creatingIfNecessary:true];
}

@end