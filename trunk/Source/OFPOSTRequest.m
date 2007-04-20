// OFPOSTRequest.m
// 
// Copyright (c) 2004-2006 Lukhnos D. Liu (lukhnos {at} gmail.com)
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Neither the name of ObjectiveFlickr nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

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
	if (!_stream) return;
	CFReadStreamUnscheduleFromRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
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
	
	if (_timeoutInterval > 0.0)
	{
		// NSLog(@"timeout timer created: %f", _timeoutInterval);
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
	// NSLog(@"timeout!");
	// we do what [self cancel] has done. the received timer is already invalidated
	CFReadStreamUnscheduleFromRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);	
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
	// NSLog(@"old %ld, new %ld", _bytesSent, _newBytesSent);

    if (_newBytesSent > _bytesSent)
    {
		if (_timeoutTimer)
		{
			// NSLog(@"reset timeout!");
			// we have indeed some progress, so we reset the timeout timer
			[_timeoutTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:_timeoutInterval]];
		}

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

