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

#import "MSIDHttpRequest.h"
#import "MSIDHttpResponseSerializer.h"
#import "MSIDUrlRequestSerializer.h"
#import "MSIDHttpRequestTelemetryHandling.h"
#import "MSIDHttpRequestErrorHandling.h"
#import "MSIDHttpRequestConfiguratorProtocol.h"
#import "MSIDHttpRequestTelemetry.h"
#import "MSIDURLSessionManager.h"
#import "MSIDJsonResponsePreprocessor.h"
#import "MSIDOAuthRequestConfigurator.h"
#import "MSIDHttpRequestServerTelemetryHandling.h"

static NSInteger s_retryCount = 1;
static NSTimeInterval s_retryInterval = 0.5;
static NSTimeInterval s_requestTimeoutInterval = 300;

@implementation MSIDHttpRequest

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _sessionManager = MSIDURLSessionManager.defaultManager;
        __auto_type responseSerializer = [MSIDHttpResponseSerializer new];
        responseSerializer.preprocessor = [MSIDJsonResponsePreprocessor new];
        _responseSerializer = responseSerializer;
        _requestSerializer = [MSIDUrlRequestSerializer new];
#if !EXCLUDE_FROM_MSALCPP
        _telemetry = [MSIDHttpRequestTelemetry new];
#endif
        _retryCounter = s_retryCount;
        _retryInterval = s_retryInterval;
        _requestTimeoutInterval = s_requestTimeoutInterval;
        _cache = [NSURLCache sharedURLCache];
        _shouldCacheResponse = NO;
    }

    return self;
}

- (void)sendWithBlock:(MSIDHttpRequestDidCompleteBlock)completionBlock
{
    NSParameterAssert(self.urlRequest);

    __auto_type requestConfigurator = [MSIDOAuthRequestConfigurator new];
    requestConfigurator.timeoutInterval = _requestTimeoutInterval;
    [requestConfigurator configure:self];

    self.urlRequest = [self.requestSerializer serializeWithRequest:self.urlRequest parameters:self.parameters headers:self.headers];
    NSCachedURLResponse *response = _shouldCacheResponse ? [self cachedResponse] : nil;
    if (response)
    {
        NSError *error = nil;
        id responseObject = [self.responseSerializer responseObjectForResponse:(NSHTTPURLResponse *)response.response
                                                                          data:response.data
                                                                       context:self.context
                                                                         error:&error];

        if (!responseObject)
        {
            [self.cache removeCachedResponseForRequest:self.urlRequest];
            MSID_LOG_WITH_CTX(MSIDLogLevelVerbose,self.context, @"Removing invalid response from cache %@, response: %@", _PII_NULLIFY(self.urlRequest), _PII_NULLIFY(response.response));
        }
        else
        {
            if (completionBlock) { completionBlock(responseObject, error); }
            return;
        }
    }
#if !EXCLUDE_FROM_MSALCPP
    [self.telemetry sendRequestEventWithId:self.context.telemetryRequestId];
#endif
    [self.serverTelemetry setTelemetryToRequest:self];

    MSID_LOG_WITH_CTX(MSIDLogLevelVerbose,self.context, @"Sending network request: %@, headers: %@", _PII_NULLIFY(self.urlRequest), _PII_NULLIFY(self.urlRequest.allHTTPHeaderFields));

    [[self.sessionManager.session dataTaskWithRequest:self.urlRequest completionHandler:^(NSData *data, NSURLResponse *urlResponse, NSError *error)
      {
          MSID_LOG_WITH_CTX(MSIDLogLevelVerbose,self.context, @"Received network response: %@, error %@", _PII_NULLIFY(urlResponse), _PII_NULLIFY(error));

          if (urlResponse) NSAssert([urlResponse isKindOfClass:NSHTTPURLResponse.class], NULL);

          __auto_type httpResponse = (NSHTTPURLResponse *)urlResponse;
#if !EXCLUDE_FROM_MSALCPP
          [self.telemetry responseReceivedEventWithContext:self.context
                                                urlRequest:self.urlRequest
                                              httpResponse:httpResponse
                                                      data:data
                                                     error:error];
#endif

        void (^completeBlockWrapper)(id, NSError *) = ^(id wrapperResponse, NSError *wrapperError)
        {
            [self.serverTelemetry handleError:wrapperError context:self.context];

            if (completionBlock) { completionBlock(wrapperResponse, wrapperError); }
        };

          if (error)
          {
              completeBlockWrapper(nil, error);
          }
          else if (httpResponse.statusCode == 200)
          {
              id responseObject = [self.responseSerializer responseObjectForResponse:httpResponse data:data context:self.context error:&error];

              MSID_LOG_WITH_CTX(MSIDLogLevelVerbose,self.context, @"Parsed response: %@, error %@, error domain: %@, error code: %ld", _PII_NULLIFY(responseObject), _PII_NULLIFY(error), error.domain, (long)error.code);

              if (responseObject && self->_shouldCacheResponse)
              {
                  NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:urlResponse data:data];
                  [self setCachedResponse:cachedResponse forRequest:self.urlRequest];
              }

              completeBlockWrapper(responseObject, error);
          }
          else
          {
              if (self.errorHandler)
              {
                  id<MSIDResponseSerialization> responseSerializer = self.errorResponseSerializer ? self.errorResponseSerializer : self.responseSerializer;

                  [self.errorHandler handleError:error
                                    httpResponse:httpResponse
                                            data:data
                                     httpRequest:self
                              responseSerializer:responseSerializer
                                         context:self.context
                                 completionBlock:completeBlockWrapper];
              }
              else
              {
                  completeBlockWrapper(nil, error);
              }
          }

      }] resume];
}

+ (NSInteger)retryCountSetting { return s_retryCount; }
+ (void)setRetryCountSetting:(NSInteger)retryCountSetting { s_retryCount = retryCountSetting; }

+ (NSTimeInterval)retryIntervalSetting { return s_retryInterval; }
+ (void)setRetryIntervalSetting:(NSTimeInterval)retryIntervalSetting { s_retryInterval = retryIntervalSetting; }
+ (void)setRequestTimeoutInterval:(NSTimeInterval)requestTimeoutInterval { s_requestTimeoutInterval = requestTimeoutInterval; }
+ (NSTimeInterval)requestTimeoutInterval { return s_requestTimeoutInterval; }

- (NSCachedURLResponse *)cachedResponse
{
    return [self.cache cachedResponseForRequest:self.urlRequest];
}

-(void)setCachedResponse:(__unused NSCachedURLResponse *)cachedResponse forRequest:(__unused NSURLRequest *)request
{
   [self.cache storeCachedResponse:cachedResponse forRequest:request];
}

@end
