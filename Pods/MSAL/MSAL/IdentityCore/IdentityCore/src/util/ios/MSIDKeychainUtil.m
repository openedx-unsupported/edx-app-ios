// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MSIDKeychainUtil.h"
#import "MSIDKeychainUtil+Internal.h"

@implementation MSIDKeychainUtil

#pragma mark - Public

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.teamId = [self getTeamId];
    }
    
    return self;
}

+ (MSIDKeychainUtil *)sharedInstance
{
    static MSIDKeychainUtil *singleton = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    
    return singleton;
}

- (NSString *)getTeamId
{
    NSString *keychainTeamId = nil;
    NSString *accessGroup = [self appDefaultAccessGroup];
    NSArray *components = [accessGroup componentsSeparatedByString:@"."];
    NSString *bundleSeedID = [components firstObject];
    keychainTeamId = [bundleSeedID length] ? bundleSeedID : nil;
    
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, nil, @"Using \"%@\" Team ID.", MSID_PII_LOG_MASKABLE(keychainTeamId));
    
    return keychainTeamId;
}

- (NSString *)appDefaultAccessGroup
{
    static dispatch_once_t once;
    static NSString *appDefaultAccessGroup = nil;
    
    dispatch_once(&once, ^{
        NSDictionary *query = @{ (id)kSecClass : (id)kSecClassGenericPassword,
                                 (id)kSecAttrAccount : @"SDK.ObjC.teamIDHint",
                                 (id)kSecAttrService : @"",
                                 (id)kSecReturnAttributes : @YES };
        CFDictionaryRef result = nil;
        
        OSStatus readStatus = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);

        if (readStatus == errSecInteractionNotAllowed)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Encountered an error when reading teamIDHint in keychain. Keychain status %ld", (long)readStatus);

            OSStatus deleteStatus = SecItemDelete((__bridge CFDictionaryRef)query);
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Deleted existing teamID");

            if (deleteStatus != errSecSuccess)
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to delete teamID, result %ld", (long)deleteStatus);
                return;
            }
        }

        OSStatus status = readStatus;
        
        if (readStatus == errSecItemNotFound
            || readStatus == errSecInteractionNotAllowed)
        {
            NSMutableDictionary* addQuery = [query mutableCopy];
#if TARGET_OS_MACCATALYST
            [addQuery setObject:(id)kSecAttrAccessibleAfterFirstUnlock forKey:(id)kSecAttrAccessible];
#else
            [addQuery setObject:(id)kSecAttrAccessibleAlways forKey:(id)kSecAttrAccessible];
#endif
            status = SecItemAdd((__bridge CFDictionaryRef)addQuery, (CFTypeRef *)&result);
        }
        
        if (status == errSecSuccess)
        {
            appDefaultAccessGroup = [(__bridge NSDictionary *)result objectForKey:(__bridge id)(kSecAttrAccessGroup)];
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, nil, @"Default app's access group: \"%@\".", MSID_PII_LOG_MASKABLE(appDefaultAccessGroup));
            
            CFRelease(result);
        }
        else
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Encountered an error when reading teamIDHint in keychain. Keychain status %ld, read status %ld", (long)status, (long)readStatus);
        }
    });
    
    return appDefaultAccessGroup;
}

- (NSString *)accessGroup:(NSString *)group
{
    if (!group)
    {
        return nil;
    }
    
    if (!self.teamId)
    {
        return nil;
    }
    
#if TARGET_OS_SIMULATOR
    // In simulator team id can be "FAKETEAMID" (for example in UT without host app).
    if ([self.teamId isEqualToString:@"FAKETEAMID"])
    {
        return [self appDefaultAccessGroup];
    }
#endif
    
    return [[NSString alloc] initWithFormat:@"%@.%@", self.teamId, group];
}

@end

