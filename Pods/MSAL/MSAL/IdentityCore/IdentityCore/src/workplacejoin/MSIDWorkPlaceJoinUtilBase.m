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
#import "MSIDWorkPlaceJoinUtil.h"
#import "MSIDWorkPlaceJoinUtilBase.h"
#import "MSIDWorkPlaceJoinUtilBase+Internal.h"
#import "MSIDWorkPlaceJoinConstants.h"
#import "MSIDWPJKeyPairWithCert.h"

NSString *const MSID_DEVICE_INFORMATION_UPN_ID_KEY        = @"userPrincipalName";
NSString *const MSID_DEVICE_INFORMATION_AAD_DEVICE_ID_KEY = @"aadDeviceIdentifier";
NSString *const MSID_DEVICE_INFORMATION_AAD_TENANT_ID_KEY = @"aadTenantIdentifier";

@implementation MSIDWorkPlaceJoinUtilBase

+ (NSString *_Nullable)getWPJStringDataForIdentifier:(nonnull NSString *)identifier
                                         accessGroup:(nullable NSString *)accessGroup
                                             context:(id<MSIDRequestContext>_Nullable)context
                                               error:(NSError*__nullable*__nullable)error
{
    return [self getWPJStringDataFromV2ForTenantId:nil
                                        identifier:identifier
                                               key:nil
                                       accessGroup:accessGroup
                                           context:context
                                             error:error];
}

+ (NSString *_Nullable)getWPJStringDataFromV2ForTenantId:(NSString *)tenantId
                                              identifier:(nonnull NSString *)identifier
                                                     key:(nullable NSString *)key
                                             accessGroup:(nullable NSString *)accessGroup
                                                 context:(id<MSIDRequestContext>_Nullable)context
                                                   error:(NSError*__nullable*__nullable)error
{
    // Building dictionary to retrieve given identifier from the keychain
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    [query setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
    if (tenantId)
    {
        [query setObject:tenantId forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    }
    else
    {
        [query setObject:identifier forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
    }
    [query setObject:(id)kCFBooleanTrue forKey:(__bridge id<NSCopying>)(kSecReturnAttributes)];
    if (accessGroup)
    {
        [query setObject:accessGroup forKey:(__bridge id)kSecAttrAccessGroup];
    }

    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status != errSecSuccess)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"String Data not found with error code:%d", (int)status);

        return nil;
    }
    NSString *stringData;
    if (tenantId && key)
    {
        stringData = [(__bridge NSDictionary *)result objectForKey:key];
    }
    else
    {
        stringData = [(__bridge NSDictionary *)result objectForKey:(__bridge id)(kSecAttrService)];
    }

    if (result)
    {
        CFRelease(result);
    }

    if (!stringData || stringData.msidTrimmedString.length == 0)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDKeychainErrorDomain, status, @"Found empty keychain item.", nil, nil, nil, context.correlationId, nil, NO);
        }
    }

    return stringData;
}

+ (nullable NSDictionary *)getRegisteredDeviceMetadataInformation:(nullable id<MSIDRequestContext>)context
{
    return [self getRegisteredDeviceMetadataInformation:context tenantId:nil];
}

+ (nullable NSDictionary *)getRegisteredDeviceMetadataInformation:(nullable id<MSIDRequestContext>)context tenantId:(nullable NSString *)tenantId
{
    MSIDWPJKeyPairWithCert *wpjCerts = [MSIDWorkPlaceJoinUtil getWPJKeysWithTenantId:tenantId context:context];
    NSString *userPrincipalName;
    NSString *fetchedTenantId;
    if (wpjCerts)
    {
        if (wpjCerts.keyChainVersion != MSIDWPJKeychainAccessGroupV2)
        {
            userPrincipalName = [MSIDWorkPlaceJoinUtil getWPJStringDataForIdentifier:kMSIDUPNKeyIdentifier context:context error:nil];
            fetchedTenantId = [MSIDWorkPlaceJoinUtil getWPJStringDataForIdentifier:kMSIDTenantKeyIdentifier context:context error:nil];
        }
        else
        {
            NSString *formattedKeyForUPN = (__bridge NSString * )kSecAttrLabel;
            NSString *formattedKeyForTenantId = (__bridge NSString *)kSecAttrService;
            userPrincipalName = [MSIDWorkPlaceJoinUtil getWPJStringDataFromV2ForTenantId:tenantId identifier:kMSIDUPNKeyIdentifier key:formattedKeyForUPN context:context error:nil];
            fetchedTenantId = [MSIDWorkPlaceJoinUtil getWPJStringDataFromV2ForTenantId:tenantId identifier:kMSIDTenantKeyIdentifier key:formattedKeyForTenantId context:context error:nil];
        }
        NSMutableDictionary *registrationInfoMetadata = [NSMutableDictionary new];

        // Certificate subject is nothing but the AAD deviceID
        [registrationInfoMetadata setValue:wpjCerts.certificateSubject forKey:MSID_DEVICE_INFORMATION_AAD_DEVICE_ID_KEY];
        [registrationInfoMetadata setValue:userPrincipalName forKey:MSID_DEVICE_INFORMATION_UPN_ID_KEY];
        [registrationInfoMetadata setValue:fetchedTenantId forKey:MSID_DEVICE_INFORMATION_AAD_TENANT_ID_KEY];
        return registrationInfoMetadata;
    }

    return nil;
}
+ (nullable MSIDWPJKeyPairWithCert *)findWPJRegistrationInfoWithAdditionalPrivateKeyAttributes:(nonnull NSDictionary *)queryAttributes
                                                                                certAttributes:(nullable NSDictionary *)certAttributes
                                                                                       context:(nullable id<MSIDRequestContext>)context
{
    OSStatus status = noErr;
    CFTypeRef privateKeyCFDict = NULL;
    
    // Set the private key query dictionary.
    NSMutableDictionary *queryPrivateKey = [NSMutableDictionary new];
    
    if (queryAttributes)
    {
        [queryPrivateKey addEntriesFromDictionary:queryAttributes];
    }
    
    queryPrivateKey[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    queryPrivateKey[(__bridge id)kSecReturnAttributes] = @YES;
    queryPrivateKey[(__bridge id)kSecReturnRef] = @YES;
    // TODO: hardcoding this to query RSA keys only for now. Once ECC registration is ready and tested, after removing this line, code should be able to find either ECC or RSA keys, since there should be single key corresponding to the tag per tenant
    queryPrivateKey[(__bridge id)kSecAttrKeyType] = (__bridge id)kSecAttrKeyTypeRSA;
    
    status = SecItemCopyMatching((__bridge CFDictionaryRef)queryPrivateKey, (CFTypeRef*)&privateKeyCFDict); // +1 privateKeyCFDict
    if (status != errSecSuccess)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to find workplace join private key with status %ld", (long)status);
        return nil;
    }
        
    NSDictionary *privateKeyDict = CFBridgingRelease(privateKeyCFDict); // -1 privateKeyCFDict
    
    /*
     kSecAttrApplicationLabel
     For asymmetric keys this holds the public key hash which allows digital identity formation (to form a digital identity, this value must match the kSecAttrPublicKeyHash ('pkhh') attribute of the certificate)
     */
    NSData *applicationLabel = privateKeyDict[(__bridge id)kSecAttrApplicationLabel];

    if (!applicationLabel)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Unexpected key found without application label. Aborting lookup");
        return nil;
    }
    
    SecKeyRef privateKeyRef = (__bridge SecKeyRef)privateKeyDict[(__bridge id)kSecValueRef];
    
    if (!privateKeyRef)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"No private key ref found. Aborting lookup.");
        return nil;
    }
    
    NSMutableDictionary *mutableCertQuery = [NSMutableDictionary new];
    
    if (certAttributes)
    {
        [mutableCertQuery addEntriesFromDictionary:certAttributes];
    }
    
    mutableCertQuery[(__bridge id)kSecClass] = (__bridge id)kSecClassCertificate;
    mutableCertQuery[(__bridge id)kSecAttrPublicKeyHash] = applicationLabel;
    mutableCertQuery[(__bridge id)kSecReturnRef] = @YES;
    
    SecCertificateRef certRef;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)mutableCertQuery, (CFTypeRef*)&certRef); // +1 certRef
    
    if (status != errSecSuccess || !certRef)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to find certificate for public key hash with status %ld", (long)status);
        return nil;
    }
    
    MSIDWPJKeyPairWithCert *keyPair = [[MSIDWPJKeyPairWithCert alloc] initWithPrivateKey:privateKeyRef
                                                                             certificate:certRef
                                                                       certificateIssuer:nil];
    CFReleaseNull(certRef);
    return keyPair;
}

@end
