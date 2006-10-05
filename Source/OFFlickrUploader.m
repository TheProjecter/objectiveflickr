// OFFlickrUploader.m
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

@interface OFFlickrUploader (OFFlickrUploaderInternals)
- (void)dealloc;
- (void)POSTRequest:(OFPOSTRequest*)request didComplete:(NSData*)response userInfo:(id)userinfo;
- (void)POSTRequest:(OFPOSTRequest*)request error:(CFStreamError)errinfo userInfo:(id)userinfo;
- (void)POSTRequest:(OFPOSTRequest*)request progress:(size_t)bytesSent total:(size_t)totalLength userInfo:(id)userinfo ;
- (void)POSTRequest:(OFPOSTRequest*)request didCancel:(id)userinfo;
- (void)POSTRequest:(OFPOSTRequest*)request didTimeout:(id)userinfo;
@end

@implementation OFFlickrUploader
+ (id)uploaderWithContext:(OFFlickrContext*)context delegate:(id)aDelegate
{
	return [OFFlickrUploader uploaderWithContext:context delegate:aDelegate timeoutInterval:0];
}
+ (id)uploaderWithContext:(OFFlickrContext*)context delegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval
{
	return [[[OFFlickrUploader alloc] initWithContext:context delegate:aDelegate timeoutInterval:interval] autorelease];
}
- (id)initWithContext:(OFFlickrContext*)context delegate:(id)aDelegate
{
	return [self initWithContext:context delegate:aDelegate timeoutInterval:0];
}
- (id)initWithContext:(OFFlickrContext*)context delegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval
{
	if ((self = [super init])) {
		_delegate = [aDelegate retain];
		_context = [context retain];
		_request = [[OFPOSTRequest requestWithDelegate:self timeoutInterval:interval] retain];
	}
	return self;
}
- (BOOL)uploadWithData:(NSData*)data filename:(NSString*)filename photoInformation:(NSDictionary*)photoinfo userInfo:(id)userinfo
{
	NSURL *uploadurl = [NSURL URLWithString:[_context uploadURL]];
	NSData *uploaddata = [_context prepareUploadData:data filename:filename information:photoinfo];
	
	return [_request POSTRequest:uploadurl data:uploaddata separator:[OFFlickrContext POSTDataSeparator] userInfo:userinfo];
}
- (BOOL)uploadWithContentsOfFile:(NSString*)filename photoInformation:(NSDictionary*)photoinfo userInfo:(id)userinfo
{
	return [self uploadWithData:[NSData dataWithContentsOfFile:filename] filename:filename photoInformation:photoinfo userInfo:userinfo];
}
- (BOOL)isClosed
{
	return [_request isClosed];
}
- (void)cancel
{
	if (![_request isClosed]) [_request cancel];
}
- (OFFlickrContext*)context
{
	return _context;
}
@end

@implementation OFFlickrUploader (OFFlickrUploaderInternals)
- (void)dealloc
{
	if (_delegate) [_delegate release];
	if (_request) {
		if (![_request isClosed]) [_request cancel];
		[_request release];
	}
	if (_context) [_context release];
	[super dealloc];
}
- (void)POSTRequest:(OFPOSTRequest*)request didComplete:(NSData*)response userInfo:(id)userinfo
{
	int errcode = 0;
	id errmsg = nil;
	BOOL err = NO;

	NSXMLDocument *xmldoc = [[NSXMLDocument alloc] initWithData:response options:NSXMLDocumentXMLKind error:&errmsg];
	if (!xmldoc) {
		err = YES;
		errcode = OFXMLDocumentMalformed;
	}
	else {
		err = [xmldoc hasFlickrError:&errcode message:&errmsg];
	}

	if (err) {
		if ([_delegate respondsToSelector:@selector(flickrUploader:errorCode:errorInfo:userInfo:)])
		{
			[_delegate flickrUploader:self errorCode:errcode errorInfo:errmsg userInfo:userinfo];
		}
	}
	else {
		// extract the returned <photoid>id</photoid> tag
		NSXMLElement *e = [[xmldoc nodesForXPath:@"/rsp/photoid" error:nil] objectAtIndex:0];
		NSString *pid = [e stringValue];

		if ([_delegate respondsToSelector:@selector(flickrUploader:didComplete:userInfo:)]) {
			[_delegate flickrUploader:self didComplete:pid userInfo:userinfo];
		}	
	}
}
- (void)POSTRequest:(OFPOSTRequest*)request error:(CFStreamError)errinfo userInfo:(id)userinfo
{
	if ([_delegate respondsToSelector:@selector(flickrUploader:errorCode:errorInfo:userInfo:)])
	{
		NSValue *errinfo = [NSValue valueWithBytes:&errinfo objCType:@encode(CFStreamError)];
		[_delegate flickrUploader:self errorCode:OFConnectionError errorInfo:errinfo userInfo:userinfo];
	}

}
- (void)POSTRequest:(OFPOSTRequest*)request progress:(size_t)bytesSent total:(size_t)totalLength userInfo:(id)userinfo
{
	if ([_delegate respondsToSelector:@selector(flickrUploader:progress:total:userInfo:)])
	{
		[_delegate flickrUploader:self progress:bytesSent total:totalLength userInfo:userinfo];
	}
}
- (void)POSTRequest:(OFPOSTRequest*)request didCancel:(id)userinfo
{
	if ([_delegate respondsToSelector:@selector(flickrUploader:didCancel:)])
	{
		[_delegate flickrUploader:self didCancel:userinfo];
	}
}
- (void)POSTRequest:(OFPOSTRequest*)request didTimeout:(id)userinfo
{
	if ([_delegate respondsToSelector:@selector(flickrUploader:errorCode:errorInfo:userInfo:)])
	{
		[_delegate flickrUploader:self errorCode:OFConnectionTimeout errorInfo:nil userInfo:userinfo];
	}
}
@end

