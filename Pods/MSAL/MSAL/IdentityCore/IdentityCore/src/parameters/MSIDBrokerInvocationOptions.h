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

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MSIDBrokerProtocolType)
{
    MSIDBrokerProtocolTypeCustomScheme,
    MSIDBrokerProtocolTypeUniversalLink
};

typedef NS_ENUM(NSInteger, MSIDBrokerAADRequestVersion)
{
    MSIDBrokerAADRequestVersionV1,
    MSIDBrokerAADRequestVersionV2
};

typedef NS_ENUM(NSInteger, MSIDRequiredBrokerType)
{
    MSIDRequiredBrokerTypeWithADALOnly, // First broker version supporting ADAL only
    MSIDRequiredBrokerTypeWithV2Support, // Second broker version supporting both ADAL and MSAL
    MSIDRequiredBrokerTypeWithNonceSupport, // Third broker version supporting nonce and application key rolling
    
    MSIDRequiredBrokerTypeDefault = MSIDRequiredBrokerTypeWithNonceSupport
};

NS_ASSUME_NONNULL_BEGIN

@interface MSIDBrokerInvocationOptions : NSObject

@property (nonatomic, readonly) MSIDRequiredBrokerType minRequiredBrokerType;
@property (nonatomic, readonly) MSIDBrokerProtocolType protocolType;
@property (nonatomic, readonly) MSIDBrokerAADRequestVersion brokerAADRequestVersion;
@property (nonatomic, readonly) BOOL isRequiredBrokerPresent;
@property (nonatomic, readonly) NSString *brokerBaseUrlString;
@property (nonatomic, readonly) NSString *versionDisplayableName;
@property (nonatomic, readonly) BOOL isUniversalLink;

- (nullable instancetype)initWithRequiredBrokerType:(MSIDRequiredBrokerType)minRequiredBrokerType
                                       protocolType:(MSIDBrokerProtocolType)protocolType
                                  aadRequestVersion:(MSIDBrokerAADRequestVersion)aadRequestVersion;


@end

NS_ASSUME_NONNULL_END
