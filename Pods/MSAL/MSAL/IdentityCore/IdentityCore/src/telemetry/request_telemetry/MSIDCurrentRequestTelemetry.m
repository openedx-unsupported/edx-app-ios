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

#if !EXCLUDE_FROM_MSALCPP

#import "MSIDCurrentRequestTelemetry.h"
#import "MSIDCurrentRequestTelemetrySerializedItem.h"
#import "MSIDRequestTelemetryConstants.h"

@implementation MSIDCurrentRequestTelemetry

#pragma mark - MSIDTelemetryStringSerializable

- (NSString *)telemetryString
{
    return [self serializeCurrentTelemetryString];
}

#pragma mark - Init

- (nullable instancetype)initWithAppId:(NSInteger)appId
                 tokenCacheRefreshType:(TokenCacheRefreshType)tokenCacheRefreshType
                        platformFields:(nullable NSMutableArray *)platformFields
{
    self = [super init];
    if (self)
    {
        _schemaVersion = HTTP_REQUEST_TELEMETRY_SCHEMA_VERSION;
        _apiId = appId;
        _tokenCacheRefreshType = tokenCacheRefreshType;
        _platformFields = platformFields;
    }
    
    return self;
}

#pragma mark - Private

- (NSString *)serializeCurrentTelemetryString
{
    MSIDCurrentRequestTelemetrySerializedItem *currentTelemetryFields = [self createSerializedItem];
    return [currentTelemetryFields serialize];
}

- (MSIDCurrentRequestTelemetrySerializedItem *)createSerializedItem
{
    NSArray *defaultFields = @[[NSNumber numberWithInteger:self.apiId], [NSNumber numberWithInteger:self.tokenCacheRefreshType]];
    return [[MSIDCurrentRequestTelemetrySerializedItem alloc] initWithSchemaVersion:[NSNumber numberWithInteger:self.schemaVersion] defaultFields:defaultFields platformFields:self.platformFields];
}

@end

#endif
