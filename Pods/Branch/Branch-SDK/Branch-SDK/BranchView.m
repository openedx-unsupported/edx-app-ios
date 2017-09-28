//
//  BranchView.m
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/4/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BranchView.h"
#import "BNCPreferenceHelper.h"

NSInteger const BRANCH_VIEW_USAGE_UNLIMITED = -1;
NSString * const BRANCH_VIEW_ID = @"id";
NSString * const BRANCH_VIEW_ACTION = @"action";
NSString * const BRANCH_VIEW_NUM_USE = @"number_of_use";
NSString * const BRANCH_VIEW_WEBURL = @"url";
NSString * const BRANCH_VIEW_WEBHTML = @"html";

@interface BranchView()
@end

@implementation BranchView

- (id)initWithBranchView:(NSDictionary *)branchViewDict andActionName:(NSString *)actionName {
    if (self = [super init]) {
        self.branchViewAction = actionName;
        self.branchViewID = [branchViewDict objectForKey:BRANCH_VIEW_ID];
        self.numOfUse = [[branchViewDict objectForKey:BRANCH_VIEW_NUM_USE] integerValue];
        self.webUrl = [branchViewDict objectForKey:BRANCH_VIEW_WEBURL];
        self.webHtml = [branchViewDict objectForKey:BRANCH_VIEW_WEBHTML];
    }
    return self;
}

- (BOOL)isAvailable {
    NSInteger currentUsage = [[BNCPreferenceHelper preferenceHelper] getBranchViewCount:self.branchViewID];
    return ((self.numOfUse > currentUsage )|| (self.numOfUse == BRANCH_VIEW_USAGE_UNLIMITED));
}

- (void)updateUsageCount {
    [[BNCPreferenceHelper preferenceHelper] updateBranchViewCount:self.branchViewID];
}

@end

