// Copyright 2013 Smartling, Inc.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this work except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
//  NSBundle+Smartling_i18n.m
//  Smartling.i18n
//
//  Created by Pavel Ivashkov on 2013-03-06.
//

#import <objc/runtime.h>
#import "SLLocalization.h"


@implementation NSBundle(Smartling_i18n)

- (NSString *)pluralizedStringWithKey:(NSString *)key defaultValue:(NSString *)defaultValue table:(NSString *)tableName pluralValue:(float)pluralValue
{
	for (NSString *locale in self.cachedLocales) {
		
		NSString *ls = [self _pluralizedStringWithKey:key table:tableName pluralValue:pluralValue forLocalization:locale];
		if (ls.length) {
			return ls;
		}
	}
	
	if (defaultValue.length) {
		return defaultValue;
	}
	
	return key;
}

- (NSString *)pluralizedStringWithKey:(NSString *)key
						 defaultValue:(NSString *)defaultValue
								table:(NSString *)tableName
						  pluralValue:(float)pluralValue
					  forLocalization:(NSString *)locale
{
	NSString *ls = [self _pluralizedStringWithKey:key table:tableName pluralValue:pluralValue forLocalization:locale];
	if (ls.length) {
		return ls;
	}
	
	if (defaultValue.length) {
		return defaultValue;
	}
	
	return key;
}

- (NSString *)_pluralizedStringWithKey:(NSString *)key
								 table:(NSString *)tableName
						   pluralValue:(float)pluralValue
					   forLocalization:(NSString *)locale

{
	if (tableName.length == 0) {
		tableName = @"Localizable";
	}
	
	// keyVariant: key##{form}
	
	NSString *lang = locale;
	NSRange range = [locale rangeOfString:@"-"];
	if (range.location != NSNotFound) {
		lang = [locale substringToIndex:range.location];
	}
	
	const char* form = pluralformf([lang cStringUsingEncoding:NSASCIIStringEncoding], pluralValue);
	char suffix[16] = "##{";
	strcat(suffix, form);
	strcat(suffix, "}");
	NSString *keyVariant = [key stringByAppendingString:[NSString stringWithUTF8String:suffix]];
	NSDictionary *dict = [self stringsWithContentsOfFile:tableName forLocalization:locale];
	NSString *ls = dict[keyVariant];
	
	if (!ls && self.shouldReportNonLocalizedStrings) {
		NSLog(@"Missing %@ localization for \"%@\"", locale.uppercaseString, keyVariant);
		return [keyVariant uppercaseString];
	}
	
	return ls;
}

- (NSDictionary *)stringsWithContentsOfFile:(NSString *)path forLocalization:(NSString *)lang
{
	NSMutableString *key = [NSMutableString stringWithCapacity:path.length + lang.length + 1];
	[key appendString:path];
	[key appendString:@"-"];
	[key appendString:lang];
	
	id dict = self.cachedTables[key];
	if (dict) {
		if (dict == NSNull.null) return nil;
		return dict;
	}
	
	NSString *tableName = path;
	if (tableName) {
		tableName = [self pathForResource:tableName ofType:@"strings" inDirectory:nil forLocalization:lang];
	}
	if (!tableName) {
		NSArray *paths = [self pathsForResourcesOfType:@"strings" inDirectory:nil forLocalization:lang];
		if (paths.count) tableName = paths[0];
	}
	
	if (tableName) {
		dict = [NSDictionary dictionaryWithContentsOfFile:tableName];
	}
	
	self.cachedTables[key] = dict ? : NSNull.null;
	
	return dict;
}

- (NSMutableDictionary *)cachedTables
{
	static const NSString *kSLBundleCachedTables = @"kSLBundleCachedTables";
	NSMutableDictionary *d = objc_getAssociatedObject(self, (__bridge const void *)(kSLBundleCachedTables));
	if (!d) {
		d = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, (__bridge const void *)(kSLBundleCachedTables), d, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return d;
}

- (NSArray *)cachedLocales
{
	static const NSString *kSLBundleCachedLocales = @"kSLBundleCachedLocales";
	NSMutableArray *locales = objc_getAssociatedObject(self, (__bridge const void *)(kSLBundleCachedLocales));
	if (!locales) {
		locales = [NSMutableArray arrayWithArray:self.preferredLocalizations];
		if (self.developmentLocalization && ![[locales lastObject] isEqualToString:self.developmentLocalization]) {
			[locales addObject:self.developmentLocalization];
		}
		objc_setAssociatedObject(self, (__bridge const void *)(kSLBundleCachedLocales), locales, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return locales;
}

- (BOOL)shouldReportNonLocalizedStrings
{
	static BOOL report = NO;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		report = [[NSUserDefaults standardUserDefaults] boolForKey:@"NSShowNonLocalizedStrings"];
	});
	return report;
}

@end

// Technical Q&A QA1490
// Building Objective-C static libraries with categories
// http://developer.apple.com/library/mac/#qa/qa1490/_index.html
#define LINK_CATEGORIES(UNIQUE_NAME) @interface FORCELOAD_##UNIQUE_NAME : NSObject @end @implementation FORCELOAD_##UNIQUE_NAME @end
LINK_CATEGORIES(NSBundle_Smartling_i18n)
