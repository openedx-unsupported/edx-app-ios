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

#import "MSIDRegistrationInformation.h"

@implementation MSIDRegistrationInformation

@synthesize securityIdentity = _securityIdentity;
@synthesize certificate = _certificate;
@synthesize certificateSubject = _certificateSubject;
@synthesize certificateData = _certificateData;
@synthesize certificateIssuer = _certificateIssuer;
@synthesize privateKey = _privateKey;

- (id)initWithSecurityIdentity:(SecIdentityRef)identity
             certificateIssuer:(NSString *)certificateIssuer
                   certificate:(SecCertificateRef)certificate
            certificateSubject:(NSString *)certificateSubject
               certificateData:(NSData *)certificateData
                    privateKey:(SecKeyRef)privateKey

{
    if (!(identity && certificateIssuer && certificate && certificateSubject && certificateData && privateKey)) return nil;
    
    if (!(self = [super init])) return nil;
    
    // ARC is not aware of Core Foundation objects, so they still have to be
    // manually retained and released.
    _securityIdentity = identity;
    CFRetain(identity);
    _certificate = certificate;
    CFRetain(certificate);
    _privateKey = privateKey;
    CFRetain(privateKey);
    
    _certificateSubject = certificateSubject;
    _certificateData = certificateData;
    _certificateIssuer = certificateIssuer;
    
    return self;
}

- (void)dealloc
{
    // ARC is not aware of Core Foundation objects, so they still have to be
    // manually retained and released.
    CFRelease(_securityIdentity);
    _securityIdentity = NULL;
    
    CFRelease(_certificate);
    _certificate = NULL;
    
    CFRelease(_privateKey);
    _privateKey = NULL;
}

- (BOOL)isWorkPlaceJoined
{
    return _certificate != nil;
}

@end
