//
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


#import "MSIDWebOpenBrowserResponseOperation.h"
#import "MSIDWebOpenBrowserResponse.h"
#import "MSIDInteractiveRequestParameters.h"
#import "MSIDTokenRequestProviding.h"
#if TARGET_OS_IPHONE
#import "MSIDAppExtensionUtil.h"
#endif

@interface MSIDWebOpenBrowserResponseOperation()

@property (nonatomic) NSURL *browserURL;

@end

@implementation MSIDWebOpenBrowserResponseOperation

- (nullable instancetype)initWithResponse:(nonnull MSIDWebviewResponse *)response
                                    error:(NSError * _Nullable *)error
{
    self = [super initWithResponse:response
                             error:error];
    if (self)
    {
        if (![response isKindOfClass:MSIDWebOpenBrowserResponse.class] || [NSString msidIsStringNilOrBlank:[(MSIDWebOpenBrowserResponse *)response browserURL].absoluteString])
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"response is not valid");
            if (error)
            {
                *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Wrong type of response or response does not contain a valid broswer URL", nil, nil, nil, nil, nil, YES);
            }
            return nil;
        }
        
        MSIDWebOpenBrowserResponse *openUrlResponse = (MSIDWebOpenBrowserResponse *)response;
        _browserURL = openUrlResponse.browserURL;
    }
    
    return self;
}

- (BOOL)doActionWithCorrelationId:(NSUUID *)correlationId
                            error:(NSError * _Nullable __autoreleasing *)error
{
    #if TARGET_OS_IPHONE
    if (![MSIDAppExtensionUtil isExecutingInAppExtension])
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, nil, @"Opening a browser - %@", MSID_PII_LOG_MASKABLE(self.browserURL));
        [MSIDAppExtensionUtil sharedApplicationOpenURL:self.browserURL];
    }
    else
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorAttemptToOpenURLFromExtension, @"unable to redirect to browser from extension", nil, nil, nil, correlationId, nil, YES);
        }
        return YES;
    }
    #else
    [[NSWorkspace sharedWorkspace] openURL:self.browserURL];
    #endif
    if (error)
    {
        *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorSessionCanceledProgrammatically, @"Authorization session was cancelled programatically.", nil, nil, nil, correlationId, nil, YES);
    }
    return YES;
}

@end
