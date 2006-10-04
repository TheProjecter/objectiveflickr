#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface NSXMLNode(OFFlickrXMLExtension)
- (NSDictionary*)flickrDictionaryFromNode;
@end

@interface NSXMLElement(OFFlickrXMLExtension)
- (NSDictionary*)flickrDictionaryFromNode;
@end

@interface NSXMLDocument(OFFlickrXMLExtension)
- (BOOL)hasFlickrError:(int*)errcode message:(NSString**)errorMsg;
- (NSDictionary*)flickrDictionaryFromDocument;
+ (NSString*)flickrXMLAttribute:(NSString*)attr;
+ (NSString*)flickrXMLAttributePrefix;
+ (NSString*)flickrXMLTextNodeKey;
@end
