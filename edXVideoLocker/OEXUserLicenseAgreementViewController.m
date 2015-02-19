//
//  OEXUserLicenseAgreementViewController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 19/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXUserLicenseAgreementViewController.h"

@interface OEXUserLicenseAgreementViewController ()<UIWebViewDelegate>
{
    IBOutlet UIWebView *webView;
    IBOutlet UIActivityIndicatorView *activityIndicator;
}
@end

@implementation OEXUserLicenseAgreementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    NSURLRequest *request=[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.agreement.url]];
    webView.delegate=self;
    [webView loadRequest:request];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [UIApplication sharedApplication].statusBarHidden=YES;
}

-(void)viewWillDisappear:(BOOL)animated{
    [UIApplication sharedApplication].statusBarHidden=NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
