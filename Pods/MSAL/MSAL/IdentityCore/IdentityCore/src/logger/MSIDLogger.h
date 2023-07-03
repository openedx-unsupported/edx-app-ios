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

@protocol MSIDLoggerConnecting;

/*! Levels of logging. Defines the priority of the logged message */
typedef NS_ENUM(NSInteger, MSIDLogLevel)
{
    MSIDLogLevelNothing,
    MSIDLogLevelError,
    MSIDLogLevelWarning,
    MSIDLogLevelInfo,
    MSIDLogLevelVerbose,
    MSIDLogLevelLast = MSIDLogLevelVerbose,
};

/*! Levels of log masking */
typedef NS_ENUM(NSInteger, MSIDLogMaskingLevel)
{
    /** Common core will not return any messages with any user or organizational information. This includes EUII and EUPI. */
    MSIDLogMaskingSettingsMaskAllPII,
    
    /** Common core logs will still include OII (organization identifiable information), and EUPI (end user pseudonymous identifiers), but MSAL will try to exclude and/or mask any EUII (end user identifiable information) like UPN, username, email from its logs. */
    MSIDLogMaskingSettingsMaskEUIIOnly,
    
    /** Common core logs will still include OII (organization identifiable information),  EUPI (end user pseudonymous identifiers), and EUII (end user identifiable information) like UPN, username, email from its logs. MSAL will still hide all secrets like tokens from its logs */
    MSIDLogMaskingSettingsMaskSecretsOnly
};

/*!
 The LogCallback block for the logger
 
 @param  level           The level of the log message
 @param  message         The message being logged
 @param  containsPII     If the message might contain Personally Identifiable Information (PII)
 this will be true. Log messages possibly containing PII will not be
 sent to the callback unless PIllLoggingEnabled is set to YES on the
 logger.
 
 */
typedef void (^MSIDLogCallback)(MSIDLogLevel level, NSString *message, BOOL containsPII);

@interface MSIDLogger : NSObject

+ (MSIDLogger *)sharedLogger;

/*! Allows to ovveride logger behaviour. */
@property (nonatomic, weak) id<MSIDLoggerConnecting> loggerConnector;

/*!
 The minimum log level for messages to be passed onto the log callback.
 */
@property (nonatomic, readwrite) MSIDLogLevel level;

/*!
    Provides a mechanism for a more granular log masking.
    All PII will be masked by default.
 */
@property (nonatomic, readwrite) MSIDLogMaskingLevel logMaskingLevel;

@property (nonatomic, readwrite) BOOL nsLoggingEnabled;

/*!
 Set to YES to add <file>:<line> info to log messages.
 */
@property (nonatomic, readwrite) BOOL sourceLineLoggingEnabled;

/*!
 Sets the callback block to send MSID log messages to.
 
 NOTE: Once this is set this can not be unset, and it should be set early in
 the program's execution.
 */
- (void)setCallback:(MSIDLogCallback)callback;

@end
