//
//  NSDictionary+OEXReplaceNull.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 04/07/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "NSDictionary+OEXReplaceNull.h"

@implementation NSDictionary (OEXReplaceNull)
- (NSDictionary *) oex_dictionaryByReplacingNullsWithStrings{
    
    const NSMutableDictionary *replaced = [NSMutableDictionary dictionaryWithDictionary: self];
    const NSString *blank = @"";
    
    for (NSString *key in [self allKeys]) {
        const id object = [self objectForKey: key];
        if ([object isKindOfClass:[NSNull class]]) {
            [replaced setObject: blank forKey: key];
        }
        else if ([object isKindOfClass: [NSDictionary class]]) {
            
            [replaced setObject: [object oex_dictionaryByReplacingNullsWithStrings] forKey: key];
            
        }else if([object isKindOfClass:[NSArray class]]){
            
            const  NSMutableArray *array=[NSMutableArray arrayWithArray:object];
            
            for ( int i=0 ; i <[array count]  ; i++) {
                
                id instance=[array objectAtIndex:i];
                
                if([instance isKindOfClass:[NSDictionary class]]){
                    
                    id obj=  [instance oex_dictionaryByReplacingNullsWithStrings];
                    
                    [array replaceObjectAtIndex:i withObject:obj];
                    
                }
                
                
            }
            
            [replaced setObject:array forKey:key];
            
        }
    }
    
    return replaced;
}

@end
