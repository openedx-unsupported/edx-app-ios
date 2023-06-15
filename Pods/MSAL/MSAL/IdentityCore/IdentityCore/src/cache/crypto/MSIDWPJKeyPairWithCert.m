//
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


#import "MSIDWPJKeyPairWithCert.h"
#import "MSIDKeychainUtil.h"

@interface MSIDWPJKeyPairWithCert()

@property (nonatomic) SecCertificateRef certificateRef;
@property (nonatomic) NSData *certificateData;
@property (nonatomic) NSString *certificateSubject;
@property (nonatomic) NSString *certificateIssuer;
@property (nonatomic) SecKeyRef privateKeyRef;

@end

@implementation MSIDWPJKeyPairWithCert

- (nullable instancetype)initWithPrivateKey:(SecKeyRef)privateKey
                                certificate:(SecCertificateRef)certRef
                          certificateIssuer:(nullable NSString *)issuer
{
    if (!certRef || !privateKey)
    {
        return nil;
    }
    
    self = [super init];
    
    if (self)
    {
        _certificateData = (NSData *)CFBridgingRelease(SecCertificateCopyData(certRef));
        
        if (!_certificateData)
        {
            return nil;
        }
        
        _privateKeyRef = privateKey;
        CFRetain(_privateKeyRef);
        
        _certificateRef = certRef;
        CFRetain(_certificateRef);
        
        _certificateSubject = (__bridge_transfer NSString *)(SecCertificateCopySubjectSummary(_certificateRef));
        
        if (![NSString msidIsStringNilOrBlank:issuer])
        {
            _certificateIssuer = issuer;
        }
        else
        {
            NSData *issuerData = nil;
            
            if (@available(iOS 11.0, macOS 10.12.4, *))
            {
                issuerData = CFBridgingRelease(SecCertificateCopyNormalizedIssuerSequence(certRef));
            }
#if !TARGET_OS_IPHONE
            else
            {
                issuerData = CFBridgingRelease(SecCertificateCopyNormalizedIssuerContent(certRef, NULL));
            }
#endif
                
            if (issuerData)
            {
                _certificateIssuer = [[NSString alloc] initWithData:issuerData encoding:NSASCIIStringEncoding];
            }
        }
        
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, nil, @"Retrieved WPJ issuer %@", _certificateIssuer);
    }
    
    return self;
}

- (void)dealloc
{
    if (_certificateRef)
    {
        CFRelease(_certificateRef);
        _certificateRef = NULL;
    }
    
    if (_privateKeyRef)
    {
        CFRelease(_privateKeyRef);
        _privateKeyRef = NULL;
    }
}

@end
