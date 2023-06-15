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

#import "MSIDWebResponseBaseOperation.h"

@implementation MSIDWebResponseBaseOperation

- (nullable instancetype)initWithResponse:(nonnull __unused MSIDWebviewResponse *)response
                                    error:(__unused NSError * _Nullable *)error
{
    self = [super init];
    return self;
}

- (void)invokeWithInteractiveTokenRequestParameters:(nonnull __unused MSIDInteractiveRequestParameters *)interactiveTokenRequestParameters
                               tokenRequestProvider:(nonnull __unused id<MSIDTokenRequestProviding>)tokenRequestProvider
                                         completion:(nonnull __unused MSIDRequestCompletionBlock)completion
{
    MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Cannot find operation for this response type");
    NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, nil, nil, nil, nil, nil, nil, YES);
    completion(nil, error);
}

- (BOOL)doActionWithCorrelationId:(__unused NSUUID *)correlationId
                            error:(NSError * _Nullable *_Nullable)error
{
    MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Cannot find operation for this response type");
    if (error)
    {
        *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, nil, nil, nil, nil, nil, nil, YES);
    }
    return YES;
}

@end
