//
//  OEXKeychainAccess.m
//  edXVideoLocker
//
//  Created by Abhradeep on 20/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXKeychainAccess.h"
#import "OEXAccessToken.h"
#import "OEXUserDetails.h"
#import <Security/Security.h>
#define kAccessTokenKey @"kAccessTokenKey"
#define kUserDetailsKey @"kUserDetailsKey"
#define kCredentialsService @"kCredentialsService"

@interface OEXKeychainAccess (){
    
}

- (NSMutableDictionary *)getKeychainQuery:(NSString *)service;
- (void)saveService:(NSString *)service data:(id)data;
- (id)loadService:(NSString *)service;
- (void)deleteService:(NSString *)service;

@end

@implementation OEXKeychainAccess

+ (instancetype)sharedKeychainAccess {
    static dispatch_once_t onceToken;
    static OEXKeychainAccess* sharedKeychainAccess = nil;
    dispatch_once(&onceToken, ^{
        sharedKeychainAccess = [[OEXKeychainAccess alloc] init];
    });
    return sharedKeychainAccess;
}

-(void)startSessionWithAccessToken:(OEXAccessToken *)accessToken userDetails:(OEXUserDetails *)userDetails{
    NSData *accessTokenData = [accessToken accessTokenData];
    NSData *userDetailsData=[userDetails userDetailsData];
    if(accessTokenData && userDetailsData){
        [self endSession];
        NSDictionary *sessionDictionary = @{kAccessTokenKey:accessTokenData, kUserDetailsKey:userDetailsData};
        [self saveService:kCredentialsService data:sessionDictionary];
    }
}

-(void)endSession{
    [self deleteService:kCredentialsService];
}

-(OEXAccessToken *)storedAccessToken{
    return [OEXAccessToken accessTokenWithData:[[self loadService:kCredentialsService] objectForKey:kAccessTokenKey]];
}

-(OEXUserDetails *)storedUserDetails{
    return [OEXUserDetails userDetailsWithData:[[self loadService:kCredentialsService] objectForKey:kUserDetailsKey]];

}

- (void)saveService:(NSString *)service data:(id)data {
    OSStatus result;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:(__bridge id)kSecValueData];
    result=SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
#ifdef DEBUG
     NSAssert(result==noErr, @"Could not add credential to keychain");
#endif
    
}

- (id)loadService:(NSString *)service {
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        }
        @catch (NSException *e) {
            NSLog(@"Unarchive of %@ failed: %@", service, e);
        }
        @finally {}
    }
    if (keyData){
        CFRelease(keyData);
    }
    return ret;
}

- (void)deleteService:(NSString *)service {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
}

- (NSMutableDictionary *)getKeychainQuery:(NSString *)service {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
            service, (__bridge id)kSecAttrService,
            service, (__bridge id)kSecAttrAccount,
            (__bridge id)kSecAttrAccessibleAfterFirstUnlock, (__bridge id)kSecAttrAccessible,
            nil];
}

@end
