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

/*!
 The minimum log level for messages to be passed onto the log callback.
 */
@property (readwrite) MSIDLogLevel level;

/*!
 Set to YES to allow messages possibly containing Personally Identifiable Information (PII) to be
 sent to the logging callback.
 */
@property (readwrite) BOOL PiiLoggingEnabled;

@property (readwrite) BOOL NSLoggingEnabled;

/*!
 Set to YES to add <file>:<line> info to log messages.
 */
@property (readwrite) BOOL SourceLineLoggingEnabled;

/*!
 Sets the callback block to send MSID log messages to.
 
 NOTE: Once this is set this can not be unset, and it should be set early in
 the program's execution.
 */
- (void)setCallback:(MSIDLogCallback)callback;

@end
