#import "TSResponse.h"
#import "TSHelpers.h"

@implementation TSResponse

@synthesize status = status;
@synthesize message = message;
@synthesize data = data;

- (id)initWithStatus:(int)statusVal message:(NSString *)messageVal data:(NSData *)dataVal
{
	if((self = [super init]) != nil)
	{
		status = statusVal;
		message = RETAIN(messageVal);
		data = RETAIN(dataVal);
	}
	return self;
}

- (void)dealloc
{
	RELEASE(message);
	RELEASE(data);
	SUPER_DEALLOC;
}

@end
