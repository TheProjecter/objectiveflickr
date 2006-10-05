#import <Cocoa/Cocoa.h>

@interface OFPOSTRequest : NSObject
{
	id _delegate;
	NSTimeInterval _timeoutInterval;

	id _userInfo;
	size_t _dataSize;
	size_t _bytesSent;
	CFReadStreamRef _stream;
	NSMutableData *_response;
	NSTimer *_progressTicker;
	NSTimer *_timeoutTimer;
}
+ (id)requestWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)timeoutInterval;
- (id)initWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)timeoutInterval;
- (BOOL)isClosed;
- (void)cancel;
- (BOOL)POSTRequest:(NSURL*)url data:(NSData*)data separator:(NSString*)separator userInfo:(id)userinfo;
@end

@interface NSObject (OFPOSTRequestDelegate)
- (void)POSTRequest:(OFPOSTRequest*)request didComplete:(NSData*)response userInfo:(id)userinfo;
- (void)POSTRequest:(OFPOSTRequest*)request error:(CFStreamError)errinfo userInfo:(id)userinfo;
- (void)POSTRequest:(OFPOSTRequest*)request progress:(size_t)bytesSent total:(size_t)totalLength userInfo:(id)userinfo ;
- (void)POSTRequest:(OFPOSTRequest*)request didCancel:(id)userinfo;
- (void)POSTRequest:(OFPOSTRequest*)request didTimeout:(id)userinfo;
@end
