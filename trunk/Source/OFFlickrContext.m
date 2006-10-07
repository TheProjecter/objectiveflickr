// OFFlickrContext.m
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

#import <ObjectiveFlickr/ObjectiveFlickr.h>
#import "CocoaCryptoHashing.h"

#define OFDefaultRESTAPIEndPoint			@"http://api.flickr.com/services/rest/"
#define OFDefaultAuthenticationEndPoint		@"http://flickr.com/services/auth/"
#define OFDefaultPhotoURLPrefix				@"http://static.flickr.com/"
#define OFDefaultUploadEndPoint				@"http://api.flickr.com/services/upload/"
#define OFDefaultUploadCallBackEndPoint		@"http://www.flickr.com/tools/uploader_edit.gne"

#define OFSharedSeparator	@"---------------------------8f999edae883c6039b244c0d341f45f8"

@interface OFFlickrContext (OFFlickrContextInternals)
- (void)dealloc;
- (NSString*)description;
- (NSString*)signatureForCall:(NSDictionary*)parameters;
- (NSMutableData*)internalPreparePOSTData:(NSDictionary*)parameters authentication:(BOOL)auth sign:(BOOL)sign endMark:(BOOL)endmark;
@end

@implementation OFFlickrContext
+ (OFFlickrContext*)contextWithAPIKey:(NSString*)key sharedSecret:(NSString*)secret
{
	return [[[OFFlickrContext alloc] initWithAPIKey:key sharedSecret:secret] autorelease];
}
- (OFFlickrContext*)initWithAPIKey:(NSString*)key sharedSecret:(NSString*)secret
{
	if ((self = [super init])) {
		_APIKey = [[NSString alloc] initWithString:key];
		_sharedSecret = [[NSString alloc] initWithString:secret ? secret: @""];
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
- (NSString*)photoURLFromDictionary:(NSDictionary*)photoDict size:(NSString*)size type:(NSString*)type
{
	return [self photoURLFromID:[photoDict objectForKey:[NSXMLDocument flickrXMLAttribute:@"id"]]
		serverID:[photoDict objectForKey:[NSXMLDocument flickrXMLAttribute:@"server"]]
		secret:[photoDict objectForKey:[NSXMLDocument flickrXMLAttribute:@"secret"]]
		size:size
		type:type];
}
@end

@implementation OFFlickrContext (OFFlickrContextInternals)
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
	
	// NSLog(@"signature string %@, md5=%@", sigstr, [sigstr md5HexHash]);
	return [sigstr md5HexHash];
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
			[OFFlickrContext POSTDataSeparator], k, v];

		[data appendData:[addstr dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	if (endmark) {
		NSString *ending = [NSString stringWithFormat: @"--%@--", [OFFlickrContext POSTDataSeparator]];
		[data appendData:[ending dataUsingEncoding:NSUTF8StringEncoding]];	
	}
	
	return data;
}
@end

@implementation OFFlickrContext (OFFlickrDataPreparer)
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
- (NSData*)prepareRESTPOSTData:(NSDictionary*)parameters authentication:(BOOL)auth sign:(BOOL)sign
{
	return [self internalPreparePOSTData:parameters authentication:auth sign:sign endMark:YES];
}
+ (NSString*)POSTDataSeparator
{
	return OFSharedSeparator;
}
@end

@implementation OFFlickrContext (OFFlickrUploadHelper)
- (NSData*)prepareUploadData:(NSData*)data filename:(NSString*)filename information:(NSDictionary*)info
{
	// TO-DO: Quote processing of filename

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
		[OFFlickrContext POSTDataSeparator], lastpart, content_type];

	[cooked appendData:[filename_str dataUsingEncoding:NSUTF8StringEncoding]];
	[cooked appendData:data];	
	NSString *endmark = [NSString stringWithFormat: @"\r\n--%@--", [OFFlickrContext POSTDataSeparator]];
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
	
	// NSLog(@"finished preparing uploadCallBackURL: %@", urlstr);
	return urlstr;
}
- (NSString*)uploadCallBackURLWithPhotoID:(NSString*)photo_id
{
	return [self uploadCallBackURLWithPhotos:[NSArray arrayWithObject:photo_id]];
}
@end
