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

#import "MSIDAssymetricKeyKeychainGenerator.h"
#import "MSIDKeychainUtil.h"
#import "MSIDAssymetricKeyPair.h"
#import "MSIDAssymetricKeyLookupAttributes.h"

static const OSStatus kNoStatus = -1;

@interface MSIDAssymetricKeyKeychainGenerator()

@property (nonatomic) NSString *keychainGroup;
@property (nonatomic) NSDictionary *defaultKeychainQuery;

@end

@implementation MSIDAssymetricKeyKeychainGenerator

#pragma mark - Init

- (nullable instancetype)initWithGroup:(nullable NSString *)keychainGroup error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    if (!keychainGroup)
    {
        keychainGroup = [[NSBundle mainBundle] bundleIdentifier];
    }
    
    MSIDKeychainUtil *keychainUtil = [MSIDKeychainUtil sharedInstance];
    if (!keychainUtil.teamId)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Failed to retrieve teamId from keychain.", nil, nil, nil, nil, nil, YES);
        }
        
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to retrieve teamId from keychain.");
        return nil;
    }
    
    // Add team prefix to keychain group if it is missed.
    if (![keychainGroup hasPrefix:keychainUtil.teamId])
    {
        keychainGroup = [keychainUtil accessGroup:keychainGroup];
    }
    
    _keychainGroup = keychainGroup;
    
    if (!_keychainGroup)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Failed to set keychain access group.", nil, nil, nil, nil, nil, YES);
        }
        
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to set keychain access group.");
        return nil;
    }
    
    NSMutableDictionary *defaultKeychainQuery = [@{(id)kSecAttrAccessGroup : self.keychainGroup} mutableCopy];
    [defaultKeychainQuery addEntriesFromDictionary:[self additionalPlatformKeychainAttributes]];
    
    self.defaultKeychainQuery = defaultKeychainQuery;
    return self;
}

#pragma mark - MSIDAssymetricKeyGenerating

- (MSIDAssymetricKeyPair *)generateKeyPairForAttributes:(MSIDAssymetricKeyLookupAttributes *)attributes
                                                  error:(NSError **)error
{
    if ([NSString msidIsStringNilOrBlank:attributes.privateKeyIdentifier])
    {
        [self logAndFillError:@"Invalid key generation attributes provided" status:kNoStatus error:error];
        return nil;
    }
    
    // 0. Cleanup any previous state
    BOOL cleanupResult = [self deleteItemWithAttributes:[attributes privateKeyAttributes] error:error];
    if (!cleanupResult)
    {
        MSID_LOG_WITH_CTX(
            MSIDLogLevelError,
            nil,
            @"Failed to cleanup keychain prior to generating new keypair. Proceeding may produce in unexpected results. Keychain may need to be manually cleaned to recover.");
        return nil;
    }
    
    // 1. Generate keypair
    NSDictionary *keyPairAttr = [self keychainQueryWithAttributes:[attributes assymetricKeyPairAttributes]];
    return [self generateKeyPairForKeyDict:keyPairAttr error:error];
}

- (MSIDAssymetricKeyPair *)readOrGenerateKeyPairForAttributes:(MSIDAssymetricKeyLookupAttributes *)attributes
                                                        error:(NSError **)error
{
    NSError *readError = nil;
    MSIDAssymetricKeyPair *keyPair = [self readKeyPairForAttributes:attributes error:&readError];

    if (keyPair || readError)
    {
        if (error) *error = readError;
        return keyPair;
    }
    
    return [self generateKeyPairForAttributes:attributes error:error];
}

- (MSIDAssymetricKeyPair *)readKeyPairForAttributes:(MSIDAssymetricKeyLookupAttributes *)attributes
                                             error:(NSError **)error
{
    if (@available(iOS 10.0, macOS 10.12, *))
    {
        if ([NSString msidIsStringNilOrBlank:attributes.privateKeyIdentifier])
        {
            [self logAndFillError:@"Invalid key lookup attributes provided" status:kNoStatus error:error];
            return nil;
        }
        
        NSDictionary *privateKeyDict = [self keyAttributesWithQueryDictionary:[attributes privateKeyAttributes] error:error];
        if (!privateKeyDict)
        {
            return nil;
        }
        
        SecKeyRef privateKeyRef = (__bridge SecKeyRef)privateKeyDict[(__bridge id)kSecValueRef];
        if (!privateKeyRef)
        {
            [self logAndFillError:@"Failed to query private key reference from keychain." status:kNoStatus error:error];
            return nil;
        }
        
        SecKeyRef publicKeyRef = SecKeyCopyPublicKey(privateKeyRef);
        if (!publicKeyRef)
        {
            [self logAndFillError:@"Failed to copy public key from private key." status:kNoStatus error:error];
            return nil;
        }
        
        MSIDAssymetricKeyPair *keypair = [[MSIDAssymetricKeyPair alloc] initWithPrivateKey:privateKeyRef
                                                                                 publicKey:publicKeyRef
                                                                            privateKeyDict:privateKeyDict];

        CFRelease(publicKeyRef);
        return keypair;
    }
    else
    {
        [self logAndFillError:@"Failed to generate asymmetric key pair due to unsupported iOS/OSX platform." status:kNoStatus error:error];
        return nil;
    }
}

#pragma mark - Cleanup

- (BOOL)deleteItemWithAttributes:(NSDictionary *)attributes error:(NSError **)error
{
    NSDictionary *queryAttributes = [self keychainQueryWithAttributes:attributes];
    OSStatus result = SecItemDelete((CFDictionaryRef)queryAttributes);
    
    if (result != errSecSuccess
        && result != errSecItemNotFound)
    {
        [self logAndFillError:@"Failed to remove keychain item"
                       status:result
                        error:error];
        return NO;
    }
    
    return YES;
}

#pragma mark - Private

- (NSDictionary *)keyAttributesWithQueryDictionary:(NSDictionary *)queryDictionary error:(NSError **)error
{
    NSMutableDictionary *keychainQuery = [[self keychainQueryWithAttributes:queryDictionary] mutableCopy];
    CFDictionaryRef keyCFDict = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyCFDict);
    
    if (status != errSecSuccess)
    {
        if (status != errSecItemNotFound)
        {
            [self logAndFillError:@"Failed to query private key"
                           status:status
                            error:error];
        }
        
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Failed to find key with query %@ with status %ld", keychainQuery, (long)status);
        return nil;
    }
    
    NSDictionary *privateKeyDict = CFBridgingRelease(keyCFDict);
    return privateKeyDict;
}

- (NSDictionary *)keychainQueryWithAttributes:(NSDictionary *)attributes
{
    NSMutableDictionary *keyPairAttr = [self.defaultKeychainQuery mutableCopy];
    [keyPairAttr addEntriesFromDictionary:attributes];
    return keyPairAttr;
}

- (MSIDAssymetricKeyPair *)generateEphemeralKeyPair:(NSError **)error
{
    NSDictionary *attributesDict = @{(__bridge id)kSecAttrKeyType : (__bridge id)kSecAttrKeyTypeRSA,
                                     (__bridge id)kSecAttrKeySizeInBits : @2048};
    return [self generateKeyPairForKeyDict:attributesDict error:error];
}

- (MSIDAssymetricKeyPair *)generateKeyPairForKeyDict:(NSDictionary *)attributes
                                               error:(NSError **)error
{
    if (@available(iOS 10.0, macOS 10.12, *))
    {
        CFErrorRef keyGenerationError = NULL;
        SecKeyRef privateKeyRef = SecKeyCreateRandomKey((__bridge CFDictionaryRef)attributes, &keyGenerationError);
        
        if (!privateKeyRef)
        {
            NSError *keyError = CFBridgingRelease(keyGenerationError);
            [self logAndFillError:@"Failed to generate private key." status:(int)keyError.code error:error];
            return nil;
        }
        
        SecKeyRef publicKeyRef = SecKeyCopyPublicKey(privateKeyRef);
        if (!publicKeyRef)
        {
            [self logAndFillError:@"Failed to copy public key from private key." status:kNoStatus error:error];
            CFRelease(privateKeyRef);
            return nil;
        }
        
        /*
         Setting creationDate to nil here intentionally as it is only needed for cpp code.
         CreationDate will be initialized using lazy loading once it is queried for the first time on key pair object.
         */
        
        MSIDAssymetricKeyPair *keyPair = [[MSIDAssymetricKeyPair alloc] initWithPrivateKey:privateKeyRef publicKey:publicKeyRef privateKeyDict:attributes];
        
        if (privateKeyRef) CFRelease(privateKeyRef);
        if (publicKeyRef) CFRelease(publicKeyRef);
        
        return keyPair;
    }
    else
    {
        [self logAndFillError:@"Failed to generate asymmetric key pair due to unsupported iOS/OSX platform." status:kNoStatus error:error];
        return nil;
    }
}

#pragma mark - Platform

- (NSDictionary *)additionalPlatformKeychainAttributes
{
    #ifdef __MAC_OS_X_VERSION_MAX_ALLOWED
    #if __MAC_OS_X_VERSION_MAX_ALLOWED >= 101500
        if (@available(macOS 10.15, *)) {
            return @{(id)kSecUseDataProtectionKeychain : @YES};
        }
    #endif
    #endif
    
    return nil;
}

#pragma mark - Utils

- (BOOL)logAndFillError:(NSString *)errorTitle status:(OSStatus)status error:(NSError **)error
{
    NSString *description = [NSString stringWithFormat:@"Operation failed with title \"%@\", status %ld", errorTitle, (long)status];
    MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"%@", description);
    
    if (error) {
        if (status == kNoStatus) {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, description, nil, nil, nil, nil, nil, NO);
        } else {
            // Implementation of this class guarantees that any non-trivial status is OSStatus coming from keychain API.
            *error = MSIDCreateError(MSIDKeychainErrorDomain, status, description, nil, nil, nil, nil, nil, NO);
        }
    }
    
    return YES;
}

@end
