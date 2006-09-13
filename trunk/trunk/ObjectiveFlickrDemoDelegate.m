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

#error Please put your own Flickr API key here
NSString *OFDemo_apikey=@"";
#error Please put your own Shared Secret here
NSString *OFDemo_secret=@"";

@implementation ObjectiveFlickrDemoDelegate

- (void)awakeFromNib 
{
	frob = nil;
	token = nil;
	photos = [[NSArray array] retain];
	furl = [[FlickrRESTURL alloc] initWithAPIKey:OFDemo_apikey secret:OFDemo_secret];
	freq = [[FlickrRESTRequest alloc] initWithDelegate:self timeoutInterval:10.0];
	
	[photoList setDataSource:self];
	[photoList setDelegate:self];
	[webView setFrameLoadDelegate:self];
}
- (void)dealloc 
{
	if (frob) [frob release];
	if (token) [token release];
	if (photos) [photos release];
	[furl release];
	[freq release];
	[super dealloc];
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
	NSString *authurl=[furl authURL:@"read" withFrob:frob];
	system([[NSString stringWithFormat:@"open '%@'", authurl] UTF8String]);
	[authenticateButton setEnabled:NO];
}

- (IBAction)getFrob:(id)sender
{
	[progressIndicator startAnimation:self];
	[freq requestURL:[furl getFrobURL] withState:@"getFrob"];
}

- (IBAction)getToken:(id)sender
{
	[progressIndicator startAnimation:self];

	NSString *call=[furl methodURL:@"flickr.auth.getToken" useToken:NO useAPIKey:YES arguments:
		[NSDictionary dictionaryWithObjectsAndKeys:frob, @"frob", nil]];
		
	[freq requestURL:call withState:@"getToken"];
	[authenticateButton setEnabled:NO];
}
- (void)flickrRESTRequest:(FlickrRESTRequest*)request didReceiveData:(NSXMLDocument*)document state:(NSString*)state
{
	[progressIndicator stopAnimation:self];
	NSLog(@"Data received! state=%@", [document description], state);

	if ([state isEqualToString:@"getFrob"]) {
		if (frob) [frob release];
		frob = [[NSString stringWithString: [FlickrRESTRequest extractFrob:document]] retain];
		
		[frobMsg setStringValue: [NSString stringWithFormat:@"obtained frob=%@", frob]];
		
		[authMsg setStringValue:@"now click this button to visit Flickr for authentication"];
		[tokenMsg setStringValue:@"after it's done, come back from browser and click this button"];
		[getFrobButton setEnabled:NO];
		[authenticateButton setEnabled:YES];
	}
	else if ([state isEqualToString:@"getToken"]) {
		token = [NSDictionary dictionaryWithDictionary:[FlickrRESTRequest extractTokenDictionary:document]];
		NSLog([token description]);
		[token retain];
		[furl setToken:[token objectForKey:@"token"]];

		[authMsg setStringValue:@"authentication process completed"];		
		[tokenMsg setStringValue:[NSString stringWithFormat:@"token obtained, logged in as %@", [token objectForKey:@"username"]]];
		[authenticateButton setEnabled:NO];
		[getTokenButton setEnabled:NO];
		
		[browserBox setTitle:@"Getting my recent photos..."];
		[progressIndicator startAnimation:self];
	
		NSString *call=[furl methodURL:@"flickr.people.getPublicPhotos" useToken:NO useAPIKey:YES arguments:
			[NSDictionary dictionaryWithObjectsAndKeys:[token objectForKey:@"nsid"], @"user_id", nil]];

		NSLog(@"calling %@", call);
		[freq requestURL:call withState:@"getPhotoList"];

	}
	else if ([state isEqualToString:@"getPhotoList"]) {
		NSDictionary *d=[FlickrRESTRequest extractPhotos:document];
		
		if (photos) [photos release];
		photos=[[NSArray arrayWithArray:[d objectForKey:@"photos"]] retain];

		[photoList reloadData];
		[browserBox setTitle:@"My recent photos"];
	}
}
- (void)flickrRESTRequestDidCancel:(FlickrRESTRequest*)request state:(NSString*)state
{
	NSLog(@"Transfer canceled");

	[progressIndicator stopAnimation:self];
}
- (void)flickrRESTRequest:(FlickrRESTRequest*)request error:(int)errorCode message:(NSString*)msg state:(NSString*)state
{
	NSLog(@"error! code=%d msg=%@, state=%@", errorCode, msg, state);

	[progressIndicator stopAnimation:self];

	NSString *errmsg=[NSString stringWithFormat:@"%@ (error code %d)",
		((errorCode < 0) ? @"Internal error" : @"Flickr API error"), errorCode];
	
	NSString *informtext=nil;
	
	if ([state isEqualToString:@"getFrob"]) {
		informtext = @"Please check if your API key or Shared Secret is right";
	}
	else if ([state isEqualToString:@"getToken"]) {
		informtext = @"Please get another frob and re-authenticate";
		
reauth:
		[getFrobButton setEnabled:YES];
		[authenticateButton setEnabled:NO];
		[getTokenButton setEnabled:NO];
		
		[frobMsg setStringValue:@"frob not obtained"];
		[authMsg setStringValue:@"authentication URL not yet determined"];
		[tokenMsg setStringValue:@"token not obtained"];
	}
	else if ([state isEqualToString:@"getPhotoList"]) {
		informtext = @"Please check Flickr API parameters, or re-authenticate";
		goto reauth;
	}

	if (errorCode < 0) {
		informtext = @"Please check your network connection";
	}
	
	[[NSAlert alertWithMessageText:errmsg 
		defaultButton:@"Go back"
		alternateButton:nil
		otherButton:nil
		informativeTextWithFormat:informtext
	] runModal];	
}
- (void)flickrRESTRequest:(FlickrRESTRequest*)request progress:(size_t)length total:(long long)expectedLength state:(NSString*)state
{
	NSLog(@"Transfer progress! %d of %d, state=%@", length, expectedLength, state);
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
	NSDictionary *o=[photos objectAtIndex:rowIndex];
			
	NSString *u=[FlickrRESTRequest photoSourceURLFromServerID:[o objectForKey:@"server"]
		photoID:[o objectForKey:@"id"] secret:[o objectForKey:@"secret"] size:@"t" type:nil];

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
@end

