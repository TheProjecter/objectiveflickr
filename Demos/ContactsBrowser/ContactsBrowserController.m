#import "ContactsBrowserController.h"
#import "LoginSheetController.h"

@implementation ContactsBrowserController
- (void)dealloc
{
	if (_apicall) [_apicall release];
	[super dealloc];
}
- (void)obtainContacts:(OFFlickrAPICaller*)caller errorCode:(int)errcode data:(id)data
{
	[progressIndicator stopAnimation:self];

	if (errcode) {
		NSLog(@"error! code=%d, message=%@", errcode, data);
		return;
	}
	
	[_contacts release];
	
	id ca = [[[data flickrDictionaryFromDocument] objectForKey:@"contacts"] objectForKey:@"contact"];
	
	// chances are there is no such thing, or there is only one contact
	if (!ca) {
		_contacts = [[NSArray array] retain];
	}
	else if ([ca isKindOfClass:[NSDictionary class]]) {
		_contacts = [[NSArray arrayWithObject:ca] retain];
	}
	else {
		_contacts = [[NSArray arrayWithArray:ca] retain];
	}
	
	NSLog(@"contacts obtained! data=%@", [_contacts description]);
	[contactsList reloadData];
}
- (void)flickrAPICaller:(OFFlickrAPICaller*)caller progress:(size_t)receivedBytes expectedTotal:(size_t)total
{
	NSLog(@"contactsBrowser, progress %ld of %ld", receivedBytes, total);
}
- (void)startBrowser
{
	NSDictionary *token = [sheetController token];
	NSLog(@"browser started, token info = %@", [token description]);
	
	_contacts = [[NSArray array] retain];
	[contactsList setDataSource:self];
	[contactsList setDelegate:self];
	
	[[self window] setTitle:[NSString stringWithFormat:@"Contacts of %@", 
		[[[token objectForKey:@"auth"] objectForKey:@"user"] objectForKey:@"@fullname"]
		]];
		
	_apicall = [OFFlickrAPICaller callerWithDelegate:self context:[[NSApp delegate] context]];
	[_apicall retain];
	
	[progressIndicator startAnimation:self];
	[_apicall setSelector:@selector(obtainContacts:errorCode:data:)];
	[_apicall flickr_contacts_getList];
}
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [_contacts count];
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *realname = [[_contacts objectAtIndex:rowIndex] objectForKey:@"@realname"];
	if (![realname length]) realname = [[_contacts objectAtIndex:rowIndex] objectForKey:@"@username"];
	return realname;
}
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	NSDictionary *d = [_contacts objectAtIndex:rowIndex];

	NSString *un = [d objectForKey:@"@username"];
	NSString *rn = [d objectForKey:@"@realname"];
	NSString *fr = [d objectForKey:@"@friend"];
	NSString *fa = [d objectForKey:@"@family"];

	[labelUserName setStringValue:un];
	[labelRealName setStringValue:rn];
	[labelFriend setStringValue:[fr isEqualToString:@"1"] ? @"yes" : @"no"];
	[labelFamily setStringValue:[fa isEqualToString:@"1"] ? @"yes" : @"no"];

	return YES;
}
@end
