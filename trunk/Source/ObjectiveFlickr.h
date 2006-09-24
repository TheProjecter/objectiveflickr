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
//    may be used to endorse or promote products derived OFom this software
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

#import <Cocoa/Cocoa.h>

@interface OFFlickrApplicationContext : NSObject
{
	NSString *_APIKey;
	NSString *_sharedSecret;
	NSString *_authToken;
	NSDictionary *_endPoints;
}
+ (OFFlickrApplicationContext*)contextWithAPIKey:(NSString*)key sharedSecret:(NSString*)secret;
- (OFFlickrApplicationContext*)initWithAPIKey:(NSString*)key sharedSecret:(NSString*)secret;
- (void)setAuthToken:(NSString*)token;
- (NSString*)authToken;
- (void)setEndPoints:(NSDictionary*)newEndPoints;
- (NSDictionary*)endPoints;
- (NSString*)RESTAPIEndPoint;
- (NSString*)prepareRESTGETURL:(NSDictionary*)parameters authentication:(BOOL)auth sign:(BOOL)sign;
- (NSString*)prepareLoginURL:(NSString*)frob permission:(NSString*)perm;
- (NSData*)prepareRESTPOSTData:(NSDictionary*)parameters authentication:(BOOL)auth sign:(BOOL)sign;
- (NSData*)prepareUploadData:(NSData*)data filename:(NSString*)filename information:(NSDictionary*)info;	 /* incl. title, description, tags, is_public, is_OFiend, is_family */
- (NSString*)uploadURL;
- (NSString*)uploadCallBackURLWithPhotos:(NSArray*)photo_ids;
- (NSString*)uploadCallBackURLWithPhotoID:(NSString*)photo_id;
- (NSString*)photoURLFromID:(NSString*)photo_id serverID:(NSString*)server_id secret:(NSString*)secret size:(NSString*)size type:(NSString*)type;
@end

@interface OFFlickrRESTRequest : NSObject
{
	id _delegate;	
	NSTimeInterval _timeoutInterval;

	BOOL _closed;
	NSURLConnection *_connection;
	NSTimer *_timer;
	id _userInfo;
	size_t _expectedLength;
	NSMutableData *_receivedData;
}
+ (OFFlickrRESTRequest*)requestWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval;
- (OFFlickrRESTRequest*)initWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval;
- (BOOL)isClosed;
- (void)reset;
- (void)cancel;
- (BOOL)GETRequest:(NSString*)url userInfo:(id)info;
- (BOOL)POSTRequest:(NSString*)url data:(NSData*)data userInfo:(id)info;
@end

#define OFRequestDefaultTimeoutInterval  10.0			// 10 seconds

enum {
	OFRequestConnectionError = -1,
	OFRequestConnectionTimeout = -2,
	OFRequestMalformedXMLDocument = -3
};

@interface NSObject(OFFlickrRESTReqestDelegate)
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request didCancel:(id)userinfo;
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request didFetchData:(NSXMLDocument*)xmldoc userInfo:(id)userinfo;
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request error:(int)errorCode errorInfo:(id)errinfo userInfo:(id)userinfo;
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request progress:(size_t)receivedBytes expectedTotal:(size_t)total userInfo:(id)userinfo;
@end;

@interface OFFlickrUploader : NSObject
{
	id _delegate;
	
	id _userInfo;
	size_t _uploadSize;
	CFReadStreamRef _stream;
	NSMutableData *_response;
	NSTimer *_timer;
}
- (id)initWithDelegate:(id)aDelegate;
- (BOOL)upload:(NSData*)data filename:(NSString*)filename photoInformation:(NSDictionary*)photoinfo applicationContext:(OFFlickrApplicationContext*)context userInfo:(id)userinfo;
- (BOOL)uploadWithContentsOfFile:(NSString*)filename photoInformation:(NSDictionary*)photoinfo applicationContext:(OFFlickrApplicationContext*)context userInfo:(id)userinfo;
- (BOOL)isClosed;
- (void)cancel;
@end

@interface NSObject(OFFlickrUploaderDelegate)
- (void)flickrUploader:(OFFlickrUploader*)uploader didComplete:(NSXMLDocument*)response userInfo:(id)userinfo;
- (void)flickrUploader:(OFFlickrUploader*)uploader error:(int)code errorInfo:(id)errinfo userInfo:(id)userinfo;
- (void)flickrUploader:(OFFlickrUploader*)uploader progress:(size_t)length total:(size_t)totalLength userInfo:(id)userinfo;
- (void)flickrUploader:(OFFlickrUploader*)uploader didCancel:(id)userinfo;
@end
