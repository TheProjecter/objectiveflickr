#import <ObjectiveFlickr/ObjectiveFlickr.h>

// Class OFFlickrUploader handles photo uploading
@interface OFFlickrUploader : NSObject
{
	id _request;
}
- (id)initWithDelegate:(id)aDelegate;
- (BOOL)upload:(NSData*)data filename:(NSString*)filename photoInformation:(NSDictionary*)photoinfo applicationContext:(OFFlickrContext*)context userInfo:(id)userinfo;
- (BOOL)uploadWithContentsOfFile:(NSString*)filename photoInformation:(NSDictionary*)photoinfo applicationContext:(OFFlickrContext*)context userInfo:(id)userinfo;
- (BOOL)isClosed;
- (void)cancel;
@end

@interface NSObject(OFFlickrUploaderDelegate)
- (void)flickrUploader:(OFFlickrUploader*)uploader didComplete:(NSXMLDocument*)response userInfo:(id)userinfo;
- (void)flickrUploader:(OFFlickrUploader*)uploader error:(int)code errorInfo:(id)errinfo userInfo:(id)userinfo;
- (void)flickrUploader:(OFFlickrUploader*)uploader progress:(size_t)length total:(size_t)totalLength userInfo:(id)userinfo;
- (void)flickrUploader:(OFFlickrUploader*)uploader didCancel:(id)userinfo;
@end
