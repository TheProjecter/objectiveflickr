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


#import <Cocoa/Cocoa.h>

@interface FlickrRESTURL : NSObject
{
	NSString *api_key;
	NSString *secret;
	NSString *auth_token;
}
- (FlickrRESTURL*)initWithAPIKey:(NSString*)key secret:(NSString*)sec;
- (void)dealloc;
- (void)setToken:(NSString*)token;
- (NSString*)getFrobURL;
- (NSString*)authURL:(NSString*)permission withFrob:(NSString*)frob;
- (NSString*)methodURL:(NSString*)method useToken:(BOOL)usetoken useAPIKey:(BOOL)usekey arguments:(NSDictionary*)arg;
- (NSDictionary*)uploadPOSTDictionary:(NSString*)filename;
- (NSString*)uploadCallbackURL:(NSString*)photoId;
// - (NSString*)uploadCallbackWithPhotos:(NSArray*)photoIdArray;
@end;


@interface FlickrRESTRequest : NSObject
{
	NSTimeInterval timeoutInterval;
	id delegate;
	
	NSMutableData *rawdata;
	NSURLConnection *connection;
	size_t expectedLength;
	NSTimer *timer;
	NSString *state;
}
- (FlickrRESTRequest*)initWithDelegate:(id)deleg timeoutInterval:(NSTimeInterval)interval;
- (void)dealloc;
- (void)reset;
- (void)timeout:(NSTimer*)timer;
- (void)cancel;
- (BOOL)requestURL:(NSString*)url withState:(NSString*)st;
+ (NSString*)extractToken:(NSXMLDocument*)doc;
+ (NSDictionary*)extractTokenDictionary:(NSXMLDocument*)doc;
+ (NSString*)extractFrob:(NSXMLDocument*)doc;
+ (NSString*)photoSourceURLFromServerID:(NSString*)serverid photoID:(NSString*)pid secret:(NSString*)sec size:(NSString*)s type:(NSString*)t;
+ (NSDictionary*)extractPhotos:(NSXMLDocument*)doc;
@end;

@protocol FlickrRESTRequestDelegate
- (void)flickrRESTRequestDidCancel:(FlickrRESTRequest*)request state:(NSString*)state;
- (void)flickrRESTRequest:(FlickrRESTRequest*)request didReceiveData:(NSXMLDocument*)document state:(NSString*)state;
- (void)flickrRESTRequest:(FlickrRESTRequest*)request error:(int)errorCode message:(NSString*)msg state:(NSString*)state;
- (void)flickrRESTRequest:(FlickrRESTRequest*)request progress:(size_t)length total:(size_t)expectedLength state:(NSString*)state;
@end;

enum {
	// FRRE = FlickrRESTRequest Error
	FRREError = -1,
	FRRETimeout = -2
};

@interface FlickrUploader : NSObject
{
	id delegate;
	size_t uploadSize;
	CFReadStreamRef stream;
	NSMutableData *response;
	NSTimer *timer;
}
- (id)initWithDelegate:(id)deleg;
- (BOOL)upload:(NSString*)filename withURLRequest:(FlickrRESTURL*)req;
- (void)cancel;

// internal functions
- (void)reset;
- (void)handleResponse;
- (void)handleError;
- (void)handleComplete;
- (void)handleTimer:(NSTimer*)t;
@end;

@protocol FlickrUploaderDelegate
- (void)flickrUploader:(FlickrUploader*)uploader didComplete:(NSString*)response;
- (void)flickrUploader:(FlickrUploader*)uploader error:(int)code;
- (void)flickrUploader:(FlickrUploader*)uploader progress:(size_t)length total:(size_t)totalLength;
- (void)flickrUploaderDidCancel:(FlickrUploader*)uploader;
@end;

