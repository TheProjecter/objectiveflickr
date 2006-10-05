#import <Cocoa/Cocoa.h>

@interface OFHTTPRequest : NSObject
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
+ (OFHTTPRequest*)requestWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval;
- (OFHTTPRequest*)initWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval;
- (BOOL)isClosed;
- (void)cancel;
- (BOOL)GET:(NSString*)url userInfo:(id)info;
- (BOOL)POST:(NSString*)url data:(NSData*)data separator:(NSString*)separator userInfo:(id)info;
@end

#define OFHTTPDefaultTimeoutInterval  10.0			// 10 seconds

@interface NSObject (OFHTTPReqestDelegate)
- (void)HTTPRequest:(OFHTTPRequest*)request didCancel:(id)userinfo;
- (void)HTTPRequest:(OFHTTPRequest*)request didFetchData:(NSData*)data userInfo:(id)userinfo;
- (void)HTTPRequest:(OFHTTPRequest*)request didTimeout:(id)userinfo;
- (void)HTTPRequest:(OFHTTPRequest*)request error:(NSError*)err userInfo:(id)userinfo;
- (void)HTTPRequest:(OFHTTPRequest*)request progress:(size_t)receivedBytes expectedTotal:(size_t)total userInfo:(id)userinfo;
@end
