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

#import "MSIDOAuth2Constants.h"
#import "MSIDAADNetworkConfiguration.h"

NSString *const MSID_OAUTH2_ACCESS_TOKEN       = @"access_token";
NSString *const MSID_OAUTH2_AUTHORIZATION      = @"authorization";
NSString *const MSID_OAUTH2_AUTHORIZE_SUFFIX   = @"/oauth2/authorize";
NSString *const MSID_OAUTH2_TOKEN_SUFFIX       = @"/oauth2/token";
NSString *const MSID_OAUTH2_AUTHORITY           = @"authority";
NSString *const MSID_OAUTH2_AUTHORIZATION_CODE = @"authorization_code";
NSString *const MSID_OAUTH2_AUTHORIZATION_URI  = @"authorization_uri";
NSString *const MSID_OAUTH2_BEARER             = @"Bearer";
NSString *const MSID_OAUTH2_CLIENT_ID          = @"client_id";
NSString *const MSID_OAUTH2_CLAIMS             = @"claims";
NSString *const MSID_OAUTH2_CODE               = @"code";
NSString *const MSID_OAUTH2_ERROR              = @"error";
NSString *const MSID_OAUTH2_ERROR_DESCRIPTION  = @"error_description";
NSString *const MSID_OAUTH2_ERROR_SUBCODE      = @"error_subcode";
NSString *const MSID_OAUTH2_EXPIRES_IN         = @"expires_in";
NSString *const MSID_OAUTH2_GRANT_TYPE         = @"grant_type";
NSString *const MSID_OAUTH2_REDIRECT_URI       = @"redirect_uri";
NSString *const MSID_OAUTH2_REFRESH_TOKEN      = @"refresh_token";
NSString *const MSID_OAUTH2_RESOURCE           = @"resource";
NSString *const MSID_OAUTH2_RESPONSE_TYPE      = @"response_type";
NSString *const MSID_OAUTH2_SCOPE              = @"scope";
NSString *const MSID_OAUTH2_STATE              = @"state";
NSString *const MSID_OAUTH2_SUB_ERROR          = @"suberror";
NSString *const MSID_OAUTH2_TOKEN              = @"token";
NSString *const MSID_OAUTH2_INSTANCE_DISCOVERY_SUFFIX = @"common/discovery/instance";
NSString *const MSID_OAUTH2_TOKEN_TYPE         = @"token_type";
NSString *const MSID_OAUTH2_LOGIN_HINT         = @"login_hint";
NSString *const MSID_OAUTH2_ID_TOKEN           = @"id_token";
NSString *const MSID_OAUTH2_CORRELATION_ID_RESPONSE  = @"correlation_id";
NSString *const MSID_OAUTH2_CORRELATION_ID_REQUEST   = @"return-client-request-id";
NSString *const MSID_OAUTH2_CORRELATION_ID_REQUEST_VALUE = @"client-request-id";
NSString *const MSID_OAUTH2_ASSERTION = @"assertion";
NSString *const MSID_OAUTH2_SAML11_BEARER_VALUE = @"urn:ietf:params:oauth:grant-type:saml1_1-bearer";
NSString *const MSID_OAUTH2_SAML2_BEARER_VALUE = @"urn:ietf:params:oauth:grant-type:saml2-bearer";
NSString *const MSID_OAUTH2_SCOPE_OPENID_VALUE = @"openid";
NSString *const MSID_OAUTH2_SCOPE_PROFILE_VALUE = @"profile";
NSString *const MSID_OAUTH2_SCOPE_OFFLINE_ACCESS_VALUE = @"offline_access";
NSString *const MSID_OAUTH2_CLIENT_TELEMETRY    = @"x-ms-clitelem";
NSString *const MSID_OAUTH2_PROMPT              = @"prompt";
NSString *const MSID_OAUTH2_PROMPT_NONE         = @"none";

NSString *const MSID_OAUTH2_EXPIRES_ON          = @"expires_on";
NSString *const MSID_OAUTH2_EXT_EXPIRES_IN      = @"ext_expires_in";
NSString *const MSID_FAMILY_ID                  = @"foci";
NSString *const MSID_ENROLLMENT_ID              = @"microsoft_enrollment_id";

NSString *const MSID_OAUTH2_CODE_CHALLENGE               = @"code_challenge";
NSString *const MSID_OAUTH2_CODE_CHALLENGE_METHOD        = @"code_challenge_method";
NSString *const MSID_OAUTH2_CODE_VERIFIER                = @"code_verifier";

NSString *const MSID_OAUTH2_CLIENT_INFO                  = @"client_info";
NSString *const MSID_OAUTH2_UNIQUE_IDENTIFIER            = @"uid";
NSString *const MSID_OAUTH2_UNIQUE_TENANT_IDENTIFIER     = @"utid";

NSString *const MSID_OAUTH2_DOMAIN_REQ                   = @"domain_req";
NSString *const MSID_OAUTH2_LOGIN_REQ                    = @"login_req";

NSString *const MSID_OAUTH2_ADDITIONAL_SERVER_INFO       = @"additional_server_info";
NSString *const MSID_OAUTH2_ENVIRONMENT                  = @"environment";

NSString *const MSID_PROTECTION_POLICY_REQUIRED          = @"protection_policy_required";
NSString *const MSID_USER_DISPLAYABLE_IDENTIFIER         = @"adi";

NSString *const MSID_AUTH_CLOUD_INSTANCE_HOST_NAME       = @"cloud_instance_host_name";

NSString *const MSID_CREDENTIAL_TYPE_CACHE_KEY           = @"credential_type";
NSString *const MSID_ENVIRONMENT_CACHE_KEY               = @"environment";
NSString *const MSID_REALM_CACHE_KEY                     = @"realm";
NSString *const MSID_AUTHORITY_CACHE_KEY                 = @"authority";
NSString *const MSID_HOME_ACCOUNT_ID_CACHE_KEY           = @"home_account_id";
NSString *const MSID_ENROLLMENT_ID_CACHE_KEY             = @"enrollment_id";
NSString *const MSID_CLIENT_ID_CACHE_KEY                 = @"client_id";
NSString *const MSID_FAMILY_ID_CACHE_KEY                 = @"family_id";
NSString *const MSID_TOKEN_CACHE_KEY                     = @"secret";
NSString *const MSID_USERNAME_CACHE_KEY                  = @"username";
NSString *const MSID_TARGET_CACHE_KEY                    = @"target";
NSString *const MSID_CLIENT_INFO_CACHE_KEY               = @"client_info";
NSString *const MSID_ID_TOKEN_CACHE_KEY                  = @"id_token";
NSString *const MSID_ADDITIONAL_INFO_CACHE_KEY           = @"additional_info";
NSString *const MSID_EXPIRES_ON_CACHE_KEY                = @"expires_on";
NSString *const MSID_OAUTH_TOKEN_TYPE_CACHE_KEY          = @"access_token_type";
NSString *const MSID_CACHED_AT_CACHE_KEY                 = @"cached_at";
NSString *const MSID_EXTENDED_EXPIRES_ON_CACHE_KEY       = @"extended_expires_on";
NSString *const MSID_SPE_INFO_CACHE_KEY                  = @"spe_info";
NSString *const MSID_RESOURCE_RT_CACHE_KEY               = @"resource_refresh_token";
NSString *const MSID_LOCAL_ACCOUNT_ID_CACHE_KEY          = @"local_account_id";
NSString *const MSID_AUTHORITY_TYPE_CACHE_KEY            = @"authority_type";
NSString *const MSID_GIVEN_NAME_CACHE_KEY                = @"given_name";
NSString *const MSID_MIDDLE_NAME_CACHE_KEY               = @"middle_name";
NSString *const MSID_FAMILY_NAME_CACHE_KEY               = @"family_name";
NSString *const MSID_NAME_CACHE_KEY                      = @"name";
NSString *const MSID_ALTERNATIVE_ACCOUNT_ID_KEY          = @"alternative_account_id";
NSString *const MSID_SESSION_KEY_CACHE_KEY               = @"session_key";
NSString *const MSID_ACCOUNT_CACHE_KEY                   = @"account_metadata";
NSString *const MSID_LAST_MOD_TIME_CACHE_KEY             = @"last_modification_time";
NSString *const MSID_LAST_MOD_APP_CACHE_KEY              = @"last_modification_app";
NSString *const MSID_APPLICATION_IDENTIFIER_CACHE_KEY    = @"application_cache_identifier";
NSString *const MSID_ACCESS_TOKEN_CACHE_TYPE             = @"AccessToken";
NSString *const MSID_ACCOUNT_CACHE_TYPE                  = @"Account";
NSString *const MSID_REFRESH_TOKEN_CACHE_TYPE            = @"RefreshToken";
NSString *const MSID_APPLICATION_METADATA_CACHE_TYPE     = @"AppMetadata";
NSString *const MSID_ACCOUNT_METADATA_CACHE_TYPE         = @"AccountMetadata";
NSString *const MSID_LEGACY_TOKEN_CACHE_TYPE             = @"LegacySingleResourceToken";
NSString *const MSID_ID_TOKEN_CACHE_TYPE                 = @"IdToken";
NSString *const MSID_LEGACY_ID_TOKEN_CACHE_TYPE          = @"V1IdToken";
NSString *const MSID_PRT_TOKEN_CACHE_TYPE                = @"PrimaryRefreshToken";
NSString *const MSID_GENERAL_TOKEN_CACHE_TYPE            = @"token";
NSString *const MSID_GENERAL_CACHE_ITEM_TYPE             = @"general_cache_item";
NSString *const MSID_APP_METADATA_CACHE_TYPE             = @"appmetadata";
NSString *const MSID_APP_METADATA_AUTHORITY_MAP_TYPE     = @"authority_map";

NSString *const MSID_OPENID_CONFIGURATION_SUFFIX         = @".well-known/openid-configuration";
NSString *const MSID_PREFERRED_USERNAME_MISSING          = @"Missing from the token response";

NSString *const MSIDServerErrorClientMismatch            = @"client_mismatch";
NSString *const MSIDServerErrorBadToken                  = @"bad_token";
