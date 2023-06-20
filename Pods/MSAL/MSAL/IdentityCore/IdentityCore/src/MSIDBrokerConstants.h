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

extern NSString * _Nonnull const MSID_BROKER_RESUME_DICTIONARY_KEY;
extern NSString * _Nonnull const MSID_BROKER_SYMMETRIC_KEY_TAG;
extern NSString * _Nonnull const MSID_BROKER_ADAL_SCHEME;
extern NSString * _Nonnull const MSID_BROKER_MSAL_SCHEME;
extern NSString * _Nonnull const MSID_BROKER_NONCE_SCHEME;
extern NSString * _Nonnull const MSID_BROKER_APP_BUNDLE_ID;
extern NSString * _Nonnull const MSID_BROKER_APP_BUNDLE_ID_DF;
extern NSString * _Nonnull const MSID_BROKER_MAX_PROTOCOL_VERSION;
extern NSString * _Nonnull const MSID_BROKER_PROTOCOL_VERSION_KEY;
/**
 This protocol is being used in ADAL for URL scheme requests to broker.
 */
extern NSInteger const MSID_BROKER_PROTOCOL_VERSION_2;
/**
This protocol is being used in MSAL for URL scheme requests to broker.
*/
extern NSInteger const MSID_BROKER_PROTOCOL_VERSION_3;
/**
This protocol is being used in MSAL for XPC requests to SSO extension.
*/
extern NSInteger const MSID_BROKER_PROTOCOL_VERSION_4;
extern NSString * _Nonnull const MSID_BROKER_OPERATION_KEY;
extern NSString * _Nonnull const MSID_BROKER_KEY;
extern NSString * _Nonnull const MSID_BROKER_CLIENT_VERSION_KEY;
extern NSString * _Nonnull const MSID_BROKER_CLIENT_APP_VERSION_KEY;
extern NSString * _Nonnull const MSID_BROKER_CLIENT_APP_NAME_KEY;
extern NSString * _Nonnull const MSID_BROKER_CORRELATION_ID_KEY;
extern NSString * _Nonnull const MSID_BROKER_REQUEST_PARAMETERS_KEY;
extern NSString * _Nonnull const MSID_BROKER_LOGIN_HINT_KEY;
extern NSString * _Nonnull const MSID_BROKER_PROMPT_KEY;
extern NSString * _Nonnull const MSID_BROKER_CLIENT_SDK_KEY;
extern NSString * _Nonnull const MSID_BROKER_CLIENT_ID_KEY;
extern NSString * _Nonnull const MSID_BROKER_FAMILY_ID_KEY;
extern NSString * _Nonnull const MSID_BROKER_SIGNED_IN_ACCOUNTS_ONLY_KEY;
extern NSString * _Nonnull const MSID_BROKER_EXTRA_OIDC_SCOPES_KEY;
extern NSString * _Nonnull const MSID_BROKER_EXTRA_CONSENT_SCOPES_KEY;
extern NSString * _Nonnull const MSID_BROKER_EXTRA_QUERY_PARAM_KEY;
extern NSString * _Nonnull const MSID_BROKER_INSTANCE_AWARE_KEY;
extern NSString * _Nonnull const MSID_BROKER_INTUNE_ENROLLMENT_IDS_KEY;
extern NSString * _Nonnull const MSID_BROKER_INTUNE_MAM_RESOURCE_KEY;
extern NSString * _Nonnull const MSID_BROKER_CLIENT_CAPABILITIES_KEY;
extern NSString * _Nonnull const MSID_BROKER_REMOVE_ACCOUNT_SCOPE;
extern NSString * _Nonnull const MSID_BROKER_CLAIMS_KEY;
extern NSString * _Nonnull const MSID_BROKER_APPLICATION_TOKEN_TAG;
extern NSString * _Nonnull const MSID_BROKER_DEVICE_MODE_KEY;
extern NSString * _Nonnull const MSID_BROKER_SSO_EXTENSION_MODE_KEY;
extern NSString * _Nonnull const MSID_BROKER_WPJ_STATUS_KEY;
extern NSString * _Nonnull const MSID_BROKER_BROKER_VERSION_KEY;
extern NSString * _Nonnull const MSID_BROKER_IS_PERFORMING_CBA;
extern NSString * _Nonnull const MSID_ADAL_BROKER_MESSAGE_VERSION;
extern NSString * _Nonnull const MSID_MSAL_BROKER_MESSAGE_VERSION;
extern NSString * _Nonnull const MSID_BROKER_SDK_CAPABILITIES_KEY;
extern NSString * _Nonnull const MSID_BROKER_SDK_SSO_EXTENSION_CAPABILITY;
extern NSString * _Nonnull const MSID_BROKER_SSO_URL;
extern NSString * _Nonnull const MSID_BROKER_ACCOUNT_IDENTIFIER;
extern NSString * _Nonnull const MSID_BROKER_TYPES_OF_HEADER;
extern NSString * _Nonnull const MSID_ADDITIONAL_EXTENSION_DATA_KEY;
extern NSString * _Nonnull const MSID_SSO_NONCE_QUERY_PARAM_KEY;
extern NSString * _Nonnull const MSID_BROKER_MDM_ID_KEY;
extern NSString * _Nonnull const MSID_ENROLLED_USER_OBJECT_ID_KEY;
extern NSString * _Nonnull const MSID_EXTRA_DEVICE_INFO_KEY;

