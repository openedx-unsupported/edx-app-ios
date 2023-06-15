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

#import "MSIDAADOpenIdConfigurationInfoResponseSerializer.h"
#import "MSIDOpenIdProviderMetadata.h"
#import "MSIDAADJsonResponsePreprocessor.h"
#import "NSURL+MSIDAADUtils.h"

static NSString *s_tenantIdPlaceholder = @"{tenantid}";

@implementation MSIDAADOpenIdConfigurationInfoResponseSerializer

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.preprocessor = [MSIDAADJsonResponsePreprocessor new];
    }
    return self;
}

- (id)responseObjectForResponse:(NSHTTPURLResponse *)httpResponse
                           data:(NSData *)data
                        context:(id <MSIDRequestContext>)context
                          error:(NSError **)error
{
    NSError *jsonError;
    NSMutableDictionary *jsonObject = [[super responseObjectForResponse:httpResponse data:data context:context error:&jsonError] mutableCopy];
    
    if (!jsonObject)
    {
        if (error) *error = jsonError;
        return nil;
    }
    
    NSString *oauthError = [jsonObject msidStringObjectForKey:MSID_OAUTH2_ERROR];
    
    if (jsonObject[MSID_OAUTH2_ERROR] && !oauthError)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning, context, @"oauth error is not a string, ignoring it.");
    }
    
    if (oauthError)
    {
        NSString *oauthErrorDescription = [jsonObject msidStringObjectForKey:MSID_OAUTH2_ERROR_DESCRIPTION];
        
        NSError *localError = MSIDCreateError(MSIDErrorDomain,
                                              MSIDErrorAuthorityValidation,
                                              oauthErrorDescription,
                                              oauthError,
                                              nil,
                                              nil,
                                              context.correlationId,
                                              nil, YES);
        if (error) *error = localError;
        
        return nil;
    }
    
    __auto_type metadata = [MSIDOpenIdProviderMetadata new];
    
    if (![jsonObject msidAssertType:NSString.class ofKey:@"authorization_endpoint" required:YES error:error]) return nil;
    __auto_type authorizationEndpoint = (NSString *)jsonObject[@"authorization_endpoint"];
    
    metadata.authorizationEndpoint = [NSURL URLWithString:authorizationEndpoint];
    
    if (![jsonObject msidAssertType:NSString.class ofKey:@"token_endpoint" required:YES error:error]) return nil;
    __auto_type tokenEndpoint = (NSString *)jsonObject[@"token_endpoint"];
    
    metadata.tokenEndpoint = [NSURL URLWithString:tokenEndpoint];
    
    if (![jsonObject msidAssertType:NSString.class ofKey:@"issuer" required:YES error:error]) return nil;
    NSString *issuerString = (NSString *)jsonObject[@"issuer"];
    
    // If `issuer` contains {tenantid}, it is AAD authority.
    // Lets exctract tenant from `endpoint` and put it instead of {tenantid}.
    NSString *tenantId = [self.endpoint msidAADTenant];
    
    if ([issuerString containsString:s_tenantIdPlaceholder] && tenantId)
    {
        issuerString = [issuerString stringByReplacingOccurrencesOfString:s_tenantIdPlaceholder withString:tenantId];
    }
    
    metadata.issuer = [NSURL URLWithString:issuerString];
    
    if (![jsonObject msidAssertType:NSString.class ofKey:@"end_session_endpoint" required:NO error:error]) return nil;
    
    NSString *endSessionUrlString = (NSString *)jsonObject[@"end_session_endpoint"];
    
    if (endSessionUrlString)
    {
        metadata.endSessionEndpoint = [NSURL URLWithString:endSessionUrlString];
    }
    else
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning, context, @"End session endpoint not returned in Openid metadata");
    }
    
    return metadata;
}

@end
