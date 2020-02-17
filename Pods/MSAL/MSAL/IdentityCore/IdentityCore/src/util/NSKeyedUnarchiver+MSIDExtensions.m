// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSKeyedUnarchiver+MSIDExtensions.h"

@implementation NSKeyedUnarchiver (MSIDExtensions)

+ (instancetype)msidCreateForReadingFromData:(NSData *)data error:(NSError **)error
{
    NSKeyedUnarchiver *unarchiver;
    if (@available(iOS 11.0, macOS 10.13, *))
    {
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:error];
    }
#if !TARGET_OS_MACCATALYST
    else
    {
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    }
#endif
    
    return unarchiver;
}

+ (id)msidUnarchivedObjectOfClasses:(NSSet<Class> *)classes fromData:(NSData *)data error:(NSError **)error
{
    id result;
    if (@available(iOS 11.0, macOS 10.13, *))
    {
        result = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:error];
    }
#if !TARGET_OS_MACCATALYST
    else
    {
        result = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
#endif

    return result;
}

@end
