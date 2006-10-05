// OFFlickrContext.h
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

#define OFRESTAPIEndPointKey			@"RESTAPIEndPoint"
#define OFAuthenticationEndPointKey		@"authEndPoint"
#define OFPhotoURLPrefixKey				@"photoURLPrefix"
#define OFUploadEndPointKey				@"uploadEndPoint"
#define OFUploadCallBackEndPointKey		@"uploadCallBackEndPoint"

@interface OFFlickrContext : NSObject
{
	NSString *_APIKey;
	NSString *_sharedSecret;
	NSString *_authToken;
	NSDictionary *_endPoints;
}
+ (OFFlickrContext*)contextWithAPIKey:(NSString*)key sharedSecret:(NSString*)secret;
- (OFFlickrContext*)initWithAPIKey:(NSString*)key sharedSecret:(NSString*)secret;
- (void)setAuthToken:(NSString*)token;
- (NSString*)authToken;
- (void)setEndPoints:(NSDictionary*)newEndPoints;
- (NSDictionary*)endPoints;
- (NSString*)RESTAPIEndPoint;
- (NSString*)photoURLFromID:(NSString*)photo_id serverID:(NSString*)server_id secret:(NSString*)secret size:(NSString*)size type:(NSString*)type;
@end

@interface OFFlickrContext (OFFlickrDataPreparer)
- (NSString*)prepareRESTGETURL:(NSDictionary*)parameters authentication:(BOOL)auth sign:(BOOL)sign;
- (NSString*)prepareLoginURL:(NSString*)frob permission:(NSString*)perm;
- (NSData*)prepareRESTPOSTData:(NSDictionary*)parameters authentication:(BOOL)auth sign:(BOOL)sign;
+ (NSString*)POSTDataSeparator;
@end

@interface OFFlickrContext (OFFlickrUploadHelper)
- (NSData*)prepareUploadData:(NSData*)data filename:(NSString*)filename information:(NSDictionary*)info;	 /* incl. title, description, tags, is_public, is_OFiend, is_family */
- (NSString*)uploadURL;
- (NSString*)uploadCallBackURLWithPhotos:(NSArray*)photo_ids;
- (NSString*)uploadCallBackURLWithPhotoID:(NSString*)photo_id;
@end
