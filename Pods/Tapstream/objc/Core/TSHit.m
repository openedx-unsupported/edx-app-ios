#import "TSHit.h"
#import "TSLogging.h"

@implementation TSHit
@synthesize trackerName, encodedTrackerName, postData = tags;

+ (id)hitWithTrackerName:(NSString *)trackerName
{
	return AUTORELEASE([[TSHit alloc] initWithTrackerName:trackerName]);
}

- (id)initWithTrackerName:(NSString *)trackerNameVal
{
	if((self = [super init]) != nil)
	{
		trackerName = RETAIN(trackerNameVal);
		encodedTrackerName = RETAIN([self encodeString:trackerNameVal]);
		tags = nil;
	}
	return self;
}

- (void)dealloc
{
	RELEASE(trackerName);
	RELEASE(encodedTrackerName);
	RELEASE(tags);
	SUPER_DEALLOC;
}

- (NSString *)encodeString:(NSString *)s
{
	return AUTORELEASE((BRIDGE_TRANSFER NSString *)CFURLCreateStringByAddingPercentEscapes(
		NULL, (CFStringRef)s, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));
}

- (void)addTag:(NSString *)tag
{
	if(tag.length > 255)
	{
		[TSLogging logAtLevel:kTSLoggingWarn format:@"Tapstream Warning: Tag exceeds 255 characters, it will not be included in the post (tag=%@)", tag];
		return;
	}
	NSString *encodedTag = [self encodeString:tag];

	if(tags == nil)
	{
		tags = RETAIN([NSMutableString stringWithCapacity:64]);
		[tags appendString:@"__ts="];
	}
	else
	{
		[tags appendString:@","];
	}
	[tags appendString:encodedTag];
}

- (NSString *)postData
{
	return tags == nil ? @"" : (NSString *)tags;
}

@end
