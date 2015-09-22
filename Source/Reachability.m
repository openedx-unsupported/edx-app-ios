/*
 Copyright (c) 2011, Tony Million.
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

#import "Reachability.h"

NSString* const kReachabilityChangedNotification = @"kReachabilityChangedNotification";

@interface InternetReachability ()

@property (nonatomic, strong) __attribute__((NSObject)) SCNetworkReachabilityRef reachabilityRef;

#if NEEDS_DISPATCH_RETAIN_RELEASE
@property (nonatomic, assign) dispatch_queue_t reachabilitySerialQueue;
#else
@property (nonatomic, strong) dispatch_queue_t reachabilitySerialQueue;
#endif

@property (nonatomic, assign) BOOL reachableOnWWAN;

@property (nonatomic, strong) id reachabilityObject;

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags;
- (BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags;

@end

static NSString* reachabilityFlags(SCNetworkReachabilityFlags flags){
    return [NSString stringWithFormat:@"%c%c %c%c%c%c%c%c%c",
#if     TARGET_OS_IPHONE
            (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W': '-',
#else
            'X',
#endif
            (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R': '-',
            (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c': '-',
            (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't': '-',
            (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i': '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C': '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D': '-',
            (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l': '-',
            (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd': '-'];
}

// Start listening for reachability notifications on the current run loop
static void TMReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info){
#pragma unused (target)
#if __has_feature(objc_arc)
    InternetReachability* reachability = ((__bridge InternetReachability*)info);
#else
    InternetReachability* reachability = ((Reachability*)info);
#endif

    // We probably don't need an autoreleasepool here, as GCD docs state each queue has its own autorelease pool,
    // but what the heck eh?
    @autoreleasepool
    {
        [reachability reachabilityChanged:flags];
    }
}

@implementation InternetReachability

@synthesize reachabilityRef;
@synthesize reachabilitySerialQueue;

@synthesize reachableOnWWAN;

@synthesize reachabilityObject;

#pragma mark - Class Constructor Methods


- (id)init {
    self = [super init];
    if(self != nil) {
        struct sockaddr_in zeroAddress;
        bzero(&zeroAddress, sizeof(zeroAddress));
        zeroAddress.sin_len = sizeof(zeroAddress);
        zeroAddress.sin_family = AF_INET;
        
        SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
        
        self.reachableOnWWAN = YES;
        self.reachabilityRef = ref;
        CFRelease(ref);
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    return self;
#pragma clang diagnostic pop
}

- (void)dealloc {
    [self stopNotifier];

    if(self.reachabilityRef) {
//        CFRelease(self.reachabilityRef);
        self.reachabilityRef = nil;
    }

#if !(__has_feature(objc_arc))
    [super dealloc];
#endif
}

#pragma mark - Notifier Methods

// Notifier
// NOTE: This uses GCD to trigger the blocks - they *WILL NOT* be called on THE MAIN THREAD
// - In other words DO NOT DO ANY UI UPDATES IN THE BLOCKS.
//   INSTEAD USE dispatch_async(dispatch_get_main_queue(), ^{UISTUFF}) (or dispatch_sync if you want)

- (BOOL)startNotifier {
    SCNetworkReachabilityContext context = { 0, NULL, NULL, NULL, NULL };

    // this should do a retain on ourself, so as long as we're in notifier mode we shouldn't disappear out from under ourselves
    // woah
    self.reachabilityObject = self;

    // First, we need to create a serial queue.
    // We allocate this once for the lifetime of the notifier.
    self.reachabilitySerialQueue = dispatch_queue_create("com.tonymillion.reachability", NULL);
    if(!self.reachabilitySerialQueue) {
        return NO;
    }

#if __has_feature(objc_arc)
    context.info = (__bridge void*)self;
#else
    context.info = (void*)self;
#endif

    if(!SCNetworkReachabilitySetCallback(self.reachabilityRef, TMReachabilityCallback, &context)) {
#ifdef DEBUG
        //NSLog(@"SCNetworkReachabilitySetCallback() failed: %s", SCErrorString(SCError()));
#endif

        // Clear out the dispatch queue
        if(self.reachabilitySerialQueue) {
#if NEEDS_DISPATCH_RETAIN_RELEASE
            dispatch_release(self.reachabilitySerialQueue);
#endif
            self.reachabilitySerialQueue = nil;
        }

        self.reachabilityObject = nil;

        return NO;
    }

    // Set it as our reachability queue, which will retain the queue
    if(!SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilitySerialQueue)) {
#ifdef DEBUG
        //NSLog(@"SCNetworkReachabilitySetDispatchQueue() failed: %s", SCErrorString(SCError()));
#endif

        // UH OH - FAILURE!

        // First stop, any callbacks!
        SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);

        // Then clear out the dispatch queue.
        if(self.reachabilitySerialQueue) {
#if NEEDS_DISPATCH_RETAIN_RELEASE
            dispatch_release(self.reachabilitySerialQueue);
#endif
            self.reachabilitySerialQueue = nil;
        }

        self.reachabilityObject = nil;

        return NO;
    }

    return YES;
}

- (void)stopNotifier {
    // First stop, any callbacks!
    SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);

    // Unregister target from the GCD serial dispatch queue.
    SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, NULL);

    if(self.reachabilitySerialQueue) {
#if NEEDS_DISPATCH_RETAIN_RELEASE
        dispatch_release(self.reachabilitySerialQueue);
#endif
        self.reachabilitySerialQueue = nil;
    }

    self.reachabilityObject = nil;
}

#pragma mark - reachability tests

// This is for the case where you flick the airplane mode;
// you end up getting something like this:
//Reachability: WR ct-----
//Reachability: -- -------
//Reachability: WR ct-----
//Reachability: -- -------
// We treat this as 4 UNREACHABLE triggers - really apple should do better than this

#define testcase (kSCNetworkReachabilityFlagsConnectionRequired | kSCNetworkReachabilityFlagsTransientConnection)

- (BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags {
    BOOL connectionUP = YES;

    if(!(flags & kSCNetworkReachabilityFlagsReachable)) {
        connectionUP = NO;
    }

    if( (flags & testcase) == testcase) {
        connectionUP = NO;
    }

#if     TARGET_OS_IPHONE
    if(flags & kSCNetworkReachabilityFlagsIsWWAN) {
        // We're on 3G.
        if(!self.reachableOnWWAN) {
            // We don't want to connect when on 3G.
            connectionUP = NO;
        }
    }
#endif

    return connectionUP;
}

- (BOOL)isReachable {
    SCNetworkReachabilityFlags flags;

    if(!SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
        return NO;
    }

    return [self isReachableWithFlags:flags];
}

- (BOOL)isReachableViaWWAN {
#if     TARGET_OS_IPHONE

    SCNetworkReachabilityFlags flags = 0;

    if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        // Check we're REACHABLE
        if(flags & kSCNetworkReachabilityFlagsReachable) {
            // Now, check we're on WWAN
            if(flags & kSCNetworkReachabilityFlagsIsWWAN) {
                return YES;
            }
        }
    }
#endif

    return NO;
}

- (BOOL)isReachableViaWiFi {
    SCNetworkReachabilityFlags flags = 0;

    if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        // Check we're reachable
        if((flags & kSCNetworkReachabilityFlagsReachable)) {
#if     TARGET_OS_IPHONE
            // Check we're NOT on WWAN
            if((flags & kSCNetworkReachabilityFlagsIsWWAN)) {
                return NO;
            }
#endif
            return YES;
        }
    }

    return NO;
}

// WWAN may be available, but not active until a connection has been established.
// WiFi may require a connection for VPN on Demand.
- (BOOL)isConnectionRequired {
    return [self connectionRequired];
}

- (BOOL)connectionRequired {
    SCNetworkReachabilityFlags flags;

    if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
    }

    return NO;
}

// Dynamic, on demand connection?
- (BOOL)isConnectionOnDemand {
    SCNetworkReachabilityFlags flags;

    if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
                (flags & (kSCNetworkReachabilityFlagsConnectionOnTraffic | kSCNetworkReachabilityFlagsConnectionOnDemand)));
    }

    return NO;
}

// Is user intervention required?
- (BOOL)isInterventionRequired {
    SCNetworkReachabilityFlags flags;

    if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
                (flags & kSCNetworkReachabilityFlagsInterventionRequired));
    }

    return NO;
}

#pragma mark - reachability status stuff

- (ReachabilityStatus)currentReachabilityStatus {
    if([self isReachable]) {
        if([self isReachableViaWiFi]) {
            return ReachabilityStatusViaWiFi;
        }

#if     TARGET_OS_IPHONE
        return ReachabilityStatusViaWWAN;
#endif
    }

    return ReachabilityStatusNotReachable;
}

- (SCNetworkReachabilityFlags)reachabilityFlags {
    SCNetworkReachabilityFlags flags = 0;

    if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        return flags;
    }

    return 0;
}

- (NSString*)currentReachabilityString {
    ReachabilityStatus temp = [self currentReachabilityStatus];

    if(temp == reachableOnWWAN) {
        // Updated for the fact that we have CDMA phones now!
        return OEXLocalizedString(@"Cellular", @"");
    }
    if(temp == ReachabilityStatusViaWiFi) {
        return OEXLocalizedString(@"WiFi", @"");
    }

    return OEXLocalizedString(@"No Connection", @"");
}

- (NSString*)currentReachabilityFlags {
    return reachabilityFlags([self reachabilityFlags]);
}

#pragma mark - Callback function calls this method

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // this makes sure the change notification happens on the MAIN THREAD
        [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification
                                                            object:self];
    });
}

#pragma mark - Debug Description

- (NSString*)description {
    NSString* description = [NSString stringWithFormat:@"<%@: %#x>",
                             NSStringFromClass([self class]), (unsigned int) self];
    return description;
}

@end
