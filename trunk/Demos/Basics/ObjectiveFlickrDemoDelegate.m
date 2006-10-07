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

@implementation ObjectiveFlickrDemoDelegate
- (void)awakeFromNib 
{	
	context = [[OFFlickrContext contextWithAPIKey:OFDemoAPIKey sharedSecret:OFDemoSharedSecret] retain];
	invoc = [[OFFlickrInvocation invocationWithContext:context delegate:self] retain];
	uploader = [[OFFlickrUploader uploaderWithContext:context delegate:self] retain];
	
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
	[context release];
	[invoc release];
	[super dealloc];
}
- (IBAction)getFrob:(id)sender
{
	[progressIndicator startAnimation:self];

	[invoc setUserInfo:@"getFrob"];
	[invoc callMethod:@"flickr.auth.getFrob" arguments:nil];
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
	NSString *authurl=[context prepareLoginURL:frob permission:@"write"];
	system([[NSString stringWithFormat:@"open '%@'", authurl] UTF8String]);
	[authenticateButton setEnabled:NO];
}
- (IBAction)getToken:(id)sender
{
	[invoc setUserInfo:@"getToken"];
	[invoc callMethod:@"flickr.auth.getToken" arguments:[NSArray arrayWithObjects:@"frob", frob, nil]];
}
- (void)flickrInvocation:(OFFlickrInvocation*)invocation errorCode:(int)errcode errorInfo:(id)errinfo
{
	NSString *userinfo = [invoc userInfo];

	[progressIndicator stopAnimation:self];

	if (errcode == OFConnectionCanceled) {
		NSLog(@"demo: canceled! state=%@", userinfo);
		return;
	}
	
	NSLog(@"demo: error! code=%d, errinfo=%@, state=%@", errcode, errinfo, userinfo);

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

- (void)flickrInvocation:(OFFlickrInvocation*)invocation progress:(size_t)receivedBytes expectedTotal:(size_t)total;
{
	id userinfo = [invocation userInfo];
	NSLog(@"demo: reading data (%ld bytes of %ld), state=%@", receivedBytes, total, userinfo);
}
- (void)flickrInvocation:(OFFlickrInvocation*)invocation didFetchData:(NSXMLDocument*)xmldoc
{
	[progressIndicator stopAnimation:self];
	
	NSDictionary *payload = [xmldoc flickrDictionaryFromDocument];
	NSLog(@"data received, payload = %@", [payload description]);
	
	id userinfo = [invocation userInfo];

	if ([userinfo isEqualToString:@"getFrob"]) {
		if (frob) [frob release];
		frob = [[NSString stringWithString: [payload valueForKeyPath:@"frob.$"]] retain];
		
		[frobMsg setStringValue: [NSString stringWithFormat:@"obtained frob=%@", frob]];
		
		[authMsg setStringValue:@"now click this button to visit Flickr for authentication"];
		[tokenMsg setStringValue:@"after it's done, come back from browser and click this button"];
		[getFrobButton setEnabled:NO];
		[authenticateButton setEnabled:YES];
	}
	else if ([userinfo isEqualToString:@"getToken"]) {
		token = [[NSDictionary dictionaryWithDictionary:payload] retain];
		// NSLog(@"auth token=%@", [token valueForKeyPath:@"auth.token.$"]);
		[context setAuthToken:[token valueForKeyPath:@"auth.token.$"]];

		[authMsg setStringValue:@"authentication process completed"];		
		[tokenMsg setStringValue:[NSString stringWithFormat:@"token obtained, logged in as %@", [token valueForKeyPath:@"auth.user._fullname"]]];
		[authenticateButton setEnabled:NO];
		[getTokenButton setEnabled:NO];
		
		[uploadButton setEnabled:YES];
		
		[browserBox setTitle:@"Getting my recent photos..."];
		[progressIndicator startAnimation:self];
	
		[invoc setUserInfo:@"getPhotoList"];
		[invoc callMethod:@"flickr.people.getPublicPhotos" arguments:[NSArray arrayWithObjects:@"user_id", [token valueForKeyPath:@"auth.user._nsid"], nil]];
	}
	else if ([userinfo isEqualToString:@"getPhotoList"]) {
		if (photos) [photos release];
		photos=[[NSArray arrayWithArray:[payload valueForKeyPath:@"photos.photo"]] retain];

		[photoList reloadData];
		[browserBox setTitle:@"My recent photos"];
	}
}
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
	NSDictionary *o=[photos objectAtIndex:rowIndex];
			
	NSString *u = [context photoURLFromID:[o objectForKey:@"_id"]
		serverID:[o objectForKey:@"_server"]
		secret:[o objectForKey:@"_secret"]
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
		return [o objectForKey:@"_id"];
	}
	else if ([[aTableColumn identifier] isEqualToString:@"title"]) {
		return [o objectForKey:@"_title"];
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
	if ([op runModalForDirectory:nil file:nil] != NSFileHandlingPanelOKButton) return;
	
	NSString *f=[[op filenames] objectAtIndex:0];

	uploadFilename=[[f lastPathComponent] retain];
	[uploader cancel];

	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithFormat:@"test title %@", [uploadFilename lastPathComponent]], @"title",
		@"test flickr upload", @"description", nil];
		
	if ([uploader uploadWithContentsOfFile:f photoInformation:dict userInfo:nil])
	{
		[uploadMsg setStringValue:[NSString stringWithFormat:@"uploading %@", uploadFilename]];
	}
	else {
		[uploadMsg setStringValue:[NSString stringWithFormat:@"cannot upload %@", uploadFilename]];
	}
}
- (void)flickrUploader:(OFFlickrUploader*)uploader didComplete:(NSString*)callbackID userInfo:(id)userinfo
{
	[uploadMsg setStringValue:@"browser opened to finish the upload process"];
	NSString *callback = [context uploadCallBackURLWithPhotoID:callbackID];
	system([[NSString stringWithFormat:@"open %@", callback] UTF8String]);
}
- (void)flickrUploader:(OFFlickrUploader*)uploader errorCode:(int)code errorInfo:(id)errinfo userInfo:(id)userinfo
{
	[uploadMsg setStringValue:[NSString stringWithFormat:@"upload error, code=%d", code]];
}
- (void)flickrUploader:(OFFlickrUploader*)uploader progress:(size_t)bytesSent total:(size_t)totalLength userInfo:(id)userinfo
{
	NSLog(@"%ld bytes uploaded (of %ld bytes)", bytesSent, totalLength);
	if (bytesSent != totalLength) {
		[uploadMsg setStringValue:[NSString stringWithFormat:@"%ld bytes uploaded (of %ld bytes)", bytesSent, totalLength]];
	}
	else {
		[uploadMsg setStringValue:@"upload complete, waiting Flickr response..."];
	}
}
- (void)flickrUploader:(OFFlickrUploader*)uploader didCancel:(id)userinfo
{
	[uploadMsg setStringValue:@"upload canceled"];
}
@end

