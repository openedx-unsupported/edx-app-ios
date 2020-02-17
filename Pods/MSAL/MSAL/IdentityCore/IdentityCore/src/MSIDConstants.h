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

@class MSIDTokenResult;

typedef NS_ENUM(NSInteger, MSIDWebviewType)
{
#if TARGET_OS_IPHONE
    // For iOS 11 and up, uses AuthenticationSession (ASWebAuthenticationSession
    // or SFAuthenticationSession).
    // For older versions, with AuthenticationSession not being available, uses
    // SafariViewController.
    MSIDWebviewTypeDefault,

    // Use SFAuthenticationSession/ASWebAuthenticationSession
    MSIDWebviewTypeAuthenticationSession,

    // Use SFSafariViewController for all versions.
    MSIDWebviewTypeSafariViewController,

#endif
    // Use WKWebView
    MSIDWebviewTypeWKWebView,
};

typedef NS_ENUM(NSInteger, MSIDInteractiveRequestType)
{
    MSIDInteractiveRequestBrokeredType = 0,
    MSIDInteractiveRequestLocalType
};

typedef NS_ENUM(NSInteger, MSIDUIBehaviorType)
{
    MSIDUIBehaviorInteractiveType = 0,
    MSIDUIBehaviorAutoType,
    MSIDUIBehaviorForceType
};

typedef NS_ENUM(NSInteger, MSIDPromptType)
{
    MSIDPromptTypePromptIfNecessary = 0, // No prompt specified, will use cookies is present, prompt otherwise
    MSIDPromptTypeLogin, // prompt == "login", will force user to enter credentials
    MSIDPromptTypeConsent, // prompt == "consent", will force user to grant permissions
    MSIDPromptTypeSelectAccount, // prompt == "select_account", will show an account picker UI
    MSIDPromptTypeRefreshSession, // prompt=refresh_session
    MSIDPromptTypeNever, // prompt=none, ensures user is never prompted
    MSIDPromptTypeDefault = MSIDPromptTypePromptIfNecessary
};

typedef void (^MSIDRequestCompletionBlock)(MSIDTokenResult * _Nullable result, NSError * _Nullable error);

extern NSString * _Nonnull const MSID_PLATFORM_KEY;//The SDK platform. iOS or OSX
extern NSString * _Nonnull const MSID_SOURCE_PLATFORM_KEY;//The source SDK platform. iOS or OSX
extern NSString * _Nonnull const MSID_VERSION_KEY;
extern NSString * _Nonnull const MSID_CPU_KEY;//E.g. ARM64
extern NSString * _Nonnull const MSID_OS_VER_KEY;//iOS/OSX version
extern NSString * _Nonnull const MSID_DEVICE_MODEL_KEY;//E.g. iPhone 5S
extern NSString * _Nonnull const MSID_APP_NAME_KEY;
extern NSString * _Nonnull const MSID_APP_VER_KEY;
extern NSString * _Nonnull const MSID_BROKER_RESUME_DICTIONARY_KEY;
extern NSString * _Nonnull const MSID_BROKER_SYMMETRIC_KEY_TAG;
extern NSString * _Nonnull const MSID_BROKER_ADAL_SCHEME;
extern NSString * _Nonnull const MSID_BROKER_MSAL_SCHEME;
extern NSString * _Nonnull const MSID_BROKER_NONCE_SCHEME;
extern NSString * _Nonnull const MSID_BROKER_APP_BUNDLE_ID;
extern NSString * _Nonnull const MSID_BROKER_APP_BUNDLE_ID_DF;
extern NSString * _Nonnull const MSID_BROKER_MAX_PROTOCOL_VERSION;
extern NSString * _Nonnull const MSID_BROKER_PROTOCOL_VERSION_KEY;
extern NSString * _Nonnull const MSID_ADAL_BROKER_MESSAGE_VERSION;
extern NSString * _Nonnull const MSID_MSAL_BROKER_MESSAGE_VERSION;
extern NSString * _Nonnull const MSID_AUTHENTICATOR_REDIRECT_URI;
extern NSString * _Nonnull const MSID_DEFAULT_FAMILY_ID;
extern NSString * _Nonnull const MSID_ADAL_SDK_NAME;
extern NSString * _Nonnull const MSID_MSAL_SDK_NAME;
extern NSString * _Nonnull const MSID_SDK_NAME_KEY;
extern NSString * _Nonnull const MSID_BROKER_APPLICATION_TOKEN_TAG;

extern NSString * _Nonnull const MSIDTrustedAuthority;
extern NSString * _Nonnull const MSIDTrustedAuthorityUS;
extern NSString * _Nonnull const MSIDTrustedAuthorityChina;
extern NSString * _Nonnull const MSIDTrustedAuthorityChina2;
extern NSString * _Nonnull const MSIDTrustedAuthorityGermany;
extern NSString * _Nonnull const MSIDTrustedAuthorityWorldWide;
extern NSString * _Nonnull const MSIDTrustedAuthorityUSGovernment;
extern NSString * _Nonnull const MSIDTrustedAuthorityCloudGovApi;

extern NSString * _Nonnull const MSID_DEFAULT_AAD_AUTHORITY;
extern NSString * _Nonnull const MSID_DEFAULT_MSA_TENANTID;
