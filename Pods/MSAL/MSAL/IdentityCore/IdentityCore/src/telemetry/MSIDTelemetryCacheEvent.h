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

#import "MSIDTelemetryBaseEvent.h"
#import "MSIDCredentialCacheItem.h"
#import "MSIDCredentialCacheItem+MSIDBaseToken.h"

@interface MSIDTelemetryCacheEvent : MSIDTelemetryBaseEvent

- (void)setTokenType:(MSIDCredentialType)tokenType;
- (void)setStatus:(NSString *)status;
- (void)setIsRT:(NSString *)isRT;
- (void)setIsMRRT:(NSString *)isMRRT;
- (void)setIsFRT:(NSString *)isFRT;
- (void)setRTStatus:(NSString *)status;
- (void)setMRRTStatus:(NSString *)status;
- (void)setFRTStatus:(NSString *)status;
- (void)setSpeInfo:(NSString  *)speInfo;
- (void)setToken:(MSIDBaseToken *)token;
- (void)setCacheWipeApp:(NSString *)wipeApp;
- (void)setCacheWipeTime:(NSString *)wipeTime;
- (void)setWipeData:(NSDictionary *)wipeData;
- (void)setExternalCacheSeedingStatus:(NSString *)status;

@end
