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
	[_request cancel];
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

