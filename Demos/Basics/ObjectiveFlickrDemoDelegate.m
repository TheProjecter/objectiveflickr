// ObjectiveFlickr
// 
// Copyright (c) 2004-2006 Lukhnos D. Liu (lukhnos {at} gmail.com)
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Neither the name of ObjectiveFlickr nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.


#import <WebKit/WebKit.h>
#import "ObjectiveFlickrDemoDelegate.h"
#import "OFDemoAPIKey.h"

#ifndef OFDemoAPIKey
	#error Please define your OFDemoAPIKey in DemoAPIKey.h. This file will be ignored by svn in subsequent commits.
	#define OFDemoAPIKey @""
#endif

#ifndef OFDemoSharedSecret
	#error Please define your OFDemoSharedSecret in DemoAPIKey.h. This file will be ignored by svn in subsequent commits.
	#define OFDemoSharedSecret @""
#endif

@implementation ObjectiveFlickrDemoDelegate
- (void)awakeFromNib 
{	
	appContext = [[OFFlickrApplicationContext alloc] initWithAPIKey:OFDemoAPIKey sharedSecret:OFDemoSharedSecret];
	request = [[OFFlickrRESTRequest alloc] initWithDelegate:self timeoutInterval:OFRequestDefaultTimeoutInterval];
	
	frob = nil;
	token = nil;
	photos = [[NSArray array] retain];
	
	uploadFilename=nil;
	
	[photoList setDataSource:self];
	[photoList setDelegate:self];
	[webView setFrameLoadDelegate:self];
}
- (void)dealloc 
{
	if (frob) [frob release];
	if (token) [token release];
	if (photos) [photos release];
	if (uploadFilename) [uploadFilename release];
	[appContext release];
	[request release];
	[super dealloc];
}
- (IBAction)getFrob:(id)sender
{
	[progressIndicator startAnimation:self];

	NSDictionary *param=[NSDictionary dictionaryWithObjectsAndKeys:
		@"flickr.auth.getFrob", @"method", nil];
	NSString *urlstr=[appContext prepareRESTGETURL:param authentication:NO sign:YES];
	[request GETRequest:urlstr userInfo:@"getFrob"];
}
- (IBAction)authenticate:(id)sender
{
	if (!frob) {
		[[NSAlert alertWithMessageText:@"You must get the 'frob' first" 
			defaultButton:@"Go back"
			alternateButton:nil
			otherButton:nil
			informativeTextWithFormat:@"Only after the 'frob' is obtained does the authentication URL become available"
		] runModal];
	}
	
	[getTokenButton setEnabled:YES];
	NSString *authurl=[appContext prepareLoginURL:frob permission:@"write"];
	system([[NSString stringWithFormat:@"open '%@'", authurl] UTF8String]);
	[authenticateButton setEnabled:NO];
}
- (IBAction)getToken:(id)sender
{
	NSDictionary *param=[NSDictionary dictionaryWithObjectsAndKeys:
		@"flickr.auth.getToken", @"method",
		frob, @"frob", nil];
		
	NSString *urlstr=[appContext prepareRESTGETURL:param authentication:NO sign:YES];
	[request GETRequest:urlstr userInfo:@"getToken"];
}
- (BOOL)hasFlickrError:(NSXMLDocument*)doc receiveCode:(int*)code receiveMessage:(NSString**)message 
{
	NSXMLElement *r = [doc rootElement];

	NSXMLNode *stat =[r attributeForName:@"stat"];
	
	if ([[stat stringValue] isEqualToString:@"ok"]) {
		*code = 0;
		*message = nil;
		return NO;
	}
	
	NSXMLNode *e = [r childAtIndex:0];
	NSXMLNode *codestr = [(NSXMLElement*)e attributeForName:@"code"];
	NSXMLNode *msg = [(NSXMLElement*)e attributeForName:@"msg"];
	
	*code = [[codestr stringValue] intValue];
	*message = [NSString stringWithString:[msg stringValue]];
	return YES;
}

- (NSString*)extractToken:(NSXMLDocument*)doc
{
	NSXMLElement *e = [[doc nodesForXPath:@"/rsp/auth/token" error:nil] objectAtIndex:0];
	return [NSString stringWithString:[e stringValue]];
}
- (NSDictionary*)extractTokenDictionary:(NSXMLDocument*)doc
{
	NSMutableDictionary *d=[NSMutableDictionary dictionary];

	NSXMLElement *e = [[doc nodesForXPath:@"/rsp/auth/token" error:nil] objectAtIndex:0];
	[d setObject:[e stringValue] forKey:@"token"];
	e = [[doc nodesForXPath:@"/rsp/auth/perms" error:nil] objectAtIndex:0];
	[d setObject:[e stringValue] forKey:@"perms"];
	e = [[doc nodesForXPath:@"/rsp/auth/user" error:nil] objectAtIndex:0];
	[d setObject:[[e attributeForName:@"nsid"] stringValue] forKey:@"nsid"];
	[d setObject:[[e attributeForName:@"username"] stringValue] forKey:@"username"];
	[d setObject:[[e attributeForName:@"fullname"] stringValue] forKey:@"fullname"];

	return d;
}
- (NSString*)extractFrob:(NSXMLDocument*)doc
{
	NSXMLElement *e = [[doc nodesForXPath:@"/rsp/frob" error:nil] objectAtIndex:0];
	return [NSString stringWithString:[e stringValue]];
}
- (NSDictionary*)extractPhotos:(NSXMLDocument*)doc
{
	NSMutableDictionary *d=[NSMutableDictionary dictionary];

	NSXMLElement *e = [[doc nodesForXPath:@"/rsp/photos" error:nil] objectAtIndex:0];
	[d setObject:[[e attributeForName:@"page"] stringValue] forKey:@"page"];
	[d setObject:[[e attributeForName:@"pages"] stringValue] forKey:@"pages"];
	[d setObject:[[e attributeForName:@"perpage"] stringValue] forKey:@"perpage"];
	[d setObject:[[e attributeForName:@"total"] stringValue] forKey:@"total"];
	
	NSMutableArray *a=[NSMutableArray array];
	size_t i, c=[e childCount];
	for (i=0; i<c; i++) {
		NSXMLElement *f = (NSXMLElement*)[e childAtIndex:i];
		
		NSMutableDictionary *p=[NSMutableDictionary dictionary];
		[p setObject:[[f attributeForName:@"id"] stringValue] forKey:@"id"];
		[p setObject:[[f attributeForName:@"owner"] stringValue] forKey:@"owner"];
		[p setObject:[[f attributeForName:@"secret"] stringValue] forKey:@"secret"];
		[p setObject:[[f attributeForName:@"server"] stringValue] forKey:@"server"];
		[p setObject:[[f attributeForName:@"title"] stringValue] forKey:@"title"];
		[p setObject:[[f attributeForName:@"ispublic"] stringValue] forKey:@"ispublic"];
		[p setObject:[[f attributeForName:@"isfriend"] stringValue] forKey:@"isfriend"];
		[p setObject:[[f attributeForName:@"isfamily"] stringValue] forKey:@"isfamily"];
		[a addObject:p];
	}

	[d setObject:a forKey:@"photos"];
	return d;
}
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request didCancel:(id)userinfo 
{
	[progressIndicator stopAnimation:self];

	NSLog(@"demo: canceled! state=%@", userinfo);
}
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request error:(int)errcode errorInfo:(id)errinfo userInfo:(id)userinfo
{
	[progressIndicator stopAnimation:self];

	NSLog(@"demo: error! code=%d, state=%@", errcode, userinfo);

	NSString *errmsg=[NSString stringWithFormat:@"%@ (error code %d)",
		((errcode < 0) ? @"Internal error" : @"Flickr API error"), errcode];
	
	NSString *informtext=nil;
	
	if ([userinfo isEqualToString:@"getFrob"]) {
		informtext = @"Please check if your API key or Shared Secret is right";
	}
	else if ([userinfo isEqualToString:@"getToken"]) {
		informtext = @"Please get another frob and re-authenticate";
		
reauth:
		[getFrobButton setEnabled:YES];
		[authenticateButton setEnabled:NO];
		[getTokenButton setEnabled:NO];
		
		[frobMsg setStringValue:@"frob not obtained"];
		[authMsg setStringValue:@"authentication URL not yet determined"];
		[tokenMsg setStringValue:@"token not obtained"];
	}
	else if ([userinfo isEqualToString:@"getPhotoList"]) {
		informtext = @"Please check Flickr API parameters, or re-authenticate";
		goto reauth;
	}

	if (errcode < 0) {
		informtext = @"Please check your network connection";
	}
	
	[[NSAlert alertWithMessageText:errmsg
		defaultButton:@"Go back"
		alternateButton:nil
		otherButton:nil
		informativeTextWithFormat:informtext
	] runModal];	
}
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request progress:(size_t)receivedBytes expectedTotal:(size_t)total userInfo:(id)userinfo
{
	NSLog(@"demo: reading data (%ld bytes of %ld), state=%@", receivedBytes, total, userinfo);
}
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)req didFetchData:(NSXMLDocument*)xmldoc userInfo:(id)userinfo
{
	[progressIndicator stopAnimation:self];

	NSLog(@"demo: data fetched! state=%@, data=%@", userinfo, [xmldoc description]);

	NSLog(@"Data received! state=%@", userinfo);
	
	int errcode;
	NSString *errmsg;
	if ([self hasFlickrError:xmldoc receiveCode:&errcode receiveMessage:&errmsg]) {
		[self flickrRESTRequest:req error:errcode errorInfo:errmsg userInfo:userinfo];
		return;
	}

	if ([userinfo isEqualToString:@"getFrob"]) {
		if (frob) [frob release];
		frob = [[NSString stringWithString: [self extractFrob:xmldoc]] retain];
		
		[frobMsg setStringValue: [NSString stringWithFormat:@"obtained frob=%@", frob]];
		
		[authMsg setStringValue:@"now click this button to visit Flickr for authentication"];
		[tokenMsg setStringValue:@"after it's done, come back from browser and click this button"];
		[getFrobButton setEnabled:NO];
		[authenticateButton setEnabled:YES];
	}
	else if ([userinfo isEqualToString:@"getToken"]) {
		token = [NSDictionary dictionaryWithDictionary:[self extractTokenDictionary:xmldoc]];
		NSLog([token description]);
		[token retain];
		[appContext setAuthToken:[token objectForKey:@"token"]];

		[authMsg setStringValue:@"authentication process completed"];		
		[tokenMsg setStringValue:[NSString stringWithFormat:@"token obtained, logged in as %@", [token objectForKey:@"username"]]];
		[authenticateButton setEnabled:NO];
		[getTokenButton setEnabled:NO];
		
		[uploadButton setEnabled:YES];
		
		[browserBox setTitle:@"Getting my recent photos..."];
		[progressIndicator startAnimation:self];
	
		NSDictionary *calldict = [NSDictionary dictionaryWithObjectsAndKeys:
			@"flickr.people.getPublicPhotos", @"method",
			[token objectForKey:@"nsid"], @"user_id", nil];

		NSString *callurl = [appContext prepareRESTGETURL:calldict authentication:NO sign:NO];

		NSLog(@"calling %@", callurl);
		[request GETRequest:callurl userInfo:@"getPhotoList"];

	}
	else if ([userinfo isEqualToString:@"getPhotoList"]) {
		NSDictionary *d=[self extractPhotos:xmldoc];
		
		if (photos) [photos release];
		photos=[[NSArray arrayWithArray:[d objectForKey:@"photos"]] retain];

		[photoList reloadData];
		[browserBox setTitle:@"My recent photos"];
	}
}
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
	NSDictionary *o=[photos objectAtIndex:rowIndex];
			
	NSString *u=[appContext photoURLFromID:[o objectForKey:@"id"]
		serverID:[o objectForKey:@"server"]
		secret:[o objectForKey:@"secret"]
		size:@"t"
		type:nil];

	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:u]]];
	
	NSLog(@"selecting row %d, url=%@", rowIndex, u);
	return YES;
}
- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [photos count];
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	NSDictionary *o=[photos objectAtIndex:rowIndex];
	if ([[aTableColumn identifier] isEqualToString:@"id"]) {
		return [o objectForKey:@"id"];
	}
	else if ([[aTableColumn identifier] isEqualToString:@"title"]) {
		return [o objectForKey:@"title"];
	}
	return @"";
}
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	[progressIndicator startAnimation:self];
}
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	[progressIndicator stopAnimation:self];
}
- (IBAction)upload:(id)sender
{
	NSOpenPanel *op=[NSOpenPanel openPanel];
	[op setAllowsMultipleSelection:FALSE];
	if ([op runModalForDirectory:nil file:nil]==NSFileHandlingPanelOKButton) {
		NSString *f=[[op filenames] objectAtIndex:0];

		uploadFilename=[[f lastPathComponent] retain];

		OFFlickrUploader *up = [[OFFlickrUploader alloc] initWithDelegate:self];
		
		
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSString stringWithFormat:@"test title %@", [uploadFilename lastPathComponent]], @"title",
			@"test flickr upload", @"description", nil];
		if ([up uploadWithContentsOfFile:f photoInformation:dict applicationContext:appContext userInfo:nil])
		{
			[uploadMsg setStringValue:[NSString stringWithFormat:@"uploading %@", uploadFilename]];
		}
		else {
			[uploadMsg setStringValue:[NSString stringWithFormat:@"cannot upload %@", uploadFilename]];
		}
	}
}
- (void)flickrUploader:(OFFlickrUploader*)uploader didComplete:(NSXMLDocument*)response userInfo:(id)userinfo
{
	NSLog(@"received data = %@", [response description]);
	[uploadMsg setStringValue:@"browser opened to finish the upload process"];

	NSXMLElement *e = [[response nodesForXPath:@"/rsp/photoid" error:nil] objectAtIndex:0];
	NSString *pid = [e stringValue];
	
	NSString *callback = [appContext uploadCallBackURLWithPhotoID:pid];
	system([[NSString stringWithFormat:@"open %@", callback] UTF8String]);
	
	[uploader release];
}
- (void)flickrUploader:(OFFlickrUploader*)uploader error:(int)code errorInfo:(id)errinfo userInfo:(id)userinfo
{
	[uploadMsg setStringValue:[NSString stringWithFormat:@"upload error, code=%d", code]];
	[uploader release];
}
- (void)flickrUploader:(OFFlickrUploader*)uploader progress:(size_t)length total:(size_t)totalLength userInfo:(id)userinfo
{
	if (length != totalLength) {
		[uploadMsg setStringValue:[NSString stringWithFormat:@"%ld bytes uploaded (of %ld bytes)", length, totalLength]];
	}
	else {
		[uploadMsg setStringValue:@"upload complete, waiting Flickr response..."];
	}
}
- (void)flickrUploader:(OFFlickrUploader*)uploader didCancel:(id)userinfo
{
	[uploadMsg setStringValue:@"upload canceled"];
	[uploader release];
}

@end

