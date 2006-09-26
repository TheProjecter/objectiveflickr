#import "ObjectiveFlickr.h"

static NSSet *ofRequiresSignSet = nil;
static NSSet *ofRequiresAuthSet = nil;		// anything requires auth requires sign
static NSSet *ofRequiresPOSTSet = nil;

NSSet *OFGetRequireSignSet() {
	if (ofRequiresSignSet) return ofRequiresSignSet;
	
	ofRequiresSignSet = [NSSet setWithObjects:
		@"flickr.auth.getFrob", 
		nil];
		
	[ofRequiresSignSet retain];
	return ofRequiresSignSet;
}


NSSet *OFGetRequirePOSTSet() {
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

NSSet *OFGetRequireAuthSet() {
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


NSArray *OFParseSelectorString(const char *selname)
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



@implementation OFFlickrAPICaller
+ (OFFlickrAPICaller*)callerWithDelegate:(id)aDelegate context:(OFFlickrApplicationContext*)context timeoutInterval:(NSTimeInterval)interval
{
	return [[[OFFlickrAPICaller alloc] initWithDelegate:aDelegate context:context timeoutInterval:OFAPIDefaultTimeoutInterval] autorelease];
}
+ (OFFlickrAPICaller*)callerWithDelegate:(id)aDelegate context:(OFFlickrApplicationContext*)context
{
	return [OFFlickrAPICaller callerWithDelegate:aDelegate context:context timeoutInterval:OFAPIDefaultTimeoutInterval];
}
- (OFFlickrAPICaller*)initWithDelegate:(id)aDelegate context:(OFFlickrApplicationContext*)context timeoutInterval:(NSTimeInterval)interval
{
	if ((self = [super init])) {
		_delegate = [aDelegate retain];
		_selector = nil;
		_context = [context retain];
		_userInfo = nil;
		_timeoutInterval = interval;
		_currentRequest = nil;
	}

	return self;
}
- (OFFlickrAPICaller*)initWithDelegate:(id)aDelegate context:(OFFlickrApplicationContext*)context
{
	return [self initWithDelegate:aDelegate context:context timeoutInterval:OFAPIDefaultTimeoutInterval];
}
- (void)dealloc
{
	if (_userInfo) [_userInfo release];
	if (_context) [_context release];
	if (_delegate) [_delegate release];
	[super dealloc];
}
- (void)setUserInfo:(id)userinfo
{
	if (_userInfo) [_userInfo release];
	if (userinfo) _userInfo = [userinfo retain]; else _userInfo = nil;
}
- (id)userInfo 
{
	return _userInfo;
}
- (void)setSelector:(SEL)aSelector
{
	_selector = aSelector;
	if (![_delegate respondsToSelector:_selector]) _selector = nil;
}
- (OFFlickrApplicationContext*)context
{
	return _context;
}
- (NSString*)combineStringWithComma:(NSArray*)array;
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
- (id)cancel
{
	if (_currentRequest) [_currentRequest cancel];
}
- (BOOL)callMethod:(NSString*)method arguments:(NSArray*)args
{
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:
		[self prepareParameterDictionary:args]];

	BOOL auth = NO;
	BOOL sign = NO;
	BOOL post = NO;

	if ([OFGetRequireSignSet() containsObject:method]) sign = YES;
	if ([OFGetRequireAuthSet() containsObject:method]) auth = YES;
	if ([OFGetRequirePOSTSet() containsObject:method]) post = YES;
	
	if (auth) sign = YES;

	NSLog(@"method %@, auth = %@, sign = %@, use HTTP POST = %@", method,
		auth ? @"YES" : @"NO",
		sign ? @"YES" : @"NO",
		post ? @"YES" : @"NO");
	
	if ([d objectForKey:@"auth"]) {
		auth = YES;
		[d removeObjectForKey:@"auth"];
	}
	
	[d setObject:method forKey:@"method"];
	
	OFFlickrRESTRequest *request = [OFFlickrRESTRequest requestWithDelegate:self timeoutInterval:_timeoutInterval];

	BOOL r=NO;
	
	if (post) {
		r = [request POSTRequest:[_context RESTAPIEndPoint] data:[_context prepareRESTPOSTData:d authentication:auth sign:sign] userInfo:nil];
	}
	else {
		r = [request GETRequest:[_context prepareRESTGETURL:d authentication:auth sign:sign] userInfo:nil];
	}
	
	_currentRequest = nil;
	if (!r) return NO;
	
	[request retain];
	_currentRequest = request;

	return YES;
}
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request didCancel:(id)userinfo
{
	NSString *errmsg = nil;
	int errcode = OFAPICallCanceled;
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
		if ([_delegate respondsToSelector:@selector(flickrAPICaller:error:errorInfo:)]) {
			[_delegate flickrAPICaller:self error:OFAPICallCanceled errorInfo:nil];
		}
	}
	[request autorelease];
	_currentRequest = nil;
}
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request didFetchData:(NSXMLDocument*)xmldoc userInfo:(id)userinfo
{
	int errcode = 0;
	NSString *errmsg;
	BOOL err;
	err = [xmldoc hasFlickrError:&errcode message:&errmsg];

//  - (void)caller:(OFFlickrAPICaller*)caller error:(int)errorNo data:(id)data
	
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
			if ([_delegate respondsToSelector:@selector(flickrAPICaller:error:errorInfo:)]) {
				[_delegate flickrAPICaller:self error:errcode errorInfo:errmsg];
			}
		}
		else {
			if ([_delegate respondsToSelector:@selector(flickrAPICaller:didFetchData:)]) {
				[_delegate flickrAPICaller:self didFetchData:xmldoc];
			}	
		}
	}

	[request autorelease];
	_currentRequest = nil;
}
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request error:(int)errcode errorInfo:(id)errinfo userInfo:(id)userinfo
{
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
		if ([_delegate respondsToSelector:@selector(flickrAPICaller:error:errorInfo:)]) {
			[_delegate flickrAPICaller:self error:errcode errorInfo:errinfo];
		}
	}
	[request autorelease];
	_currentRequest = nil;
}
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request progress:(size_t)receivedBytes expectedTotal:(size_t)total userInfo:(id)userinfo
{
	_currentRequest = request;
	if ([_delegate respondsToSelector:@selector(flickrAPICaller:progress:expectedTotal:)]) {
		[_delegate flickrAPICaller:self progress:receivedBytes expectedTotal:total];
	}
}



-(NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector
{
	const char *selname = sel_getName(aSelector);
	unsigned c = [OFParseSelectorString(selname) count];
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
	
    NSLog(@"NSMethodSignature! selname=%s sig=%@", selname, sig);
    return [NSMethodSignature signatureWithObjCTypes:[sig UTF8String]];
}
-(void)forwardInvocation:(NSInvocation*)inv
{
    NSLog(@"method invocation, detail=%@", [inv description]);

	const char *selname = sel_getName([inv selector]);
	NSArray *selarray = OFParseSelectorString(selname);

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
