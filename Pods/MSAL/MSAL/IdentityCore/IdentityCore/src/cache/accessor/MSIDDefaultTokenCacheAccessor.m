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

#import "MSIDDefaultTokenCacheAccessor.h"
#import "MSIDAccount.h"
#import "MSIDAccessToken.h"
#import "MSIDRefreshToken.h"
#import "MSIDIdToken.h"
#import "MSIDAccountCacheItem.h"
#import "MSIDAccountCredentialCache.h"
#import "MSIDConfiguration.h"
#import "MSIDOauth2Factory.h"
#import "MSIDTelemetry+Internal.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDTelemetryCacheEvent.h"
#import "NSOrderedSet+MSIDExtensions.h"
#import "MSIDDefaultCredentialCacheQuery.h"
#import "MSIDBrokerResponse.h"
#import "MSIDDefaultAccountCacheQuery.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDTelemetry+Cache.h"
#import "MSIDAuthority.h"
#import "MSIDAppMetadataCacheItem.h"
#import "MSIDAppMetadataCacheQuery.h"
#import "MSIDGeneralCacheItemType.h"
#import "MSIDIntuneEnrollmentIdsCache.h"
#import "MSIDAccountMetadataCacheAccessor.h"
#import "MSIDAuthenticationScheme.h"

@interface MSIDDefaultTokenCacheAccessor()
{
    NSArray<id<MSIDCacheAccessor>> *_otherAccessors;
}

@end

@implementation MSIDDefaultTokenCacheAccessor

#pragma mark - MSIDCacheAccessor

- (instancetype)initWithDataSource:(id<MSIDExtendedTokenCacheDataSource>)dataSource
               otherCacheAccessors:(NSArray<id<MSIDCacheAccessor>> *)otherAccessors
{
    self = [super init];

    if (self)
    {
        _accountCredentialCache = [[MSIDAccountCredentialCache alloc] initWithDataSource:dataSource];
        _otherAccessors = otherAccessors;
    }

    return self;
}

#pragma mark - Saving

- (BOOL)saveTokensWithConfiguration:(MSIDConfiguration *)configuration
                           response:(MSIDTokenResponse *)response
                            factory:(MSIDOauth2Factory *)factory
                            context:(id<MSIDRequestContext>)context
                              error:(NSError *__autoreleasing *)error
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"(Default accessor) Saving multi resource refresh token");

    // Save access token
    BOOL result = [self saveAccessTokenWithConfiguration:configuration response:response factory:factory context:context error:error];

    if (!result) return result;

    // Save ID token
    result = [self saveIDTokenWithConfiguration:configuration response:response factory:factory context:context error:error];

    if (!result) return result;

    // Save SSO state (refresh token and account)
    return [self saveSSOStateWithConfiguration:configuration response:response factory:factory context:context error:error];
}

- (BOOL)saveSSOStateWithConfiguration:(MSIDConfiguration *)configuration
                             response:(MSIDTokenResponse *)response
                              factory:(MSIDOauth2Factory *)factory
                              context:(id<MSIDRequestContext>)context
                                error:(NSError *__autoreleasing *)error
{
    if (!response)
    {
        MSIDFillAndLogError(error, MSIDErrorInternal, @"No token response provided", context.correlationId);
        return NO;
    }

    MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context, @"(Default accessor) Saving SSO state");

    BOOL result = [self saveRefreshTokenWithConfiguration:configuration response:response factory:factory context:context error:error];

    if (!result) return NO;

    //Save App metadata
    result = [self saveAppMetadataWithConfiguration:configuration response:response factory:factory context:context error:error];

    if (!result) return NO;

    return [self saveAccountWithConfiguration:configuration response:response factory:factory context:context error:error];
}

#pragma mark - Refresh token read

- (MSIDRefreshToken *)getRefreshTokenWithAccount:(MSIDAccountIdentifier *)accountIdentifier
                                        familyId:(NSString *)familyId
                                   configuration:(MSIDConfiguration *)configuration
                                         context:(id<MSIDRequestContext>)context
                                           error:(NSError *__autoreleasing *)error
{
    MSIDRefreshToken *refreshToken =  [self getRefreshableTokenWithAccount:accountIdentifier
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
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"(Default accessor) Found refresh token in a different accessor %@", [accessor class]);
            return refreshToken;
        }
    }

    return nil;
}

- (MSIDPrimaryRefreshToken *)getPrimaryRefreshTokenWithAccount:(MSIDAccountIdentifier *)accountIdentifier
                                                      familyId:(NSString *)familyId
                                                 configuration:(MSIDConfiguration *)configuration
                                                       context:(id<MSIDRequestContext>)context
                                                         error:(NSError *__autoreleasing *)error
{
    MSIDPrimaryRefreshToken *prt = (MSIDPrimaryRefreshToken *)[self getRefreshableTokenWithAccount:accountIdentifier
                                                                                          familyId:familyId
                                                                                    credentialType:MSIDPrimaryRefreshTokenType
                                                                                     configuration:configuration
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
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"(Default accessor) Found primary refresh token in a different accessor %@", [accessor class]);
            return prt;
        }
    }

    return nil;
}

- (NSArray<MSIDPrimaryRefreshToken *> *)getPrimaryRefreshTokensForConfiguration:(MSIDConfiguration *)configuration
                                                                        context:(id<MSIDRequestContext>)context
                                                                          error:(NSError **)error
{
    MSIDDefaultCredentialCacheQuery *query = [MSIDDefaultCredentialCacheQuery new];
    query.environmentAliases = [configuration.authority defaultCacheEnvironmentAliases];
    query.credentialType = MSIDPrimaryRefreshTokenType;

    NSArray<MSIDPrimaryRefreshToken *> *refreshTokens = (NSArray<MSIDPrimaryRefreshToken *> *)[self getTokensWithEnvironment:configuration.authority.environment cacheQuery:query context:context error:error];
    return refreshTokens;
}

- (MSIDRefreshToken *)getRefreshableTokenWithAccount:(MSIDAccountIdentifier *)accountIdentifier
                                            familyId:(NSString *)familyId
                                      credentialType:(MSIDCredentialType)credentialType
                                       configuration:(MSIDConfiguration *)configuration
                                             context:(id<MSIDRequestContext>)context
                                               error:(NSError *__autoreleasing *)error
{
    if (credentialType != MSIDRefreshTokenType && credentialType != MSIDPrimaryRefreshTokenType) return nil;

    if (![NSString msidIsStringNilOrBlank:accountIdentifier.homeAccountId])
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Default accessor) Finding token with user ID %@, clientId %@, familyID %@, authority %@", accountIdentifier.maskedHomeAccountId, configuration.clientId, familyId, configuration.authority);

        MSIDDefaultCredentialCacheQuery *query = [MSIDDefaultCredentialCacheQuery new];
        query.homeAccountId = accountIdentifier.homeAccountId;
        query.environmentAliases = [configuration.authority defaultCacheEnvironmentAliases];
        query.clientId = familyId ? nil : configuration.clientId;
        query.familyId = familyId;
        query.credentialType = credentialType;

        MSIDRefreshToken *refreshToken = (MSIDRefreshToken *) [self getTokenWithEnvironment:configuration.authority.environment
                                                                                 cacheQuery:query
                                                                                    context:context
                                                                                      error:error];

        if (refreshToken)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context, @"(Default accessor) Found %@refresh token by home account id", credentialType == MSIDPrimaryRefreshTokenType ? @"primary " : @"");
            return refreshToken;
        }
    }

    if (![NSString msidIsStringNilOrBlank:accountIdentifier.displayableId])
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Default accessor) Finding refresh token with legacy user ID %@, clientId %@, authority %@", accountIdentifier.maskedDisplayableId, configuration.clientId, configuration.authority);

        MSIDRefreshToken *refreshToken = (MSIDRefreshToken *) [self getRefreshableTokenByDisplayableId:accountIdentifier
                                                                                             authority:configuration.authority
                                                                                              clientId:configuration.clientId
                                                                                              familyId:familyId
                                                                                        credentialType:credentialType
                                                                                               context:context
                                                                                                 error:error];

        if (refreshToken)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context, @"(Default accessor) Found %@refresh token by legacy account id", credentialType == MSIDPrimaryRefreshTokenType ? @"primary " : @"");
            return refreshToken;
        }
    }

    return nil;
}

#pragma mark - Clear cache

- (BOOL)clearWithContext:(id<MSIDRequestContext>)context
                   error:(NSError **)error
{
    MSID_LOG_WITH_CTX(MSIDLogLevelWarning, context, @"(Default accessor) Clearing everything in cache. This method should only be called in tests!");
    return [_accountCredentialCache clearWithContext:context error:error];
}

#pragma mark - Read all tokens

- (NSArray<MSIDBaseToken *> *)allTokensWithContext:(id<MSIDRequestContext>)context
                                             error:(NSError **)error
{
    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_LOOKUP, context);

    NSArray<MSIDCredentialCacheItem *> *cacheItems = [_accountCredentialCache getAllItemsWithContext:context error:error];
    NSArray<MSIDBaseToken *> *tokens = [self validTokensFromCacheItems:cacheItems];

    CONDITIONAL_STOP_CACHE_EVENT(event, nil, [cacheItems count] > 0, context);
    return tokens;
}

#pragma mark - Public

- (MSIDAccessToken *)getAccessTokenForAccount:(MSIDAccountIdentifier *)accountIdentifier
                                configuration:(MSIDConfiguration *)configuration
                                      context:(id<MSIDRequestContext>)context
                                        error:(NSError **)error
{

    MSIDDefaultCredentialCacheQuery *query = [MSIDDefaultCredentialCacheQuery new];
    query.homeAccountId = accountIdentifier.homeAccountId;
    query.environmentAliases = [configuration.authority defaultCacheEnvironmentAliases];
    query.realm = configuration.authority.realm;
    query.clientId = configuration.clientId;
    query.target = configuration.target;
    query.targetMatchingOptions = MSIDSubSet;
    query.applicationIdentifier = configuration.applicationIdentifier;
    query.credentialType = configuration.authScheme.credentialType;
    query.tokenType = configuration.authScheme.tokenType;

    __auto_type accessToken = (MSIDAccessToken *)[self getTokenWithEnvironment:configuration.authority.environment
                                                                    cacheQuery:query
                                                                       context:context
                                                                         error:error];

    if (accessToken)
    {
        NSTimeInterval expiresIn = [accessToken.expiresOn timeIntervalSinceNow];

        MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"Found access token for account %@:%@ which expires in %f", accountIdentifier.maskedHomeAccountId, accountIdentifier.maskedDisplayableId, expiresIn);
    }
    else
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Access token wasn't found.");
    }

    return accessToken;
}

- (MSIDIdToken *)getIDTokenForAccount:(MSIDAccountIdentifier *)accountIdentifier
                        configuration:(MSIDConfiguration *)configuration
                          idTokenType:(MSIDCredentialType)idTokenType
                              context:(id<MSIDRequestContext>)context
                                error:(NSError **)error
{
    if (idTokenType!=MSIDIDTokenType && idTokenType!=MSIDLegacyIDTokenType)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Wrong id token type passed.", nil, nil, nil, context.correlationId, nil, YES);
        }

        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Wrong id token type passed: %@.", [MSIDCredentialTypeHelpers credentialTypeAsString:idTokenType]);
        return nil;
    }

    MSIDDefaultCredentialCacheQuery *query = [MSIDDefaultCredentialCacheQuery new];
    query.homeAccountId = accountIdentifier.homeAccountId;
    query.environmentAliases = [configuration.authority defaultCacheEnvironmentAliases];
    query.realm = configuration.authority.realm;
    query.clientId = configuration.clientId;
    query.credentialType = idTokenType;

    __auto_type idToken = (MSIDIdToken *)[self getTokenWithEnvironment:configuration.authority.environment
                                                            cacheQuery:query
                                                               context:context
                                                                 error:error];

    if (idToken)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"Found id token %@ for account %@:%@.", MSID_EUII_ONLY_LOG_MASKABLE(idToken), accountIdentifier.maskedHomeAccountId, MSID_PII_LOG_MASKABLE(accountIdentifier.maskedDisplayableId));
    }
    else
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Id token wasn't found.");
    }

    return idToken;
}

- (NSArray<MSIDIdToken *> *)idTokensWithAuthority:(MSIDAuthority *)authority
                                accountIdentifier:(MSIDAccountIdentifier *)accountIdentifier
                                         clientId:(NSString *)clientId
                                          context:(id<MSIDRequestContext>)context
                                            error:(NSError **)error
{
    MSIDDefaultCredentialCacheQuery *query = [MSIDDefaultCredentialCacheQuery new];
    query.homeAccountId = accountIdentifier.homeAccountId;
    query.environmentAliases = [authority defaultCacheEnvironmentAliases];
    query.realm = authority.realm;
    query.clientId = clientId;
    query.credentialType = MSIDIDTokenType;

    return (NSArray<MSIDIdToken *> *)[self getTokensWithEnvironment:authority.environment cacheQuery:query context:context error:error];
}

- (BOOL)removeAccessToken:(MSIDAccessToken *)token
                  context:(id<MSIDRequestContext>)context
                    error:(NSError **)error
{
    return [self removeToken:token
                     context:context
                       error:error];
}

#pragma mark - Read all accounts

- (NSArray<MSIDAccount *> *)accountsWithAuthority:(MSIDAuthority *)authority
                                         clientId:(NSString *)clientId
                                         familyId:(NSString *)familyId
                                accountIdentifier:(MSIDAccountIdentifier *)accountIdentifier
                                          context:(id<MSIDRequestContext>)context
                                            error:(NSError **)error
{
    return [self accountsWithAuthority:authority
                              clientId:clientId
                              familyId:familyId
                     accountIdentifier:accountIdentifier
                  accountMetadataCache:nil
                  signedInAccountsOnly:YES
                               context:context error:error];
}

- (NSArray<MSIDAccount *> *)accountsWithAuthority:(MSIDAuthority *)authority
                                         clientId:(NSString *)clientId
                                         familyId:(NSString *)familyId
                                accountIdentifier:(MSIDAccountIdentifier *)accountIdentifier
                             accountMetadataCache:(MSIDAccountMetadataCacheAccessor *)accountMetadataCache
                             signedInAccountsOnly:(BOOL)signedInAccountsOnly
                                          context:(id<MSIDRequestContext>)context
                                            error:(NSError **)error
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"(Default accessor) Get accounts.");
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Default accessor) Get accounts with environment %@, clientId %@, familyId %@, account %@, username %@", authority.environment, clientId, familyId, accountIdentifier.maskedHomeAccountId, accountIdentifier.maskedDisplayableId);

    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_LOOKUP, context);

    NSArray<NSString *> *environmentAliases = [authority defaultCacheEnvironmentAliases];

    // First read accounts by specified parameters
    MSIDDefaultAccountCacheQuery *accountsQuery = [MSIDDefaultAccountCacheQuery new];
    accountsQuery.accountType = MSIDAccountTypeMSSTS;
    accountsQuery.environmentAliases = environmentAliases;
    accountsQuery.homeAccountId = accountIdentifier.homeAccountId;
    accountsQuery.username = accountIdentifier.displayableId;

    NSArray<MSIDAccountCacheItem *> *allAccounts = [_accountCredentialCache getAccountsWithQuery:accountsQuery context:context error:error];

    if (!allAccounts)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"(Default accessor) Failed accounts lookup");
        CONDITIONAL_STOP_CACHE_EVENT(event, nil, NO, context);
        return nil;
    }

    // we only need it if returning signed in accounts only
    NSSet<NSString *> *accountIdsFromRT = nil;
    NSError *localError;
    if (signedInAccountsOnly)
    {
        accountIdsFromRT = [self homeAccountIdsFromRTsWithAuthority:authority
                                                           clientId:clientId
                                                           familyId:familyId
                                             accountCredentialCache:_accountCredentialCache
                                                            context:context
                                                              error:&localError];

        if (localError)
        {
            if (error)
            {
                *error = localError;
            }
            CONDITIONAL_STOP_CACHE_EVENT(event, nil, NO, context);
            return nil;
        }
    }

    NSArray<MSIDIdToken *> *idTokens = [self idTokensWithAuthority:authority
                                                 accountIdentifier:accountIdentifier
                                                          clientId:clientId
                                                           context:context
                                                             error:nil];

    NSMutableSet<NSString *> *noReturnAccountUPNSet;
    NSMutableSet<MSIDAccount *> *returnAccountsSet = [self filterAndFillIdTokenClaimsForAccounts:allAccounts
                                                                                       authority:authority
                                                                                accountIdsFromRT:accountIdsFromRT
                                                                                        idTokens:idTokens
                                                                                        clientId:clientId
                                                                            accountMetadataCache:accountMetadataCache
                                                                            signedInAccountsOnly:signedInAccountsOnly
                                                                             noReturnAccountUPNs:&noReturnAccountUPNSet];
    if (localError)
    {
        if (error)
        {
            *error = localError;
        }
        CONDITIONAL_STOP_CACHE_EVENT(event, nil, NO, context);
        return nil;
    }

    if ([returnAccountsSet count])
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"(Default accessor) Found the following accounts in default accessor: %@", MSID_PII_LOG_MASKABLE([returnAccountsSet allObjects]));

        CONDITIONAL_STOP_CACHE_EVENT(event, nil, YES, context);
    }
    else
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"(Default accessor) No accounts found in default accessor.");
        NSError *wipeError = nil;
        CONDITIONAL_STOP_FAILED_CACHE_EVENT(event, [_accountCredentialCache wipeInfoWithContext:context error:&wipeError], context);
        if (wipeError) MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, context, @"Failed to read wipe info with error %@", MSID_PII_LOG_MASKABLE(wipeError));
    }

    for (id<MSIDCacheAccessor> accessor in _otherAccessors)
    {
        NSArray *accounts = [accessor accountsWithAuthority:authority
                                                   clientId:clientId
                                                   familyId:familyId
                                          accountIdentifier:accountIdentifier
                                                    context:context
                                                      error:error];
        accounts = [self filterSignedOutAccountsFromOtherAccessor:accounts accountMetadataCache:accountMetadataCache clientId:clientId noReturnAccountUPNs:noReturnAccountUPNSet knownReturnAccounts:returnAccountsSet];

        [returnAccountsSet addObjectsFromArray:accounts];
    }

    if ([returnAccountsSet count])
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"(Default accessor) Found the following accounts in other accessors: %@", MSID_PII_LOG_MASKABLE([returnAccountsSet allObjects]));
    }
    else
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"(Default accessor) No accounts found in other accessors.");
    }

    return [returnAccountsSet allObjects];
}

- (MSIDAccount *)getAccountForIdentifier:(MSIDAccountIdentifier *)accountIdentifier
                               authority:(MSIDAuthority *)authority
                               realmHint:(NSString *)realmHint
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError **)error
{
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Default accessor) Looking for account with authority %@, legacy user ID %@, home account ID %@", authority.url, accountIdentifier.maskedDisplayableId, accountIdentifier.maskedHomeAccountId);

    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_LOOKUP, context);

    MSIDDefaultAccountCacheQuery *cacheQuery = [MSIDDefaultAccountCacheQuery new];
    cacheQuery.homeAccountId = accountIdentifier.homeAccountId;
    cacheQuery.environmentAliases = [authority defaultCacheEnvironmentAliases];
    cacheQuery.realm = authority.realm;
    cacheQuery.accountType = MSIDAccountTypeMSSTS;

    // If homeAccountId is present, username is not needed for account lookup. Leaving it nil allows accounts to appear in guest
    // tenants under a different upn and still acquire tokens silently.
    cacheQuery.username = [NSString msidIsStringNilOrBlank:accountIdentifier.homeAccountId] ? accountIdentifier.displayableId : nil;

    NSArray<MSIDAccountCacheItem *> *accountCacheItems = [_accountCredentialCache getAccountsWithQuery:cacheQuery context:context error:error];

    if (!accountCacheItems)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning, context, @"(Default accessor) Failed to retrieve account with authority %@", authority.url);
        NSError *wipeError = nil;
        CONDITIONAL_STOP_FAILED_CACHE_EVENT(event, [_accountCredentialCache wipeInfoWithContext:context error:&wipeError], context);
        if (wipeError) MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, context, @"Failed to read wipe info with error %@", MSID_PII_LOG_MASKABLE(wipeError));
        return nil;
    }

    MSIDAccount *firstAccount = nil;

    for (MSIDAccountCacheItem *cacheItem in accountCacheItems)
    {
        MSIDAccount *account = [[MSIDAccount alloc] initWithAccountCacheItem:cacheItem];
        if (!account) continue;

        /*
        Note that lookup by realmHint is a best effort (hence it is a hint), because developer might be requesting token for tenantId not previously requested, in which case there will be no account in cache. We still want to ensure best effort account lookup in that scenario. In case we lookup wrong account (e.g. we find MSA account and developer wanted to get a token for Google B2B account), silent broker request will fail and we fall back to interactive request, which will resolve account correctly. Server side ensures here final account resolution based on which account is present in the tenant, and possibly a user choice during interactive token acquisition.
         */
        if (realmHint && [account.realm isEqualToString:realmHint])
        {
            return account;
        }

        if (!firstAccount) firstAccount = account;
    }

    CONDITIONAL_STOP_CACHE_EVENT(event, nil, YES, context);
    return firstAccount;
}

#pragma mark - Clear cache

- (BOOL)clearCacheForAccount:(MSIDAccountIdentifier *)accountIdentifier
                   authority:(MSIDAuthority *)authority
                    clientId:(NSString *)clientId
                    familyId:(NSString *)familyId
                     context:(id<MSIDRequestContext>)context
                       error:(NSError **)error
{
    return [self clearCacheForAccount:accountIdentifier
                            authority:authority
                             clientId:clientId
                             familyId:familyId
                        clearAccounts:NO
                              context:context
                                error:error];
}

- (BOOL)clearCacheForAccount:(MSIDAccountIdentifier *)accountIdentifier
                   authority:(MSIDAuthority *)authority
                    clientId:(NSString *)clientId
                    familyId:(NSString *)familyId
               clearAccounts:(BOOL)clearAccounts
                     context:(id<MSIDRequestContext>)context
                       error:(NSError **)error
{
    if (!accountIdentifier)
    {
        MSIDFillAndLogError(error, MSIDErrorInternal, @"Cannot clear cache without account provided", context.correlationId);
        return NO;
    }

    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"(Default accessor) Clearing cache for environment: %@, client ID %@, family ID %@, account %@", authority.environment, clientId, familyId, accountIdentifier.maskedHomeAccountId);

    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_DELETE, context);

    NSString *homeAccountId = accountIdentifier.homeAccountId;

    if ([NSString msidIsStringNilOrBlank:homeAccountId]
        && ![NSString msidIsStringNilOrBlank:accountIdentifier.displayableId])
    {
        homeAccountId = [self homeAccountIdForLegacyId:accountIdentifier.displayableId authority:authority context:context error:error];

        MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Default accessor) Resolving home account ID from legacy account ID, legacy account %@, resolved account %@", accountIdentifier.maskedDisplayableId, MSID_PII_LOG_TRACKABLE(homeAccountId));
    }

    BOOL result = YES;

    if (homeAccountId)
    {
        NSArray *aliases = [authority defaultCacheEnvironmentAliases];

        MSIDDefaultCredentialCacheQuery *query = [MSIDDefaultCredentialCacheQuery new];
        query.clientId = clientId;
        query.familyId = familyId;
        query.homeAccountId = homeAccountId;
        query.environmentAliases = aliases;
        query.matchAnyCredentialType = YES;

        NSError *credentialRemovalError;
        result = [_accountCredentialCache removeCredentialsWithQuery:query context:context error:&credentialRemovalError];

        if (!result)
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, context, @"Failed to remove credentials with error %@", MSID_PII_LOG_MASKABLE(credentialRemovalError));
            if (error) *error = credentialRemovalError;
        }

        if (clearAccounts)
        {
            MSIDDefaultAccountCacheQuery *accountQuery = [MSIDDefaultAccountCacheQuery new];
            accountQuery.homeAccountId = homeAccountId;
            accountQuery.environmentAliases = aliases;
            accountQuery.accountType = MSIDAccountTypeMSSTS;

            NSError *accountRemovalError;
            BOOL accountRemovalResult = [_accountCredentialCache removeAccountsWithQuery:accountQuery context:context error:&accountRemovalError];

            if (!accountRemovalResult)
            {
                MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, context, @"Failed to remove accounts with error %@", MSID_PII_LOG_MASKABLE(accountRemovalError));
                if (error) *error = accountRemovalError;
                result = NO;
            }
        }

        CONDITIONAL_STOP_CACHE_EVENT(event, nil, result, context);
    }
    else
    {
        CONDITIONAL_STOP_CACHE_EVENT(event, nil, YES, context);
    }

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
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, context, @"Failed to clear cache from other accessor:  %@, error %@", accessor.class, MSID_PII_LOG_MASKABLE(*error));
        }
    }

    return result;
}

- (BOOL)clearCacheForAllAccountsWithContext:(id<MSIDRequestContext>)context
                                      error:(NSError **)error
{
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"(Default accessor) Clearing cache for all accounts");

    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_DELETE, context);

    BOOL result = YES;
    NSError *accountRemovalError;

    result = [_accountCredentialCache clearWithContext:context error:&accountRemovalError];

    if (!result)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, context, @"Failed to remove all accounts with error %@", MSID_PII_LOG_MASKABLE(accountRemovalError));
        if (error) *error = accountRemovalError;
    }

    CONDITIONAL_STOP_CACHE_EVENT(event, nil, result, context);

    // Clear cache from other accessors
    for (id<MSIDCacheAccessor> accessor in _otherAccessors)
    {
        accountRemovalError = nil;
        if (![accessor clearWithContext:context
                                  error:&accountRemovalError])
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, context, @"Failed to clear all cache from other accessor:  %@, error %@", accessor.class, MSID_PII_LOG_MASKABLE(accountRemovalError));
            // Return new error if there wasn't a previous error (if any during primary cache cleanup)
            if (error && result) *error = accountRemovalError;
            result = NO;
        }
    }

    return result;
}

- (BOOL)validateAndRemoveRefreshToken:(MSIDRefreshToken *)token
                              context:(id<MSIDRequestContext>)context
                                error:(NSError **)error
{
    return [self validateAndRemoveRefreshableToken:token
                                    credentialType:MSIDRefreshTokenType
                                           context:context
                                             error:error];
}

- (BOOL)validateAndRemovePrimaryRefreshToken:(MSIDRefreshToken *)token
                                     context:(id<MSIDRequestContext>)context
                                       error:(NSError **)error
{
    return [self validateAndRemoveRefreshableToken:token
                                    credentialType:MSIDPrimaryRefreshTokenType
                                           context:context
                                             error:error];
}

- (BOOL)validateAndRemoveRefreshableToken:(MSIDRefreshToken *)token
                           credentialType:(MSIDCredentialType)credentialType
                                  context:(id<MSIDRequestContext>)context
                                    error:(NSError **)error
{
    if (credentialType != MSIDRefreshTokenType && credentialType != MSIDPrimaryRefreshTokenType) return NO;

    if (!token || [NSString msidIsStringNilOrBlank:token.refreshToken])
    {
        MSIDFillAndLogError(error, MSIDErrorInternal, @"Removing tokens can be done only as a result of a token request. Valid refresh token should be provided.", context.correlationId);
        return NO;
    }

    NSString *environment = token.storageEnvironment ? token.storageEnvironment : token.environment;

    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"Removing refresh token with clientID %@, environment %@, realm %@, userId %@, token %@", token.clientId, environment, token.realm, token.accountIdentifier.maskedHomeAccountId, MSID_EUII_ONLY_LOG_MASKABLE(token));

    MSIDDefaultCredentialCacheQuery *query = [MSIDDefaultCredentialCacheQuery new];
    query.homeAccountId = token.accountIdentifier.homeAccountId;
    query.environment = environment;
    query.clientId = token.clientId;
    query.familyId = token.familyId;
    query.credentialType = credentialType;

    MSIDRefreshToken *tokenInCache = (MSIDRefreshToken *) [self getTokenWithEnvironment:token.environment
                                                                             cacheQuery:query
                                                                                context:context
                                                                                  error:error];

    if (tokenInCache && [tokenInCache.refreshToken isEqualToString:token.refreshToken])
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"Found refresh token in cache and it's the latest version, removing token %@", MSID_EUII_ONLY_LOG_MASKABLE(tokenInCache));
        return [self removeToken:tokenInCache context:context error:error];
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

#pragma mark - Input validation

- (BOOL)checkAccountIdentifier:(NSString *)accountIdentifier
                       context:(id<MSIDRequestContext>)context
                         error:(NSError **)error
{
    if (!accountIdentifier)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"(Default accessor) User identifier is expected for default accessor, but not provided");

        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Account identifier is expected for MSDIDefaultTokenCacheFormat", nil, nil, nil, context.correlationId, nil, YES);
        }
        return NO;
    }

    return YES;
}

#pragma mark - Internal

- (BOOL)saveAccessTokenWithConfiguration:(MSIDConfiguration *)configuration
                                response:(MSIDTokenResponse *)response
                                 factory:(MSIDOauth2Factory *)factory
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError **)error
{
    MSIDAccessToken *accessToken = [factory accessTokenFromResponse:response configuration:configuration];
    if (!accessToken)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Didn't get access token from server. Skipping access token saving");
        return YES;
    }

    if (![self checkAccountIdentifier:accessToken.accountIdentifier.homeAccountId context:context error:error])
    {
        return NO;
    }

    // Delete access tokens with intersecting scopes
    MSIDDefaultCredentialCacheQuery *query = [MSIDDefaultCredentialCacheQuery new];
    query.homeAccountId = accessToken.accountIdentifier.homeAccountId;
    query.environment = accessToken.storageEnvironment;
    query.realm = accessToken.realm;
    query.clientId = accessToken.clientId;
    query.target = [accessToken.scopes msidToString];
    query.targetMatchingOptions = MSIDIntersect;
    query.credentialType = accessToken.credentialType;
    query.applicationIdentifier = accessToken.applicationIdentifier;
    query.tokenType = accessToken.tokenType;

    BOOL result = [_accountCredentialCache removeCredentialsWithQuery:query context:context error:error];

    if (!result)
    {
        return NO;
    }

    return [self saveToken:accessToken
                   context:context
                     error:error];
}

- (BOOL)saveIDTokenWithConfiguration:(MSIDConfiguration *)configuration
                            response:(MSIDTokenResponse *)response
                             factory:(MSIDOauth2Factory *)factory
                             context:(id<MSIDRequestContext>)context
                               error:(NSError **)error
{
    MSIDIdToken *idToken = [factory idTokenFromResponse:response configuration:configuration];

    if (idToken)
    {
        return [self saveToken:idToken
                       context:context
                         error:error];
    }

    return YES;
}

- (BOOL)saveRefreshTokenWithConfiguration:(MSIDConfiguration *)configuration
                                 response:(MSIDTokenResponse *)response
                                  factory:(MSIDOauth2Factory *)factory
                                  context:(id<MSIDRequestContext>)context
                                    error:(NSError **)error
{
    MSIDRefreshToken *refreshToken = [factory refreshTokenFromResponse:response configuration:configuration];

    if (!refreshToken)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning, context, @"(Default accessor) No refresh token was returned. Skipping caching for refresh token");
        return YES;
    }

    if (![NSString msidIsStringNilOrBlank:refreshToken.familyId])
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Default accessor) Saving family refresh token %@", MSID_EUII_ONLY_LOG_MASKABLE(refreshToken));

        if (![self saveToken:refreshToken
                     context:context
                       error:error])
        {
            return NO;
        }
    }

    // Save a separate entry for MRRT
    refreshToken.familyId = nil;
    return [self saveToken:refreshToken
                   context:context
                     error:error];
}

- (BOOL)saveAccountWithConfiguration:(MSIDConfiguration *)configuration
                            response:(MSIDTokenResponse *)response
                             factory:(MSIDOauth2Factory *)factory
                             context:(id<MSIDRequestContext>)context
                               error:(NSError **)error
{
    MSIDAccount *account = [factory accountFromResponse:response configuration:configuration];

    if (account)
    {
        return [self saveAccount:account
                         context:context
                           error:error];
    }

    MSID_LOG_WITH_CTX(MSIDLogLevelWarning, context, @"(Default accessor) No account was returned. Skipping caching for account");
    return YES;
}

- (BOOL)removeToken:(MSIDBaseToken *)token
            context:(id<MSIDRequestContext>)context
              error:(NSError **)error
{
    if (!token)
    {
        MSIDFillAndLogError(error, MSIDErrorInternal, @"Cannot remove token", context.correlationId);
        return NO;
    }

    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_DELETE, context);
    BOOL result = [_accountCredentialCache removeCredential:token.tokenCacheItem context:context error:error];

    if (result && token.credentialType == MSIDRefreshTokenType)
    {
        [_accountCredentialCache saveWipeInfoWithContext:context error:nil];
    }

    CONDITIONAL_STOP_CACHE_EVENT(event, token, result, context);
    return result;
}

#pragma mark - Private

- (NSString *)homeAccountIdForLegacyId:(NSString *)legacyAccountId
                             authority:(MSIDAuthority *)authority
                               context:(id<MSIDRequestContext>)context
                                 error:(NSError **)error
{
    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_LOOKUP, context);

    MSIDDefaultAccountCacheQuery *accountsQuery = [MSIDDefaultAccountCacheQuery new];
    accountsQuery.username = legacyAccountId;
    accountsQuery.environmentAliases = [authority defaultCacheEnvironmentAliases];
    accountsQuery.accountType = MSIDAccountTypeMSSTS;

    NSArray<MSIDAccountCacheItem *> *accountCacheItems = [_accountCredentialCache getAccountsWithQuery:accountsQuery
                                                                                               context:context
                                                                                                 error:error];

    if ([accountCacheItems count])
    {
        CONDITIONAL_STOP_CACHE_EVENT(event, nil, YES, context);
        MSIDAccountCacheItem *accountCacheItem = accountCacheItems[0];
        return accountCacheItem.homeAccountId;
    }

    CONDITIONAL_STOP_CACHE_EVENT(event, nil, NO, context);
    return nil;
}

- (MSIDBaseToken *)getTokenWithEnvironment:(NSString *)environment
                                cacheQuery:(MSIDDefaultCredentialCacheQuery *)cacheQuery
                                   context:(id<MSIDRequestContext>)context
                                     error:(NSError **)error
{
    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_LOOKUP, context);

    MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context, @"(Default accessor) Looking for token with aliases %@, tenant %@, clientId %@, scopes %@", cacheQuery.environmentAliases, cacheQuery.realm, cacheQuery.clientId, cacheQuery.target);

    NSError *cacheError = nil;
    NSArray<MSIDBaseToken *> *resultTokens = [self getTokensWithEnvironment:environment cacheQuery:cacheQuery context:context error:&cacheError];

    if (cacheError)
    {
        if (error) *error = cacheError;
        CONDITIONAL_STOP_CACHE_EVENT(event, nil, NO, context);
        return nil;
    }

    MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context, @"(Default accessor) Found %lu tokens", (unsigned long)[resultTokens count]);

    if (resultTokens.count > 0)
    {
        CONDITIONAL_STOP_CACHE_EVENT(event, resultTokens[0], YES, context);
        return resultTokens[0];
    }

    if (cacheQuery.credentialType == MSIDRefreshTokenType)
    {
        NSError *wipeError = nil;
        CONDITIONAL_STOP_FAILED_CACHE_EVENT(event, [_accountCredentialCache wipeInfoWithContext:context error:&wipeError], context);
        if (wipeError) MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, context, @"Failed to read wipe info with error %@", MSID_PII_LOG_MASKABLE(wipeError));
    }
    else
    {
        CONDITIONAL_STOP_CACHE_EVENT(event, nil, NO, context);
    }
    return nil;
}

- (NSArray<MSIDBaseToken *> *)getTokensWithEnvironment:(NSString *)requestedEnvironment
                                            cacheQuery:(MSIDDefaultCredentialCacheQuery *)cacheQuery
                                               context:(id<MSIDRequestContext>)context
                                                 error:(NSError **)error
{
    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_LOOKUP, context);

    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"(Default accessor) Looking for token with aliases %@, tenant %@, clientId %@, scopes %@", cacheQuery.environmentAliases, cacheQuery.realm, cacheQuery.clientId, cacheQuery.target);

    NSError *cacheError = nil;

    NSArray<MSIDCredentialCacheItem *> *cacheItems = [_accountCredentialCache getCredentialsWithQuery:cacheQuery context:context error:error];

    if (cacheError)
    {
        if (error) *error = cacheError;
        CONDITIONAL_STOP_CACHE_EVENT(event, nil, NO, context);
        return nil;
    }

    NSMutableArray<MSIDBaseToken *> *resultTokens = [NSMutableArray new];
    for (MSIDCredentialCacheItem *cacheItem in cacheItems)
    {
        MSIDBaseToken *resultToken = [cacheItem tokenWithType:cacheQuery.credentialType];

        if (resultToken)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"(Default accessor) Found %lu tokens", (unsigned long)[cacheItems count]);
            resultToken.storageEnvironment = resultToken.environment;

            if (requestedEnvironment)
            {
                resultToken.environment = requestedEnvironment;
            }
            [resultTokens addObject:resultToken];
        }
    }

    return resultTokens;
}

- (MSIDBaseToken *)getRefreshableTokenByDisplayableId:(MSIDAccountIdentifier *)accountIdentifier
                                            authority:(MSIDAuthority *)authority
                                             clientId:(NSString *)clientId
                                             familyId:(NSString *)familyId
                                       credentialType:(MSIDCredentialType)credentialType
                                              context:(id<MSIDRequestContext>)context
                                                error:(NSError **)error
{
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Default accessor) Looking for token with authority %@, clientId %@, legacy userId %@", authority, clientId, accountIdentifier.maskedDisplayableId);

    NSString *homeAccountId = [self homeAccountIdForLegacyId:accountIdentifier.displayableId
                                                   authority:authority
                                                     context:context
                                                       error:error];

    if ([NSString msidIsStringNilOrBlank:homeAccountId])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context, @"(Default accessor) Didn't find a matching home account id for username");
        return nil;
    }

    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"(Default accessor] Found Match with environment %@, home account ID %@", authority.environment, MSID_PII_LOG_TRACKABLE(homeAccountId));

    MSIDDefaultCredentialCacheQuery *rtQuery = [MSIDDefaultCredentialCacheQuery new];
    rtQuery.homeAccountId = homeAccountId;
    rtQuery.environmentAliases = [authority defaultCacheEnvironmentAliases];
    rtQuery.clientId = familyId ? nil : clientId;
    rtQuery.familyId = familyId;
    rtQuery.credentialType = credentialType;

    return [self getTokenWithEnvironment:authority.environment
                              cacheQuery:rtQuery
                                 context:context
                                   error:error];
}

- (BOOL)saveToken:(MSIDBaseToken *)token
          context:(id<MSIDRequestContext>)context
            error:(NSError **)error
{
    if (![self checkAccountIdentifier:token.accountIdentifier.homeAccountId context:context error:error])
    {
        return NO;
    }

    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_WRITE, context);

    MSIDCredentialCacheItem *cacheItem = token.tokenCacheItem;
    BOOL result = [_accountCredentialCache saveCredential:cacheItem context:context error:error];
    CONDITIONAL_STOP_CACHE_EVENT(event, token, result, context);
    return result;
}

- (BOOL)saveAccount:(MSIDAccount *)account
            context:(id<MSIDRequestContext>)context
              error:(NSError **)error
{
    if (![self checkAccountIdentifier:account.accountIdentifier.homeAccountId context:context error:error])
    {
        return NO;
    }

    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_TOKEN_CACHE_WRITE, context);

    MSIDAccountCacheItem *cacheItem = account.accountCacheItem;
    BOOL result = [_accountCredentialCache saveAccount:cacheItem context:context error:error];
    CONDITIONAL_STOP_CACHE_EVENT(event, nil, result, context);
    return result;
}

- (NSArray<MSIDBaseToken *> *)validTokensFromCacheItems:(NSArray<MSIDCredentialCacheItem *> *)cacheItems
{
    NSMutableArray<MSIDBaseToken *> *tokens = [NSMutableArray new];

    for (MSIDCredentialCacheItem *item in cacheItems)
    {
        MSIDBaseToken *token = [item tokenWithType:item.credentialType];
        if (token)
        {
            token.storageEnvironment = token.environment;
            [tokens addObject:token];
        }
    }

    return tokens;
}

- (NSSet<NSString *> *)homeAccountIdsFromRTsWithAuthority:(MSIDAuthority *)authority
                                                 clientId:(NSString *)clientId
                                                 familyId:(NSString *)familyId
                                   accountCredentialCache:(MSIDAccountCredentialCache *)accountCredentialCache
                                                  context:(id<MSIDRequestContext>)context
                                                    error:(NSError **)error
{
    // Retrieve refresh tokens in cache, and return account ids for those refresh tokens
    MSIDDefaultCredentialCacheQuery *refreshTokenQuery = [MSIDDefaultCredentialCacheQuery new];
    refreshTokenQuery.credentialType = MSIDRefreshTokenType;
    refreshTokenQuery.clientId = clientId;
    refreshTokenQuery.familyId = familyId;
    refreshTokenQuery.environmentAliases = [authority defaultCacheEnvironmentAliases];
    refreshTokenQuery.clientIdMatchingOptions = MSIDSuperSet;

    NSArray<MSIDCredentialCacheItem *> *refreshTokens = [accountCredentialCache getCredentialsWithQuery:refreshTokenQuery context:context error:error];

    if (!refreshTokens)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"(Default accessor) Failed refresh token lookup");
        return nil;
    }

    return [NSSet setWithArray:[refreshTokens valueForKey:@"homeAccountId"]];
}

- (NSMutableSet<MSIDAccount *> *)filterAndFillIdTokenClaimsForAccounts:(NSArray<MSIDAccountCacheItem *> *)allAccounts
                                                             authority:(MSIDAuthority *)authority
                                                      accountIdsFromRT:(NSSet<NSString *> *)accountIdsFromRT
                                                              idTokens:(NSArray<MSIDIdToken *> *)idTokens
                                                              clientId:(NSString *)clientId
                                                  accountMetadataCache:(MSIDAccountMetadataCacheAccessor *)accountMetadataCache
                                                  signedInAccountsOnly:(BOOL)signedInAccountsOnly
                                                   noReturnAccountUPNs:(NSMutableSet<NSString *> **)noReturnAccountUPNs
{
    NSMutableSet<MSIDAccount *> *returnAccountsSet = [NSMutableSet new];
    NSMutableSet<NSString *> *noReturnAccountsSet = [NSMutableSet new];

    // Build up a search map for quick id token match up
    NSMutableDictionary *idTokenSearchMap = [NSMutableDictionary new];
    for (MSIDIdToken *idToken in idTokens)
    {
        NSString *key = [NSString stringWithFormat:@"%@-%@-%@", idToken.accountIdentifier.homeAccountId, idToken.environment, idToken.realm];
        [idTokenSearchMap setValue:idToken forKey:key];
    }

    for (MSIDAccountCacheItem *accountCacheItem in allAccounts)
    {
        BOOL shouldReturnAccount = NO;
        if (signedInAccountsOnly)
        {
            if ([accountIdsFromRT containsObject:accountCacheItem.homeAccountId])
            {
                shouldReturnAccount = YES;
            }

            MSIDAccountMetadataState signInState = [accountMetadataCache signInStateForHomeAccountId:accountCacheItem.homeAccountId clientId:clientId context:nil error:nil];
            if (signInState == MSIDAccountMetadataStateSignedIn)
            {
                shouldReturnAccount = YES;
            }
            else if (signInState == MSIDAccountMetadataStateSignedOut)
            {
                shouldReturnAccount = NO;
            }
        }
        else
        {
            shouldReturnAccount = YES;
        }

        // init account from account cache item
        if (authority.environment)
        {
            accountCacheItem.environment = authority.environment;
        }

        // add account to the correct set
        if (shouldReturnAccount)
        {
            MSIDAccount *account = [[MSIDAccount alloc] initWithAccountCacheItem:accountCacheItem];
            if (!account) continue;

            NSString *idTokenSearchKey = [NSString stringWithFormat:@"%@-%@-%@", account.accountIdentifier.homeAccountId, account.environment, account.realm];
            MSIDIdToken *idToken = idTokenSearchMap[idTokenSearchKey];

            if (idToken)
            {
                NSError *error =  nil;
                account.idTokenClaims = [[MSIDIdTokenClaims alloc] initWithRawIdToken:idToken.rawIdToken error:&error];

                if (error)
                {
                    MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to create id token claims when fill id token claims for msidAccount!");
                }
            }

            [returnAccountsSet addObject:account];
        }
        else
        {
            [noReturnAccountsSet addObject:accountCacheItem.username];
        }
    }

    if (noReturnAccountUPNs) *noReturnAccountUPNs = noReturnAccountsSet;

    return returnAccountsSet;
}

- (NSArray<MSIDAccount *> *)filterSignedOutAccountsFromOtherAccessor:(NSArray<MSIDAccount *> *)accounts
                                                accountMetadataCache:(MSIDAccountMetadataCacheAccessor *)accountMetadataCache
                                                            clientId:(NSString *)clientId
                                                 noReturnAccountUPNs:(NSSet<NSString *> *)noReturnAccountUPNSet
                                                 knownReturnAccounts:(NSSet<MSIDAccount *> *)knownReturnAccounts
{
    NSMutableArray *returnAccounts = [NSMutableArray new];
    for (MSIDAccount *account in accounts)
    {
        // We rely on UPN check only if home account id is not available
        if ([NSString msidIsStringNilOrBlank:account.accountIdentifier.homeAccountId])
        {
            if ([noReturnAccountUPNSet containsObject:account.username]) continue;
        }
        else if ([knownReturnAccounts containsObject:account])
        {
            continue;
        }
        else
        {
            MSIDAccountMetadataState signInState = [accountMetadataCache signInStateForHomeAccountId:account.accountIdentifier.homeAccountId clientId:clientId context:nil error:nil];
            if (signInState == MSIDAccountMetadataStateSignedOut) continue;
        }

        [returnAccounts addObject:account];
    }

    return returnAccounts;
}

#pragma mark - App metadata

- (BOOL)saveAppMetadataWithConfiguration:(MSIDConfiguration *)configuration
                                response:(MSIDTokenResponse *)response
                                 factory:(MSIDOauth2Factory *)factory
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError **)error
{
    MSIDAppMetadataCacheItem *metadata = [factory appMetadataFromResponse:response configuration:configuration];
    if (!metadata)
    {
        MSIDFillAndLogError(error, MSIDErrorInternal, @"Failed to create app metadata from response", context.correlationId);
        return NO;
    }

    metadata.environment = [configuration.authority cacheEnvironmentWithContext:context];

    CONDITIONAL_START_CACHE_EVENT(event, MSID_TELEMETRY_EVENT_APP_METADATA_WRITE, context);

    BOOL result = [_accountCredentialCache saveAppMetadata:metadata context:context error:error];
    CONDITIONAL_STOP_CACHE_EVENT(event, nil, result, context);

    return result;
}

- (NSArray<MSIDAppMetadataCacheItem *> *)getAppMetadataEntries:(MSIDConfiguration *)configuration
                                                       context:(id<MSIDRequestContext>)context
                                                         error:(NSError *__autoreleasing *)error
{
    MSIDAppMetadataCacheQuery *metadataQuery = [[MSIDAppMetadataCacheQuery alloc] init];
    metadataQuery.clientId = configuration.clientId;
    metadataQuery.generalType = MSIDAppMetadataType;
    metadataQuery.environmentAliases = [configuration.authority defaultCacheEnvironmentAliases];
    return [_accountCredentialCache getAppMetadataEntriesWithQuery:metadataQuery context:context error:error];
}

- (BOOL)updateAppMetadataWithFamilyId:(NSString *)familyId
                             clientId:(NSString *)clientId
                            authority:(MSIDAuthority *)authority
                              context:(id<MSIDRequestContext>)context
                                error:(NSError **)error
{
    MSIDAppMetadataCacheQuery *metadataQuery = [[MSIDAppMetadataCacheQuery alloc] init];
    metadataQuery.clientId = clientId;
    metadataQuery.generalType = MSIDAppMetadataType;
    metadataQuery.environmentAliases = [authority defaultCacheEnvironmentAliases];
    NSArray<MSIDAppMetadataCacheItem *> *appmetadataItems = [_accountCredentialCache getAppMetadataEntriesWithQuery:metadataQuery context:context error:error];

    if (!appmetadataItems)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"(Default accessor) Couldn't read app metadata cache items");
        return NO;
    }

    if (![appmetadataItems count])
    {
        // Create new app metadata if there's no app metadata present at all
        MSIDAppMetadataCacheItem *appmetadata = [MSIDAppMetadataCacheItem new];
        appmetadata.clientId = clientId;
        appmetadata.environment = [authority cacheEnvironmentWithContext:context];
        appmetadata.familyId = familyId;
        return [_accountCredentialCache saveAppMetadata:appmetadata context:context error:error];
    }
    else
    {
        // If existing app metadata is present, update app metadata entries
        for (MSIDAppMetadataCacheItem *appmetadata in appmetadataItems)
        {
            appmetadata.familyId = familyId;
            BOOL updateResult = [_accountCredentialCache saveAppMetadata:appmetadata context:context error:error];

            if (!updateResult)
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"(Default accessor) Failed to save updated app metadata");
                return NO;
            }
        }

        return YES;
    }
}

@end
