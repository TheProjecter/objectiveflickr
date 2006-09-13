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
