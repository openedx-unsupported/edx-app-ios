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

#import "MSIDConstants.h"

NSString *const MSID_PLATFORM_KEY               = @"x-client-SKU";
NSString *const MSID_SOURCE_PLATFORM_KEY        = @"x-client-src-SKU";
NSString *const MSID_VERSION_KEY                = @"x-client-Ver";
NSString *const MSID_CPU_KEY                    = @"x-client-CPU";
NSString *const MSID_OS_VER_KEY                 = @"x-client-OS";
NSString *const MSID_DEVICE_MODEL_KEY           = @"x-client-DM";
NSString *const MSID_APP_NAME_KEY               = @"x-app-name";
NSString *const MSID_APP_VER_KEY                = @"x-app-ver";
NSString *const MSID_BROKER_RESUME_DICTIONARY_KEY   =   @"adal-broker-resume-dictionary";
NSString *const MSID_BROKER_SYMMETRIC_KEY_TAG   = @"com.microsoft.adBrokerKey\0";
NSString *const MSID_BROKER_ADAL_SCHEME         = @"msauth";
NSString *const MSID_BROKER_MSAL_SCHEME         = @"msauthv2";
NSString *const MSID_BROKER_NONCE_SCHEME        = @"msauthv3";
NSString *const MSID_BROKER_APP_BUNDLE_ID        = @"com.microsoft.azureauthenticator";
NSString *const MSID_BROKER_APP_BUNDLE_ID_DF     = @"com.microsoft.azureauthenticator-df";
NSString *const MSID_BROKER_MAX_PROTOCOL_VERSION = @"max_protocol_ver";
NSString *const MSID_BROKER_PROTOCOL_VERSION_KEY = @"msg_protocol_ver";
NSString *const MSID_ADAL_BROKER_MESSAGE_VERSION = @"2";
NSString *const MSID_MSAL_BROKER_MESSAGE_VERSION = @"3";
NSString *const MSID_AUTHENTICATOR_REDIRECT_URI  = @"urn:ietf:wg:oauth:2.0:oob";
NSString *const MSID_DEFAULT_FAMILY_ID           = @"1";
NSString *const MSID_ADAL_SDK_NAME               = @"adal-objc";
NSString *const MSID_MSAL_SDK_NAME               = @"msal-objc";
NSString *const MSID_SDK_NAME_KEY                = @"sdk_name";
NSString *const MSID_BROKER_APPLICATION_TOKEN_TAG = @"com.microsoft.adBrokerAppToken";


NSString *const MSIDTrustedAuthority             = @"login.windows.net";
NSString *const MSIDTrustedAuthorityUS           = @"login.microsoftonline.us";
NSString *const MSIDTrustedAuthorityChina        = @"login.chinacloudapi.cn";
NSString *const MSIDTrustedAuthorityChina2       = @"login.partner.microsoftonline.cn";
NSString *const MSIDTrustedAuthorityGermany      = @"login.microsoftonline.de";
NSString *const MSIDTrustedAuthorityWorldWide    = @"login.microsoftonline.com";
NSString *const MSIDTrustedAuthorityUSGovernment = @"login-us.microsoftonline.com";
NSString *const MSIDTrustedAuthorityCloudGovApi  = @"login.usgovcloudapi.net";

NSString *const MSID_DEFAULT_AAD_AUTHORITY       = @"https://login.microsoftonline.com/common";
NSString *const MSID_DEFAULT_MSA_TENANTID        = @"9188040d-6c67-4c5b-b112-36a304b66dad";
