// ObjectiveFlickr
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

#import "CocoaCryptoHashing.h"
#import "ObjectiveFlickr.h"

#define OFRESTAPIEndPointKey			@"api_endpoint"
#define OFAuthenticationEndPointKey		@"auth_endpoint"
#define OFPhotoURLPrefixKey				@"photo_url_prefix"
#define OFUploadEndPointKey				@"upload_endpoint"
#define OFUploadCallBackEndPointKey		@"upload_callback_endpoint"

#define OFDefaultRESTAPIEndPoint			@"http://api.flickr.com/services/rest/"				/* key "api_endpoint" */
#define OFDefaultAuthenticationEndPoint		@"http://flickr.com/services/auth/"					/* key "auth_endpoint" */
#define OFDefaultPhotoURLPrefix				@"http://static.flickr.com/"						/* key "photo_url_prefix" */
#define OFDefaultUploadEndPoint				@"http://api.flickr.com/services/upload/"			/* key "upload_endpoint" */
#define OFDefaultUploadCallBackEndPoint		@"http://www.flickr.com/tools/uploader_edit.gne"	/* key "upload_callback_endpoint" */

#define OFSharedSeparator	@"---------------------------7d44e178b0434"

@implementation OFFlickrApplicationContext
+ (OFFlickrApplicationContext*)contextWithAPIKey:(NSString*)key sharedSecret:(NSString*)secret
{
	return [[[OFFlickrApplicationContext alloc] initWithAPIKey:key sharedSecret:secret] autorelease];
}
- (OFFlickrApplicationContext*)initWithAPIKey:(NSString*)key sharedSecret:(NSString*)secret
{
	if ((self = [super init])) {
		_APIKey = [[NSString alloc] initWithString:key];
		_sharedSecret = [[NSString alloc] initWithString:secret];
		_authToken = [[NSString alloc] init];
	
		// populate the default end points
		NSMutableDictionary *ma = [[NSMutableDictionary alloc] init];
		[ma setObject:OFDefaultRESTAPIEndPoint forKey:OFRESTAPIEndPointKey];
		[ma setObject:OFDefaultAuthenticationEndPoint forKey:OFAuthenticationEndPointKey];
		[ma setObject:OFDefaultPhotoURLPrefix forKey:OFPhotoURLPrefixKey];
		[ma setObject:OFDefaultUploadEndPoint forKey:OFUploadEndPointKey];
		[ma setObject:OFDefaultUploadCallBackEndPoint forKey:OFUploadCallBackEndPointKey];
		_endPoints = ma;
	}
	return self;
}
- (void)dealloc {
	if (_APIKey) [_APIKey release];
	if (_sharedSecret) [_sharedSecret release];
	if (_authToken) [_authToken release];
	if (_endPoints) [_endPoints release];
	[super dealloc];
}
- (NSString*)description {
	return [NSString stringWithFormat:@"api_key=\"%@\", shared_secret=\"%@\", auth_token=\"%@\", end_points=%@",
		_APIKey, _sharedSecret, _authToken, _endPoints];
}
- (void)setAuthToken:(NSString*)token {
	if (_authToken) [_authToken release];
	_authToken = [[NSString alloc] initWithString:token];
}
- (NSString*)authToken {
	return [NSString stringWithString:_authToken];
}
- (void)setEndPoints:(NSDictionary*)newEndPoints {
	if (_endPoints) [_endPoints release];
	_endPoints = [[NSDictionary dictionaryWithDictionary:newEndPoints] autorelease];
}
- (NSDictionary*)endPoints {
	return [NSDictionary dictionaryWithDictionary:_endPoints];
}
- (NSString*)RESTAPIEndPoint {
	return [NSString stringWithString:[_endPoints objectForKey:OFRESTAPIEndPointKey]];
}
- (NSString*)signatureForCall:(NSDictionary*)parameters {
	NSMutableString *sigstr=[NSMutableString stringWithString:_sharedSecret];
	NSArray *sortedkeys=[[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	unsigned i, c=[sortedkeys count];
	for (i=0; i<c; i++) {
		NSString *k=[sortedkeys objectAtIndex:i];
		NSString *v=[parameters objectForKey:k];
		[sigstr appendString:k];
		[sigstr appendString:v];
	}
	
	NSLog(@"signature string %@, md5=%@", sigstr, [sigstr md5HexHash]);
	return [sigstr md5HexHash];
}
- (NSString*)prepareRESTGETURL:(NSDictionary*)parameters authentication:(BOOL)auth sign:(BOOL)sign
{
	NSMutableString *urlstr=[NSMutableString stringWithFormat:@"%@?", [_endPoints objectForKey:OFRESTAPIEndPointKey]];
	NSMutableDictionary *newparam=[NSMutableDictionary dictionaryWithDictionary:parameters];

	[newparam setObject:_APIKey forKey:@"api_key"];
	if (auth) [newparam setObject:_authToken forKey:@"auth_token"];

	NSArray *keys=[newparam allKeys];
	unsigned i, c=[keys count];
 	
	for (i=0; i<c; i++) {
		NSString *k=[keys objectAtIndex:i];
		NSString *v=[newparam objectForKey:k];
		[urlstr appendString:[NSString stringWithFormat:((i == c-1) ? @"%@=%@" : @"%@=%@&"), k, v]];
	}

	if (sign) {
		NSString *apisig=[self signatureForCall:newparam];
		[urlstr appendString:[NSString stringWithFormat:@"&api_sig=%@", apisig]];
	}
	
	return urlstr;
}
- (NSString*)prepareLoginURL:(NSString*)frob permission:(NSString*)perm
{
	NSDictionary *authdict=[NSDictionary dictionaryWithObjectsAndKeys:
		_APIKey, @"api_key",
		perm, @"perms",
		frob, @"frob", nil];
		
	return [NSString stringWithFormat:@"%@?api_key=%@&perms=%@&frob=%@&api_sig=%@",
		[_endPoints objectForKey:OFAuthenticationEndPointKey], _APIKey, perm, frob, [self signatureForCall:authdict]];
}
- (NSMutableData*)internalPreparePOSTData:(NSDictionary*)parameters authentication:(BOOL)auth sign:(BOOL)sign endMark:(BOOL)endmark
{
	NSMutableData *data=[NSMutableData data];
	NSMutableDictionary *newparam=[NSMutableDictionary dictionaryWithDictionary:parameters];

	[newparam setObject:_APIKey forKey:@"api_key"];
	if (auth) [newparam setObject:_authToken forKey:@"auth_token"];

	if (sign) {
		NSString *apisig=[self signatureForCall:newparam];
		[newparam setObject:apisig forKey:@"api_sig"];
	}

	NSArray *keys=[newparam allKeys];
	unsigned i, c=[keys count];
 	
	for (i=0; i<c; i++) {
		NSString *k=[keys objectAtIndex:i];
		NSString *v=[newparam objectForKey:k];
		
		NSString *addstr = [NSString stringWithFormat:
			@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n",
			OFSharedSeparator, k, v];

		[data appendData:[addstr dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	if (endmark) {
		NSString *ending = [NSString stringWithFormat: @"--%@--", OFSharedSeparator];
		[data appendData:[ending dataUsingEncoding:NSUTF8StringEncoding]];	
	}
	
	return data;
}
- (NSData*)prepareRESTPOSTData:(NSDictionary*)parameters authentication:(BOOL)auth sign:(BOOL)sign
{
	return [self internalPreparePOSTData:parameters authentication:auth sign:sign endMark:YES];
}
- (NSData*)prepareUploadData:(NSData*)data filename:(NSString*)filename information:(NSDictionary*)info
{
	NSMutableData *cooked=[self internalPreparePOSTData:(info ? info : [NSDictionary dictionary]) authentication:YES sign:YES endMark:NO];

	NSString *lastpart = [filename lastPathComponent];
	NSString *extension = [filename pathExtension];
	NSString *content_type = @"image/jpeg";
	
	if ([extension isEqualToString:@"png"]) {
		content_type = @"image/png";
	}
	else if ([extension isEqualToString:@"gif"]) {
		content_type = @"image/gif";
	}
	
	NSString *filename_str = [NSString stringWithFormat:
		@"--%@\r\nContent-Disposition: form-data; name=\"photo\"; filename=\"%@\"\r\nContent-Type: %@\r\n\r\n",
		OFSharedSeparator, lastpart, content_type];

	[cooked appendData:[filename_str dataUsingEncoding:NSUTF8StringEncoding]];
	[cooked appendData:data];	
	NSString *endmark = [NSString stringWithFormat: @"\r\n--%@--", OFSharedSeparator];
	[cooked appendData:[endmark dataUsingEncoding:NSUTF8StringEncoding]];
	return cooked;
}
- (NSString*)uploadURL
{
	return [NSString stringWithString:[_endPoints objectForKey:OFUploadEndPointKey]];
}
- (NSString*)uploadCallBackURLWithPhotos:(NSArray*)photo_ids
{
	NSMutableString *urlstr=[NSMutableString stringWithFormat:@"%@?ids=", [_endPoints objectForKey:OFUploadCallBackEndPointKey]];
	unsigned i, c=[photo_ids count];
	
	for (i=0; i<c; i++) {
		NSString *pid=[photo_ids objectAtIndex:i];
		[urlstr appendString:[NSString stringWithFormat:((i == c-1) ? @"%@" : @"%@,"), pid]];
	}
	
	NSLog(@"finished preparing uploadCallBackURL: %@", urlstr);
	return urlstr;
}
- (NSString*)uploadCallBackURLWithPhotoID:(NSString*)photo_id
{
	return [self uploadCallBackURLWithPhotos:[NSArray arrayWithObject:photo_id]];
}
- (NSString*)photoURLFromID:(NSString*)photo_id serverID:(NSString*)server_id secret:(NSString*)secret size:(NSString*)size type:(NSString*)type
{
	NSMutableString *r=[NSMutableString stringWithFormat:@"%@%@/%@_%@", [_endPoints objectForKey:OFPhotoURLPrefixKey], server_id, photo_id, secret];
	
	if (size) {
		if ([size length]) {
			[r appendString:@"_"];
			[r appendString:size];
		}
	}
	
 	[r appendString:[NSString stringWithFormat:@".%@", (type ? ([type length] ? type : @"jpg") : @"jpg")]];
	return r;
}
@end


@implementation OFFlickrRESTRequest
+ (OFFlickrRESTRequest*)requestWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval
{
	return [[[OFFlickrRESTRequest alloc] initWithDelegate:aDelegate timeoutInterval:interval] autorelease];
}
- (OFFlickrRESTRequest*)initWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval
{
	if ((self = [super init])) {
		_delegate = [aDelegate retain];
		_timeoutInterval = (interval > 0) ? interval : OFRequestDefaultTimeoutInterval;
		
		_closed = YES;
		_connection = nil;
		_timer = nil;
		_userInfo = nil;
		_expectedLength = 0;
		_receivedData = nil;
	}
	return self;
}
- (void)dealloc {
	if (_delegate) [_delegate release];
	if (_connection) [_connection release];
	if (_timer) [_timer release];
	if (_userInfo) [_userInfo release];
	if (_receivedData) [_receivedData release];
	[super dealloc];
}
- (BOOL)isClosed {
	return _closed;
}
- (void)reset {
	if (!_closed) [self cancel];
	
	_closed = YES;
	_expectedLength = 0;

	if (_connection) {
		[_connection release];
		_connection = nil;
	}
	if (_timer) {
		if ([_timer isValid]) {
			[_timer invalidate];
		}
		[_timer release];
		_timer = nil;
	}
	if (_userInfo) {
		[_userInfo release];
		_userInfo = nil;
	}
	if (_receivedData) {
		[_receivedData release];
		_receivedData = nil;
	}
}
- (void)cancel {
	if (!_closed) return;
	[_connection cancel];
	[_timer invalidate];
	_closed = YES;
	
	if ([_delegate respondsToSelector:@selector(flickrRESTRequest:didCancel:)]) {
		[_delegate flickrRESTRequest:self didCancel:_userInfo];
	}
}
- (BOOL)GETRequest:(NSString*)url userInfo:(id)info {
	if (!_closed) return NO;

	[self reset];
	_userInfo = [info retain];
	_receivedData = [[NSMutableData data] retain];

	NSURLRequest *req=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:_timeoutInterval];
	_connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	if (!_connection) {
		[self reset];
		return NO;
	}
	
	_timer = [NSTimer scheduledTimerWithTimeInterval:_timeoutInterval target:self selector:@selector(handleTimeout:) userInfo:nil repeats:NO];
	[_timer retain];

	return YES;

}
- (BOOL)POSTRequest:(NSString*)url data:(NSData*)data userInfo:(id)info
{
	if (!_closed) return NO;

	[self reset];
	_userInfo = [info retain];
	_receivedData = [[NSMutableData data] retain];

	NSMutableURLRequest *req=[[[NSMutableURLRequest alloc] init] autorelease];
	[req setURL:[NSURL URLWithString:url]];
	[req setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[req setTimeoutInterval:_timeoutInterval];
	[req setHTTPMethod:@"POST"];
	
	NSString *header=[NSString stringWithFormat:@"multipart/form-data; boundary=%@", OFSharedSeparator];
	[req setValue:header forHTTPHeaderField:@"Content-Type"];
	[req setHTTPBody:data];
	
	_connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	if (!_connection) {
		[self reset];
		return NO;
	}
	
	_timer = [NSTimer scheduledTimerWithTimeInterval:_timeoutInterval target:self selector:@selector(handleTimeout:) userInfo:nil repeats:NO];
	return YES;
}

- (void)handleTimeout:(NSTimer*)timer
{
	if ([_delegate respondsToSelector:@selector(flickrRESTRequest:error:errorInfo:userInfo:)]) {
		[_delegate flickrRESTRequest:self error:OFRequestConnectionTimeout errorInfo:nil userInfo:_userInfo];
	}
	
	[_connection cancel];
	_closed = YES;
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[_receivedData setLength:0];
	_expectedLength = (size_t)[response expectedContentLength];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_receivedData appendData:data];
	if ([_delegate respondsToSelector:@selector(flickrRESTRequest:progress:expectedTotal:userInfo:)]) {
		[_delegate flickrRESTRequest:self progress:[_receivedData length] expectedTotal:_expectedLength userInfo:_userInfo];
	}
}
- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
	if (_timer) [_timer invalidate];
	_closed = YES;

	NSXMLDocument *x=[[NSXMLDocument alloc] initWithData:_receivedData options:0 error:nil];
	
	if (!x) {
		if ([_delegate respondsToSelector:@selector(flickrRESTRequest:error:errorInfo:userInfo:)]) {
			[_delegate flickrRESTRequest:self error:OFRequestMalformedXMLDocument errorInfo:nil userInfo:_userInfo];
		}
		return;
	}
	
	[x autorelease];

	if ([_delegate respondsToSelector:@selector(flickrRESTRequest:didFetchData:userInfo:)]) {
		[_delegate flickrRESTRequest:self didFetchData:x userInfo:_userInfo];
	}
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"error!");

	if (_timer) [_timer invalidate];
	_closed = YES;

	if ([_delegate respondsToSelector:@selector(flickrRESTRequest:error:errorInfo:userInfo:)]) {
		[_delegate flickrRESTRequest:self error:OFRequestConnectionError errorInfo:error userInfo:_userInfo];
	}
}

@end

@interface OFFlickrUploader(OFFlickrUploaderInternals)
- (void)handleResponse;
- (void)handleError;
- (void)handleTimer:(NSTimer*)timer;
- (void)handleComplete;
@end

static void OFFUReadStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType type, void *callbackInfo)
{
	switch (type)
	{
	 case kCFStreamEventHasBytesAvailable:
		  [(OFFlickrUploader*)callbackInfo handleResponse];
		  break;			
	 case kCFStreamEventEndEncountered:
		  [(OFFlickrUploader*)callbackInfo handleComplete];
		  break;
	 case kCFStreamEventErrorOccurred:
		  [(OFFlickrUploader*)callbackInfo handleError];
		  break;
	 }
}

@implementation OFFlickrUploader
- (id)initWithDelegate:(id)aDelegate
{
	if ((self = [super init])) {
		_delegate = [aDelegate retain];
		_userInfo = nil;
		_uploadSize = 0;
		_stream = NULL;
		_response = nil;
		_timer = nil;
	}
	return self;
}
- (void)dealloc
{
	if (_delegate) [_delegate release];
	if (_userInfo) [_userInfo release];
	if (_response) [_response release];
	if (_stream) CFRelease(_stream);
	if (_timer) [_timer release];
	[super dealloc];
}
- (void)reset
{
	if (_timer) {
		if ([_timer isValid]) {
			[_timer invalidate];
		}
		[_timer release];
		_timer = nil;
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

	_uploadSize = 0;
}
- (BOOL)isClosed {
	return _stream ? NO : YES;
}
- (void)cancel 
{
	CFReadStreamClose(_stream);
	_stream = NULL;
	
	[_timer invalidate];

	if ([_delegate respondsToSelector:@selector(flickrUploader:didCancel:)])
	{
		[_delegate flickrUploader:self didCancel:_userInfo];
	}
}
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
	_uploadSize = [uploaddata length];
		
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

	_timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
	[_timer retain];
	return YES;
}
- (BOOL)uploadWithContentsOfFile:(NSString*)filename photoInformation:(NSDictionary*)photoinfo applicationContext:(OFFlickrApplicationContext*)context userInfo:(id)userinfo
{
	return [self upload:[NSData dataWithContentsOfFile:filename] filename:filename photoInformation:photoinfo applicationContext:context userInfo:userinfo];
}
- (void)handleResponse
{
	UInt8 buffer[2048];
	CFIndex bytesread = CFReadStreamRead(_stream, buffer, sizeof(buffer));

	if (bytesread > 0) [_response appendBytes:(void*)buffer length:(unsigned)bytesread];
}
- (void)handleError
{
	if ([_delegate respondsToSelector:@selector(flickrUploader:error:errorInfo:userInfo:)]) {
		[_delegate flickrUploader:self error:OFRequestConnectionError errorInfo:nil userInfo:_userInfo];
	}
}
- (void)handleTimer:(NSTimer*)timer
{
	if (!_stream) return;
	CFNumberRef bytesWrittenProperty = (CFNumberRef)CFReadStreamCopyProperty(_stream, kCFStreamPropertyHTTPRequestBytesWrittenCount); 
	int bytesWritten;
	CFNumberGetValue (bytesWrittenProperty, kCFNumberSInt32Type, &bytesWritten);

	if ([_delegate respondsToSelector:@selector(flickrUploader:progress:total:userInfo:)]) {
		[_delegate flickrUploader:self progress:(size_t)bytesWritten total:_uploadSize userInfo:_userInfo];
	}
}
- (void)handleComplete
{
	// CFReadStreamClose(_stream);
	// CFRelease(_stream);
	_stream = NULL; // the stream is already released, so we just set to NULL
	[_timer invalidate];

	NSXMLDocument *x=[[NSXMLDocument alloc] initWithData:_response options:0 error:nil];
	[x autorelease];
	
	if (!x) {
		if ([_delegate respondsToSelector:@selector(flickrUploader:error:errorInfo:userInfo:)]) {
			[_delegate flickrUploader:self error:OFRequestMalformedXMLDocument errorInfo:nil userInfo:_userInfo];
		}
	}
	
	if ([_delegate respondsToSelector:@selector(flickrUploader:didComplete:userInfo:)]) {
		[_delegate flickrUploader:self didComplete:x userInfo:_userInfo];
	}
}
@end
