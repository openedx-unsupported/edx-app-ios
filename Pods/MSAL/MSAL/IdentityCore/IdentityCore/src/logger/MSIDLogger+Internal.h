//------------------------------------------------------------------------------
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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "MSIDLogger.h"
#import "MSIDRequestContext.h"
#import "MSIDMaskedLogParameter.h"
#import "MSIDMaskedHashableLogParameter.h"
#import "MSIDMaskedUsernameLogParameter.h"

// Convenience macro for obscuring PII in log macros that don't allow PII.
#define _PII_NULLIFY(_OBJ) _OBJ ? @"(not-null)" : @"(null)"

#define MSID_LOG_COMMON(_LVL, _CONTEXT, _CORRELATION_ID, _PII, _FMT, ...) \
    [[MSIDLogger sharedLogger] logWithLevel:_LVL                          \
                                        context:_CONTEXT                  \
                                  correlationId:_CORRELATION_ID           \
                                    containsPII:_PII                      \
                                       filename:@__FILE__                 \
                                     lineNumber:__LINE__                  \
                                       function:@(__func__)               \
                                         format:_FMT, ##__VA_ARGS__]

#define MSID_LOG_WITH_CTX(_LVL, _CONTEXT, _FMT, ...) MSID_LOG_COMMON(_LVL, _CONTEXT, nil, NO, _FMT, ##__VA_ARGS__)
#define MSID_LOG_WITH_CORR(_LVL, _CORRELATION_ID, _FMT, ...) MSID_LOG_COMMON(_LVL, nil, _CORRELATION_ID, NO, _FMT, ##__VA_ARGS__)
#define MSID_LOG_WITH_CTX_PII(_LVL, _CONTEXT, _FMT, ...) MSID_LOG_COMMON(_LVL, _CONTEXT, nil, YES, _FMT, ##__VA_ARGS__)
#define MSID_LOG_WITH_CORR_PII(_LVL, _CORRELATION_ID, _FMT, ...) MSID_LOG_COMMON(_LVL, nil, _CORRELATION_ID, YES, _FMT, ##__VA_ARGS__)

#define MSID_PII_LOG_MASKABLE(_PARAMETER) [[MSIDMaskedLogParameter alloc] initWithParameterValue:_PARAMETER]
#define MSID_EUII_ONLY_LOG_MASKABLE(_PARAMETER) [[MSIDMaskedLogParameter alloc] initWithParameterValue:_PARAMETER isEUII:YES]
#define MSID_PII_LOG_TRACKABLE(_PARAMETER) [[MSIDMaskedHashableLogParameter alloc] initWithParameterValue:_PARAMETER]
#define MSID_PII_LOG_EMAIL(_PARAMETER) [[MSIDMaskedUsernameLogParameter alloc] initWithParameterValue:_PARAMETER]

@interface MSIDLogger (Internal)

/*!
 Logs message with the specified level. If correlationId is nil, uses correlationId from the context.
 @param context         Log context, provides correlationId and log component
 @param correlationId   Alternative way to pass correlationId for cases when context is not available
 @param containsPII     Specifies if message contains PII
 @param format          Message format

 */

// Same log line for both cases
// If PII is not enabled, mask sensitive data
// If PII is enabled, pass on sensitive data
- (void)logWithLevel:(MSIDLogLevel)level
             context:(id<MSIDRequestContext>)context
       correlationId:(NSUUID *)correlationId
         containsPII:(BOOL)containsPII
            filename:(NSString *)filename
          lineNumber:(NSUInteger)lineNumber
            function:(NSString *)function
              format:(NSString *)format, ... NS_FORMAT_FUNCTION(8, 9);

- (void)logToken:(NSString *)token
       tokenType:(NSString *)tokenType
   expiresOnDate:(NSDate *)expiresOn
    additionaLog:(NSString *)additionalLog
         context:(id<MSIDRequestContext>)context;

@end

