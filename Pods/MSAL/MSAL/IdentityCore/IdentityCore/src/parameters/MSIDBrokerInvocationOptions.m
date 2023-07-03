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

#import "MSIDBrokerInvocationOptions.h"
#import "MSIDConstants.h"
#if TARGET_OS_IPHONE
#import "MSIDAppExtensionUtil.h"
#endif

@interface MSIDBrokerInvocationOptions()

@property (nonatomic, readwrite) MSIDRequiredBrokerType minRequiredBrokerType;
@property (nonatomic, readwrite) MSIDBrokerProtocolType protocolType;
@property (nonatomic, readwrite) MSIDBrokerAADRequestVersion brokerAADRequestVersion;
@property (nonatomic, readwrite) NSArray *requiredSchemes;
@property (nonatomic, readwrite) NSString *brokerBaseUrlString;
@property (nonatomic, readwrite) NSString *versionDisplayableName;
@property (nonatomic, readwrite) BOOL isUniversalLink;

@end

@implementation MSIDBrokerInvocationOptions

#pragma mark - Init

- (nullable instancetype)initWithRequiredBrokerType:(MSIDRequiredBrokerType)minRequiredBrokerType
                                       protocolType:(MSIDBrokerProtocolType)protocolType
                                  aadRequestVersion:(MSIDBrokerAADRequestVersion)aadRequestVersion
{
    self = [super init];
    
    if (self)
    {
        _minRequiredBrokerType = minRequiredBrokerType;
        _protocolType = protocolType;
        _brokerAADRequestVersion = aadRequestVersion;
        
        _requiredSchemes = [self requiredSchemesForBrokerType:minRequiredBrokerType requestType:aadRequestVersion];
        
        if (!_requiredSchemes)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning, nil, @"Unable to resolve expected URL scheme for required broker type %ld", (long)minRequiredBrokerType);
            return nil;
        }
        
        _brokerBaseUrlString = [self brokerBaseUrlForCommunicationProtocolType:protocolType aadRequestVersion:aadRequestVersion];
        
        if (!_brokerBaseUrlString)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning, nil, @"Unable to resolve base broker URL for protocol type %ld", (long)protocolType);
            return nil;
        }
        
        _versionDisplayableName = [self displayableNameForBrokerType:minRequiredBrokerType];
        _isUniversalLink = [_brokerBaseUrlString hasPrefix:@"https"];
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithRequiredBrokerType:MSIDRequiredBrokerTypeDefault
                               protocolType:MSIDBrokerProtocolTypeUniversalLink
                          aadRequestVersion:MSIDBrokerAADRequestVersionV2];
}

#pragma mark - Getters

- (BOOL)isRequiredBrokerPresent
{
#if TARGET_OS_IPHONE
    if (![self.requiredSchemes count])
    {
        return NO;
    }
    
    if (![MSIDAppExtensionUtil isExecutingInAppExtension])
    {
        // Verify broker app url can be opened
        for (NSString *scheme in self.requiredSchemes)
        {
            BOOL schemePresent = [[MSIDAppExtensionUtil sharedApplication] canOpenURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@://broker", scheme]]];
            
            if (!schemePresent)
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelWarning, nil, @"Scheme %@ for broker not present", scheme);
                return NO;
            }
        }
        
        return YES;
    }
    else
    {
        // Cannot perform app switching from application extension hosts
        return NO;
    }
#else
    return NO;
#endif
}

#pragma mark - Helpers

- (NSString *)brokerBaseUrlForCommunicationProtocolType:(MSIDBrokerProtocolType)protocolType
                                      aadRequestVersion:(MSIDBrokerAADRequestVersion)aadRequestVersion
{
    NSString *aadRequestScheme = nil;
    
    switch (aadRequestVersion) {
        case MSIDBrokerAADRequestVersionV1:
            aadRequestScheme = MSID_BROKER_ADAL_SCHEME;
            break;
            
        case MSIDBrokerAADRequestVersionV2:
            aadRequestScheme = MSID_BROKER_MSAL_SCHEME;
            break;
            
        default:
            return nil;
    }
    
    switch (protocolType) {
        case MSIDBrokerProtocolTypeCustomScheme:
            return [NSString stringWithFormat:@"%@://broker", aadRequestScheme];
            break;
        case MSIDBrokerProtocolTypeUniversalLink:
            return [NSString stringWithFormat:@"https://%@/applebroker/%@", MSIDTrustedAuthorityWorldWide, aadRequestScheme];
        default:
            break;
    }
    
    return nil;
}

- (NSString *)displayableNameForBrokerType:(MSIDRequiredBrokerType)brokerType
{
    switch (brokerType) {
        case MSIDRequiredBrokerTypeWithADALOnly:
            return @"V1-broker";
            
        case MSIDRequiredBrokerTypeWithV2Support:
            return @"V2-broker";
            
        case MSIDRequiredBrokerTypeWithNonceSupport:
            return @"V2-broker-nonce";
            
        default:
            break;
    }
}

- (NSArray *)requiredSchemesForBrokerType:(MSIDRequiredBrokerType)brokerType
                              requestType:(MSIDBrokerAADRequestVersion)aadRequestVersion
{
    switch (brokerType) {
        case MSIDRequiredBrokerTypeWithADALOnly:
            return @[MSID_BROKER_ADAL_SCHEME];
            
        case MSIDRequiredBrokerTypeWithV2Support:
            return @[MSID_BROKER_MSAL_SCHEME];
            
        case MSIDRequiredBrokerTypeWithNonceSupport:
        {
            if (aadRequestVersion == MSIDBrokerAADRequestVersionV1)
            {
                return @[MSID_BROKER_ADAL_SCHEME, MSID_BROKER_NONCE_SCHEME];
            }
            else return @[MSID_BROKER_MSAL_SCHEME, MSID_BROKER_NONCE_SCHEME];
        }
            
        default:
            return nil;
    }
}

@end
