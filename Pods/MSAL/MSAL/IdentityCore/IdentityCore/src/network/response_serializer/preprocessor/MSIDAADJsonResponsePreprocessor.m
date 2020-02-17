//
//  MSIDAADJsonResponsePreprocessor.m
//  IdentityCore
//
//  Created by Sergey Demchenko on 12/24/18.
//  Copyright © 2018 Microsoft. All rights reserved.
//

#import "MSIDAADJsonResponsePreprocessor.h"
#import "MSIDTelemetryEventStrings.h"
#import "NSString+MSIDTelemetryExtensions.h"

@implementation MSIDAADJsonResponsePreprocessor

- (id)responseObjectForResponse:(NSHTTPURLResponse *)httpResponse
                           data:(NSData *)data
                        context:(id <MSIDRequestContext>)context
                          error:(NSError **)error
{
    NSError *jsonError;
    NSMutableDictionary *jsonObject = [[super responseObjectForResponse:httpResponse data:data context:context error:&jsonError] mutableCopy];
    
    if (jsonError)
    {
        if (error) *error = jsonError;
        return nil;
    }
    
    if (jsonObject && ![jsonObject isKindOfClass:[NSDictionary class]])
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorServerInvalidResponse, @"Response is not of the expected type: NSDictionary.", nil, nil, nil, context.correlationId, nil, NO);
        }
        
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Response is not of the expected type: NSDictionary.");
        
        return nil;
    }
    
    jsonObject[MSID_OAUTH2_CORRELATION_ID_RESPONSE] = httpResponse.allHeaderFields[MSID_OAUTH2_CORRELATION_ID_REQUEST_VALUE];
    
    NSString *clientTelemetry = httpResponse.allHeaderFields[MSID_OAUTH2_CLIENT_TELEMETRY];
    if (![NSString msidIsStringNilOrBlank:clientTelemetry])
    {
        NSString *speInfo = [clientTelemetry msidParsedClientTelemetry][MSID_TELEMETRY_KEY_SPE_INFO];
        
        if (![NSString msidIsStringNilOrBlank:speInfo])
        {
            jsonObject[MSID_TELEMETRY_KEY_SPE_INFO] = speInfo;
        }
    }
    
    return jsonObject;
}


@end
