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

#define OFSharedSeparator	@"---------------------------8f999edae883c6039b244c0d341f45f8"


static NSDictionary *_OFPresetEndPoints = nil;
static NSDictionary *_OFDefaultEndPoints = nil;
static OFFlickrContext *_OFDefaultContext = nil;

@interface OFFlickrContext (OFFlickrContextInternals)
+ (void)initialize;
- (void)dealloc;
- (NSString*)description;
- (NSString*)signatureForCall:(NSDictionary*)parameters;
- (NSMutableData*)internalPreparePOSTData:(NSDictionary*)parameters authentication:(BOOL)auth sign:(BOOL)sign endMark:(BOOL)endmark;
@end

@implementation OFFlickrContext
+ (void)setDefaultEndPointsByName:(NSString*)name
{
	_OFDefaultEndPoints = [_OFPresetEndPoints objectForKey:name];
	if (!_OFDefaultEndPoints) _OFDefaultEndPoints = [_OFPresetEndPoints objectForKey:OFFlickrEndPoints];
}
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
	
		_endPoints = [[NSDictionary dictionaryWithDictionary:_OFDefaultEndPoints] retain];
	}
	return self;
}
+ (OFFlickrContext*)defaultContext
{
  return _OFDefaultContext;
}

+ (void)setDefaultContext: (OFFlickrContext*) inContext
{
  if (![_OFDefaultContext isEqualTo:inContext])
  {
    [_OFDefaultContext release];
    _OFDefaultContext = [inContext retain];
  }
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
	// no farm id here
	NSString *urlbase =  [NSString stringWithFormat:[_endPoints objectForKey:OFPhotoURLPrefixKey], @""];
	NSMutableString *r=[NSMutableString stringWithFormat:@"%@%@/%@_%@", urlbase, server_id, photo_id, secret];
	
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
- (NSString*)photoURLFromDictionary:(NSDictionary*)photoDict size:(NSString*)size
{
	NSString *pid = [photoDict objectForKey:[NSXMLDocument flickrXMLAttribute:@"id"]];
	NSString *secret = [photoDict objectForKey:[NSXMLDocument flickrXMLAttribute:@"secret"]];
	NSString *sid = [photoDict objectForKey:[NSXMLDocument flickrXMLAttribute:@"server"]];
	NSString *farm = [photoDict objectForKey:[NSXMLDocument flickrXMLAttribute:@"farm"]];
	NSString *osct = [photoDict objectForKey:[NSXMLDocument flickrXMLAttribute:@"originalsecret"]];
	NSString *ofmt = [photoDict objectForKey:[NSXMLDocument flickrXMLAttribute:@"originalformat"]];

	NSString *farmurl = @"";
	if (farm) { if (![farm isEqualToString:@""]) farmurl = [NSString stringWithFormat:@"farm%@.", farm]; }
	NSString *urlbase =  [NSString stringWithFormat:[_endPoints objectForKey:OFPhotoURLPrefixKey], farmurl];

	if (size) { 
		if ([size isEqualToString:@"o"]) {
			return [NSMutableString stringWithFormat:@"%@%@/%@_%@_o.%@", urlbase, sid, pid, osct, ofmt];
		}
	}

	NSMutableString *r=[NSMutableString stringWithFormat:@"%@%@/%@_%@", urlbase, sid, pid, secret];
	
	if (size) {
		if ([size length]) {
			[r appendString:@"_"];
			[r appendString:size];
		}
	}
	
 	[r appendString:@".jpg"];
	return r;
}
- (NSString*)buddyIconURLWithUserID:(NSString*)nsid iconServer:(NSString*)server iconFarm:(NSString*)farm
{
	NSString *def = [_endPoints objectForKey:OFDefaultBuddyIconKey];
	if (!server) return def;
	if ([server isEqualToString:@""] || [server isEqualToString:@"0"]) return def;
	
	NSString *farmurl = @"";
	if (farm) { if (![farm isEqualToString:@""]) farmurl = [NSString stringWithFormat:@"farm%@.", farm]; }
	NSString *urlbase =  [NSString stringWithFormat:[_endPoints objectForKey:OFPhotoURLPrefixKey], farmurl];

	return [NSString stringWithFormat:@"%@%@/buddyicons/%@.jpg", urlbase, server, nsid];
}
- (NSString*)buddyIconURLFromDictionary:(NSDictionary*)userdict
{
	return [self buddyIconURLWithUserID:
			[userdict objectForKey:[NSXMLDocument flickrXMLAttribute:@"nsid"]]
		iconServer:
			[userdict objectForKey:[NSXMLDocument flickrXMLAttribute:@"iconserver"]]
		iconFarm:
			[userdict objectForKey:[NSXMLDocument flickrXMLAttribute:@"iconfarm"]]];
}
@end

@implementation OFFlickrContext (OFFlickrContextInternals)
+ (void)initialize
{
    if ( self == [OFFlickrContext class] ) {
		_OFPresetEndPoints = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSDictionary dictionaryWithObjectsAndKeys:
				@"http://api.flickr.com/services/rest/", OFRESTAPIEndPointKey,
				@"http://flickr.com/services/auth/", OFAuthenticationEndPointKey, 
				@"http://%@static.flickr.com/", OFPhotoURLPrefixKey, 
				@"http://www.flickr.com/images/buddyicon.jpg", OFDefaultBuddyIconKey,
				@"http://api.flickr.com/services/upload/", OFUploadEndPointKey,
				@"http://www.flickr.com/tools/uploader_edit.gne", OFUploadCallBackEndPointKey, nil],
			OFFlickrEndPoints,
				
			[NSDictionary dictionaryWithObjectsAndKeys:
				@"http://beta.zooomr.com/bluenote/api/rest/", OFRESTAPIEndPointKey,
				@"http://beta.zooomr.com/auth/", OFAuthenticationEndPointKey, 
				@"http://static.zooomr.com/images/", OFPhotoURLPrefixKey, 
				@"http://static.zooomr.com/images/buddyicon.jpg", OFDefaultBuddyIconKey,
				@"http://beta.zooomr.com/bluenote/api/upload/", OFUploadEndPointKey,
				@"http://beta.zooomr.com/tools/uploader_edit.gne", OFUploadCallBackEndPointKey, nil],
			OFZooomrEndPoints,

			[NSDictionary dictionaryWithObjectsAndKeys:
				@"http://www.23hq.com/services/rest/", OFRESTAPIEndPointKey,
				@"http://www.23hq.com/services/auth/", OFAuthenticationEndPointKey, 
				@"http://www.23hq.com/", OFPhotoURLPrefixKey, 
				@"http://www.23hq.com/images/buddyicon.jpg", OFDefaultBuddyIconKey,
				@"http://www.23hq.com/services/upload/", OFUploadEndPointKey,
				@"http://www.23hq.com/tools/uploader_edit.gne", OFUploadCallBackEndPointKey, nil],
			OF23HQEndPoints, nil];
			
		_OFDefaultEndPoints = [_OFPresetEndPoints objectForKey:OFFlickrEndPoints];
    }
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
