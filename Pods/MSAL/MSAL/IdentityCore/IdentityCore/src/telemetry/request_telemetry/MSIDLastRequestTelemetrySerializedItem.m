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

#import "MSIDCurrentRequestTelemetrySerializedItem+Internal.h"
#import "MSIDLastRequestTelemetrySerializedItem.h"

@interface MSIDLastRequestTelemetrySerializedItem()

@property (nonatomic) NSArray<MSIDRequestTelemetryErrorInfo *> *errorsInfo;
@property (nonatomic) NSMutableArray<MSIDRequestTelemetryErrorInfo *> *unserializedErrors;

@end

@implementation MSIDLastRequestTelemetrySerializedItem

// // Represents 350 byte limit for size of last request telemetry string sent to server
static int telemetryStringSizeLimit = 350;

+ (int)telemetryStringSizeLimit
{
    return telemetryStringSizeLimit;
}

+ (void)setTelemetryStringSizeLimit:(int)newLimit
{
    telemetryStringSizeLimit = newLimit;
}

- (instancetype)initWithSchemaVersion:(NSNumber *)schemaVersion defaultFields:(NSArray *)defaultFields errorInfo:(NSArray *)errorsInfo platformFields:(NSArray *)platformFields
{
    self = [super initWithSchemaVersion:schemaVersion defaultFields:defaultFields platformFields:platformFields];
    if (self)
    {
        _errorsInfo = errorsInfo;
    }
    return self;
}

// Builds last telemetry string using default serialization of each set of fields
// specified in the last telemetry string schema
- (NSString *)serialize
{
    NSString *telemetryString = [NSString stringWithFormat:@"%@|", self.schemaVersion];
    telemetryString = [telemetryString stringByAppendingFormat:@"%@|", [super serializeFields: super.defaultFields]];
    
    NSUInteger startLength = [telemetryString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    telemetryString = [telemetryString stringByAppendingFormat:@"%@|", [self serializeErrorsInfoWithCurrentStringSize:startLength]];
    
    telemetryString = [telemetryString stringByAppendingFormat:@"%@", [super serializeFields: self.platformFields]];
    
    return telemetryString;
}

#pragma mark Helper

- (NSString *)serializeErrorsInfoWithCurrentStringSize:(NSUInteger)startLength
{
    NSString *failedRequestsString = @"";
    NSString *errorMessagesString = @"";
    
    if (self.errorsInfo.count > 0)
    {
        int lastIndex = (int)self.errorsInfo.count - 1;
        
        // Set first post in fencepost structure -- last item in string doesn't have comma at the end
        NSString *currentFailedRequest = [NSString stringWithFormat:@"%ld,%@", (long)self.errorsInfo[lastIndex].apiId, self.errorsInfo[lastIndex].correlationId ?: @""];
        NSString *currentErrorMessage = [NSString stringWithFormat:@"%@", self.errorsInfo[lastIndex].error ?: @""];
        
        // Only add error info into string if the resulting string smaller than size limit
        if ((int)([currentFailedRequest lengthOfBytesUsingEncoding:NSUTF8StringEncoding] +
                [currentErrorMessage lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + startLength) < [MSIDLastRequestTelemetrySerializedItem telemetryStringSizeLimit])
        {
            failedRequestsString = [currentFailedRequest stringByAppendingString:failedRequestsString];
            errorMessagesString = [currentErrorMessage stringByAppendingString:errorMessagesString];
        }
        else
        {
            [self addRemainingErrorsToUnserializedTelemetry:lastIndex];
            
            return [NSString stringWithFormat:@"%@|%@", failedRequestsString, errorMessagesString];
        }

        // Fill in remaining errors with comma at the end of each error
        for (int i = lastIndex - 1; i >= 0; i--)
        {
            currentFailedRequest = [NSString stringWithFormat:@"%ld,%@,", (long)self.errorsInfo[i].apiId, self.errorsInfo[i].correlationId ?: @""];
            currentErrorMessage = [NSString stringWithFormat:@"%@,", self.errorsInfo[i].error ?: @""];
            
            NSString *newFailedRequestsString = [currentFailedRequest stringByAppendingString:failedRequestsString];
            NSString *newErrorMessagesString = [currentErrorMessage stringByAppendingString:errorMessagesString];
            
            // Only add next error into string if the resulting string smaller than size limit, otherwise stop building
            // the string
            if ((int)([newFailedRequestsString lengthOfBytesUsingEncoding:NSUTF8StringEncoding] +
                    [newErrorMessagesString lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + startLength) < [MSIDLastRequestTelemetrySerializedItem telemetryStringSizeLimit])
            {
                failedRequestsString = newFailedRequestsString;
                errorMessagesString = newErrorMessagesString;
            }
            else
            {
                [self addRemainingErrorsToUnserializedTelemetry:i];
                
                return [NSString stringWithFormat:@"%@|%@", failedRequestsString, errorMessagesString];
            }
        }
    }
    NSString *telemetryString = [NSString stringWithFormat:@"%@|%@", failedRequestsString, errorMessagesString];
    return telemetryString;
}

- (NSMutableArray<MSIDRequestTelemetryErrorInfo *> *)getUnserializedTelemetry
{
    return self.unserializedErrors;
}

- (void)addRemainingErrorsToUnserializedTelemetry:(int)index
{
    if (!self.unserializedErrors)
    {
        self.unserializedErrors = [NSMutableArray<MSIDRequestTelemetryErrorInfo *> new];
    }
    
    for (int i = 0; i <= index; i++)
    {
        [self.unserializedErrors addObject:self.errorsInfo[i]];
    }
}

@end

#endif
