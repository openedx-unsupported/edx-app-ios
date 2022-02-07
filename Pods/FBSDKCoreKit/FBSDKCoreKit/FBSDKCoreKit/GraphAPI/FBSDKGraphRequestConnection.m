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

#import "FBSDKGraphRequestConnection+Internal.h"

#import "FBSDKConstants.h"
#import "FBSDKCoreKit+Internal.h"
#import "FBSDKError.h"
#import "FBSDKErrorConfigurationProvider.h"
#import "FBSDKEventLogger.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestBody.h"
#import "FBSDKGraphRequestConnectionFactory.h"
#import "FBSDKGraphRequestDataAttachment.h"
#import "FBSDKGraphRequestMetadata.h"
#import "FBSDKGraphRequestPiggybackManagerProvider.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKLogger.h"
#import "FBSDKOperatingSystemVersionComparing.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKURLSession+URLSessionProxying.h"
#import "FBSDKURLSessionProxyFactory.h"
#import "FBSDKURLSessionProxying.h"
#import "NSProcessInfo+Protocols.h"

NSString *const FBSDKNonJSONResponseProperty = @"FACEBOOK_NON_JSON_RESULT";

// URL construction constants
static NSString *const kGraphURLPrefix = @"graph.";
static NSString *const kGraphVideoURLPrefix = @"graph-video.";

static NSString *const kBatchKey = @"batch";
static NSString *const kBatchMethodKey = @"method";
static NSString *const kBatchRelativeURLKey = @"relative_url";
static NSString *const kBatchAttachmentKey = @"attached_files";
static NSString *const kBatchFileNamePrefix = @"file";
static NSString *const kBatchEntryName = @"name";

static NSString *const kAccessTokenKey = @"access_token";
#if TARGET_OS_TV
static NSString *const kSDK = @"tvos";
static NSString *const kUserAgentBase = @"FBtvOSSDK";
#else
static NSString *const kSDK = @"ios";
static NSString *const kUserAgentBase = @"FBiOSSDK";
#endif
static NSString *const kBatchRestMethodBaseURL = @"method/";

static NSTimeInterval g_defaultTimeout = 60.0;

#if !TARGET_OS_TV
static FBSDKAccessToken *_CreateExpiredAccessToken(FBSDKAccessToken *accessToken)
{
  if (accessToken == nil) {
    return nil;
  }
  if (accessToken.isExpired) {
    return accessToken;
  }
  NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-1];
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  return [[FBSDKAccessToken alloc] initWithTokenString:accessToken.tokenString
                                           permissions:accessToken.permissions.allObjects
                                   declinedPermissions:accessToken.declinedPermissions.allObjects
                                    expiredPermissions:accessToken.expiredPermissions.allObjects
                                                 appID:accessToken.appID
                                                userID:accessToken.userID
                                        expirationDate:expirationDate
                                           refreshDate:expirationDate
                              dataAccessExpirationDate:expirationDate
                                           graphDomain:accessToken.graphDomain];
  #pragma clange diagnostic pop
}

#endif

// ----------------------------------------------------------------------------
// FBSDKGraphRequestConnectionState

typedef NS_ENUM(NSUInteger, FBSDKGraphRequestConnectionState) {
  kStateCreated,
  kStateSerialized,
  kStateStarted,
  kStateCompleted,
  kStateCancelled,
};

// ----------------------------------------------------------------------------
// Private properties and methods

@interface FBSDKGraphRequestConnection () <
  NSURLSessionDataDelegate
#if !TARGET_OS_TV
  , FBSDKGraphErrorRecoveryProcessorDelegate
#endif
>

@property (nonatomic, retain) NSMutableArray<FBSDKGraphRequestMetadata *> *requests;
@property (nonatomic, assign) FBSDKGraphRequestConnectionState state;
@property (nonatomic, strong) FBSDKLogger *logger;
@property (nonatomic, assign) uint64_t requestStartTime;
@property (nonatomic, strong) id<FBSDKURLSessionProxying> session;
@property (nonatomic, strong) id<FBSDKURLSessionProxyProviding> sessionProxyFactory;
@property (nonatomic, strong) id<FBSDKErrorConfigurationProviding> errorConfigurationProvider;
@property (nonatomic, strong) Class<FBSDKGraphRequestPiggybackManagerProviding> piggybackManagerProvider;
@property (nonatomic, strong) Class<FBSDKSettings> settings;
@property (nonatomic, strong) id<FBSDKGraphRequestConnectionProviding> connectionFactory;
@property (nonatomic, strong) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, strong) id<FBSDKOperatingSystemVersionComparing> operatingSystemVersionComparer;
@property (nonatomic, strong) id<FBSDKMacCatalystDetermining> macCatalystDeterminator;

@end

// ----------------------------------------------------------------------------
// FBSDKGraphRequestConnection

@implementation FBSDKGraphRequestConnection
{
  NSString *_overrideVersionPart;
  NSUInteger _expectingResults;
  NSOperationQueue *_delegateQueue;
  id<FBSDKURLSessionProxying> _session;
  id<FBSDKURLSessionProxyProviding> _sessionProxyFactory;
#if !TARGET_OS_TV
  FBSDKGraphRequestMetadata *_recoveringRequestMetadata;
  FBSDKGraphErrorRecoveryProcessor *_errorRecoveryProcessor;
#endif
}

static BOOL _canMakeRequests = NO;

- (instancetype)init
{
  return [self initWithURLSessionProxyFactory:[FBSDKURLSessionProxyFactory new]
                   errorConfigurationProvider:[FBSDKErrorConfigurationProvider new]
                     piggybackManagerProvider:FBSDKGraphRequestPiggybackManagerProvider.self
                                     settings:FBSDKSettings.self
                            connectionFactory:[FBSDKGraphRequestConnectionFactory new]
                                  eventLogger:[FBSDKEventLogger new]
               operatingSystemVersionComparer:NSProcessInfo.processInfo
                      macCatalystDeterminator:NSProcessInfo.processInfo];
}

- (instancetype)initWithURLSessionProxyFactory:(id<FBSDKURLSessionProxyProviding>)proxyFactory
                    errorConfigurationProvider:(id<FBSDKErrorConfigurationProviding>)errorConfigurationProvider
                      piggybackManagerProvider:(Class<FBSDKGraphRequestPiggybackManagerProviding>)piggybackManagerProvider
                                      settings:(Class<FBSDKSettings>)settings
                             connectionFactory:(id<FBSDKGraphRequestConnectionProviding>)factory
                                   eventLogger:(id<FBSDKEventLogging>)eventLogger
                operatingSystemVersionComparer:(id<FBSDKOperatingSystemVersionComparing>)operatingSystemVersionComparer
                       macCatalystDeterminator:(id<FBSDKMacCatalystDetermining>)macCatalystDeterminator
{
  if ((self = [super init])) {
    _requests = [NSMutableArray new];
    _timeout = g_defaultTimeout;
    _state = kStateCreated;
    _logger = [[FBSDKLogger alloc] initWithLoggingBehavior:FBSDKLoggingBehaviorNetworkRequests];
    _sessionProxyFactory = proxyFactory;
    _session = [proxyFactory createSessionProxyWithDelegate:self queue:_delegateQueue];
    _errorConfigurationProvider = errorConfigurationProvider;
    _piggybackManagerProvider = piggybackManagerProvider;
    _settings = settings;
    _connectionFactory = factory;
    _eventLogger = eventLogger;
    _operatingSystemVersionComparer = operatingSystemVersionComparer;
    _macCatalystDeterminator = macCatalystDeterminator;
  }
  return self;
}

- (void)dealloc
{
  [self.session invalidateAndCancel];
}

#pragma mark - Public

+ (void)setDefaultConnectionTimeout:(NSTimeInterval)defaultTimeout
{
  if (defaultTimeout >= 0) {
    g_defaultTimeout = defaultTimeout;
  }
}

+ (NSTimeInterval)defaultConnectionTimeout
{
  return g_defaultTimeout;
}

- (void) addRequest:(id<FBSDKGraphRequest>)request
  completionHandler:(FBSDKGraphRequestBlock)handler
{
  [self addRequest:request batchEntryName:@"" completionHandler:handler];
}

- (void) addRequest:(id<FBSDKGraphRequest>)request
     batchEntryName:(NSString *)name
  completionHandler:(FBSDKGraphRequestBlock)handler
{
  NSDictionary<NSString *, id> *batchParams = name.length > 0 ? @{kBatchEntryName : name } : nil;
  [self addRequest:request batchParameters:batchParams completionHandler:handler];
}

- (void) addRequest:(id<FBSDKGraphRequest>)request
    batchParameters:(NSDictionary<NSString *, id> *)batchParameters
  completionHandler:(FBSDKGraphRequestBlock)handler
{
  if (self.state != kStateCreated) {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Cannot add requests once started or if a URLRequest is set"
                                 userInfo:nil];
  }
  FBSDKGraphRequestMetadata *metadata = [[FBSDKGraphRequestMetadata alloc] initWithRequest:request
                                                                         completionHandler:handler
                                                                           batchParameters:batchParameters];

  [FBSDKTypeUtility array:self.requests addObject:metadata];
}

- (void)cancel
{
  self.state = kStateCancelled;
  [self.session invalidateAndCancel];
}

- (void)overrideGraphAPIVersion:(NSString *)version
{
  if (![_overrideVersionPart isEqualToString:version]) {
    _overrideVersionPart = [version copy];
  }
}

- (void)start
{
  if (![self.class canMakeRequests]) {
    NSString *msg = @"FBSDKGraphRequestConnection cannot be started before Facebook SDK initialized.";
    [self.logger.class singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                             formatString:@"%@", msg];
    self.state = kStateCancelled;
    [self completeFBSDKURLSessionWithResponse:nil
                                         data:nil
                                 networkError:[FBSDKError unknownErrorWithMessage:msg]];

    return;
  }

  if (self.state != kStateCreated && self.state != kStateSerialized) {
    [self.logger.class singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                             formatString:@"FBSDKGraphRequestConnection cannot be started again."];
    return;
  }
  Class<FBSDKGraphRequestPiggybackManaging> piggybackManager = [self.piggybackManagerProvider.class piggybackManager];
  [piggybackManager.class addPiggybackRequests:self];
  NSMutableURLRequest *request = [self requestWithBatch:self.requests timeout:_timeout];

  self.state = kStateStarted;

  [self logRequest:request bodyLength:0 bodyLogger:nil attachmentLogger:nil];
  _requestStartTime = [FBSDKInternalUtility currentTimeInMilliseconds];

  FBSDKURLSessionTaskBlock completionHandler = ^(NSData *responseDataV1, NSURLResponse *responseV1, NSError *errorV1) {
    FBSDKURLSessionTaskBlock handler = ^(NSData *responseDataV2,
                                         NSURLResponse *responseV2,
                                         NSError *errorV2) {
      [self completeFBSDKURLSessionWithResponse:responseV2
                                           data:responseDataV2
                                   networkError:errorV2];
    };

    if (errorV1) {
      [self _taskDidCompleteWithError:errorV1 handler:handler];
    } else {
      [self taskDidCompleteWithResponse:responseV1 data:responseDataV1 requestStartTime:self.requestStartTime handler:handler];
    }
  };
  [self.session executeURLRequest:request completionHandler:completionHandler];

  id<FBSDKGraphRequestConnectionDelegate> delegate = self.delegate;
  if ([delegate respondsToSelector:@selector(requestConnectionWillBeginLoading:)]) {
    if (_delegateQueue) {
      [_delegateQueue addOperationWithBlock:^{
        [delegate requestConnectionWillBeginLoading:self];
      }];
    } else {
      [delegate requestConnectionWillBeginLoading:self];
    }
  }
}

- (NSOperationQueue *)delegateQueue
{
  return _delegateQueue;
}

- (void)setDelegateQueue:(NSOperationQueue *)queue
{
  _session.delegateQueue = queue;
  _delegateQueue = queue;
}

#pragma mark - Private Properties

+ (void)setCanMakeRequests
{
  _canMakeRequests = YES;
}

+ (BOOL)canMakeRequests
{
  return _canMakeRequests;
}

- (id<FBSDKURLSessionProxying>)session
{
  return _session;
}

- (id<FBSDKURLSessionProxyProviding>)sessionProxyFactory
{
  return _sessionProxyFactory;
}

#pragma mark - Private methods (request generation)

//
// Adds request data to a batch in a format expected by the JsonWriter.
// Binary attachments are referenced by name in JSON and added to the
// attachments dictionary.
//
- (void)addRequest:(FBSDKGraphRequestMetadata *)metadata
           toBatch:(NSMutableArray *)batch
       attachments:(NSMutableDictionary *)attachments
        batchToken:(NSString *)batchToken
{
  NSMutableDictionary *requestElement = [NSMutableDictionary new];

  if (metadata.batchParameters) {
    [requestElement addEntriesFromDictionary:metadata.batchParameters];
  }

  if (batchToken) {
    NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary
                                                   dictionaryWithDictionary:metadata.request.parameters];
    [FBSDKTypeUtility dictionary:params setObject:batchToken forKey:kAccessTokenKey];
    metadata.request.parameters = params;
    [self registerTokenToOmitFromLog:batchToken];
  }

  NSString *urlString = [self urlStringForSingleRequest:metadata.request forBatch:YES];
  [FBSDKTypeUtility dictionary:requestElement setObject:urlString forKey:kBatchRelativeURLKey];
  [FBSDKTypeUtility dictionary:requestElement setObject:metadata.request.HTTPMethod forKey:kBatchMethodKey];

  NSMutableArray *attachmentNames = [NSMutableArray array];

  [FBSDKTypeUtility dictionary:metadata.request.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
    if ([FBSDKGraphRequest isAttachment:value]) {
      NSString *name = [NSString stringWithFormat:@"%@%lu",
                        kBatchFileNamePrefix,
                        (unsigned long)attachments.count];
      [FBSDKTypeUtility array:attachmentNames addObject:name];
      [FBSDKTypeUtility dictionary:attachments setObject:value forKey:name];
    }
  }];

  if (attachmentNames.count) {
    [FBSDKTypeUtility dictionary:requestElement setObject:[attachmentNames componentsJoinedByString:@","] forKey:kBatchAttachmentKey];
  }

  [FBSDKTypeUtility array:batch addObject:requestElement];
}

- (void)appendAttachments:(NSDictionary *)attachments
                   toBody:(FBSDKGraphRequestBody *)body
              addFormData:(BOOL)addFormData
                   logger:(FBSDKLogger *)logger
{
  [FBSDKTypeUtility dictionary:attachments enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
    value = [FBSDKBasicUtility convertRequestValue:value];
    if ([value isKindOfClass:[NSString class]]) {
      if (addFormData) {
        [body appendWithKey:key formValue:(NSString *)value logger:logger];
      }
    } else if ([value isKindOfClass:[UIImage class]]) {
      [body appendWithKey:key imageValue:(UIImage *)value logger:logger];
    } else if ([value isKindOfClass:[NSData class]]) {
      [body appendWithKey:key dataValue:(NSData *)value logger:logger];
    } else if ([value isKindOfClass:[FBSDKGraphRequestDataAttachment class]]) {
      [body appendWithKey:key dataAttachmentValue:(FBSDKGraphRequestDataAttachment *)value logger:logger];
    } else {
      [logger.class singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors formatString:@"Unsupported FBSDKGraphRequest attachment:%@, skipping.", value];
    }
  }];
}

//
// Serializes all requests in the batch to JSON and appends the result to
// body.  Also names all attachments that need to go as separate blocks in
// the body of the request.
//
// All the requests are serialized into JSON, with any binary attachments
// named and referenced by name in the JSON.
//
- (void)appendJSONRequests:(NSArray *)requests
                    toBody:(FBSDKGraphRequestBody *)body
        andNameAttachments:(NSMutableDictionary *)attachments
                    logger:(FBSDKLogger *)logger
{
  NSMutableArray *batch = [NSMutableArray new];
  NSString *batchToken = nil;
  for (FBSDKGraphRequestMetadata *metadata in requests) {
    NSString *individualToken = [self accessTokenWithRequest:metadata.request];
    BOOL isClientToken = [self.settings.class clientToken] && [individualToken hasSuffix:[self.settings.class clientToken]];
    if (!batchToken
        && !isClientToken) {
      batchToken = individualToken;
    }
    [self addRequest:metadata
             toBatch:batch
         attachments:attachments
          batchToken:[batchToken isEqualToString:individualToken] ? nil : individualToken];
  }

  NSString *jsonBatch = [FBSDKBasicUtility JSONStringForObject:batch error:NULL invalidObjectHandler:NULL];

  [body appendWithKey:kBatchKey formValue:jsonBatch logger:logger];
  if (batchToken) {
    [body appendWithKey:kAccessTokenKey formValue:batchToken logger:logger];
  }
}

- (BOOL)_shouldWarnOnMissingFieldsParam:(id<FBSDKGraphRequest>)request
{
  NSString *minVersion = @"2.4";
  NSString *version = request.version;
  if (!version) {
    return YES;
  }
  if ([version hasPrefix:@"v"]) {
    version = [version substringFromIndex:1];
  }

  NSComparisonResult result = [version compare:minVersion options:NSNumericSearch];

  // if current version is the same as minVersion, or if the current version is > minVersion
  return (result == NSOrderedSame) || (result == NSOrderedDescending);
}

// Validate that all GET requests after v2.4 have a "fields" param
- (void)_validateFieldsParamForGetRequests:(NSArray *)requests
{
  for (FBSDKGraphRequestMetadata *metadata in requests) {
    id<FBSDKGraphRequest> request = metadata.request;
    if ([request.HTTPMethod.uppercaseString isEqualToString:@"GET"]
        && [self _shouldWarnOnMissingFieldsParam:request]
        && !request.parameters[@"fields"]
        && [request.graphPath rangeOfString:@"fields="].location == NSNotFound) {
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                         formatString:@"starting with Graph API v2.4, GET requests for /%@ should contain an explicit \"fields\" parameter", request.graphPath];
    }
  }
}

//
// Generates a NSURLRequest based on the contents of self.requests, and sets
// options on the request.  Chooses between URL-based request for a single
// request and JSON-based request for batches.
//
- (NSMutableURLRequest *)requestWithBatch:(NSArray *)requests
                                  timeout:(NSTimeInterval)timeout
{
  FBSDKGraphRequestBody *body = [FBSDKGraphRequestBody new];
  FBSDKLogger *bodyLogger = [[FBSDKLogger alloc] initWithLoggingBehavior:_logger.loggingBehavior];
  FBSDKLogger *attachmentLogger = [[FBSDKLogger alloc] initWithLoggingBehavior:_logger.loggingBehavior];

  NSMutableURLRequest *request;

  if (requests.count == 0) {
    [[NSException exceptionWithName:NSInvalidArgumentException
                             reason:@"FBSDKGraphRequestConnection: Must have at least one request or urlRequest not specified."
                           userInfo:nil]
     raise];
  }

  [self _validateFieldsParamForGetRequests:requests];

  if (requests.count == 1) {
    FBSDKGraphRequestMetadata *metadata = [FBSDKTypeUtility array:requests objectAtIndex:0];
    NSURL *url = [NSURL URLWithString:[self urlStringForSingleRequest:metadata.request forBatch:NO]];
    request = [NSMutableURLRequest requestWithURL:url
                                      cachePolicy:NSURLRequestUseProtocolCachePolicy
                                  timeoutInterval:timeout];

    // HTTP methods are case-sensitive; be helpful in case someone provided a mixed case one.
    NSString *httpMethod = metadata.request.HTTPMethod.uppercaseString;
    request.HTTPMethod = httpMethod;
    [self appendAttachments:metadata.request.parameters
                     toBody:body
                addFormData:[httpMethod isEqualToString:@"POST"]
                     logger:attachmentLogger];
  } else {
    // Find the session with an app ID and use that as the batch_app_id. If we can't
    // find one, try to load it from the plist. As a last resort, pass 0.
    NSString *batchAppID = [self.settings.class appID];
    if (!batchAppID || batchAppID.length == 0) {
      // The Graph API batch method requires either an access token or batch_app_id.
      // If we can't determine an App ID to use for the batch, we can't issue it.
      [[NSException exceptionWithName:NSInternalInconsistencyException
                               reason:@"FBSDKGraphRequestConnection: [FBSDKSettings appID] must be specified for batch requests"
                             userInfo:nil]
       raise];
    }

    [body appendWithKey:@"batch_app_id" formValue:batchAppID logger:bodyLogger];

    NSMutableDictionary *attachments = [NSMutableDictionary new];

    [self appendJSONRequests:requests
                      toBody:body
          andNameAttachments:attachments
                      logger:bodyLogger];

    [self appendAttachments:attachments
                     toBody:body
                addFormData:NO
                     logger:attachmentLogger];

    NSURL *url = [FBSDKInternalUtility
                  facebookURLWithHostPrefix:kGraphURLPrefix
                  path:@""
                  queryParameters:@{}
                  defaultVersion:_overrideVersionPart
                  error:NULL];

    request = [NSMutableURLRequest requestWithURL:url
                                      cachePolicy:NSURLRequestUseProtocolCachePolicy
                                  timeoutInterval:timeout];
    request.HTTPMethod = @"POST";
  }

  if ([request.HTTPMethod isEqualToString:@"POST"]) {
    [self addBody:body toPostRequest:request];
  } else {
    request.HTTPBody = body.data;
  }
  [request setValue:[self userAgent] forHTTPHeaderField:@"User-Agent"];
  [request setValue:[body mimeContentType] forHTTPHeaderField:@"Content-Type"];
  [request setHTTPShouldHandleCookies:NO];

  [self logRequest:request bodyLength:(request.HTTPBody.length / 1024) bodyLogger:bodyLogger attachmentLogger:attachmentLogger];

  return request;
}

- (void)addBody:(FBSDKGraphRequestBody *)body toPostRequest:(NSMutableURLRequest *)request
{
  NSData *compressedData;
  if ((compressedData = [body compressedData])) {
    request.HTTPBody = compressedData;
    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
  } else {
    request.HTTPBody = body.data;
  }
}

//
// Generates a URL for a batch containing only a single request,
// and names all attachments that need to go in the body of the
// request.
//
// The URL contains all parameters that are not body attachments,
// including the session key if present.
//
// Attachments are named and referenced by name in the URL.
//
- (NSString *)urlStringForSingleRequest:(id<FBSDKGraphRequest>)request forBatch:(BOOL)forBatch
{
  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionaryWithDictionary:request.parameters];
  [FBSDKTypeUtility dictionary:params setObject:@"json" forKey:@"format"];
  [FBSDKTypeUtility dictionary:params setObject:kSDK forKey:@"sdk"];
  [FBSDKTypeUtility dictionary:params setObject:@"false" forKey:@"include_headers"];

  request.parameters = params;

  NSString *baseURL;
  if (forBatch) {
    baseURL = request.graphPath;
  } else {
    NSString *token = [self accessTokenWithRequest:request];
    if (token) {
      [params setValue:token forKey:kAccessTokenKey];
      request.parameters = params;
      [self registerTokenToOmitFromLog:token];
    }

    NSString *prefix = kGraphURLPrefix;
    // We special case a graph post to <id>/videos and send it to graph-video.facebook.com
    // We only do this for non batch post requests
    NSString *graphPath = request.graphPath.lowercaseString;
    if ([request.HTTPMethod.uppercaseString isEqualToString:@"POST"]
        && [graphPath hasSuffix:@"/videos"]) {
      graphPath = [graphPath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
      NSArray *components = [graphPath componentsSeparatedByString:@"/"];
      if (components.count == 2) {
        prefix = kGraphVideoURLPrefix;
      }
    }

    baseURL = [FBSDKInternalUtility
               facebookURLWithHostPrefix:prefix
               path:request.graphPath
               queryParameters:@{}
               defaultVersion:request.version
               error:NULL].absoluteString;
  }

  NSString *url = [FBSDKGraphRequest serializeURL:baseURL
                                           params:request.parameters
                                       httpMethod:request.HTTPMethod
                                         forBatch:forBatch];
  return url;
}

#pragma mark - Private methods (response parsing)

- (void)completeFBSDKURLSessionWithResponse:(NSURLResponse *)response
                                       data:(NSData *)data
                               networkError:(NSError *)error
{
  if (self.state != kStateCancelled) {
    NSAssert(
      self.state == kStateStarted,
      @"Unexpected state %lu in completeWithResponse",
      (unsigned long)self.state
    );
    self.state = kStateCompleted;
  }

  NSArray *results = nil;
  _urlResponse = (NSHTTPURLResponse *)response;
  if (response) {
    NSAssert(
      [response isKindOfClass:[NSHTTPURLResponse class]],
      @"Expected NSHTTPURLResponse, got %@",
      response
    );

    NSInteger statusCode = _urlResponse.statusCode;

    if (!error && [response.MIMEType hasPrefix:@"image"]) {
      error = [FBSDKError errorWithCode:FBSDKErrorGraphRequestNonTextMimeTypeReturned
                                message:@"Response is a non-text MIME type; endpoints that return images and other "
               @"binary data should be fetched using NSURLRequest and NSURLSession"];
    } else {
      results = [self parseJSONResponse:data
                                  error:&error
                             statusCode:statusCode];
    }
  } else if (!error) {
    error = [FBSDKError errorWithCode:FBSDKErrorUnknown
                              message:@"Missing NSURLResponse"];
  }

  if (!error) {
    if (self.requests.count != results.count) {
      error = [FBSDKError errorWithCode:FBSDKErrorGraphRequestProtocolMismatch
                                message:@"Unexpected number of results returned from server."];
    } else {
      [_logger appendFormat:@"Response <#%lu>\nDuration: %llu msec\nSize: %lu kB\nResponse Body:\n%@\n\n",
       (unsigned long)_logger.loggerSerialNumber,
       [FBSDKInternalUtility currentTimeInMilliseconds] - _requestStartTime,
       (unsigned long)data.length,
       results];
    }
  }

  if (error) {
    [_logger appendFormat:@"Response <#%lu> <Error>:\n%@\n%@\n",
     (unsigned long)_logger.loggerSerialNumber,
     error.localizedDescription,
     error.userInfo];
  }
  [_logger emitToNSLog];

  [self _completeWithResults:results networkError:error];

  [self.session invalidateAndCancel];
}

//
// If there is one request, the JSON is the response.
// If there are multiple requests, the JSON has an array of dictionaries whose
// body property is the response.
// [{ "code":200,
// "body":"JSON-response-as-a-string" },
// { "code":200,
// "body":"JSON-response-as-a-string" }]
//
// In both cases, this function returns an NSArray containing the results.
// The NSArray looks just like the multiple request case except the body
// value is converted from a string to parsed JSON.
//
- (NSArray *)parseJSONResponse:(NSData *)data
                         error:(NSError **)error
                    statusCode:(NSInteger)statusCode
{
  // Graph API can return "true" or "false", which is not valid JSON.
  // Translate that before asking JSON parser to look at it.
  NSString *responseUTF8 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  NSMutableArray *results = [NSMutableArray new];;
  id response = [self parseJSONOrOtherwise:responseUTF8 error:error];

  if (responseUTF8 == nil) {
    NSString *base64Data = data.length != 0 ? [data base64EncodedStringWithOptions:0] : @"";
    if (base64Data != nil) {
      [self.eventLogger logInternalEvent:@"fb_response_invalid_utf8" isImplicitlyLogged:YES];
    }
  }

  NSDictionary *responseError = nil;
  if (!response) {
    if ((error != NULL) && (*error == nil)) {
      *error = [self _errorWithCode:FBSDKErrorUnknown
                         statusCode:statusCode
                 parsedJSONResponse:nil
                         innerError:nil
                            message:@"The server returned an unexpected response."];
    }
  } else if (self.requests.count == 1) {
    // response is the entry, so put it in a dictionary under "body" and add
    // that to array of responses.
    [FBSDKTypeUtility array:results addObject:@{
       @"code" : @(statusCode),
       @"body" : response
     }];
  } else if ([response isKindOfClass:[NSArray class]]) {
    // response is the array of responses, but the body element of each needs
    // to be decoded from JSON.
    for (id item in response) {
      // Don't let errors parsing one response stop us from parsing another.
      NSError *batchResultError = nil;
      if (![item isKindOfClass:[NSDictionary class]]) {
        [FBSDKTypeUtility array:results addObject:item];
      } else {
        NSMutableDictionary *result = [((NSDictionary *)item) mutableCopy];
        if (result[@"body"]) {
          [FBSDKTypeUtility dictionary:result setObject:[self parseJSONOrOtherwise:result[@"body"] error:&batchResultError] forKey:@"body"];
        }
        [FBSDKTypeUtility array:results addObject:result];
      }
      if (batchResultError) {
        // We'll report back the last error we saw.
        *error = batchResultError;
      }
    }
  } else if ([response isKindOfClass:[NSDictionary class]]
             && (responseError = [FBSDKTypeUtility dictionaryValue:response[@"error"]]) != nil
             && [responseError[@"type"] isEqualToString:@"OAuthException"]) {
    // if there was one request then return the only result. if there were multiple requests
    // but only one error then the server rejected the batch access token
    NSDictionary *result = @{
      @"code" : @(statusCode),
      @"body" : response
    };

    for (NSUInteger resultIndex = 0, resultCount = self.requests.count; resultIndex < resultCount; ++resultIndex) {
      [FBSDKTypeUtility array:results addObject:result];
    }
  } else if (error != NULL) {
    *error = [self _errorWithCode:FBSDKErrorGraphRequestProtocolMismatch
                       statusCode:statusCode
               parsedJSONResponse:results
                       innerError:nil
                          message:nil];
  }

  return results;
}

- (id)parseJSONOrOtherwise:(NSString *)unsafeString
                     error:(NSError **)error
{
  id parsed = nil;

  // Historically, people have passed-in `id` here. So, gotta double-check.
  NSString *const utf8 = FBSDK_CAST_TO_CLASS_OR_NIL(unsafeString, NSString);
  if (!(*error) && utf8) {
    parsed = [FBSDKBasicUtility objectForJSONString:utf8 error:error];
    // if we fail parse we attempt a re-parse of a modified input to support results in the form "foo=bar", "true", etc.
    // which is shouldn't be necessary since Graph API v2.1.
    if (*error) {
      // we round-trip our hand-wired response through the parser in order to remain
      // consistent with the rest of the output of this function (note, if perf turns out
      // to be a problem -- unlikely -- we can return the following dictionary outright)
      NSError *reparseError = nil;
      parsed =
      [FBSDKBasicUtility
       objectForJSONString:
       [FBSDKBasicUtility JSONStringForObject:@{ FBSDKNonJSONResponseProperty : utf8 }
                                        error:NULL
                         invalidObjectHandler:NULL]
       error:&reparseError];

      if (!reparseError) {
        *error = nil;
      }
    }
  }
  return parsed;
}

- (void)_completeWithResults:(NSArray *)results
                networkError:(NSError *)networkError
{
  NSUInteger count = self.requests.count;
  _expectingResults = count;
  NSUInteger disabledRecoveryCount = 0;
  for (FBSDKGraphRequestMetadata *metadata in self.requests) {
    if ([(id<FBSDKGraphRequestInternal>)metadata.request isGraphErrorRecoveryDisabled]) {
      disabledRecoveryCount++;
    }
  }
#if !TARGET_OS_TV
  BOOL isSingleRequestToRecover = (count - disabledRecoveryCount == 1);
#endif

  [self.requests enumerateObjectsUsingBlock:^(FBSDKGraphRequestMetadata *metadata, NSUInteger i, BOOL *stop) {
    id result = networkError ? nil : [FBSDKTypeUtility array:results objectAtIndex:i];
    NSError *const resultError = networkError ?: [self errorFromResult:result request:metadata.request];

    id body = nil;
    if (!resultError && [result isKindOfClass:[NSDictionary class]]) {
      NSDictionary *resultDictionary = [FBSDKTypeUtility dictionaryValue:result];
      body = [FBSDKTypeUtility dictionaryValue:resultDictionary[@"body"]];
    }

  #if !TARGET_OS_TV
    BOOL isRecoveryDisabled = [(id<FBSDKGraphRequestInternal>)metadata.request isGraphErrorRecoveryDisabled];
    if (resultError && !isRecoveryDisabled && isSingleRequestToRecover) {
      self->_recoveringRequestMetadata = metadata;
      self->_errorRecoveryProcessor = [FBSDKGraphErrorRecoveryProcessor new];
      if ([self->_errorRecoveryProcessor processError:resultError request:metadata.request delegate:self]) {
        return;
      }
    }
  #endif

    [self processResultBody:body error:resultError metadata:metadata canNotifyDelegate:networkError == nil];
  }];

  if (networkError) {
    if ([_delegate respondsToSelector:@selector(requestConnection:didFailWithError:)]) {
      [_delegate requestConnection:self didFailWithError:networkError];
    }
  }
}

- (void)processResultBody:(NSDictionary *)body error:(NSError *)error metadata:(FBSDKGraphRequestMetadata *)metadata canNotifyDelegate:(BOOL)canNotifyDelegate
{
  void (^finishAndInvokeCompletionHandler)(void) = ^{
    NSDictionary<NSString *, id> *graphDebugDict = body[@"__debug__"];
    if ([graphDebugDict isKindOfClass:[NSDictionary class]]) {
      [self processResultDebugDictionary:graphDebugDict];
    }
    [metadata invokeCompletionHandlerForConnection:self withResults:body error:error];

    if (--self->_expectingResults == 0) {
      if (canNotifyDelegate && [self->_delegate respondsToSelector:@selector(requestConnectionDidFinishLoading:)]) {
        [self->_delegate requestConnectionDidFinishLoading:self];
      }
    }
  };

#if !TARGET_OS_TV
  void (^clearToken)(NSInteger) = ^(NSInteger errorSubcode) {
    FBSDKGraphRequestFlags flags = [(id<FBSDKGraphRequestInternal>)metadata.request flags];
    if (flags & FBSDKGraphRequestFlagDoNotInvalidateTokenOnError) {
      return;
    }
    if (errorSubcode == 493) {
      [FBSDKAccessToken setCurrentAccessToken:_CreateExpiredAccessToken([FBSDKAccessToken currentAccessToken])];
    } else {
      [FBSDKAccessToken setCurrentAccessToken:nil];
    }
  };

  NSString *metadataTokenString = metadata.request.tokenString;
  NSString *currentTokenString = [FBSDKAccessToken currentAccessToken].tokenString;

  if ([metadataTokenString isEqualToString:currentTokenString]) {
    NSInteger errorCode = [error.userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey] integerValue];
    NSInteger errorSubcode = [error.userInfo[FBSDKGraphRequestErrorGraphErrorSubcodeKey] integerValue];
    if (errorCode == 190 || errorCode == 102) {
      clearToken(errorSubcode);
    }
  }
#endif
  // this is already on the queue since we are currently in the NSURLSession callback.
  finishAndInvokeCompletionHandler();
}

- (void)processResultDebugDictionary:(NSDictionary *)dict
{
  NSArray *messages = [FBSDKTypeUtility arrayValue:dict[@"messages"]];
  if (!messages.count) {
    return;
  }

  [messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSDictionary *messageDict = [FBSDKTypeUtility dictionaryValue:obj];
    NSString *message = [FBSDKTypeUtility coercedToStringValue:messageDict[@"message"]];
    NSString *type = [FBSDKTypeUtility coercedToStringValue:messageDict[@"type"]];
    NSString *link = [FBSDKTypeUtility coercedToStringValue:messageDict[@"link"]];
    if (!message || !type) {
      return;
    }

    NSString *loggingBehavior = FBSDKLoggingBehaviorGraphAPIDebugInfo;
    if ([type isEqualToString:@"warning"]) {
      loggingBehavior = FBSDKLoggingBehaviorGraphAPIDebugWarning;
    }
    if (link) {
      message = [message stringByAppendingFormat:@" Link: %@", link];
    }

    [self.logger.class singleShotLogEntry:loggingBehavior logEntry:message];
  }];
}

- (NSError *_Nullable)errorFromResult:(id)untypedParam request:(id<FBSDKGraphRequest>)request
{
  NSDictionary *const result = FBSDK_CAST_TO_CLASS_OR_NIL(untypedParam, NSDictionary);
  if (!result) {
    return nil;
  }

  NSDictionary *const body = FBSDK_CAST_TO_CLASS_OR_NIL(result[@"body"], NSDictionary);
  if (!body) {
    return nil;
  }

  NSDictionary *const errorDictionary = FBSDK_CAST_TO_CLASS_OR_NIL(body[@"error"], NSDictionary);
  if (!errorDictionary) {
    return nil;
  }

  NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
  [FBSDKTypeUtility dictionary:userInfo setObject:errorDictionary[@"code"] forKey:FBSDKGraphRequestErrorGraphErrorCodeKey];
  [FBSDKTypeUtility dictionary:userInfo setObject:errorDictionary[@"error_subcode"] forKey:FBSDKGraphRequestErrorGraphErrorSubcodeKey];
  // "message" is preferred over error_msg or error_reason.
  [FBSDKTypeUtility dictionary:userInfo setObject:errorDictionary[@"error_msg"] forKey:FBSDKErrorDeveloperMessageKey];
  [FBSDKTypeUtility dictionary:userInfo setObject:errorDictionary[@"error_reason"] forKey:FBSDKErrorDeveloperMessageKey];
  [FBSDKTypeUtility dictionary:userInfo setObject:errorDictionary[@"message"] forKey:FBSDKErrorDeveloperMessageKey];
  [FBSDKTypeUtility dictionary:userInfo setObject:errorDictionary[@"error_user_title"] forKey:FBSDKErrorLocalizedTitleKey];
  [FBSDKTypeUtility dictionary:userInfo setObject:errorDictionary[@"error_user_msg"] forKey:FBSDKErrorLocalizedDescriptionKey];
  [FBSDKTypeUtility dictionary:userInfo setObject:errorDictionary[@"error_user_msg"] forKey:NSLocalizedDescriptionKey];
  [FBSDKTypeUtility dictionary:userInfo setObject:result[@"code"] forKey:FBSDKGraphRequestErrorHTTPStatusCodeKey];
  [FBSDKTypeUtility dictionary:userInfo setObject:result forKey:FBSDKGraphRequestErrorParsedJSONResponseKey];

  NSString *errorCode = [[FBSDKTypeUtility numberValue:userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey]] stringValue];
  NSString *errorSubcode = [[FBSDKTypeUtility numberValue:userInfo[FBSDKGraphRequestErrorGraphErrorSubcodeKey]] stringValue];
  FBSDKErrorRecoveryConfiguration *recoveryConfiguration = [self.errorConfigurationProvider.errorConfiguration
                                                            recoveryConfigurationForCode:errorCode ?: @"*"
                                                            subcode:errorSubcode ?: @"*"
                                                            request:request];
  BOOL isTransient = [[FBSDKTypeUtility numberValue:errorDictionary[@"is_transient"]] boolValue];
  NSNumber *errorCategory = isTransient ? @(FBSDKGraphRequestErrorTransient) : @(recoveryConfiguration.errorCategory);
  [FBSDKTypeUtility dictionary:userInfo
                     setObject:errorCategory
                        forKey:FBSDKGraphRequestErrorKey];
  [FBSDKTypeUtility dictionary:userInfo
                     setObject:recoveryConfiguration.localizedRecoveryDescription
                        forKey:NSLocalizedRecoverySuggestionErrorKey];
  [FBSDKTypeUtility dictionary:userInfo
                     setObject:recoveryConfiguration.localizedRecoveryOptionDescriptions
                        forKey:NSLocalizedRecoveryOptionsErrorKey];
  FBSDKErrorRecoveryAttempter *attempter = [FBSDKErrorRecoveryAttempter recoveryAttempterFromConfiguration:recoveryConfiguration];
  [FBSDKTypeUtility dictionary:userInfo setObject:attempter forKey:NSRecoveryAttempterErrorKey];

  return [FBSDKError errorWithCode:FBSDKErrorGraphRequestGraphAPI
                          userInfo:userInfo
                           message:nil
                   underlyingError:nil];
}

- (NSError *)_errorWithCode:(FBSDKCoreError)code
                 statusCode:(NSInteger)statusCode
         parsedJSONResponse:(id<NSObject>)response
                 innerError:(NSError *)innerError
                    message:(NSString *)message
{
  NSMutableDictionary *const userInfo = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:userInfo setObject:@(statusCode) forKey:FBSDKGraphRequestErrorHTTPStatusCodeKey];

  if (response) {
    [FBSDKTypeUtility dictionary:userInfo setObject:response forKey:FBSDKGraphRequestErrorParsedJSONResponseKey];
  }

  if (innerError) {
    [FBSDKTypeUtility dictionary:userInfo setObject:innerError forKey:FBSDKGraphRequestErrorParsedJSONResponseKey];
  }

  if (message) {
    [FBSDKTypeUtility dictionary:userInfo setObject:message forKey:FBSDKErrorDeveloperMessageKey];
  }

  return
  [[NSError alloc]
   initWithDomain:FBSDKErrorDomain
   code:code
   userInfo:userInfo];
}

#pragma mark - Private methods (logging and completion)

- (void)logAndInvokeHandler:(FBSDKURLSessionTaskBlock)handler
                      error:(NSError *)error
{
  if (error) {
    NSString *logEntry = [NSString
                          stringWithFormat:@"FBSDKURLSessionTask <#%lu>:\n  Error: '%@'\n%@\n",
                          (unsigned long)[FBSDKLogger generateSerialNumber],
                          error.localizedDescription,
                          error.userInfo];

    [self logMessage:logEntry];
  }

  [self invokeHandler:handler error:error response:nil responseData:nil];
}

- (void)logAndInvokeHandler:(FBSDKURLSessionTaskBlock)handler
                   response:(NSURLResponse *)response
               responseData:(NSData *)responseData
           requestStartTime:(uint64_t)requestStartTime
{
  // Basic logging just prints out the URL.  FBSDKGraphRequest logging provides more details.
  NSString *mimeType = response.MIMEType;
  NSMutableString *mutableLogEntry = [NSMutableString stringWithFormat:@"FBSDKGraphRequestConnection <#%lu>:\n  Duration: %llu msec\nResponse Size: %lu kB\n  MIME type: %@\n",
                                      (unsigned long)[FBSDKLogger generateSerialNumber],
                                      [FBSDKInternalUtility currentTimeInMilliseconds] - requestStartTime,
                                      (unsigned long)responseData.length / 1024,
                                      mimeType];

  if ([mimeType isEqualToString:@"text/javascript"]) {
    NSString *responseUTF8 = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    [mutableLogEntry appendFormat:@"  Response:\n%@\n\n", responseUTF8];
  }

  [self logMessage:mutableLogEntry];

  [self invokeHandler:handler error:nil response:response responseData:responseData];
}

- (void)invokeHandler:(FBSDKURLSessionTaskBlock)handler
                error:(NSError *)error
             response:(NSURLResponse *)response
         responseData:(NSData *)responseData
{
  if (handler != nil) {
    dispatch_async(dispatch_get_main_queue(), ^{
      handler(responseData, response, error);
    });
  }
}

- (void)logMessage:(NSString *)message
{
  [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorNetworkRequests formatString:@"%@", message];
}

- (void)taskDidCompleteWithResponse:(NSURLResponse *)response
                               data:(NSData *)data
                   requestStartTime:(uint64_t)requestStartTime
                            handler:(FBSDKURLSessionTaskBlock)handler
{
  @try {
    [self logAndInvokeHandler:handler
                     response:response
                 responseData:data
             requestStartTime:requestStartTime];
  } @finally {}
}

#pragma mark - Private methods (miscellaneous)

- (void)_taskDidCompleteWithError:(NSError *)error
                          handler:(FBSDKURLSessionTaskBlock)handler
{
  @try {
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == kCFURLErrorSecureConnectionFailed) {
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                             logEntry:@"WARNING: FBSDK secure network request failed. Please verify you have followed "
       "all of the steps at https://developers.facebook.com/docs/ios/getting-started"];
    }
    [self logAndInvokeHandler:handler error:error];
  } @finally {}
}

- (void)logRequest:(NSMutableURLRequest *)request
        bodyLength:(NSUInteger)bodyLength
        bodyLogger:(FBSDKLogger *)bodyLogger
  attachmentLogger:(FBSDKLogger *)attachmentLogger
{
  if (_logger.isActive) {
    [_logger appendFormat:@"Request <#%lu>:\n", (unsigned long)_logger.loggerSerialNumber];
    [_logger appendKey:@"URL" value:request.URL.absoluteString];
    [_logger appendKey:@"Method" value:request.HTTPMethod];
    [_logger appendKey:@"UserAgent" value:[request valueForHTTPHeaderField:@"User-Agent"]];
    [_logger appendKey:@"MIME" value:[request valueForHTTPHeaderField:@"Content-Type"]];

    if (bodyLength != 0) {
      [_logger appendKey:@"Body Size" value:[NSString stringWithFormat:@"%lu kB", (unsigned long)bodyLength / 1024]];
    }

    if (bodyLogger != nil) {
      [_logger appendKey:@"Body (w/o attachments)" value:bodyLogger.contents];
    }

    if (attachmentLogger != nil) {
      [_logger appendKey:@"Attachments" value:attachmentLogger.contents];
    }

    [_logger appendString:@"\n"];

    [_logger emitToNSLog];
  }
}

- (NSString *)accessTokenWithRequest:(id<FBSDKGraphRequest>)request
{
  NSString *token = request.tokenString ?: request.parameters[kAccessTokenKey];
  FBSDKGraphRequestFlags flags = [(id<FBSDKGraphRequestInternal>)request flags];
  if (!token && !(flags & FBSDKGraphRequestFlagSkipClientToken) && [[self.settings.class clientToken] length] > 0) {
    NSString *baseTokenString = [NSString stringWithFormat:@"%@|%@", [self.settings.class appID], [self.settings.class clientToken]];
    if ([FBSDKAuthenticationToken.currentAuthenticationToken.graphDomain isEqualToString:@"gaming"]) {
      return [@"GG|" stringByAppendingString:baseTokenString];
    } else {
      return baseTokenString;
    }
  }
  return token;
}

- (void)registerTokenToOmitFromLog:(NSString *)token
{
  if (![[self.settings.class loggingBehaviors] containsObject:FBSDKLoggingBehaviorAccessTokens]) {
    [FBSDKLogger registerStringToReplace:token replaceWith:@"ACCESS_TOKEN_REMOVED"];
  }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (NSString *)userAgent
{
  static NSString *agent = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    agent = [NSString stringWithFormat:@"%@.%@", kUserAgentBase, FBSDK_VERSION_STRING];
  });
  NSString *agentWithSuffix = nil;
  if ([self.settings.class userAgentSuffix]) {
    agentWithSuffix = [NSString stringWithFormat:@"%@/%@", agent, [self.settings.class userAgentSuffix]];
  }
  if (@available(iOS 13.0, *)) {
    SEL selector = NSSelectorFromString(@"isMacCatalystApp");
    if (selector && [self.macCatalystDeterminator respondsToSelector:selector] && [self.macCatalystDeterminator performSelector:selector]) {
      return [NSString stringWithFormat:@"%@/%@", agentWithSuffix ?: agent, @"macOS"];
    }
  }

  return agentWithSuffix ?: agent;
}

#pragma clang diagnostic pop

#pragma mark - NSURLSessionDataDelegate

- (void)        URLSession:(NSURLSession *)session
                      task:(NSURLSessionTask *)task
           didSendBodyData:(int64_t)bytesSent
            totalBytesSent:(int64_t)totalBytesSent
  totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
  id<FBSDKGraphRequestConnectionDelegate> delegate = self.delegate;

  if ([delegate respondsToSelector:@selector(requestConnection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
    [delegate requestConnection:self
                didSendBodyData:(NSUInteger)bytesSent
              totalBytesWritten:(NSUInteger)totalBytesSent
      totalBytesExpectedToWrite:(NSUInteger)totalBytesExpectedToSend];
  }
}

#pragma mark - FBSDKGraphErrorRecoveryProcessorDelegate

#if !TARGET_OS_TV
- (void)processorDidAttemptRecovery:(FBSDKGraphErrorRecoveryProcessor *)processor didRecover:(BOOL)didRecover error:(NSError *)error
{
  @try {
    if (didRecover) {
      id<FBSDKGraphRequest> originalRequest = _recoveringRequestMetadata.request;
      id<FBSDKGraphRequest> retryRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:originalRequest.graphPath
                                                                             parameters:originalRequest.parameters
                                                                            tokenString:[FBSDKAccessToken currentAccessToken].tokenString
                                                                             HTTPMethod:originalRequest.HTTPMethod
                                                                                version:originalRequest.version
                                                                                  flags:FBSDKGraphRequestFlagDisableErrorRecovery
                                                                      connectionFactory:self.connectionFactory];
      FBSDKGraphRequestMetadata *retryMetadata = [[FBSDKGraphRequestMetadata alloc] initWithRequest:retryRequest completionHandler:_recoveringRequestMetadata.completionHandler batchParameters:_recoveringRequestMetadata.batchParameters];
      [retryRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *retriedError) {
        [self processResultBody:result error:retriedError metadata:retryMetadata canNotifyDelegate:YES];
        self->_errorRecoveryProcessor = nil;
        self->_recoveringRequestMetadata = nil;
      }];
    } else {
      [self processResultBody:nil error:error metadata:_recoveringRequestMetadata canNotifyDelegate:YES];
      _errorRecoveryProcessor = nil;
      _recoveringRequestMetadata = nil;
    }
  } @catch (NSException *exception) {}
}

#endif

#pragma mark - Debugging helpers

- (NSString *)description
{
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@: %p, %lu request(s): (\n",
                             NSStringFromClass([self class]),
                             self,
                             (unsigned long)self.requests.count];
  BOOL comma = NO;
  for (FBSDKGraphRequestMetadata *metadata in self.requests) {
    id<FBSDKGraphRequest> request = metadata.request;
    if (comma) {
      [result appendString:@",\n"];
    }
    [result appendString:request.formattedDescription];
    comma = YES;
  }
  [result appendString:@"\n)>"];
  return result;
}

// MARK: - Testability

#if DEBUG
 #if FBSDKTEST

/// Resets the default connection timeout to 60 seconds
+ (void)resetDefaultConnectionTimeout
{
  g_defaultTimeout = 60;
}

- (NSString *)_overrideVersionPart
{
  return _overrideVersionPart;
}

+ (void)resetCanMakeRequests
{
  _canMakeRequests = NO;
}

 #endif
#endif

@end
