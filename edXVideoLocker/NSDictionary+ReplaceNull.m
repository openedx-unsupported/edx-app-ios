//
//  NSDictionary+ReplaceNull.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 04/07/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "NSDictionary+ReplaceNull.h"

@implementation NSDictionary (ReplaceNull)
- (NSDictionary *) dictionaryByReplacingNullsWithStrings{
    
    const NSMutableDictionary *replaced = [NSMutableDictionary dictionaryWithDictionary: self];
    const NSString *blank = @"";
    
    for (NSString *key in [self allKeys]) {
        const id object = [self objectForKey: key];
        if ([object isKindOfClass:[NSNull class]]) {
            [replaced setObject: blank forKey: key];
        }
        else if ([object isKindOfClass: [NSDictionary class]]) {
            
            [replaced setObject: [(NSDictionary *) object dictionaryByReplacingNullsWithStrings] forKey: key];
            
        }else if([object isKindOfClass:[NSArray class]]){
            
            const  NSMutableArray *array=[NSMutableArray arrayWithArray:object];
            
            for ( int i=0 ; i <[array count]  ; i++) {
                
                id instance=[array objectAtIndex:i];
                
                if([instance isKindOfClass:[NSDictionary class]]){
                    
                    id obj=  [(NSDictionary *)instance dictionaryByReplacingNullsWithStrings];
                    
                    [array replaceObjectAtIndex:i withObject:obj];
                    
                }
                
                
            }
            
            [replaced setObject:array forKey:key];
            
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:replaced];
}

@end
