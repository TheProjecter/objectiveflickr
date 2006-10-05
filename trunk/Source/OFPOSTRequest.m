#import "OFPOSTRequest.h"

@interface OFPOSTRequest(OFPOSTRequestInternals)
- (void)dealloc;
- (void)reset;
- (void)handleResponse;
- (void)handleError;
- (void)handleProgressTicker:(NSTimer*)timer;
- (void)handleTimeout:(NSTimer*)timer;
- (void)handleComplete;
@end

static void OFFUReadStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType type, void *callbackInfo);

@implementation OFPOSTRequest
+ (id)requestWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)timeoutInterval
{
	return [[[OFPOSTRequest alloc] initWithDelegate:aDelegate timeoutInterval:timeoutInterval] autorelease];
}
- (id)initWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)timeoutInterval
{
	if ((self = [super init])) {
		_delegate = [aDelegate retain];
		_timeoutInterval = timeoutInterval;
		_userInfo = nil;
		_dataSize = 0;
		_bytesSent = 0;
		_stream = NULL;
		_response = nil;
		_progressTicker = nil;
		_timeoutTimer = nil;
	}
	return self;
}
- (void)cancel 
{
	CFReadStreamClose(_stream);
	_stream = NULL;
	
	[_progressTicker invalidate];
	if (_timeoutTimer) {
        if ([_timeoutTimer isValid]) [_timeoutTimer invalidate];
    }

	if ([_delegate respondsToSelector:@selector(POSTRequest:didCancel:)])
	{
		[_delegate POSTRequest:self didCancel:_userInfo];
	}
}
- (BOOL)isClosed
{
	return _stream ? NO : YES;
}
- (BOOL)POSTRequest:(NSURL*)url data:(NSData*)data separator:(NSString*)separator userInfo:(id)userinfo
{
	// if the stream is still open, we fail
	if (_stream) return NO;
	
	[self reset];
	_userInfo = [userinfo retain];

	// create the HTTP POST body
	CFHTTPMessageRef httpreq;
	httpreq = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("POST"), (CFURLRef)url, kCFHTTPVersion1_1);

	NSString *headerfield=[NSString stringWithFormat:@"multipart/form-data; boundary=%@", separator];
	CFHTTPMessageSetHeaderFieldValue(httpreq, CFSTR("Content-Type"), (CFStringRef)headerfield);

	_dataSize = [data length];
		
	CFHTTPMessageSetBody(httpreq, (CFDataRef)data); 

	_stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, httpreq);
	CFRelease(httpreq);

	CFStreamClientContext streamcontext = {0, self, NULL, NULL, NULL};
	CFOptionFlags eventflags = kCFStreamEventOpenCompleted | 
	   kCFStreamEventHasBytesAvailable | 
	   kCFStreamEventEndEncountered | 
	   kCFStreamEventErrorOccurred;
	
	// open the stream with callback function
	if (!CFReadStreamSetClient(_stream, eventflags, OFFUReadStreamClientCallBack, &streamcontext))
	{
		[self reset];
		return NO;
	}

	CFReadStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	_response = [[NSMutableData data] retain];

	if (!CFReadStreamOpen(_stream)) 
	{
		[self reset];
		return NO;
	}

	_progressTicker = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(handleProgressTicker:) userInfo:nil repeats:YES];
	[_progressTicker retain];
	
	if (_timeoutInterval)
	{
	   _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:_timeoutInterval target:self selector:@selector(handleTimeout:) userInfo:nil repeats:NO];
	   [_timeoutTimer retain];
	}
	
	return YES;
}
@end

static void OFFUReadStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType type, void *callbackInfo)
{
	switch (type)
	{
	 case kCFStreamEventHasBytesAvailable:
		  [(OFPOSTRequest*)callbackInfo handleResponse];
		  break;			
	 case kCFStreamEventEndEncountered:
		  [(OFPOSTRequest*)callbackInfo handleComplete];
		  break;
	 case kCFStreamEventErrorOccurred:
		  [(OFPOSTRequest*)callbackInfo handleError];
		  break;
	 }
}


@implementation OFPOSTRequest(OFPOSTRequestInternals)
- (void)dealloc
{
	if (_delegate) [_delegate release];
	if (_userInfo) [_userInfo release];
	if (_response) [_response release];
	if (_stream) CFRelease(_stream);
	if (_progressTicker) [_progressTicker release];
	if (_timeoutTimer) [_timeoutTimer release];
	[super dealloc];
}
- (void)reset
{
    if (_timeoutTimer) {
		if ([_timeoutTimer isValid]) {
			[_timeoutTimer invalidate];
		}
		[_timeoutTimer release];
		_timeoutTimer = nil;
    }

	if (_progressTicker) {
		if ([_progressTicker isValid]) {
			[_progressTicker invalidate];
		}
		[_progressTicker release];
		_progressTicker = nil;
	}
	if (_userInfo) {
		[_userInfo release];
		_userInfo = nil;
	}
	if (_response) {
		[_response release];
		_response = nil;
	}
	if (_stream) {
		CFRelease(_stream);
		_stream = NULL;
	}

	_dataSize = 0;
	_bytesSent = 0;
	_timeoutInterval = 0;
}
- (void)handleResponse
{
	UInt8 buffer[2048];
	CFIndex bytesread = CFReadStreamRead(_stream, buffer, sizeof(buffer));

	if (bytesread > 0) [_response appendBytes:(void*)buffer length:(unsigned)bytesread];
}
- (void)handleError
{
	if ([_delegate respondsToSelector:@selector(POSTRequest:error:userInfo:)]) {
		CFStreamError errinfo = CFReadStreamGetError (_stream);
		[_delegate POSTRequest:self error:errinfo userInfo:_userInfo];
	}
}
- (void)handleTimeout:(NSTimer*)timer
{
	// we do what [self cancel] has done. the received timer is already invalidated
 	CFReadStreamClose(_stream);
	_stream = NULL;

	if ([_delegate respondsToSelector:@selector(POSTRequest:didTimeout:)])
	{
		[_delegate POSTRequest:self didTimeout:_userInfo];
	}   
}
- (void)handleProgressTicker:(NSTimer*)timer
{
	if (!_stream) return;
	CFNumberRef bytesWrittenProperty = (CFNumberRef)CFReadStreamCopyProperty(_stream, kCFStreamPropertyHTTPRequestBytesWrittenCount); 
	int bytesWritten;
	CFNumberGetValue (bytesWrittenProperty, kCFNumberSInt32Type, &bytesWritten);

    size_t _newBytesSent = (size_t)bytesWritten;

    if (_timeoutTimer && _newBytesSent > _bytesSent)
    {
        // we have indeed some progress, so we reset the timeout timer
        [_timeoutTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:_timeoutInterval]];
		_bytesSent = _newBytesSent;

		if ([_delegate respondsToSelector:@selector(POSTRequest:progress:total:userInfo:)]) {
			[_delegate POSTRequest:self progress:_bytesSent total:_dataSize userInfo:_userInfo];
		}
	}
}
- (void)handleComplete
{
    // We don't need to close and release the stream--it's already closed *and* released
	_stream = NULL;
	[_progressTicker invalidate];
	if (_timeoutTimer) [_timeoutTimer invalidate];

	if ([_delegate respondsToSelector:@selector(POSTRequest:didComplete:userInfo:)]) {
		[_delegate POSTRequest:self didComplete:_response userInfo:_userInfo];
	}
}
@end


/* 

- (BOOL)upload:(NSData*)data filename:(NSString*)filename photoInformation:(NSDictionary*)photoinfo applicationContext:(OFFlickrApplicationContext*)context userInfo:(id)userinfo
{
	// if the stream is still open, we fail
	if (_stream) return NO;

	_userInfo = [userinfo retain];

	NSURL *uploadurl = [NSURL URLWithString:[context uploadURL]];

	// create the HTTP POST body
	CFHTTPMessageRef httpreq;
	httpreq = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("POST"), (CFURLRef)uploadurl, kCFHTTPVersion1_1);

	NSString *headerfield=[NSString stringWithFormat:@"multipart/form-data; boundary=%@", OFSharedSeparator];
	CFHTTPMessageSetHeaderFieldValue(httpreq, CFSTR("Content-Type"), (CFStringRef)headerfield);

	NSData *uploaddata = [context prepareUploadData:data filename:filename information:photoinfo];
	_dataSize = [uploaddata length];
		
	CFHTTPMessageSetBody(httpreq, (CFDataRef)uploaddata); 

	_stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, httpreq);
	CFRelease(httpreq);

	CFStreamClientContext streamcontext = {0, self, NULL, NULL, NULL};
	CFOptionFlags eventflags = kCFStreamEventOpenCompleted | kCFStreamEventHasBytesAvailable |
		kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred;
	
	// open the stream with callback function
	if (!CFReadStreamSetClient(_stream, eventflags, OFFUReadStreamClientCallBack, &streamcontext))
	{
		[self reset];
		return NO;
	}

	CFReadStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	_response = [[NSMutableData data] retain];

	if (!CFReadStreamOpen(_stream)) 
	{
		[self reset];
		return NO;
	}

	_progressTicker = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
	[_progressTicker retain];
	return YES;
}
- (BOOL)uploadWithContentsOfFile:(NSString*)filename photoInformation:(NSDictionary*)photoinfo applicationContext:(OFFlickrApplicationContext*)context userInfo:(id)userinfo
{
	return [self upload:[NSData dataWithContentsOfFile:filename] filename:filename photoInformation:photoinfo applicationContext:context userInfo:userinfo];
}


*/
