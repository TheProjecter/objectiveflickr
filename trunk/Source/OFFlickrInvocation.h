// OFFlickrInvocation.h
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

@interface OFFlickrInvocation : NSObject
{
	id _delegate;
	id _userInfo;
	
	id _request;
	SEL _selector;
	OFFlickrContext *_context;
}
+ (OFFlickrInvocation*)invocationWithContext:(OFFlickrContext*)context;
+ (OFFlickrInvocation*)invocationWithContext:(OFFlickrContext*)context delegate:(id)aDelegate;
+ (OFFlickrInvocation*)invocationWithContext:(OFFlickrContext*)context delegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval;
- (OFFlickrInvocation*)initWithContext:(OFFlickrContext*)context;
- (OFFlickrInvocation*)initWithContext:(OFFlickrContext*)context delegate:(id)aDelegate;
- (OFFlickrInvocation*)initWithContext:(OFFlickrContext*)context delegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval;
- (id)delegate;
- (void)setDelegate:(id)aDelegate;
- (void)setSelector:(SEL)aSelector;
- (id)userInfo;
- (void)setUserInfo:(id)userinfo;
- (OFFlickrContext*)context;
- (void)cancel;
- (BOOL)isClosed;
- (BOOL)callMethod:(NSString*)method arguments:(NSArray*)parameter;
- (BOOL)callMethod:(NSString*)method arguments:(NSArray*)parameter selector:(SEL)aSelector;
- (BOOL)callMethod:(NSString*)method arguments:(NSArray*)parameter delegate:(id)aDelegate selector:(SEL)aSelector;
@end

@interface NSObject(OFFlickrInvocationDelegate)
- (void)flickrInvocation:(OFFlickrInvocation*)invocation didFetchData:(NSXMLDocument*)xmldoc;
- (void)flickrInvocation:(OFFlickrInvocation*)invocation errorCode:(int)errcode errorInfo:(id)errinfo;
- (void)flickrInvocation:(OFFlickrInvocation*)invocation progress:(size_t)receivedBytes expectedTotal:(size_t)total;
@end

@interface OFFlickrInvocation (OFFlickrAPIStub)
- (id)flickr_auth_getToken:(id)userinfo frob:(NSString*)aFrob;
- (id)flickr_auth_getToken:(id)userinfo frob:(NSString*)aFrob selector:(SEL)aSelector;
- (id)flickr_auth_getFrob:(id)userinfo;
- (id)flickr_auth_getFrob:(id)userinfo selector:(SEL)aSelector;
@end