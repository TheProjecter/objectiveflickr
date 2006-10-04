#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface OFFlickrInvocation (OFFlickrInvocationInternals)
- (void)dealloc;
- (NSString*)combineStringWithComma:(NSArray*)array;
- (NSDictionary*)prepareParameterDictionary:(NSArray*)array;
@end

@interface OFFlickrInvocation (OFFlickrInvocationUtility)
+ (NSSet*)getRequiresSignSet;
+ (NSSet*)getRequiresPOSTSet;
+ (NSSet*)getRequiresAuthSet;	// anything requires auth requires sign (the reverse not necessarily true)
+ (NSArray*)parseSelectorString:(const char *)selname;
@end

@interface OFFlickrInvocation (OFFlickrInvocationCallbacks)
- (void)HTTPRequest:(OFHTTPRequest*)request didCancel:(id)userinfo;
- (void)HTTPRequest:(OFHTTPRequest*)request didFetchData:(NSData*)data userInfo:(id)userinfo;
- (void)HTTPRequest:(OFHTTPRequest*)request didTimeout:(id)userinfo;
- (void)HTTPRequest:(OFHTTPRequest*)request error:(NSError*)err userInfo:(id)userinfo;
- (void)HTTPRequest:(OFHTTPRequest*)request progress:(size_t)receivedBytes expectedTotal:(size_t)total userInfo:(id)userinfo;
@end

@interface OFFlickrInvocation (OFFlickrInvocationHack)
-(NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector;
-(void)forwardInvocation:(NSInvocation*)inv;
@end

@implementation OFFlickrInvocation
+ (OFFlickrInvocation*)invocationWithContext:(OFFlickrContext*)context
{
	return [[[OFFlickrInvocation alloc] initWithContext:context] autorelease];
}
+ (OFFlickrInvocation*)invocationWithContext:(OFFlickrContext*)context timeoutInterval:(NSTimeInterval)interval
{
	return [[[OFFlickrInvocation alloc] initWithContext:context timeoutInterval:interval] autorelease];

}
- (OFFlickrInvocation*)initWithContext:(OFFlickrContext*)context
{
	return [self initWithContext:context timeoutInterval:OFDefaultTimeoutInterval];
}
- (OFFlickrInvocation*)initWithContext:(OFFlickrContext*)context timeoutInterval:(NSTimeInterval)interval
{
	if ((self = [super init])) {
		_context = [context retain];
		_request = [[OFHTTPRequest requestWithDelegate:self timeoutInterval:interval] retain];
		_selector = nil;
		_delegate = nil;
		_userInfo = nil;
	}
	return self;
}
- (id)delegate 
{
	return _delegate;
}
- (void)setDelegate:(id)aDelegate
{
	id tmp = [aDelegate retain];
	if (_delegate) [_delegate release];
	_delegate = tmp;
}
- (void)setSelector:(SEL)aSelector
{
	_selector = nil;
	if (_delegate) {
		if ([_delegate respondsToSelector:aSelector]) _selector = aSelector;
	}
}
- (id)userInfo
{
	return _userInfo;
}
- (void)setUserInfo:(id)userinfo
{
	id tmp = [userinfo retain];
	if (_userInfo) [_userInfo release];
	_userInfo = tmp;
}
- (OFFlickrContext*)context
{
	return _context;
}
- (void)cancel
{
	if ([self isClosed]) return;
	[_request cancel];
}
- (BOOL)isClosed
{
	return [_request isClosed];
}
- (BOOL)callMethod:(NSString*)method arguments:(NSArray*)parameter
{
	if (![self isClosed]) return NO;

	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:[self prepareParameterDictionary:parameter]];
	BOOL auth = NO;
	BOOL sign = NO;
	BOOL post = NO;

	if ([[OFFlickrInvocation getRequiresSignSet] containsObject:method]) sign = YES;
	if ([[OFFlickrInvocation getRequiresAuthSet] containsObject:method]) auth = YES;
	if ([[OFFlickrInvocation getRequiresPOSTSet] containsObject:method]) post = YES;
	
	NSLog(@"invoking method %@, use auth = %@, signed = %@, use HTTP POST = %@", method,
		auth ? @"YES" : @"NO",
		sign ? @"YES" : @"NO",
		post ? @"YES" : @"NO");
	
	if ([d objectForKey:@"auth"]) {
		auth = YES;
		[d removeObjectForKey:@"auth"];
	}

	if (auth) sign = YES;
	
	[d setObject:method forKey:@"method"];
	
	BOOL r=NO;
	
	if (post) {
		return [_request POST:[_context RESTAPIEndPoint] data:[_context prepareRESTPOSTData:d authentication:auth sign:sign] separator:[OFFlickrContext POSTDataSeparator] userInfo:nil];
	}
	else {
		return [_request GET:[_context prepareRESTGETURL:d authentication:auth sign:sign] userInfo:nil];
	}

}
- (BOOL)callMethod:(NSString*)method arguments:(NSArray*)parameter delegate:(id)aDelegate selector:(SEL)aSelector
{
	[self setDelegate:aDelegate];
	[self setSelector:aSelector];
	return [self callMethod:method arguments:parameter];
}
@end

@implementation OFFlickrInvocation (OFFlickrInvocationInternals)
- (void)dealloc
{
	if (_request) [_request release];
	if (_context) [_context release];
	if (_delegate) [_delegate release];
	if (_userInfo) [_userInfo release];
	[super dealloc];
}
- (NSString*)combineStringWithComma:(NSArray*)array
{
	NSMutableString *s=[NSMutableString string];
	unsigned i, c=[array count];
	if (!c) return s;
	
	for (i=0; i<c; i++) {
		[s appendString: [NSString stringWithFormat:((i==c-1) ? @"%@" : @"%@,"), [array objectAtIndex:i]]];
	}
	return s;
}
- (NSDictionary*)prepareParameterDictionary:(NSArray*)array
{
	NSMutableDictionary *d=[NSMutableDictionary dictionary];
	if (!array) return d;
	
	unsigned i, c=[array count];
	if (!c) return d;
	
	for (i=0; i<c; i++) {
		NSString *key = [array objectAtIndex:i];
		id value;
		
		i++;
		value = ((i == c) ? @"" : [array objectAtIndex:i]);
		
		if ([value isKindOfClass:[NSArray class]]) {
			value = [self combineStringWithComma:value];
		}
		[d setObject:value forKey:key];
	}
	return d;
}
@end

@implementation OFFlickrInvocation (OFFlickrInvocationCallbacks)
- (void)HTTPRequest:(OFHTTPRequest*)request didCancel:(id)userinfo
{
	NSLog(@"HTTPRequest didCancel");

	NSString *errmsg = nil;
	int errcode = OFConnectionCanceled;
	if (_selector) {
		// we can be quote sure this works only if _delegate reponses to _selector
		NSMethodSignature *sig = [_delegate methodSignatureForSelector:_selector];
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
		[inv setArgument:&_delegate atIndex:0];
		[inv setArgument:&_selector atIndex:1];
		[inv setArgument:&self atIndex:2];
		[inv setArgument:&errcode atIndex:3];
		[inv setArgument:&errmsg atIndex:4];
		[inv invokeWithTarget:_delegate];
	}
	else {
		if ([_delegate respondsToSelector:@selector(flickrInvocation:errorCode:errorInfo:)]) {
			[_delegate flickrInvocation:self errorCode:errcode errorInfo:errmsg];
		}
	}
}
- (void)HTTPRequest:(OFHTTPRequest*)request didFetchData:(NSData*)data userInfo:(id)userinfo
{
	// NSLog(@"HTTPRequest didFetchData");

	int errcode = 0;
	id errmsg = nil;
	BOOL err = NO;
	
	NSXMLDocument *xmldoc = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentXMLKind error:&errmsg];
	if (!xmldoc) {
		err = YES;
		errcode = OFXMLDocumentMalformed;
	}
	else {
		err = [xmldoc hasFlickrError:&errcode message:&errmsg];
	}

	if (_selector) {
		// we can be quote sure this works only if _delegate reponses to _selector
		NSMethodSignature *sig = [_delegate methodSignatureForSelector:_selector];
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
		[inv setArgument:&_delegate atIndex:0];
		[inv setArgument:&_selector atIndex:1];
		[inv setArgument:&self atIndex:2];
		[inv setArgument:&errcode atIndex:3];
		if (err) [inv setArgument:&errmsg atIndex:4]; else [inv setArgument:&xmldoc atIndex:4];
		[inv invokeWithTarget:_delegate];
	}
	else {
		if (err) {
			if ([_delegate respondsToSelector:@selector(flickrInvocation:errorCode:errorInfo:)]) {
				[_delegate flickrInvocation:self errorCode:errcode errorInfo:errmsg];
			}
		}
		else {
			if ([_delegate respondsToSelector:@selector(flickrInvocation:didFetchData:)]) {
				[_delegate flickrInvocation:self didFetchData:xmldoc];
			}	
		}
	}
}
- (void)HTTPRequest:(OFHTTPRequest*)request didTimeout:(id)userinfo
{
	// NSLog(@"HTTPRequest didTimeout");

	int errcode = OFConnectionTimeout;
	id errinfo = nil;
	if (_selector) {
		// we can be quote sure this works only if _delegate reponses to _selector
		NSMethodSignature *sig = [_delegate methodSignatureForSelector:_selector];
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
		[inv setArgument:&_delegate atIndex:0];
		[inv setArgument:&_selector atIndex:1];
		[inv setArgument:&self atIndex:2];
		[inv setArgument:&errcode atIndex:3];
		[inv setArgument:&errinfo atIndex:4];
		[inv invokeWithTarget:_delegate];
	}
	else {
		if ([_delegate respondsToSelector:@selector(flickrInvocation:errorCode:errorInfo:)]) {
			[_delegate flickrInvocation:self errorCode:errcode errorInfo:errinfo];
		}
	}
}
- (void)HTTPRequest:(OFHTTPRequest*)request error:(NSError*)err userInfo:(id)userinfo
{
	// NSLog(@"HTTPRequest error");

	int errcode = OFConnectionError;
	id errinfo = err;
	if (_selector) {
		// we can be quote sure this works only if _delegate reponses to _selector
		NSMethodSignature *sig = [_delegate methodSignatureForSelector:_selector];
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
		[inv setArgument:&_delegate atIndex:0];
		[inv setArgument:&_selector atIndex:1];
		[inv setArgument:&self atIndex:2];
		[inv setArgument:&errcode atIndex:3];
		[inv setArgument:&errinfo atIndex:4];
		[inv invokeWithTarget:_delegate];
	}
	else {
		if ([_delegate respondsToSelector:@selector(flickrInvocation:errorCode:errorInfo:)]) {
			[_delegate flickrInvocation:self errorCode:errcode errorInfo:errinfo];
		}
	}
}
- (void)HTTPRequest:(OFHTTPRequest*)request progress:(size_t)receivedBytes expectedTotal:(size_t)total userInfo:(id)userinfo
{
	// NSLog(@"HTTPRequest progress");

	if ([_delegate respondsToSelector:@selector(flickrInvocation:progress:expectedTotal:)]) {
		[_delegate flickrInvocation:self progress:receivedBytes expectedTotal:total];
	}
}
@end

@implementation OFFlickrInvocation (OFFlickrInvocationHack)
-(NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector
{
	const char *selname = sel_getName(aSelector);
	unsigned c = [[OFFlickrInvocation parseSelectorString:selname] count];
	int l = c + 4;
	char *s = (char*)malloc(l);
	int i;
	for (i = 3; i < c+3 ; i++) s[i] = '@';
	s[0]='@';
	s[1]='@';
	s[2]=':';
	s[c+3] = 0;
	NSString *sig = [NSString stringWithUTF8String:s];
	free(s);
	
    // NSLog(@"NSMethodSignature! selname=%s sig=%@", selname, sig);
    return [NSMethodSignature signatureWithObjCTypes:[sig UTF8String]];
}
-(void)forwardInvocation:(NSInvocation*)inv
{
    NSLog(@"method invocation, detail=%@", [inv description]);

	const char *selname = sel_getName([inv selector]);
	NSArray *selarray = [OFFlickrInvocation parseSelectorString:selname];

	NSLog(@"method invocation, selname=%s, array=%@", selname, [selarray description]);

	NSMutableArray *param = [NSMutableArray array];
	
	unsigned i, c = [selarray count];
	
	NSString *methodname;
	
	id arg;
	if (c > 0) {
		methodname = [selarray objectAtIndex:0];
		[inv getArgument:&arg atIndex:2];
		[self setUserInfo:arg];
		NSLog(@"has user info = %@", arg);
	}
	else {
		methodname = [NSString stringWithUTF8String:selname];
	}
	
	// replace every _ to .
	char *repstr = (char*)malloc(strlen([methodname UTF8String] + 1));
	strcpy(repstr, [methodname UTF8String]);
	char *rp = repstr;
	while (*rp) {
		if (*rp == '_') *rp = '.';
		rp++;
	}
	methodname = [NSString stringWithUTF8String:repstr];
	
	for (i = 1; i < c; i++) {
		[param addObject:[selarray objectAtIndex:i]];		
		[inv getArgument:&arg atIndex:2+i];
		[param addObject:arg];
	}
	
	NSLog(@"finished prepared, method = %@, argument = %@", methodname, [param description]);

	BOOL r;
	r = [self callMethod:methodname arguments:param];
	if (r)  [inv setReturnValue:&self];
}
@end

@implementation OFFlickrInvocation (OFFlickrInvocationUtility)
+ (NSSet*)getRequiresSignSet
{
	static NSSet *ofRequiresSignSet = nil;

	if (ofRequiresSignSet) return ofRequiresSignSet;
	
	ofRequiresSignSet = [NSSet setWithObjects:
		@"flickr.auth.getFrob", 
		nil];
		
	[ofRequiresSignSet retain];
	return ofRequiresSignSet;
}
+ (NSSet*)getRequiresPOSTSet
{
	static NSSet *ofRequiresPOSTSet = nil;		

	if (ofRequiresPOSTSet) return ofRequiresPOSTSet;
	
	ofRequiresPOSTSet = [NSSet setWithObjects:
		@"flickr.blogs.postPhoto", 
		@"flickr.favorites.add", 
		@"flickr.favorites.remove", 
		@"flickr.groups.pools.add", 
		@"flickr.groups.pools.remove", 
		@"flickr.photos.addTags", 
		@"flickr.photos.delete", 
		@"flickr.photos.removeTag", 
		@"flickr.photos.setDates", 
		@"flickr.photos.setMeta", 
		@"flickr.photos.setPerms", 
		@"flickr.photos.setTags", 
		@"flickr.photos.comments.addComment", 
		@"flickr.photos.comments.deleteComment", 
		@"flickr.photos.comments.editComment", 
		@"flickr.photos.geo.removeLocation", 
		@"flickr.photos.geo.setLocation", 
		@"flickr.photos.geo.setPerms", 
		@"flickr.photos.licenses.setLicense", 
		@"flickr.photos.notes.add", 
		@"flickr.photos.notes.delete", 
		@"flickr.photos.notes.edit", 
		@"flickr.photos.transform", 
		@"flickr.photosets.addPhoto", 
		@"flickr.photosets.create", 
		@"flickr.photosets.delete", 
		@"flickr.photosets.editMeta", 
		@"flickr.photosets.editPhotos", 
		@"flickr.photosets.orderSets", 
		@"flickr.photosets.removePhoto", 
		@"flickr.photosets.comments.addComment", 
		@"flickr.photosets.comments.deleteComment", 
		@"flickr.photosets.comments.editComment", 
		nil];
		
	[ofRequiresPOSTSet retain];
	return ofRequiresPOSTSet;
}
+ (NSSet*)getRequiresAuthSet
{
	static NSSet *ofRequiresAuthSet = nil;

	if (ofRequiresAuthSet) return ofRequiresAuthSet;
	
	ofRequiresAuthSet = [NSSet setWithObjects:
		@"flickr.auth.checkToken", 
		// @"flickr.auth.getFrob", 
		@"flickr.auth.getFullToken", 
		@"flickr.auth.getToken", 
		@"flickr.blogs.getList", 
		@"flickr.blogs.postPhoto", 
		@"flickr.contacts.getList", 
		// @"flickr.contacts.getPublicList", 
		@"flickr.favorites.add", 
		@"flickr.favorites.getList", 
		// @"flickr.favorites.getPublicList", 
		@"flickr.favorites.remove", 
		@"flickr.groups.browse", 
		// @"flickr.groups.getInfo", 
		// @"flickr.groups.search",			// makes a differnece if auth'ed !
		@"flickr.groups.pools.add", 
		// @"flickr.groups.pools.getContext", 
		@"flickr.groups.pools.getGroups", 
		// @"flickr.groups.pools.getPhotos", 
		@"flickr.groups.pools.remove", 
		// @"flickr.interestingness.getList", 
		// @"flickr.people.findByEmail", 
		// @"flickr.people.findByUserName", 
		// @"flickr.people.getInfo", 
		// @"flickr.people.getPublicGroups", 
		// @"flickr.people.getPublicPhotos", 
		@"flickr.people.getUploadStatus", 
		@"flickr.photos.addTags", 
		@"flickr.photos.delete", 
		// @"flickr.photos.getAllContexts", 
		@"flickr.photos.getContactsPhotos", 
		// @"flickr.photos.getContactsPublicPhotos", 
		// @"flickr.photos.getContext", 
		@"flickr.photos.getCounts", 
		// @"flickr.photos.getExif", 
		// @"flickr.photos.getInfo",		// makes a differnece if auth'ed !
		@"flickr.photos.getNotInSet", 
		@"flickr.photos.getPerms", 
		// @"flickr.photos.getRecent", 
		// @"flickr.photos.getSizes", 
		@"flickr.photos.getUntagged", 
		@"flickr.photos.getWithGeoData", 
		@"flickr.photos.getWithoutGeoData", 
		@"flickr.photos.recentlyUpdated", 
		@"flickr.photos.removeTag", 
		// @"flickr.photos.search",			// makes a differnece if auth'ed !
		@"flickr.photos.setDates", 
		@"flickr.photos.setMeta", 
		@"flickr.photos.setPerms", 
		@"flickr.photos.setTags", 
		@"flickr.photos.comments.addComment", 
		@"flickr.photos.comments.deleteComment", 
		@"flickr.photos.comments.editComment", 
		// @"flickr.photos.comments.getList", 
		// @"flickr.photos.geo.getLocation", 
		@"flickr.photos.geo.getPerms", 
		@"flickr.photos.geo.removeLocation", 
		@"flickr.photos.geo.setLocation", 
		@"flickr.photos.geo.setPerms", 
		// @"flickr.photos.licenses.getInfo", 
		@"flickr.photos.licenses.setLicense", 
		@"flickr.photos.notes.add", 
		@"flickr.photos.notes.delete", 
		@"flickr.photos.notes.edit", 
		@"flickr.photos.transform", 
		// @"flickr.photos.upload.checkTickets", 
		@"flickr.photosets.addPhoto", 
		@"flickr.photosets.create", 
		@"flickr.photosets.delete", 
		@"flickr.photosets.editMeta", 
		@"flickr.photosets.editPhotos", 
		// @"flickr.photosets.getContext", 
		// @"flickr.photosets.getInfo", 
		// @"flickr.photosets.getList", 
		// @"flickr.photosets.getPhotos", 
		@"flickr.photosets.orderSets", 
		@"flickr.photosets.removePhoto", 
		@"flickr.photosets.comments.addComment", 
		@"flickr.photosets.comments.deleteComment", 
		@"flickr.photosets.comments.editComment", 
		// @"flickr.photosets.comments.getList", 
		// @"flickr.reflection.getMethodInfo", 
		// @"flickr.reflection.getMethods", 
		// @"flickr.tags.getListPhoto", 
		// @"flickr.tags.getListUser", 
		// @"flickr.tags.getListUserPopular", 
		//	@"flickr.tags.getRelated", 
		// @"flickr.test.echo", 
		@"flickr.test.login", 
		@"flickr.test.null", 
		// @"flickr.urls.getGroup", 
		// @"flickr.urls.getUserPhotos", 
		// @"flickr.urls.getUserProfile", 
		// @"flickr.urls.lookupGroup", 
		@"flickr.urls.lookupUser", 		
		nil];
		
	[ofRequiresAuthSet retain];
	return ofRequiresAuthSet;
}
+ (NSArray*)parseSelectorString:(const char *)selname
{
	NSMutableArray *a = [NSMutableArray array];
	if (selname[strlen(selname) - 1] != ':') return a;
	
	NSMutableString *current = [NSMutableString string];
	
	const char *p = selname;	
	while (*p) {
		if (*p == ':') {
			[a addObject:current];
			current = [NSMutableString string];
		}
		else {
			[current appendString:[NSString stringWithFormat:@"%c", *p]];
		}
		p++;
	}
	return a;
}
@end
