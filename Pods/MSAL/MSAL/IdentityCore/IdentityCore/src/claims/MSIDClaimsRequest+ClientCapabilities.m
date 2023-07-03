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

#import "MSIDClaimsRequest+ClientCapabilities.h"
#import "MSIDIndividualClaimRequest.h"
#import "MSIDIndividualClaimRequestAdditionalInfo.h"

static NSString *kCapabilitiesClaimName = @"xms_cc";

@implementation MSIDClaimsRequest (ClientCapabilities)

- (void)requestCapabilities:(NSArray<NSString *> *)capabilities
{
    if (capabilities.count == 0) return;
    
    MSIDIndividualClaimRequest *claimRequest = [[MSIDIndividualClaimRequest alloc] initWithName:kCapabilitiesClaimName];
    claimRequest.additionalInfo = [MSIDIndividualClaimRequestAdditionalInfo new];
    claimRequest.additionalInfo.values = capabilities;
    
    [self requestClaim:claimRequest forTarget:MSIDClaimsRequestTargetAccessToken error:nil];
}

+ (MSIDClaimsRequest *)claimsRequestFromCapabilities:(NSArray<NSString *> *)capabilities
                                       claimsRequest:(MSIDClaimsRequest *)claimsRequest
{
    if (!capabilities && !claimsRequest) return nil;
    
    MSIDClaimsRequest *result = claimsRequest ? [claimsRequest copy] : [MSIDClaimsRequest new];
    
    if (capabilities) [result requestCapabilities:capabilities];
    
    return result;
}

@end
