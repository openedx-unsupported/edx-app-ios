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
//  floatvalue.m
//  Smartling.i18n
//
//  Created by Pavel Ivashkov on 2013-03-06.
//
float floatvalue(const void* value, const char* valueType);

float floatvalue(const void* value, const char* valueType)
{
	if (value == NULL || valueType == NULL) {
		return 0;
	}

	float fval = 0;

	char typecode = valueType[0];
	switch (typecode) {
		case '@':
		{
			__unsafe_unretained id obj = *(__unsafe_unretained id*)value;
			if ([obj respondsToSelector:@selector(floatValue)]) {
				fval = [obj floatValue];
			}
			else {
				NSLog(@"Cannot get number value from object of type %@", NSStringFromClass([obj class]));
			}
		}
			break;
			
		case 'c': fval = *(char *)value; break;
		case 'i': fval = *(int *)value; break;
		case 's': fval = *(short *)value; break;
		case 'l': fval = *(long *)value; break;
		case 'q': fval = *(long long *)value; break;
		case 'C': fval = *(u_char *)value; break;
		case 'I': fval = *(u_int *)value; break;
		case 'S': fval = *(u_short *)value; break;
		case 'L': fval = *(u_long *)value; break;
		case 'Q': fval = *(unsigned long long *)value; break;
		case 'f': fval = *(float *)value; break;
		case 'd': fval = *(double *)value; break;
		case 'B': fval = *(_Bool *)value; break;
			
		default:
			NSLog(@"Cannot convert value of type \"%s\" to number", valueType);
			break;
	}
	
	return fval;
}
