#import "TSLogging.h"
#import "TSHelpers.h"

static void(^currentLogger)(int, NSString *) = nil;
static bool overridden = false;


@implementation TSLogging

+ (void)setLogger:(void(^)(int, NSString *))logger
{
	@synchronized(self)
	{
		overridden = true;
		currentLogger = logger;
	}
}

+ (void)logAtLevel:(TSLoggingLevel)level format:(NSString *)format, ...
{
	@synchronized(self)
	{
		if(currentLogger != nil || !overridden)
		{
			va_list ap;
			va_start(ap, format);

			NSString *message = AUTORELEASE([[NSString alloc] initWithFormat:format arguments:ap]);

			if(currentLogger != nil)
			{
				currentLogger(level, message);
			}
			else
			{
				NSLog(@"%@", message);
			}

			va_end(ap);
		}
	}
}

@end
