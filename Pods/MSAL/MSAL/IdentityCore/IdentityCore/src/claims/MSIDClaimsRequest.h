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
#import "MSIDJsonSerializable.h"

@class MSIDIndividualClaimRequest;

typedef NS_ENUM(NSUInteger, MSIDClaimsRequestTarget)
{
    MSIDClaimsRequestTargetInvalid,
    MSIDClaimsRequestTargetIdToken,
    MSIDClaimsRequestTargetAccessToken
};

NS_ASSUME_NONNULL_BEGIN

/*!
 Represents the claims request parameter as an object. It is not thread safe.
 See more info here: https://openid.net/specs/openid-connect-core-1_0-final.html#ClaimsParameter
 
 Example of Claims Request serialized to json:
 
 {
    "access_token":
    {
        "capolids": {"essential":true, "values":["00000000-0000-0000-0000-000000000001"]}
    },
    "id_token":
    {
        "auth_time": {"essential": true},
        "acr": {"values": ["urn:mace:incommon:iap:silver"]}
    }
 }
 
 */
@interface MSIDClaimsRequest : NSObject <NSCopying, MSIDJsonSerializable>

/*!
 Returns NO if claims request is empty, YES otherwise.
 */
@property (readonly) BOOL hasClaims;

/*!
 Adds a request for a specific claim to be included in the target via the claims request parameter.
 If claim request alredy exists, provided claim request takes its place.
 @param request Individual claim request.
 @param target Target of individual claim.
 @param error The error that occurred during requesting the claim.
 @return YES if operation was successful, NO otherwise.
 */
- (BOOL)requestClaim:(MSIDIndividualClaimRequest *)request
           forTarget:(MSIDClaimsRequestTarget)target
               error:(NSError * _Nullable * _Nullable)error;

/*!
 Return the array of requested claims for the target.
 @param target Target of requested claims.
 @return Array of individual claim requests.
 */
- (nullable NSArray<MSIDIndividualClaimRequest *> *)claimsRequestsForTarget:(MSIDClaimsRequestTarget)target;

/*!
 Remove requested claims for the target.
 @param name of requested claim.
 @param target Target of individual claim.
 @param error The error that occurred during removing the claim request.
 @return YES if operation was successful, NO otherwise.
 */
- (BOOL)removeClaimRequestWithName:(NSString *)name
                            target:(MSIDClaimsRequestTarget)target
                             error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
