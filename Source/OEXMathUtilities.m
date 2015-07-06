//
//  OEXMathUtilities.m
//  edX
//
//  Created by Akiva Leffert on 6/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXMathUtilities.h"

static const CGFloat OEXEpsilon = .00001;

BOOL OEXDoublesWithinEpsilon(double left, double right) {
    return fabs(left - right) < OEXEpsilon;
}