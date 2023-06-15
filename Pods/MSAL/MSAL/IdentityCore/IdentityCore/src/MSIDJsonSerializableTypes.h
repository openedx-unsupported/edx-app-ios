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

#import <Foundation/Foundation.h>

typedef NSString *const MSIDJsonSerializableType NS_TYPED_ENUM;

extern MSIDJsonSerializableType const MSID_JSON_TYPE_AAD_AUTHORITY;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_ADFS_AUTHORITY;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_B2C_AUTHORITY;

extern MSIDJsonSerializableType const MSID_JSON_TYPE_OPERATION_REQUEST_REMOVE_ACCOUNT;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_OPERATION_REQUEST_SIGNOUT_ACCOUNT;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_OPERATION_REQUEST_GET_ACCOUNTS;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_OPERATION_REQUEST_GET_DEVICE_INFO;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_OPERATION_REQUEST_GET_PRT;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_OPERATION_REQUEST_GET_SSO_COOKIES;

extern MSIDJsonSerializableType const MSID_JSON_TYPE_BROKER_OPERATION_GET_ACCOUNTS_RESPONSE;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_BROKER_OPERATION_GENERIC_RESPONSE;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_BROKER_OPERATION_TOKEN_RESPONSE;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_PROVIDER_AADV1;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_PROVIDER_AADV2;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_PROVIDER_B2C;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_PROVIDER_ADFS;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_AADV1_TOKEN_RESPONSE;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_AADV2_TOKEN_RESPONSE;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_B2C_TOKEN_RESPONSE;
extern MSIDJsonSerializableType const MSID_JSON_TYPE_BROKER_OPERATION_GET_SSO_COOKIES_RESPONSE;
