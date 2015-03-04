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
//  SLLocalization.h
//  Smartling.i18n
//
//  Created by Pavel Ivashkov on 2013-03-15.
//

// The following macros return localized string of the key, according to plural rule of the value n:
//   SLPluralizedString(key, n, comment)
//   SLPluralizedStringFromTable(key, tbl, n, comment)
//   SLPluralizedStringFromTableInBundle(key, tbl, bundle, n, comment)
//   SLPluralizedStringWithDefaultValue(key, tbl, bundle, n, val, comment)


@interface NSBundle (Smartling_i18n)

- (NSString *)pluralizedStringWithKey:(NSString *)key
						 defaultValue:(NSString *)defaultValue
								table:(NSString *)tableName
						  pluralValue:(float)pluralValue NS_FORMAT_ARGUMENT(1);

- (NSString *)pluralizedStringWithKey:(NSString *)key
						 defaultValue:(NSString *)defaultValue
								table:(NSString *)tableName
						  pluralValue:(float)pluralValue
					  forLocalization:(NSString *)locale NS_FORMAT_ARGUMENT(1);

@end


#define SL_FLOATVALUE(n) ({ \
	__typeof__(n) _n = (n); \
	floatvalue(&_n, @encode(__typeof__(n))); })

#define SLPluralizedString(key, n, comment) ({ \
	[[NSBundle mainBundle] pluralizedStringWithKey:key defaultValue:@"" table:nil pluralValue:SL_FLOATVALUE(n)]; })
#define SLPluralizedStringFromTable(key, tbl, n, comment) ({ \
	[[NSBundle mainBundle] pluralizedStringWithKey:key defaultValue:@"" table:(tbl) pluralValue:SL_FLOATVALUE(n)]; })
#define SLPluralizedStringFromTableInBundle(key, tbl, bundle, n, comment) ({ \
	[bundle pluralizedStringWithKey:key defaultValue:@"" table:(tbl) pluralValue:SL_FLOATVALUE(n)]; })
#define SLPluralizedStringWithDefaultValue(key, tbl, bundle, n, val, comment) ({ \
	[bundle pluralizedStringWithKey:key defaultValue:(val) table:(tbl) pluralValue:SL_FLOATVALUE(n)]; })

// Returns one of: zero, one, two, few, many, other
FOUNDATION_EXPORT const char* pluralform(const char* lang, int n);
FOUNDATION_EXPORT const char* pluralformf(const char* lang, float n);
FOUNDATION_EXPORT float floatvalue(const void* value, const char* valueType);
