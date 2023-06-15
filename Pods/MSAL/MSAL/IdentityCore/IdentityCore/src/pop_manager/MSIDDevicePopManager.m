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

#import "MSIDDevicePopManager.h"
#import "MSIDConstants.h"
#import "NSData+MSIDExtensions.h"
#import "MSIDJWTHelper.h"
#import "MSIDAssymetricKeyGeneratorFactory.h"
#import "MSIDAssymetricKeyLookupAttributes.h"
#import "MSIDAssymetricKeyPair.h"

@interface MSIDDevicePopManager()

@property (nonatomic) MSIDCacheConfig *cacheConfig;
@property (nonatomic) id<MSIDAssymetricKeyGenerating> keyGeneratorFactory;
@property (nonatomic) MSIDAssymetricKeyLookupAttributes *keyPairAttributes;
@property (nonatomic) MSIDAssymetricKeyPair *keyPair;

@end

@implementation MSIDDevicePopManager

- (instancetype)initWithCacheConfig:(MSIDCacheConfig *)cacheConfig
                  keyPairAttributes:(MSIDAssymetricKeyLookupAttributes *)keyPairAttributes
{
    self = [super init];
    if (self)
    {
        _cacheConfig = cacheConfig;
        _keyGeneratorFactory = [MSIDAssymetricKeyGeneratorFactory defaultKeyGeneratorWithCacheConfig:self.cacheConfig error:nil];
        _keyPairAttributes = keyPairAttributes;
    }
    
    return self;
}

 - (MSIDAssymetricKeyPair *)keyPair
{
    if (!_keyPair)
    {
        NSError *keyPairError = nil;
        _keyPair = [self.keyGeneratorFactory readOrGenerateKeyPairForAttributes:self.keyPairAttributes error:&keyPairError];
        if (!_keyPair)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelError,nil, @"Failed to generate key pair, error: %@", MSID_PII_LOG_MASKABLE(keyPairError));
        }
    }
    
    return _keyPair;
}

- (NSDictionary *)buildPayloadDict:(NSString *)accessToken
                              host:(NSString *)host
                        httpMethod:(NSString *)httpMethod
                             nonce:(NSString *)nonce
                              path:(NSString *)path
                     publicKeyDict:(NSDictionary *)publicKeyDict
{
    NSMutableDictionary *payload = [NSMutableDictionary new];
    
    [payload setObject:accessToken forKey:@"at"];
    NSDictionary *cnf = @{@"cnf": @{
                                  @"jwk":publicKeyDict
    }};
    [payload addEntriesFromDictionary:cnf];
    
    [payload setObject:[NSNumber numberWithLong:(long)[[NSDate date] timeIntervalSince1970]] forKey:@"ts"];
    [payload setObject:host forKey:@"u"];
    if (![NSString msidIsStringNilOrBlank:httpMethod])
    {
        [payload setObject:httpMethod forKey:@"m"];
    }
    
    if (![NSString msidIsStringNilOrBlank:path])
    {
        [payload setObject:path forKey:@"p"];
    }
    
    if (![NSString msidIsStringNilOrBlank:nonce])
    {
        [payload setObject:nonce forKey:@"nonce"];
    }
    
    return payload;
}

- (NSString *)createSignedAccessToken:(NSString *)accessToken
                           httpMethod:(NSString *)httpMethod
                           requestUrl:(NSString *)requestUrl
                                nonce:(NSString *)nonce
                                error:(NSError *__autoreleasing * _Nullable)error
{
    NSString *kid = self.keyPair.kid;
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"%@", [NSString stringWithFormat:@"MSIDDevicePopManager: createSignedAccessToken with httpMethod: %@ requestUrl: %@ nonce: %@", httpMethod, requestUrl, nonce]);
    
    if ([NSString msidIsStringNilOrBlank:kid])
    {
        [self logAndFillError:@"Failed to create signed access token, unable to generate kid." error:error];
        return nil;
    }
    
    NSURL *url = [NSURL URLWithString:requestUrl];
    if (!url)
    {
        [self logAndFillError:[NSString stringWithFormat:@"Failed to create signed access token, invalid request url : %@.",requestUrl] error:error];
        return nil;
    }
    
    NSString *host = url.host;
    if ([NSString msidIsStringNilOrBlank:host])
    {
        [self logAndFillError:[NSString stringWithFormat:@"Failed to create signed access token, invalid request url : %@.",requestUrl] error:error];
        return nil;
    }
    
    NSString *path = url.path;
    if ([NSString msidIsStringNilOrBlank:path])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"MSIDDevicePopManager: createSignedAccessToken path is empty");
    }
    
    if ([NSString msidIsStringNilOrBlank:self.keyPair.stkJwk])
    {
        [self logAndFillError:@"Failed to create signed access token, unable to generate public key." error:error];
        return nil;
    }
    
    NSData *publicKeyData = [self.keyPair.stkJwk dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *publicKeyDict = [NSJSONSerialization JSONObjectWithData:publicKeyData options:0 error:error];
    if (!publicKeyDict)
    {
        [self logAndFillError:@"Failed to create signed access token, unable to serialize public key." error:error];
        return nil;
    }
    
    if ([NSString msidIsStringNilOrBlank:accessToken])
    {
        [self logAndFillError:@"Failed to create signed access token, access token is invalid." error:error];
        return nil;
    }
    
    if ([NSString msidIsStringNilOrBlank:httpMethod])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"MSIDDevicePopManager: createSignedAccessToken httpMethod is empty");
    }
    
    if ([NSString msidIsStringNilOrBlank:nonce])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"MSIDDevicePopManager: createSignedAccessToken nonce is empty");
    }
    
    NSDictionary *header = @{
        @"alg" : @"RS256",
        @"typ" : @"JWT",
        @"kid" : kid
    };
    
    NSDictionary *payload = [self buildPayloadDict:accessToken host:host httpMethod:httpMethod nonce:nonce path:path publicKeyDict:publicKeyDict];
    
    SecKeyRef privateKeyRef = self.keyPair.privateKeyRef;
    NSString *signedJwtHeader = [MSIDJWTHelper createSignedJWTforHeader:header payload:payload signingKey:privateKeyRef];
    return signedJwtHeader;
}

- (BOOL)logAndFillError:(NSString *)description error:(NSError **)error
{
    MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"%@", description);
    
    if (error)
    {
        *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, description, nil, nil, nil, nil, nil, NO);
    }
    
    return YES;
}

@end

