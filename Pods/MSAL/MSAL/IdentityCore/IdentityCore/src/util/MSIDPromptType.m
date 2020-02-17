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

#import "MSIDPromptType_Internal.h"

NSString * MSIDPromptParamFromType(MSIDPromptType type)
{
    switch (type) {
        case MSIDPromptTypeLogin:
            return @"login";
        case MSIDPromptTypeConsent:
            return @"consent";
        case MSIDPromptTypeSelectAccount:
            return @"select_account";
        case MSIDPromptTypeRefreshSession:
            return @"refresh_session";
        case MSIDPromptTypeNever:
            return @"none";

        default:
            return @"";
    }
}

MSIDPromptType MSIDPromptTypeFromString(NSString *promptTypeString)
{
    if ([promptTypeString isEqualToString:@"login"])
    {
        return MSIDPromptTypeLogin;
    }
    else if ([promptTypeString isEqualToString:@"consent"])
    {
        return MSIDPromptTypeConsent;
    }
    else if ([promptTypeString isEqualToString:@"select_account"])
    {
        return MSIDPromptTypeSelectAccount;
    }
    else if ([promptTypeString isEqualToString:@"refresh_session"])
    {
        return MSIDPromptTypeRefreshSession;
    }
    else if ([promptTypeString isEqualToString:@"none"])
    {
        return MSIDPromptTypeNever;
    }

    return MSIDPromptTypeDefault;
}
