#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface OFFlickrUploader : NSObject
{
	id _delegate;
	id _request;
	id _context;
}
+ (id)uploaderWithContext:(OFFlickrContext*)context delegate:(id)aDelegate;
+ (id)uploaderWithContext:(OFFlickrContext*)context delegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval;
- (id)initWithContext:(OFFlickrContext*)context delegate:(id)aDelegate;
- (id)initWithContext:(OFFlickrContext*)context delegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval;
- (BOOL)uploadWithData:(NSData*)data filename:(NSString*)filename photoInformation:(NSDictionary*)photoinfo userInfo:(id)userinfo;
- (BOOL)uploadWithContentsOfFile:(NSString*)filename photoInformation:(NSDictionary*)photoinfo userInfo:(id)userinfo;
- (BOOL)isClosed;
- (void)cancel;
@end

@interface NSObject (OFFlickrUploaderDelegate)
- (void)flickrUploader:(OFFlickrUploader*)uploader didComplete:(NSString*)callbackID userInfo:(id)userinfo;
- (void)flickrUploader:(OFFlickrUploader*)uploader errorCode:(int)errcode errorInfo:(id)errinfo userInfo:(id)userinfo;
- (void)flickrUploader:(OFFlickrUploader*)uploader progress:(size_t)bytesSent total:(size_t)totalLength userInfo:(id)userinfo;
- (void)flickrUploader:(OFFlickrUploader*)uploader didCancel:(id)userinfo;
@end
