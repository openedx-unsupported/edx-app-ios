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

#import "MSIDLegacyTokenCacheAccessor.h"
#import "MSIDKeyedArchiverSerializer.h"
#import "MSIDLegacySingleResourceToken.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDTelemetryCacheEvent.h"
#import "MSIDLegacyTokenCacheKey.h"
#import "MSIDTokenResponse.h"
#import "NSDate+MSIDExtensions.h"
#import "MSIDAuthority.h"
#import "MSIDOauth2Factory.h"
#import "MSIDLegacyTokenCacheQuery.h"
#import "MSIDLegacyAccessToken.h"
#import "MSIDLegacyRefreshToken.h"
#import "MSIDLegacyTokenCacheItem.h"
#import "MSIDBrokerResponse.h"
#import "MSIDTokenFilteringHelper.h"
#import "NSString+MSIDExtensions.h"
#import "MSIDAADV1IdTokenClaims.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDTelemetry+Cache.h"
#import "NSURL+MSIDExtensions.h"
#import "NSURL+MSIDAADUtils.h"

@interface MSIDLegacyTokenCacheAccessor()
{
    id<MSIDTokenCacheDataSource> _dataSource;
    MSIDKeyedArchiverSerializer *_serializer;
    NSArray *_otherAccessors;
}

@end

@implementation MSIDLegacyTokenCacheAccessor

#pragma mark - Init

- (instancetype)initWithDataSource:(id<MSIDTokenCacheDataSource>)dataSource
               otherCacheAccessors:(NSArray<id<MSIDCacheAccessor>> *)otherAccessors
{
    self = [super init];

    if (self)
    {
        _dataSource = dataSource;
        _serializer = [[MSIDKeyedArchiverSerializer alloc] init];
        _otherAccessors = otherAccessors;
    }

    return self;
}

#pragma mark - Saving

- (BOOL)saveTokensWithConfiguration:(MSIDConfiguration *)configuration
                           response:(MSIDTokenResponse *)response
                            factory:(MSIDOauth2Factory *)factory
                            context:(id<MSIDRequestContext>)context
                              error:(NSError **)error
{
    if (response.isMultiResource)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context,@"(Legacy accessor) Saving multi resource refresh token");
        BOOL result = [self saveAccessTokenWithConfiguration:configuration response:response factory:factory context:context error:error];

        if (!result) return NO;

        return [self saveSSOStateWithConfiguration:configuration response:response factory:factory context:context error:error];
    }
    else
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context,@"(Legacy accessor) Saving single resource refresh token");
        return [self saveLegacySingleResourceTokenWithConfiguration:configuration response:response factory:factory context:context error:error];
    }
}

- (BOOL)saveSSOStateWithConfiguration:(MSIDConfiguration *)configuration
                             response:(MSIDTokenResponse *)response
                              factory:(MSIDOauth2Factory *)factory
                              context:(id<MSIDRequestContext>)context
                                error:(NSError **)error
{
    if (!response)
    {
        MSIDFillAndLogError(error, MSIDErrorInternal, @"No response provided", context.correlationId);
        return NO;
    }

    MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context,@"(Legacy accessor) Saving SSO state");

    BOOL result = [self saveRefreshTokenWithConfiguration:configuration
                                                 response:response
                                                  factory:factory
                                                  context:context
                                                    error:error];

    if (!result)
    {
        return NO;
    }

    for (id<MSIDCacheAccessor> accessor in _otherAccessors)
    {
        NSError *otherAccessorError = nil;

        if (![accessor saveSSOStateWithConfiguration:configuration
                                            response:response
                                             factory:factory
                                             context:context
                                               error:&otherAccessorError])
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning,context, @"Failed to save SSO state in other accessor: %@, error %@", accessor.class, MSID_PII_LOG_MASKABLE(otherAccessorError));
        }
    }

    return YES;
}

#pragma mark - Refresh token read

- (MSIDRefreshToken *)getRefreshTokenWithAccount:(MSIDAccountIdentifier *)accountIdentifier
                                        familyId:(NSString *)familyId
                                   configuration:(MSIDConfiguration *)configuration
                                         context:(id<MSIDRequestContext>)context
                                           error:(NSError **)error
{
    MSIDRefreshToken *refreshToken = [self getRefreshableTokenWithAccount:accountIdentifier
                                                                 familyId:familyId
                                                           credentialType:MSIDRefreshTokenType
                                                            configuration:configuration
                                                                  context:context
                                                                    error:error];
    
    if (refreshToken) return refreshToken;
    
    for (id<MSIDCacheAccessor> accessor in _otherAccessors)
    {
        refreshToken = [accessor getRefreshTokenWithAccount:accountIdentifier
                                                   familyId:familyId
                                              configuration:configuration
                                                    context:context
                                                      error:error];
        
        if (refreshToken)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context,@"(Legacy accessor) Found refresh token in a different accessor %@", [accessor class]);
            return refreshToken;
        }
    }
    
    return nil;
}

- (MSIDPrimaryRefreshToken *)getPrimaryRefreshTokenWithAccount:(MSIDAccountIdentifier *)accountIdentifier
                                                      familyId:(NSString *)familyId
                                                 configuration:(MSIDConfiguration *)configuration
                                                       context:(id<MSIDRequestContext>)context
                                                         error:(NSError **)error
{
    MSIDConfiguration *config = [configuration copy];
    config.clientId = MSID_LEGACY_CACHE_NIL_KEY;
    
    MSIDPrimaryRefreshToken *prt = (MSIDPrimaryRefreshToken *)[self getRefreshableTokenWithAccount:accountIdentifier
                                                                                          familyId:familyId
                                                                                    credentialType:MSIDPrimaryRefreshTokenType
                                                                                     configuration:config
                                                                                           context:context
                                                                                             error:error];
    
    if (prt) return prt;
    
    for (id<MSIDCacheAccessor> accessor in _otherAccessors)
    {
        prt = [accessor getPrimaryRefreshTokenWithAccount:accountIdentifier
                                                 familyId:familyId
                                            configuration:configuration
                                                  context:context
                                                    error:error];
        
        if (prt)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context,@"(Legacy accessor) Found primary refresh token in a different accessor %@", [accessor class]);
            return prt;
        }
    }
    
    return nil;
}

- (MSIDRefreshToken *)getRefreshableTokenWithAccount:(MSIDAccountIdentifier *)accountIdentifier
                                            familyId:(NSString *)familyId
                                      credentialType:(MSIDCredentialType)credentialType
                                       configuration:(MSIDConfiguration *)configuration
                                             context:(id<MSIDRequestContext>)context
                                               error:(NSError **)error
{
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Legacy accessor) Get token %@ with authority %@, clientId %@, familyID %@, account %@", [MSIDCredentialTypeHelpers credentialTypeAsString:credentialType], configuration.authority, configuration.clientId, familyId, accountIdentifier.maskedHomeAccountId);
    
    if (credentialType!=MSIDRefreshTokenType && credentialType!=MSIDPrimaryRefreshTokenType) return nil;

    MSIDRefreshToken *refreshToken = [self getLegacyRefreshableTokenForAccountImpl:accountIdentifier
                                                                          familyId:familyId
                                                                    credentialType:credentialType
                                                                     configuration:configuration
                                                                           context:context
                                                                             error:error];
    return refreshToken;

}

#pragma mark - Clear cache

- (BOOL)clearWithContext:(id<MSIDRequestContext>)context
                   error:(NSError **)error
{
    MSID_LOG_WITH_CTX(MSIDLogLevelWarning,context, @"(Legacy accessor) Clearing everything in cache. This method should only be called in tests!");
    return [_dataSource clearWithContext:context error:error];
}

#pragma mark - Read all accounts

- (NSArray<MSIDAccount *> *)accountsWithAuthority:(MSIDAuthority *)authority
                                         clientId:(NSString *)clientId
                                         familyId:(NSString *)familyId
                                accountIdentifier:(MSIDAccountIdentifier *)accountIdentifier
                                          context:(id<MSIDRequestContext>)context
                                            error:(NSError **)error
{
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Legacy accessor) Get accounts with environment %@, clientId %@, familyId %@, account identifier %@, legacy identifier %@", authority.environment, clientId, familyId, accountIdentifier.maskedHomeAccountId, accountIdentifier.maskedDisplayableId);
    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_LOOKUP, context);

    MSIDLegacyTokenCacheQuery *query = [MSIDLegacyTokenCacheQuery new];
    query.legacyUserId = accountIdentifier.displayableId;
    __auto_type items = [_dataSource tokensWithKey:query serializer:_serializer context:context error:error];

    NSArray<NSString *> *environmentAliases = [authority defaultCacheEnvironmentAliases];

    BOOL (^filterBlock)(MSIDCredentialCacheItem *tokenCacheItem) = ^BOOL(MSIDCredentialCacheItem *tokenCacheItem) {
        if ([environmentAliases count] && ![tokenCacheItem.environment msidIsEquivalentWithAnyAlias:environmentAliases])
        {
            return NO;
        }
        if (tokenCacheItem.credentialType == MSIDPrimaryRefreshTokenType)
        {
            return YES;
        }
        
        if (accountIdentifier.homeAccountId && ![tokenCacheItem.homeAccountId isEqualToString:accountIdentifier.homeAccountId])
        {
            return NO;
        }
        
        if (!clientId && !familyId)
        {
            // Nothing else to match by as neither clientId or familyId have been provided
            return YES;
        }
        
        if (clientId && [tokenCacheItem.clientId isEqualToString:clientId])
        {
            return YES;
        }

        if (familyId && [tokenCacheItem.familyId isEqualToString:familyId])
        {
            return YES;
        }

        return NO;
    };

    NSArray *refreshTokens = [MSIDTokenFilteringHelper filterTokenCacheItems:items
                                                                   tokenType:MSIDRefreshTokenType
                                                                 returnFirst:NO
                                                                    filterBy:filterBlock];
    
    NSArray *primaryRefreshTokens = [MSIDTokenFilteringHelper filterTokenCacheItems:items
                                                                          tokenType:MSIDPrimaryRefreshTokenType
                                                                        returnFirst:NO
                                                                           filterBy:filterBlock];
    
    NSMutableArray *allRefreshTokens = [refreshTokens mutableCopy];
    [allRefreshTokens addObjectsFromArray:primaryRefreshTokens];

    if ([allRefreshTokens count] == 0)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context,@"(Legacy accessor) Found no refresh tokens");
        NSError *wipeError = nil;
        CONDITIONAL_STOP_FAILED_CACHE_EVENT(event, [_dataSource wipeInfo:context error:&wipeError], context);
        
        if (wipeError) MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, nil, @"Failed to read wipe data with error %@", MSID_PII_LOG_MASKABLE(wipeError));
    }
    else
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context,@"(Legacy accessor) Found %lu refresh tokens", (unsigned long)[allRefreshTokens count]);
        CONDITIONAL_STOP_CACHE_EVENT(event, nil, YES, context);
    }

    NSMutableSet *resultAccounts = [NSMutableSet set];

    for (MSIDLegacyRefreshToken *refreshToken in allRefreshTokens)
    {
        __auto_type account = [MSIDAccount new];
        account.accountIdentifier = refreshToken.accountIdentifier;
        account.username = refreshToken.accountIdentifier.displayableId;
        account.accountType = MSIDAccountTypeMSSTS;
        account.environment = authority.environment ? authority.environment : refreshToken.environment;
        account.storageEnvironment = refreshToken.environment;
        
        MSIDIdTokenClaims *idTokenClaims = refreshToken.idTokenClaims;
        account.realm = idTokenClaims.realm;
        account.name = idTokenClaims.name;
        account.localAccountId = idTokenClaims.uniqueId;
        
        BOOL clientIdMatch = !clientId ||[clientId isEqualToString:refreshToken.clientId];
        
        if (clientIdMatch)
        {
            account.idTokenClaims = idTokenClaims;
        }
        
        [resultAccounts addObject:account];
    }

    return [resultAccounts allObjects];
}

#pragma mark - Public

- (MSIDLegacyAccessToken *)getAccessTokenForAccount:(MSIDAccountIdentifier *)accountIdentifier
                                      configuration:(MSIDConfiguration *)configuration
                                            context:(id<MSIDRequestContext>)context
                                              error:(NSError **)error
{
    NSArray *aliases = [configuration.authority legacyAccessTokenLookupAuthorities] ?: @[];

    return (MSIDLegacyAccessToken *)[self getTokenByLegacyUserId:accountIdentifier.displayableId
                                                            type:MSIDAccessTokenType
                                                     environment:configuration.authority.environment
                                                   lookupAliases:aliases
                                                        clientId:configuration.clientId
                                                        resource:configuration.target
                                                   appIdentifier:configuration.applicationIdentifier
                                                         context:context
                                                           error:error];
}

- (MSIDLegacySingleResourceToken *)getSingleResourceTokenForAccount:(MSIDAccountIdentifier *)accountIdentifier
                                                      configuration:(MSIDConfiguration *)configuration
                                                            context:(id<MSIDRequestContext>)context
                                                              error:(NSError **)error
{
    NSArray *aliases = [configuration.authority legacyAccessTokenLookupAuthorities] ?: @[];

    return (MSIDLegacySingleResourceToken *)[self getTokenByLegacyUserId:accountIdentifier.displayableId
                                                                    type:MSIDLegacySingleResourceTokenType
                                                             environment:configuration.authority.environment
                                                           lookupAliases:aliases
                                                                clientId:configuration.clientId
                                                                resource:configuration.target
                                                           appIdentifier:configuration.applicationIdentifier
                                                                 context:context
                                                                   error:error];
}

- (BOOL)validateAndRemoveRefreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)token
                              context:(id<MSIDRequestContext>)context
                                error:(NSError **)error
{
    return [self validateAndRemoveRefreshableToken:token context:context error:error];
}

- (BOOL)validateAndRemovePrimaryRefreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)token
                                     context:(id<MSIDRequestContext>)context
                                       error:(NSError **)error
{
    return [self validateAndRemoveRefreshableToken:token context:context error:error];
}

- (BOOL)validateAndRemoveRefreshableToken:(MSIDBaseToken<MSIDRefreshableToken> *)token
                                  context:(id<MSIDRequestContext>)context
                                    error:(NSError **)error
{
    if (!token || [NSString msidIsStringNilOrBlank:token.refreshToken])
    {
        MSIDFillAndLogError(error, MSIDErrorInternal, @"Removing tokens can be done only as a result of a token request. Valid refresh token should be provided.", context.correlationId);
        return NO;
    }

    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"Removing refresh token with clientID %@, environment %@, realm %@, userId %@, token %@", token.clientId, token.environment, token.realm, token.accountIdentifier.maskedHomeAccountId, MSID_EUII_ONLY_LOG_MASKABLE(token));

    MSIDCredentialCacheItem *cacheItem = [token tokenCacheItem];
    
    NSString *storageEnvironment = token.storageEnvironment ? token.storageEnvironment : token.environment;
    NSURL *storageAuthority = [NSURL msidAADURLWithEnvironment:storageEnvironment tenant:token.realm];

    __auto_type lookupAliases = storageAuthority ? @[storageAuthority] : @[];

    MSIDLegacyRefreshToken *tokenInCache = (MSIDLegacyRefreshToken *)[self getTokenByLegacyUserId:token.accountIdentifier.displayableId
                                                                                             type:cacheItem.credentialType
                                                                                      environment:token.environment
                                                                                    lookupAliases:lookupAliases
                                                                                         clientId:cacheItem.clientId
                                                                                         resource:cacheItem.target
                                                                                    appIdentifier:nil
                                                                                          context:context
                                                                                            error:error];

    if (tokenInCache && [tokenInCache.refreshToken isEqualToString:token.refreshToken])
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"Found refresh token in cache and it's the latest version, removing token %@", MSID_EUII_ONLY_LOG_MASKABLE(token));
        
        return [self removeTokenEnvironment:storageEnvironment
                                      realm:token.realm
                                   clientId:cacheItem.clientId
                                     target:cacheItem.target
                                     userId:tokenInCache.accountIdentifier.displayableId
                             credentialType:cacheItem.credentialType
                                     appKey:cacheItem.appKey
                      applicationIdentifier:nil
                                    context:context
                                      error:error];
    }
    
    // Clear RT from other accessors
    for (id<MSIDCacheAccessor> accessor in _otherAccessors)
    {
        if (![accessor validateAndRemoveRefreshToken:token context:context error:error])
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, context, @"Failed to remove RT from other accessor:  %@, error %@", accessor.class, MSID_PII_LOG_MASKABLE(*error));
            return NO;
        }
    }

    return YES;
}

- (BOOL)removeAccessToken:(MSIDAccessToken *)token
                  context:(id<MSIDRequestContext>)context
                    error:(NSError **)error
{
    return [self removeTokenEnvironment:token.environment
                                  realm:token.realm
                               clientId:token.clientId
                                 target:token.resource
                                 userId:token.accountIdentifier.displayableId
                         credentialType:token.credentialType
                                 appKey:nil
                  applicationIdentifier:token.applicationIdentifier
                                context:context
                                  error:error];
}

- (BOOL)clearCacheForAccount:(MSIDAccountIdentifier *)accountIdentifier
                   authority:(MSIDAuthority *)authority
                    clientId:(NSString *)clientId
                    familyId:(NSString *)familyId
                     context:(id<MSIDRequestContext>)context
                       error:(NSError **)error 
{
    if (!accountIdentifier)
    {
        MSIDFillAndLogError(error, MSIDErrorInternal, @"Cannot clear cache without account provided", context.correlationId);
        return NO;
    }

    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Legacy accessor) Clearing cache with account %@ and client id %@", accountIdentifier.maskedDisplayableId, clientId);

    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_DELETE, context);

    BOOL result = YES;

    MSIDLegacyTokenCacheQuery *query = [MSIDLegacyTokenCacheQuery new];
    query.legacyUserId = accountIdentifier.displayableId;

    // If only user id is provided, optimize operation by deleting from data source directly
    if ([NSString msidIsStringNilOrBlank:clientId]
        && [NSString msidIsStringNilOrBlank:familyId] && !authority
        && ![NSString msidIsStringNilOrBlank:accountIdentifier.displayableId])
    {
        result = [_dataSource removeTokensWithKey:query context:context error:error];
        [_dataSource saveWipeInfoWithContext:context error:nil];
    }
    else
    {
        // If we need to filter by client id, then we need to query all items by user id and go through them
        NSArray *results = [_dataSource tokensWithKey:query serializer:_serializer context:context error:error];

        if (results)
        {
            NSString *requestClientID = familyId ? [MSIDCacheKey familyClientId:familyId] : clientId;
            NSArray *aliases = authority.defaultCacheEnvironmentAliases;

            for (MSIDLegacyTokenCacheItem *cacheItem in results)
            {
                if ((!requestClientID || [cacheItem.clientId isEqualToString:requestClientID])
                    && (!authority || [cacheItem.environment msidIsEquivalentWithAnyAlias:aliases]))
                {
                    result &= [self removeTokenEnvironment:cacheItem.environment
                                                     realm:cacheItem.realm
                                                  clientId:cacheItem.clientId
                                                    target:cacheItem.target
                                                    userId:cacheItem.idTokenClaims.userId
                                            credentialType:cacheItem.credentialType
                                                    appKey:cacheItem.appKey
                                     applicationIdentifier:cacheItem.applicationIdentifier
                                                   context:context
                                                     error:error];
                }
            }
        }
    }

    CONDITIONAL_STOP_CACHE_EVENT(event, nil, result, context);

    // Clear cache from other accessors
    for (id<MSIDCacheAccessor> accessor in _otherAccessors)
    {
        if (![accessor clearCacheForAccount:accountIdentifier
                                  authority:authority
                                   clientId:clientId
                                   familyId:familyId
                                    context:context
                                      error:error])
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning,context, @"Failed to clear cache from other accessor:  %@, error %@", accessor.class, MSID_PII_LOG_MASKABLE(*error));
        }
    }

    return result;
}

#pragma mark - Internal

- (MSIDLegacyRefreshToken *)getLegacyRefreshableTokenForAccountImpl:(MSIDAccountIdentifier *)accountIdentifier
                                                           familyId:(NSString *)familyId
                                                     credentialType:(MSIDCredentialType)credentialType
                                                      configuration:(MSIDConfiguration *)configuration
                                                            context:(id<MSIDRequestContext>)context
                                                              error:(NSError **)error
{
    
    
    NSString *clientId = familyId ? [MSIDCacheKey familyClientId:familyId] : configuration.clientId;
    NSArray<NSURL *> *aliases = [configuration.authority legacyRefreshTokenLookupAliases] ?: @[];

    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Legacy accessor) Finding token %@ with legacy user ID %@, clientId %@, authority %@", [MSIDCredentialTypeHelpers credentialTypeAsString:credentialType], accountIdentifier.maskedDisplayableId, clientId, aliases);

    return (MSIDLegacyRefreshToken *)[self getTokenByLegacyUserId:accountIdentifier.displayableId
                                                             type:credentialType
                                                      environment:configuration.authority.environment
                                                    lookupAliases:aliases
                                                         clientId:clientId
                                                         resource:nil
                                                    appIdentifier:nil
                                                          context:context
                                                            error:error];
}

- (BOOL)saveAccessTokenWithConfiguration:(MSIDConfiguration *)configuration
                                response:(MSIDTokenResponse *)response
                                 factory:(MSIDOauth2Factory *)factory
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError **)error
{
    MSIDLegacyAccessToken *accessToken = [factory legacyAccessTokenFromResponse:response configuration:configuration];

    if (!accessToken)
    {
        MSIDFillAndLogError(error, MSIDErrorInternal, @"Tried to save access token, but no access token returned", context.correlationId);
        return NO;
    }
    
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"(Legacy accessor) Saving access token in legacy accessor %@", MSID_EUII_ONLY_LOG_MASKABLE(accessToken));
    
    return [self saveToken:accessToken
                   context:context
                     error:error];
}

- (BOOL)saveRefreshToken:(MSIDLegacyRefreshToken *)refreshToken
           configuration:(__unused MSIDConfiguration *)configuration
                 context:(id<MSIDRequestContext>)context
                   error:(NSError **)error
{
    if (!refreshToken)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"No refresh token returned in the token response, not updating cache");
        return YES;
    }
    
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"(Legacy accessor) Saving multi resource refresh token in legacy accessor %@", MSID_EUII_ONLY_LOG_MASKABLE(refreshToken));
    
    BOOL result = [self saveToken:refreshToken
                          context:context
                            error:error];
    
    if (!result || [NSString msidIsStringNilOrBlank:refreshToken.familyId])
    {
        // If saving failed or it's not an FRT, we're done
        return result;
    }

    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"Saving family refresh token in all caches %@", MSID_EUII_ONLY_LOG_MASKABLE(refreshToken));

    // If it's an FRT, save it separately and update the clientId of the token item
    MSIDLegacyRefreshToken *familyRefreshToken = [refreshToken copy];
    familyRefreshToken.clientId = [MSIDCacheKey familyClientId:refreshToken.familyId];
    
    return [self saveToken:familyRefreshToken
                   context:context
                     error:error];
}

- (BOOL)saveRefreshTokenWithConfiguration:(MSIDConfiguration *)configuration
                                 response:(MSIDTokenResponse *)response
                                  factory:(MSIDOauth2Factory *)factory
                                  context:(id<MSIDRequestContext>)context
                                    error:(NSError **)error
{
    MSIDLegacyRefreshToken *refreshToken = [factory legacyRefreshTokenFromResponse:response configuration:configuration];
    
    if (!refreshToken)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"No refresh token returned in the token response, not updating cache");
        return YES;
    }
    
    return [self saveRefreshToken:refreshToken configuration:configuration context:context error:error];
}

- (BOOL)saveLegacySingleResourceTokenWithConfiguration:(MSIDConfiguration *)configuration
                                              response:(MSIDTokenResponse *)response
                                               factory:(MSIDOauth2Factory *)factory
                                               context:(id<MSIDRequestContext>)context
                                                 error:(NSError **)error
{
    MSIDLegacySingleResourceToken *legacyToken = [factory legacyTokenFromResponse:response configuration:configuration];

    if (!legacyToken)
    {
        MSIDFillAndLogError(error, MSIDErrorInternal, @"Tried to save single resource token, but no access token returned", context.correlationId);
        return NO;
    }
    
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"(Legacy accessor) Saving single resource tokens in legacy accessor %@", MSID_EUII_ONLY_LOG_MASKABLE(legacyToken));

    // Save token for legacy single resource token
    return [self saveToken:legacyToken
                   context:context
                     error:error];
}

- (BOOL)saveToken:(MSIDBaseToken<MSIDLegacyCredentialCacheCompatible> *)token
          context:(id<MSIDRequestContext>)context
            error:(NSError **)error
{
    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_WRITE, context);
    
    MSIDCredentialCacheItem *tokenCacheItem = token.legacyTokenCacheItem;

    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Legacy accessor) Saving token %@ for account %@ with environment %@, realm %@, clientID %@", MSID_EUII_ONLY_LOG_MASKABLE(tokenCacheItem), token.accountIdentifier.maskedDisplayableId, token.storageEnvironment, token.realm, tokenCacheItem.clientId);
    
    MSIDLegacyTokenCacheKey *key = [[MSIDLegacyTokenCacheKey alloc] initWithEnvironment:tokenCacheItem.environment
                                                                                  realm:tokenCacheItem.realm
                                                                               clientId:tokenCacheItem.clientId
                                                                               resource:tokenCacheItem.target
                                                                           legacyUserId:token.accountIdentifier.displayableId];
    
    key.applicationIdentifier = tokenCacheItem.applicationIdentifier;

    BOOL result = [_dataSource saveToken:tokenCacheItem
                                     key:key
                              serializer:_serializer
                                 context:context
                                   error:error];

    if (!result)
    {
        CONDITIONAL_STOP_CACHE_EVENT(event, token, NO, context);
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context, @"Failed to save token with alias: %@", tokenCacheItem.environment);
        return NO;
    }

    CONDITIONAL_STOP_CACHE_EVENT(event, token, YES, context);
    return YES;
}

- (NSArray<MSIDBaseToken *> *)allTokensWithContext:(id<MSIDRequestContext>)context
                                             error:(NSError **)error
{
    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_LOOKUP, context);

    MSIDLegacyTokenCacheQuery *query = [MSIDLegacyTokenCacheQuery new];
    __auto_type items = [_dataSource tokensWithKey:query serializer:_serializer context:context error:error];
    
    NSMutableArray<MSIDBaseToken *> *tokens = [NSMutableArray new];
    
    for (MSIDLegacyTokenCacheItem *item in items)
    {
        MSIDBaseToken *token = [item tokenWithType:item.credentialType];
        if (token)
        {
            token.storageEnvironment = token.environment;
            [tokens addObject:token];
        }
    }

    CONDITIONAL_STOP_CACHE_EVENT(event, nil, [tokens count] > 0, context);
    return tokens;
}

- (BOOL)removeTokenEnvironment:(NSString *)environment
                         realm:(NSString *)realm
                      clientId:(NSString *)clientId
                        target:(NSString *)target
                        userId:(NSString *)userId
                credentialType:(MSIDCredentialType)credentialType
                        appKey:(NSString *)appKey
         applicationIdentifier:(NSString *)applicationIdentifier
                       context:(id<MSIDRequestContext>)context
                         error:(NSError **)error
{
    if (!environment || !clientId || !userId)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Token key components not provided", nil, nil, nil, context.correlationId, nil, YES);
        }

        return NO;
    }

    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Legacy accessor) Removing token with clientId %@, environment %@, realm %@, target %@, account %@", clientId, environment, realm, target, MSID_PII_LOG_EMAIL(userId));

    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_DELETE, context);
    
    MSIDLegacyTokenCacheKey *key = [[MSIDLegacyTokenCacheKey alloc] initWithEnvironment:environment
                                                                                  realm:realm
                                                                               clientId:clientId
                                                                               resource:target
                                                                           legacyUserId:userId];
    key.appKey = appKey;
    key.applicationIdentifier = applicationIdentifier;

    BOOL result = [_dataSource removeTokensWithKey:key context:context error:error];

    if (result && credentialType == MSIDRefreshTokenType)
    {
        [_dataSource saveWipeInfoWithContext:context error:nil];
    }

    CONDITIONAL_STOP_CACHE_EVENT(event, nil, result, context);
    return result;
}

#pragma mark - Private

- (MSIDBaseToken *)getTokenByLegacyUserId:(NSString *)legacyUserId
                                     type:(MSIDCredentialType)type
                              environment:(NSString *)environment
                            lookupAliases:(NSArray<NSURL *> *)aliases
                                 clientId:(NSString *)clientId
                                 resource:(NSString *)resource
                            appIdentifier:(NSString *)appIdentifier
                                  context:(id<MSIDRequestContext>)context
                                    error:(NSError **)error
{
    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_LOOKUP, context);

    for (NSURL *alias in aliases)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Legacy accessor) Looking for token with alias %@, clientId %@, resource %@, legacy userId %@", alias, clientId, resource, MSID_PII_LOG_EMAIL(legacyUserId));
        
        MSIDLegacyTokenCacheKey *key = [[MSIDLegacyTokenCacheKey alloc] initWithAuthority:alias
                                                                                 clientId:clientId
                                                                                 resource:resource
                                                                             legacyUserId:legacyUserId];
        
        if (!key)
        {
            return nil;
        }
        
        key.applicationIdentifier = appIdentifier;
        
        NSError *cacheError = nil;
        MSIDLegacyTokenCacheItem *cacheItem = (MSIDLegacyTokenCacheItem *) [_dataSource tokenWithKey:key serializer:_serializer context:context error:&cacheError];
        
        if (cacheError)
        {
            CONDITIONAL_STOP_CACHE_EVENT(event, nil, NO, context);
            if (error) *error = cacheError;
            return nil;
        }

        if (cacheItem)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context,@"(Legacy accessor) Found token");
            MSIDBaseToken *token = [cacheItem tokenWithType:type];
            token.storageEnvironment = token.environment;
            token.environment = environment;
            CONDITIONAL_STOP_CACHE_EVENT(event, token, YES, context);
            return token;
        }
    }

    if (type == MSIDRefreshTokenType)
    {
        NSError *wipeError = nil;
        CONDITIONAL_STOP_FAILED_CACHE_EVENT(event, [_dataSource wipeInfo:context error:&wipeError], context);
        if (wipeError) MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, nil, @"Failed to read wipe data with error %@", MSID_PII_LOG_MASKABLE(wipeError));
    }
    else
    {
        CONDITIONAL_STOP_CACHE_EVENT(event, nil, NO, context);
    }
    return nil;
}

@end
