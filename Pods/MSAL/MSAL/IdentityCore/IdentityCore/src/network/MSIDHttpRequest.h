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
#import "MSIDHttpRequestProtocol.h"

@protocol MSIDRequestSerialization;
@protocol MSIDResponseSerialization;
@protocol MSIDRequestContext;
@protocol MSIDHttpRequestTelemetryHandling;
@protocol MSIDHttpRequestErrorHandling;
@class MSIDURLSessionManager;

@interface MSIDHttpRequest : NSObject <MSIDHttpRequestProtocol>
{
@protected
    NSDictionary<NSString *, NSString *> *_parameters;
    NSURLRequest *_urlRequest;
    id<MSIDRequestSerialization> _requestSerializer;
    id<MSIDResponseSerialization> _responseSerializer;
    id<MSIDHttpRequestTelemetryHandling> _telemetry;
    id<MSIDHttpRequestErrorHandling> _errorHandler;
    id<MSIDRequestContext> _context;
}

@property (nonatomic, nonnull) MSIDURLSessionManager *sessionManager;

@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *parameters;

@property (nonatomic, nullable) NSURLRequest *urlRequest;

@property (nonatomic, nonnull) id<MSIDRequestSerialization> requestSerializer;

@property (nonatomic, nonnull) id<MSIDResponseSerialization> responseSerializer;

@property (nonatomic, nonnull) id<MSIDResponseSerialization> errorResponseSerializer;

@property (nonatomic, nullable) id<MSIDHttpRequestTelemetryHandling> telemetry;

@property (nonatomic, nullable) id<MSIDHttpRequestErrorHandling> errorHandler;

@property (nonatomic, nullable) id<MSIDRequestContext> context;

@property (nonatomic) NSInteger retryCounter;
@property (nonatomic) NSTimeInterval retryInterval;
@property (nonatomic) NSTimeInterval requestTimeoutInterval;

@property (class, nonatomic, readwrite) NSInteger retryCountSetting;
@property (class, nonatomic, readwrite) NSTimeInterval retryIntervalSetting;
@property (class, nonatomic, readwrite) NSTimeInterval requestTimeoutInterval;

@end
