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

#import "MSIDJsonSerializableTypes.h"

MSIDJsonSerializableType MSID_JSON_TYPE_AAD_AUTHORITY = @"authority_aad";
MSIDJsonSerializableType MSID_JSON_TYPE_ADFS_AUTHORITY = @"authority_adfs";
MSIDJsonSerializableType MSID_JSON_TYPE_B2C_AUTHORITY = @"authority_b2c";

MSIDJsonSerializableType MSID_JSON_TYPE_OPERATION_REQUEST_REMOVE_ACCOUNT = @"remove_account_operation";
MSIDJsonSerializableType MSID_JSON_TYPE_OPERATION_REQUEST_SIGNOUT_ACCOUNT = @"signout_account_operation";
MSIDJsonSerializableType MSID_JSON_TYPE_OPERATION_REQUEST_GET_ACCOUNTS = @"get_accounts_operation";
MSIDJsonSerializableType MSID_JSON_TYPE_OPERATION_REQUEST_GET_DEVICE_INFO = @"get_device_info";
MSIDJsonSerializableType MSID_JSON_TYPE_OPERATION_REQUEST_GET_PRT = @"get_prt";
MSIDJsonSerializableType MSID_JSON_TYPE_OPERATION_REQUEST_GET_SSO_COOKIES = @"get_sso_cookies";
MSIDJsonSerializableType MSID_JSON_TYPE_BROKER_OPERATION_GET_ACCOUNTS_RESPONSE = @"operation_get_accounts_response";
MSIDJsonSerializableType MSID_JSON_TYPE_BROKER_OPERATION_GENERIC_RESPONSE = @"operation_generic_response";
MSIDJsonSerializableType MSID_JSON_TYPE_BROKER_OPERATION_TOKEN_RESPONSE = @"operation_token_response";
MSIDJsonSerializableType MSID_JSON_TYPE_BROKER_OPERATION_GET_SSO_COOKIES_RESPONSE = @"operation_get_sso_cookies_response";
MSIDJsonSerializableType MSID_JSON_TYPE_PROVIDER_AADV1 = @"provider_aad_v1";
MSIDJsonSerializableType MSID_JSON_TYPE_PROVIDER_AADV2 = @"provider_aad_v2";
MSIDJsonSerializableType MSID_JSON_TYPE_PROVIDER_B2C = @"provider_b2c";
MSIDJsonSerializableType MSID_JSON_TYPE_PROVIDER_ADFS = @"provider_adfs";
MSIDJsonSerializableType MSID_JSON_TYPE_AADV1_TOKEN_RESPONSE = @"token_response_aad_v1";
MSIDJsonSerializableType MSID_JSON_TYPE_AADV2_TOKEN_RESPONSE = @"token_response_aad_v2";
MSIDJsonSerializableType MSID_JSON_TYPE_B2C_TOKEN_RESPONSE = @"token_response_b2c";
