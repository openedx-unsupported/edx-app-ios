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

#import "MSIDNTLMUIPrompt.h"
#import "MSIDAppExtensionUtil.h"
#import "UIApplication+MSIDExtensions.h"
#import "MSIDMainThreadUtil.h"

@implementation MSIDNTLMUIPrompt

__weak static UIAlertController *_presentedPrompt = nil;

+ (void)dismissPrompt
{
    [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
        if (_presentedPrompt.presentingViewController)
        {
            [_presentedPrompt.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
        
        _presentedPrompt = nil;
    }];
}

+ (void)presentPromptInParentController:(UIViewController *)parentViewController
                      completionHandler:(void (^)(NSString *username, NSString *password, BOOL cancel))block
{
    
    if ([MSIDAppExtensionUtil isExecutingInAppExtension])
    {
        block(nil, nil, YES);
        return;
    }
    
     [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
         
        UIViewController *viewController = [UIApplication msidCurrentViewController:parentViewController];
         
        if (!viewController)
        {
            block(nil, nil, YES);
            return;
        }
        
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        
        NSString *title = NSLocalizedStringFromTableInBundle(@"Enter your credentials", nil, bundle, nil);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction =
        [UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", nil, bundle, nil)
                                 style:UIAlertActionStyleCancel
                               handler:^(__unused UIAlertAction * _Nonnull action)
         {
             block(nil, nil, YES);
         }];
        
        UIAlertAction *loginAction =
        [UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Login", nil, bundle, nil)
                                 style:UIAlertActionStyleDefault
                               handler:^(__unused UIAlertAction * _Nonnull action)
         {
             UITextField *username = alert.textFields.firstObject;
             UITextField *password = alert.textFields.lastObject;
             
             block(username.text, password.text, NO);
         }];
        
        [alert addAction:cancelAction];
        [alert addAction:loginAction];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) { (void)textField; }];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.secureTextEntry = YES;
        }];
        
        [viewController presentViewController:alert animated:YES completion:^{}];
        
        _presentedPrompt = alert;
    }];
}

@end

