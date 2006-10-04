#import <ObjectiveFlickr/OFHTTPRequest.h>

@interface OFHTTPRequest(OFHTTPRequestInternals)
- (void)dealloc;
- (void)reset;
- (void)internalCancel;
- (void)handleTimeout:(NSTimer*)timer;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
@end

@implementation OFHTTPRequest
+ (OFHTTPRequest*)requestWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval
{
	return [[[OFHTTPRequest alloc] initWithDelegate:aDelegate timeoutInterval:interval] autorelease];
}
- (OFHTTPRequest*)initWithDelegate:(id)aDelegate timeoutInterval:(NSTimeInterval)interval
{
	if ((self = [super init])) {
		_delegate = [aDelegate retain];
		_timeoutInterval = (interval > 0) ? interval : OFHTTPDefaultTimeoutInterval;
		
		_closed = YES;
		_connection = nil;
		_timer = nil;
		_userInfo = nil;
		_expectedLength = 0;
		_receivedData = nil;
	}
	return self;
}
- (BOOL)isClosed {
	return _closed;
}
- (void)cancel {
	if (!_closed) return;
	[self internalCancel];
	
	if ([_delegate respondsToSelector:@selector(HTTPRequest:didCancel:)]) {
		[_delegate HTTPRequest:self didCancel:_userInfo];
	}
}
- (BOOL)GET:(NSString*)url userInfo:(id)info {
	if (!_closed) return NO;

	[self reset];
	_userInfo = [info retain];
	_receivedData = [[NSMutableData data] retain];

	NSURLRequest *req=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:_timeoutInterval];
	_connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	if (!_connection) {
		[self reset];
		return NO;
	}
	
	_timer = [NSTimer scheduledTimerWithTimeInterval:_timeoutInterval target:self selector:@selector(handleTimeout:) userInfo:nil repeats:NO];
	[_timer retain];

	return YES;

}
- (BOOL)POST:(NSString*)url data:(NSData*)data separator:(NSString*)separator userInfo:(id)info
{
	if (!_closed) return NO;

	[self reset];
	_userInfo = [info retain];
	_receivedData = [[NSMutableData data] retain];

	NSMutableURLRequest *req=[[[NSMutableURLRequest alloc] init] autorelease];
	[req setURL:[NSURL URLWithString:url]];
	[req setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[req setTimeoutInterval:_timeoutInterval];
	[req setHTTPMethod:@"POST"];
	
	NSString *header=[NSString stringWithFormat:@"multipart/form-data; boundary=%@", separator];
	[req setValue:header forHTTPHeaderField:@"Content-Type"];
	[req setHTTPBody:data];
	
	_connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	if (!_connection) {
		[self reset];
		return NO;
	}
	
	_timer = [NSTimer scheduledTimerWithTimeInterval:_timeoutInterval target:self selector:@selector(handleTimeout:) userInfo:nil repeats:NO];
	return YES;
}
@end

@implementation OFHTTPRequest(OFHTTPRequestInternals)
- (void)dealloc {
	if (_delegate) [_delegate release];
	if (_connection) [_connection release];
	if (_timer) [_timer release];
	if (_userInfo) [_userInfo release];
	if (_receivedData) [_receivedData release];
	[super dealloc];
}
- (void)internalCancel
{
	[_connection cancel];
	[_timer invalidate];
	_closed = YES;	
}
- (void)reset {
	if (!_closed) [self cancel];
	
	_closed = YES;
	_expectedLength = 0;

	if (_connection) {
		[_connection release];
		_connection = nil;
	}
	if (_timer) {
		if ([_timer isValid]) {
			[_timer invalidate];
		}
		[_timer release];
		_timer = nil;
	}
	if (_userInfo) {
		[_userInfo release];
		_userInfo = nil;
	}
	if (_receivedData) {
		[_receivedData release];
		_receivedData = nil;
	}
}
- (void)handleTimeout:(NSTimer*)timer
{
	if ([_delegate respondsToSelector:@selector(HTTPRequest:didTimeout:)]) {
		[_delegate HTTPRequest:self didTimeout:_userInfo];
	}
	
	[_connection internalCancel];
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[_receivedData setLength:0];
	_expectedLength = (size_t)[response expectedContentLength];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_receivedData appendData:data];
	if ([_delegate respondsToSelector:@selector(HTTPRequest:progress:expectedTotal:userInfo:)]) {
		[_delegate HTTPRequest:self progress:[_receivedData length] expectedTotal:_expectedLength userInfo:_userInfo];
	}
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (_timer) [_timer invalidate];
	_closed = YES;

	if ([_delegate respondsToSelector:@selector(HTTPRequest:didFetchData:userInfo:)]) {
		[_delegate HTTPRequest:self didFetchData:_receivedData userInfo:_userInfo];
	}
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (_timer) [_timer invalidate];
	_closed = YES;

	if ([_delegate respondsToSelector:@selector(HTTPRequest:error:errorInfo:userInfo:)]) {
		[_delegate HTTPRequest:self error:error errorInfo:error userInfo:_userInfo];
	}
}
@end
