// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKReferralManagerLogger.h"

 #import "FBSDKLoginConstants.h"
 #import "FBSDKReferralManagerResult.h"

 #ifdef FBSDKCOCOAPODS
  #import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
 #else
  #import "FBSDKCoreKit+Internal.h"
 #endif

static NSString *const FBSDKReferralManagerLoggerParamIdentifierKey = @"0_logger_id";
static NSString *const FBSDKReferralManagerLoggerParamTimestampKey = @"1_timestamp_ms";
static NSString *const FBSDKReferralManagerLoggerParamResultKey = @"2_result";
static NSString *const FBSDKReferralManagerLoggerParamErrorCodeKey = @"3_error_code";
static NSString *const FBSDKReferralManagerLoggerParamErrorMessageKey = @"4_error_message";
static NSString *const FBSDKReferralManagerLoggerParamExtrasKey = @"5_extras";
static NSString *const FBSDKReferralManagerLoggerParamLoggingTokenKey = @"6_logging_token";

static NSString *const FBSDKReferralManagerLoggerValueEmpty = @"";

static NSString *const FBSDKReferralManagerLoggerResultSuccessString = @"success";
static NSString *const FBSDKReferralManagerLoggerResultCancelString = @"cancelled";
static NSString *const FBSDKReferralManagerLoggerResultErrorString = @"error";

@implementation FBSDKReferralManagerLogger
{
  @private
  NSString *_identifier;
  NSMutableDictionary *_extras;
  NSString *_loggingToken;
}

- (instancetype)init
{
  if (self = [super init]) {
    FBSDKServerConfiguration *serverConfiguration = [FBSDKServerConfigurationManager cachedServerConfiguration];
    NSString *loggingToken = serverConfiguration.loggingToken;
    _identifier = [NSUUID UUID].UUIDString;
    _extras = [NSMutableDictionary dictionary];
    _loggingToken = [loggingToken copy];
  }
  return self;
}

- (void)logReferralStart
{
  [self logEvent:FBSDKAppEventNameFBReferralStart params:[self _parametersForNewEvent]];
}

- (void)logReferralEnd:(FBSDKReferralManagerResult *)result error:(NSError *)error
{
  NSString *resultString = FBSDKReferralManagerLoggerValueEmpty;

  if (error != nil) {
    resultString = FBSDKReferralManagerLoggerResultErrorString;
  } else if (result.isCancelled) {
    resultString = FBSDKReferralManagerLoggerResultCancelString;
  } else if (result.referralCodes) {
    resultString = FBSDKReferralManagerLoggerResultSuccessString;
  }

  NSMutableDictionary *params = [self _parametersForNewEvent];
  [FBSDKTypeUtility dictionary:params setObject:resultString forKey:FBSDKReferralManagerLoggerParamResultKey];

  if ([error.domain isEqualToString:FBSDKErrorDomain] || [error.domain isEqualToString:FBSDKLoginErrorDomain]) {
    NSString *errorMessage = error.userInfo[@"error_message"] ?: error.userInfo[FBSDKErrorLocalizedDescriptionKey];
    [FBSDKTypeUtility dictionary:params
                       setObject:errorMessage
                          forKey:FBSDKReferralManagerLoggerParamErrorMessageKey];

    NSString *errorCode = error.userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey] ?: [NSString stringWithFormat:@"%ld", (long)error.code];
    [FBSDKTypeUtility dictionary:params
                       setObject:errorCode
                          forKey:FBSDKReferralManagerLoggerParamErrorCodeKey];

    NSError *innerError = error.userInfo[NSUnderlyingErrorKey];
    if (innerError != nil) {
      NSString *innerErrorMessage = innerError.userInfo[@"error_message"] ?: innerError.userInfo[NSLocalizedDescriptionKey];
      [FBSDKTypeUtility dictionary:_extras
                         setObject:innerErrorMessage
                            forKey:@"inner_error_message"];

      NSString *innerErrorCode = innerError.userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey] ?: [NSString stringWithFormat:@"%ld", (long)innerError.code];
      [FBSDKTypeUtility dictionary:_extras
                         setObject:innerErrorCode
                            forKey:@"inner_error_code"];
    }
  } else if (error) {
    [FBSDKTypeUtility dictionary:params
                       setObject:@(error.code)
                          forKey:FBSDKReferralManagerLoggerParamErrorCodeKey];
    [FBSDKTypeUtility dictionary:params
                       setObject:error.localizedDescription
                          forKey:FBSDKReferralManagerLoggerParamErrorMessageKey];
  }

  [self logEvent:FBSDKAppEventNameFBReferralEnd params:params];
}

- (NSMutableDictionary *)_parametersForNewEvent
{
  NSMutableDictionary *eventParameters = [NSMutableDictionary new];

  // NOTE: We ALWAYS add all params to each event, to ensure predictable mapping on the backend.
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:_identifier ?: FBSDKReferralManagerLoggerValueEmpty
                        forKey:FBSDKReferralManagerLoggerParamIdentifierKey];
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:@(round(1000 * [NSDate date].timeIntervalSince1970))
                        forKey:FBSDKReferralManagerLoggerParamTimestampKey];
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:FBSDKReferralManagerLoggerValueEmpty
                        forKey:FBSDKReferralManagerLoggerParamResultKey];
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:FBSDKReferralManagerLoggerValueEmpty
                        forKey:FBSDKReferralManagerLoggerParamErrorCodeKey];
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:FBSDKReferralManagerLoggerValueEmpty
                        forKey:FBSDKReferralManagerLoggerParamErrorMessageKey];
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:FBSDKReferralManagerLoggerValueEmpty
                        forKey:FBSDKReferralManagerLoggerParamExtrasKey];
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:_loggingToken ?: FBSDKReferralManagerLoggerValueEmpty
                        forKey:FBSDKReferralManagerLoggerParamLoggingTokenKey];

  return eventParameters;
}

- (void)logEvent:(NSString *)eventName params:(NSMutableDictionary *)params
{
  if (_identifier) {
    NSString *extrasJSONString = [FBSDKBasicUtility JSONStringForObject:_extras
                                                                  error:NULL
                                                   invalidObjectHandler:NULL];
    if (extrasJSONString) {
      [FBSDKTypeUtility dictionary:params
                         setObject:extrasJSONString
                            forKey:FBSDKReferralManagerLoggerParamExtrasKey];
    }
    [_extras removeAllObjects];

    [FBSDKAppEvents logInternalEvent:eventName
                          parameters:params
                  isImplicitlyLogged:YES];
  }
}

@end

#endif
