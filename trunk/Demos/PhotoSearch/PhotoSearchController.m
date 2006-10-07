#import "PhotoSearchController.h"
#import "OFDemoAPIKey.h"
#import <WebKit/DOMExtensions.h>

// we put this to make compiler happier... not absolutely necessary
@interface OFFlickrInvocation (OurOwnInvocation)
- (void)flickr_photos_search:(id)userinfo text:(NSString*)searchText selector:(SEL)aSelector;
@end

@implementation PhotoSearchController
- (void)awakeFromNib
{
	// we use public photos, so no shared secret here
	context = [[OFFlickrContext contextWithAPIKey:OFDemoAPIKey sharedSecret:nil] retain];
	invoc = [[OFFlickrInvocation invocationWithContext:context delegate:self] retain];
	
	// load index.html
	[[webView mainFrame] loadRequest:
		[NSURLRequest requestWithURL:
			[NSURL fileURLWithPath:
				[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"index.html"]
			]
		]
	];
	
	// tell search field not to return us the string every time we type a key
	[[searchField cell] setSendsWholeSearchString:YES];
}
- (void)dealloc
{
	[context release];
	[invoc release];
	[super dealloc];
}
- (void)handleSearch:(id)userinfo errorCode:(int)errorcode data:(id)data
{
	[progressIndicator stopAnimation:self];
	
	// error handler
	if (errorcode) {
		NSString *title = [NSString stringWithFormat:@"%@ (code %d)", 
			errorcode < 0 ? @"Connection error" : @"Flickr Error", errorcode];
		NSRunAlertPanel(title, [data description], @"Start a new search", nil, nil);
		return;
	}
	
	// get our photos
	NSArray *photos = [[data flickrDictionaryFromDocument] valueForKeyPath:@"photos.photo"];
	NSMutableString *code = [NSMutableString string];

	if ([photos isKindOfClass:[NSArray class]]) {
		unsigned i, c = [photos count];		
		for (i = 0; i < c; i++) {
			// now we combine the photos
			NSString *url=[context photoURLFromDictionary:[photos objectAtIndex:i] size:@"s" type:nil];
			[code appendString:[NSString stringWithFormat:@"<img src=\"%@\" />", url]];
		}
	}
	else {
		[code appendString:@"No photos found!"];
	}
	
	// Some AJAX stuff... :)
	DOMHTMLElement *e = (DOMHTMLElement*)[[[webView mainFrame] DOMDocument] getElementById:@"photos"];
	[e setInnerHTML:code];	
	[webView stringByEvaluatingJavaScriptFromString:@"new Effect.BlindDown('photos')"];
}
- (IBAction)startSearch:(id)sender
{
	// we convert the search string into percent-escaped string
	NSString *srchstr = [[sender stringValue] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];	
	if ([srchstr isEqualToString:@""]) return;

	[progressIndicator startAnimation:self];
	[invoc flickr_photos_search:nil text:srchstr selector:@selector(handleSearch:errorCode:data:)];
}

@end
