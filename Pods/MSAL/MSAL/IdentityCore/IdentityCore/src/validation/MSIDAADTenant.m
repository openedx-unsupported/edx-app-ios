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


#import "MSIDAADTenant.h"

NSString *const MSIDAADTenantTypeCommonRawValue = @"common";
NSString *const MSIDAADTenantTypeOrganizationsRawValue = @"organizations";
NSString *const MSIDAADTenantTypeConsumersRawValue = @"consumers";

@implementation MSIDAADTenant

- (nullable instancetype)initWithRawTenant:(nonnull NSString *)rawTenant
                                   context:(nullable id<MSIDRequestContext>)context
                                     error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    self = [self init];
    if (self)
    {
        rawTenant = rawTenant.lowercaseString.msidTrimmedString;
        
        if (!rawTenant)
        {
            if (error)
            {
                *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Tenant value should not be nil.", nil, nil, nil, context.correlationId, nil, YES);
            }
            return nil;
        }

        if ([rawTenant isEqualToString:MSIDAADTenantTypeCommonRawValue])
        {
            _type = MSIDAADTenantTypeCommon;
        }
        else if ([rawTenant isEqualToString:MSIDAADTenantTypeOrganizationsRawValue])
        {
            _type = MSIDAADTenantTypeOrganizations;
        }
        else if ([rawTenant isEqualToString:MSIDAADTenantTypeConsumersRawValue])
        {
            _type = MSIDAADTenantTypeConsumers;
        }
        else
        {
            _type = MSIDAADTenantTypeIdentifier;
        }
        
        _rawTenant = rawTenant;
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDAADTenant *tenant = [[self.class allocWithZone:zone] init];
    tenant->_rawTenant = [_rawTenant copyWithZone:zone];
    tenant->_type = _type;
    
    return tenant;
}

@end
