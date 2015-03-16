//
//  OEXRevealContentViewController+Protected.h
//  edXVideoLocker
//
//  Created by Abhradeep on 16/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRevealContentViewController.h"
#import "SWRevealViewController.h"

@interface OEXRevealContentViewController () <SWRevealViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIButton* overlayButton;

- (IBAction)overlayButtonTapped:(id)sender;

@end
