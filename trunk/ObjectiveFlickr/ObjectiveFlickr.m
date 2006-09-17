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

#define FR_RESTAPI_ENDPOINT @"http://api.flickr.com/services/rest/?"
#define FR_AUTHAPI_ENDPOINT @"http://flickr.com/services/auth/?"
#define FR_PHOTOURL_PREFIX  @"http://static.flickr.com/"

@implementation FlickrRESTURL
- (FlickrRESTURL*)initWithAPIKey:(NSString*)key secret:(NSString*)sec
{
	if ((self = [super init])) {
		api_key=[[NSString alloc] initWithString:key];
		secret=[[NSString alloc] initWithString:sec];
		auth_token=[[NSString alloc] init];
	}
	return self;
}
- (void)dealloc
{
	[api_key release];
	[secret release];
	[auth_token release];
	[super dealloc];
}
- (void)setToken:(NSString*)token 
{
	[auth_token release];
	auth_token=[[NSString alloc] initWithString:token];
}
- (NSString*)getFrobURL
{
	NSString *sig=[[NSString stringWithFormat:@"%@api_key%@method%@", 
		secret, api_key, @"flickr.auth.getFrob"] md5HexHash];

	return [NSString stringWithFormat:
		@"%@method=flickr.auth.getFrob&api_key=%@&api_sig=%@",
		FR_RESTAPI_ENDPOINT, api_key, sig];
}
- (NSString*)authURL:(NSString*)permission withFrob:(NSString*)frob
{
	NSString *sig=[[NSString stringWithFormat:@"%@api_key%@frob%@perms%@",
		secret, api_key, frob, permission] md5HexHash];
	return [NSString stringWithFormat:
		@"%@api_key=%@&perms=%@&frob=%@&api_sig=%@",
		FR_AUTHAPI_ENDPOINT, api_key, permission, frob, sig];
}

- (NSString*)methodURL:(NSString*)method useToken:(BOOL)usetoken useAPIKey:(BOOL)usekey arguments:(NSDictionary*)arg
{
	NSMutableDictionary *param=[NSMutableDictionary dictionaryWithDictionary:arg];
	[param setObject:method forKey:@"method"];
	
	if (usekey) [param setObject:api_key forKey:@"api_key"];
	if (usetoken) [param setObject:auth_token forKey:@"auth_token"];
	
	NSMutableString *call=[NSMutableString stringWithString:FR_RESTAPI_ENDPOINT];
	
	NSMutableString *sigstr=[NSMutableString stringWithString:secret];
	NSArray *sortedkeys=[[param allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	int c=[sortedkeys count];
	int i;
	for (i=0; i<c; i++) {
		NSString *k=[sortedkeys objectAtIndex:i];
		NSString *v=[param objectForKey:k];
		if (i) [call appendString:@"&"];
		[call appendString:k];
		[call appendString:@"="];
		[call appendString:[param objectForKey:k]];
		
		[sigstr appendString:k];
		[sigstr appendString:v];
	}
	
	if (1) {
		[call appendString:@"&api_sig="];
		[call appendString:[sigstr md5HexHash]];
	}
	
	return call;
}
- (NSDictionary*)uploadPOSTDictionary:(NSString*)filename
{
	NSMutableDictionary *d;
	
	[d setObject:[NSString stringWithString:api_key] forKey:@"api_key"];
	[d setObject:[NSString stringWithString:auth_token] forKey:@"auth_token"];

	NSString *sig=[[NSString stringWithFormat:@"%@api_key%@auth_token%@", secret, api_key, auth_token] md5HexHash];
	[d setObject:sig forKey:@"api_sig"];
	
	NSString *lastpart = [filename lastPathComponent];
	NSString *extension = [filename pathExtension];
	
	[d setObject:lastpart forKey:@"filename"];
	
	if ([extension isEqualToString:@".png"]) {
		[d setObject:@"image/png" forKey:@"content-type"];
	}
	else {
		[d setObject:@"image/jpeg" forKey:@"content-type"];
	}
	
	return d;
}
@end


@implementation FlickrRESTRequest
- (FlickrRESTRequest*)initWithDelegate:(id)deleg timeoutInterval:(NSTimeInterval)interval
{
	if ((self = [super init])) {
		delegate=deleg;
		timeoutInterval = interval;
		
		rawdata = nil;
		connection = nil;
		state = nil;
		expectedLength = 0;
	}
	return self;
}

- (void)dealloc
{
	if (rawdata) [rawdata release];
	if (connection) [connection release];
	if (state) [state release];
	[super dealloc];
}
- (void)reset
{
	// NSLog(@"flickr request reset");
	if (rawdata) {
		[rawdata release];
		rawdata = nil;
	}
	if (connection) {
		[connection cancel];
		[connection release];
		connection = nil;
	}
	if (timer) {
		[timer invalidate];
		timer = nil;
	}
	if (state) {
		[state release];
		state = nil;
	}
	expectedLength = 0;
}
- (void)cancel
{
	// NSLog(@"flickr request canceled");
	[connection cancel];
	if ([delegate respondsToSelector:@selector(flickrRESTRequestDidCancel:state:)]) {
		[delegate flickrRESTRequestDidCancel:self state:state];
	}
	[self reset];
}
- (BOOL)requestURL:(NSString*)url withState:(NSString*)st {
	NSLog(@"flickr requesting URL %@", url);
	[self reset];

	state = [[NSString alloc] initWithString:st];
	rawdata=[[NSMutableData data] retain];

	NSURLRequest *req=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeoutInterval];
	connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	if (!connection) {
		// NSLog(@"cannot establish connection");
		[self reset];
		return NO;
	}
	
	timer=[NSTimer scheduledTimerWithTimeInterval:timeoutInterval target:self selector:@selector(timeout:) userInfo:nil repeats:NO];

	return YES;
}
- (void)timeout:(NSTimer*)timer 
{
	// NSLog(@"flickr request timeout");
	if ([delegate respondsToSelector:@selector(flickrRESTRequest:error:message:state:)]) {
		[delegate flickrRESTRequest:self error:FRRETimeout message:@"Request timeout" state:state];
	}
	[self reset];
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// if we encounter a redirect response, we set data pointer to zero
    [rawdata setLength:0];
	expectedLength = (size_t)[response expectedContentLength];
	// NSLog(@"flickr request received response");
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d
{
    // append the new data to the receivedData
    [rawdata appendData:d];
	// NSLog(@"flickr request received data, length=%d, now total=%d", [d length], [rawdata length]);
	
	if ([delegate respondsToSelector:@selector(flickrRESTRequest:progress:total:state:)]) {
		[delegate flickrRESTRequest:self progress:[rawdata length] total:expectedLength state:state];
	}
}
- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
    // do something with the data
    // NSLog(@"Succeeded! Received %d bytes of data",[rawdata length]);

	// close connection
	if (connection) {
		[connection release];
		connection = nil;
	}
	if (timer) {
		[timer invalidate];
		timer = nil;
	}

	NSXMLDocument *x=[[NSXMLDocument alloc] initWithData:rawdata options:0 error:nil];
	[x autorelease];
	if (x) {
		NSXMLElement *r = [x rootElement];

		NSXMLNode *stat =[r attributeForName:@"stat"];
		// NSLog(@"stat attribute, name = %@, value =%@", [stat name], [stat stringValue]);
		
		if ([[stat stringValue] isEqualToString:@"ok"]) {
			if ([delegate respondsToSelector:@selector(flickrRESTRequest:didReceiveData:state:)]) {
				[delegate flickrRESTRequest:self didReceiveData:x state:state];
			}
		}
		else {
			NSXMLNode *e = [r childAtIndex:0];
			NSXMLNode *code = [(NSXMLElement*)e attributeForName:@"code"];
			NSXMLNode *msg = [(NSXMLElement*)e attributeForName:@"msg"];
			// NSLog(@"error code=%@, msg=%@", [code stringValue], [msg stringValue]);

			if ([delegate respondsToSelector:@selector(flickrRESTRequest:error:message:state:)]) {
				[delegate flickrRESTRequest:self error:[[code stringValue] intValue] message:[msg stringValue] state:state];
			}
		}
	}
	else {
		if ([delegate respondsToSelector:@selector(flickrRESTRequest:error:message:state:)]) {
			[delegate flickrRESTRequest:self error:FRREError message:@"Malformed XML document" state:state];
		}	
	}

	// we can't do this at this stage, otherwise it'll be miserable
	// [self reset];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if ([delegate respondsToSelector:@selector(flickrRESTRequest:error:message:state:)]) {
		[delegate flickrRESTRequest:self error:FRREError message:@"Connection failed" state:state];
	}
	[self reset];
}
+ (NSString*)extractToken:(NSXMLDocument*)doc
{
	NSXMLElement *e = [[doc nodesForXPath:@"/rsp/auth/token" error:nil] objectAtIndex:0];
	return [NSString stringWithString:[e stringValue]];
}
+ (NSDictionary*)extractTokenDictionary:(NSXMLDocument*)doc
{
	NSMutableDictionary *d=[NSMutableDictionary dictionary];

	NSXMLElement *e = [[doc nodesForXPath:@"/rsp/auth/token" error:nil] objectAtIndex:0];
	[d setObject:[e stringValue] forKey:@"token"];
	e = [[doc nodesForXPath:@"/rsp/auth/perms" error:nil] objectAtIndex:0];
	[d setObject:[e stringValue] forKey:@"perms"];
	e = [[doc nodesForXPath:@"/rsp/auth/user" error:nil] objectAtIndex:0];
	[d setObject:[[e attributeForName:@"nsid"] stringValue] forKey:@"nsid"];
	[d setObject:[[e attributeForName:@"username"] stringValue] forKey:@"username"];
	[d setObject:[[e attributeForName:@"fullname"] stringValue] forKey:@"fullname"];

	return d;
}
+ (NSString*)extractFrob:(NSXMLDocument*)doc
{
	NSXMLElement *e = [[doc nodesForXPath:@"/rsp/frob" error:nil] objectAtIndex:0];
	return [NSString stringWithString:[e stringValue]];
}
+ (NSString*)photoSourceURLFromServerID:(NSString*)serverid photoID:(NSString*)pid secret:(NSString*)sec size:(NSString*)s type:(NSString*)t
{
	NSMutableString *r=[NSMutableString stringWithFormat:@"%@%@/%@_%@", FR_PHOTOURL_PREFIX, serverid, pid, sec];
	
	if (s) {
		if ([s length]) {
			[r appendString:@"_"];
			[r appendString:s];
		}
	}
	
	[r appendString:@"."];
	if (t) [r appendString:t]; else [r appendString:@"jpg"];
	return r;
}
+ (NSDictionary*)extractPhotos:(NSXMLDocument*)doc
{
	NSMutableDictionary *d=[NSMutableDictionary dictionary];

	NSXMLElement *e = [[doc nodesForXPath:@"/rsp/photos" error:nil] objectAtIndex:0];
	[d setObject:[[e attributeForName:@"page"] stringValue] forKey:@"page"];
	[d setObject:[[e attributeForName:@"pages"] stringValue] forKey:@"pages"];
	[d setObject:[[e attributeForName:@"perpage"] stringValue] forKey:@"perpage"];
	[d setObject:[[e attributeForName:@"total"] stringValue] forKey:@"total"];
	
	NSMutableArray *a=[NSMutableArray array];
	size_t i, c=[e childCount];
	for (i=0; i<c; i++) {
		NSXMLElement *f = (NSXMLElement*)[e childAtIndex:i];
		
		NSMutableDictionary *p=[NSMutableDictionary dictionary];
		[p setObject:[[f attributeForName:@"id"] stringValue] forKey:@"id"];
		[p setObject:[[f attributeForName:@"owner"] stringValue] forKey:@"owner"];
		[p setObject:[[f attributeForName:@"secret"] stringValue] forKey:@"secret"];
		[p setObject:[[f attributeForName:@"server"] stringValue] forKey:@"server"];
		[p setObject:[[f attributeForName:@"title"] stringValue] forKey:@"title"];
		[p setObject:[[f attributeForName:@"ispublic"] stringValue] forKey:@"ispublic"];
		[p setObject:[[f attributeForName:@"isfriend"] stringValue] forKey:@"isfriend"];
		[p setObject:[[f attributeForName:@"isfamily"] stringValue] forKey:@"isfamily"];
		[a addObject:p];
	}

	[d setObject:a forKey:@"photos"];
	return d;
}

@end


static const CFOptionFlags FUClientNetworkEvents = 
	kCFStreamEventOpenCompleted     |
	kCFStreamEventHasBytesAvailable |
	kCFStreamEventEndEncountered    |
	kCFStreamEventErrorOccurred;
	
static void FUReadStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType type, void *callbackInfo)
{
	switch (type)
	{
	 case kCFStreamEventHasBytesAvailable:
		  [(FlickrUploader*)callbackInfo handleResponse];
		  break;			
	 case kCFStreamEventEndEncountered:
		  [(FlickrUploader*)callbackInfo handleComplete];
		  break;
	 case kCFStreamEventErrorOccurred:
		  [(FlickrUploader*)callbackInfo handleError];
		  break;
	 }
}


@implementation FlickrUploader
- (id)initWithDelegate:(id)deleg
{
	if ((self = [super init])) {
		delegate = deleg;
		uploadSize = 0;
		stream = NULL;
		response = nil;
		timer = nil;
	}
	return self;
}
- (void)dealloc {
	[self reset];
	[super dealloc];
}
- (void)reset {
	uploadSize = 0;
	if (stream) {
		CFRelease(stream);
		stream = NULL;
	}
	if (response) {
		[response release];
		response=nil;
	}
	if (timer) {
		[timer invalidate];
		[timer release];
		timer=nil;
	}
}
- (BOOL)upload:(NSString*)filename withURLRequest:(FlickrRESTURL*)req
{
	NSDictionary *dict = [req uploadPOSTDictionary:filename];
	NSURL *url = [dict objectForKey:@"url"];

	// create the HTTP POST body
	CFHTTPMessageRef httpreq;
	httpreq = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("POST"), (CFURLRef)url, kCFHTTPVersion1_1);

	NSString *separator=@"----------0xKhTmLbOuNdArY";
	NSString *headerfield=[NSString stringWithFormat:@"multipart/form-data; boundary=%@", separator];
	CFHTTPMessageSetHeaderFieldValue(httpreq, CFSTR("Content-Type"), (CFStringRef)headerfield);

	NSString *apikey_str = [NSString stringWithFormat:
		@"%@\r\nContent-Disposition: form-data; name=\"api_key\"\r\n\r\n%@\r\n",
		separator, [dict objectForKey:@"api_key"]];
	
	NSString *authtoken_str = [NSString stringWithFormat:
		@"%@\r\nContent-Disposition: form-data; name=\"auth_token\"\r\n\r\n%@\r\n",
		separator, [dict objectForKey:@"auth_token"]];
	
	NSString *apisig_str = [NSString stringWithFormat:
		@"%@\r\nContent-Disposition: form-data; name=\"api_sig\"\r\n\r\n%@\r\n",
		separator, [dict objectForKey:@"api_sig"]];
		
	NSString *filename_str = [NSString stringWithFormat:
		@"%@\r\nContent-Disposition: form-data; name=\"photo\"\r\n filename=\"%@\"\r\nContent-Type: %@\r\n",
		separator, [dict objectForKey:@"filename"], [dict objectForKey:@"content-type"]];

	NSMutableData *postdata = [[NSMutableData alloc] initWithCapacity:60000];

	[postdata appendData:[apikey_str dataUsingEncoding:NSUTF8StringEncoding]];
	[postdata appendData:[authtoken_str dataUsingEncoding:NSUTF8StringEncoding]];
	[postdata appendData:[apisig_str dataUsingEncoding:NSUTF8StringEncoding]];
	[postdata appendData:[filename_str dataUsingEncoding:NSUTF8StringEncoding]];

	NSDictionary *fileAtributes = [[NSFileManager defaultManager] fileAttributesAtPath:filename traverseLink:YES];
	uploadSize = [[fileAtributes objectForKey:NSFileSize] longValue];

	[postdata appendData:[NSData dataWithContentsOfFile:filename]];

	NSString *endmark = [NSString stringWithFormat: @"\r\n%@--", separator];
	[postdata appendData:[endmark dataUsingEncoding:NSUTF8StringEncoding]];
	
	CFHTTPMessageSetBody(httpreq, (CFDataRef)postdata); 

	stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, httpreq);
	CFRelease(httpreq);

	CFStreamClientContext context = {0, self, NULL, NULL, NULL};

	// Wir teilen CFNetwork jetzt mit, dass wir Callbacks erhalten möchten.
	if (!CFReadStreamSetClient(stream, FUClientNetworkEvents, FUReadStreamClientCallBack, &context))
	{
		[self reset];
		return NO;
	}

	CFReadStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);

	response = [[NSMutableData data] retain];

	CFReadStreamOpen(stream);

	timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
	return YES;
}

- (void)cancel 
{
	CFReadStreamClose(stream);
	[self reset];
	[delegate flickrUploaderDidCancel:self];
}
- (void)handleResponse
{
	UInt8 buffer[2048];
	CFIndex bytesRead = CFReadStreamRead(stream, buffer, sizeof(buffer));

	if (bytesRead < 0)
	{
		  NSLog(@"Warning: Error (< 0b from CFReadStreamRead");
	}
	else if (bytesRead)
	{
		[response appendBytes:(void *)buffer length:(unsigned)bytesRead];
	}
}
- (void)handleError
{
	[delegate flickrUploader:self error:FRREError];
}
- (void)handleComplete
{
	#warning TO-DO: handle response id
	NSString *rep = [[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] autorelease];
	[delegate flickrUploader:self didComplete:rep];
	[self reset];
}

- (void)handleTimer:(NSTimer*)t
{
	CFNumberRef bytesWrittenProperty = (CFNumberRef)CFReadStreamCopyProperty (stream, kCFStreamPropertyHTTPRequestBytesWrittenCount); 
	int bytesWritten;
	CFNumberGetValue (bytesWrittenProperty, 3, &bytesWritten);
	long written = (long)bytesWritten;

	[delegate flickrUploader:self progress:(size_t)written total:uploadSize];
}

@end;

