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
- (BOOL)callMethod:(NSString*)method arguments:(NSArray*)parameter delegate:(id)aDelegate selector:(SEL)aSelector;
@end

@interface NSObject(OFFlickrInvocationDelegate)
- (void)flickrInvocation:(OFFlickrInvocation*)invocation didFetchData:(NSXMLDocument*)xmldoc;
- (void)flickrInvocation:(OFFlickrInvocation*)invocation errorCode:(int)errcode errorInfo:(id)errinfo;
- (void)flickrInvocation:(OFFlickrInvocation*)invocation progress:(size_t)receivedBytes expectedTotal:(size_t)total;
@end
