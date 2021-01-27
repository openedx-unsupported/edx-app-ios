//
//  OEXPersistentCredentialStorage.m
//  edXVideoLocker
//
//  Created by Abhradeep on 20/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXPersistentCredentialStorage.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "OEXAccessToken.h"
#import "OEXUserDetails.h"

#import <Security/Security.h>

#define kAccessTokenKey @"kAccessTokenKey"
#define kUserDetailsKey @"kUserDetailsKey"
#define kCredentialsService @"kCredentialsService"

@implementation OEXPersistentCredentialStorage

+ (instancetype)sharedKeychainAccess {
    static dispatch_once_t onceToken;
    static OEXPersistentCredentialStorage* sharedKeychainAccess = nil;
    dispatch_once(&onceToken, ^{
        sharedKeychainAccess = [[OEXPersistentCredentialStorage alloc] init];
    });
    return sharedKeychainAccess;
}

- (void)saveAccessToken:(OEXAccessToken*)accessToken userDetails:(OEXUserDetails*)userDetails {
    NSData* accessTokenData = [accessToken accessTokenData];
    NSData* userDetailsData = [userDetails userDetailsData];
    NSDictionary* sessionDictionary = @{kAccessTokenKey:accessTokenData, kUserDetailsKey:userDetailsData};
    [self saveService:kCredentialsService data:sessionDictionary];
}

- (void)clear {
    [self deleteService:kCredentialsService];
    
    NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for(NSHTTPCookie* cookie in [cookieStorage cookies]) {
        [cookieStorage deleteCookie:cookie];
    }
    
    NSURLCredentialStorage* credentialStorage = [NSURLCredentialStorage sharedCredentialStorage];
    NSDictionary* allCredentials = credentialStorage.allCredentials;
    for(NSURLProtectionSpace* space in allCredentials.allKeys) {
        NSDictionary* spaceCredentials = allCredentials[space];
        for(NSURLCredential* credential in spaceCredentials.allValues) {
            [credentialStorage removeCredential:credential forProtectionSpace:space];
        }
    }
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (OEXAccessToken*)storedAccessToken {
    return [OEXAccessToken accessTokenWithData:[[self loadService:kCredentialsService] objectForKey:kAccessTokenKey]];
}

- (OEXUserDetails*)storedUserDetails {
    NSData* data = [[self loadService:kCredentialsService] objectForKey:kUserDetailsKey];
    if(data && [data isKindOfClass:[NSData class]]) {
        return [[OEXUserDetails alloc] initWithUserDetailsData:data];
    }
    else {
        return nil;
    }
}

- (void)saveService:(NSString*)service data:(id)data {
    OSStatus result;
    NSMutableDictionary* keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data requiringSecureCoding:NO error:nil] forKey:(__bridge id)kSecValueData];
    result = SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
#ifdef DEBUG
    NSAssert(result == noErr, @"Could not add credential to keychain");
#endif
}

- (id)loadService:(NSString*)service {
    id ret = nil;
    NSMutableDictionary* keychainQuery = [self getKeychainQuery:service];
    [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if(SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef*)&keyData) == noErr) {
        // TODO: Replace this with code that doesn't raise and swallow exceptions
        @try {
            ret = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSString class] fromData:(__bridge NSData*)keyData error:nil];
        }
        @catch(NSException* e) {
            OEXLogInfo(@"STORAGE", @"Unarchive of %@ failed: %@", service, e);
        }
        @finally {}
    }
    if(keyData) {
        CFRelease(keyData);
    }
    return ret;
}

- (void)deleteService:(NSString*)service {
    NSMutableDictionary* keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
}

- (NSMutableDictionary*)getKeychainQuery:(NSString*)service {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
            service, (__bridge id)kSecAttrService,
            service, (__bridge id)kSecAttrAccount,
            (__bridge id)kSecAttrAccessibleAfterFirstUnlock, (__bridge id)kSecAttrAccessible,
            nil];
}

@end
