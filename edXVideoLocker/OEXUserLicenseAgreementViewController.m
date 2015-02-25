//
//  OEXUserLicenseAgreementViewController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 19/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXUserLicenseAgreementViewController.h"
#import "OEXRegistrationAgreement.h"

@interface OEXUserLicenseAgreementViewController ()<UIWebViewDelegate>
{
    IBOutlet UIWebView *webView;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    IBOutlet UILabel *labelTitle;
}
@end

@implementation OEXUserLicenseAgreementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if(self.agreementTitle){
        labelTitle.text=self.agreementTitle;
    }else{
        labelTitle.hidden=YES;
    }
    NSURLRequest *request=[[NSURLRequest alloc] initWithURL:self.contentUrl];
    webView.delegate=self;
    [webView loadRequest:request];
}

-(void)viewWillAppear:(BOOL)animated{
    [UIApplication sharedApplication].statusBarHidden=YES;
}

-(void)viewWillDisappear:(BOOL)animated{
    [UIApplication sharedApplication].statusBarHidden=NO;
}

-(IBAction)closeButtonTapped:(id)sender{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [activityIndicator stopAnimating];
    ELog(@"error==>%@",[error localizedDescription]);
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [activityIndicator stopAnimating];
    ELog(@"Web view did finish loading");
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    [activityIndicator startAnimating];
    ELog(@"Web view did start loading");
    
}
@end
