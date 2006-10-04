#import <ObjectiveFlickr/ObjectiveFlickr.h>

#define OFRESTAPIEndPointKey			@"RESTAPIEndPoint"
#define OFAuthenticationEndPointKey		@"authEndPoint"
#define OFPhotoURLPrefixKey				@"photoURLPrefix"
#define OFUploadEndPointKey				@"uploadEndPoint"
#define OFUploadCallBackEndPointKey		@"uploadCallBackEndPoint"

@interface OFFlickrContext : NSObject
{
	NSString *_APIKey;
	NSString *_sharedSecret;
	NSString *_authToken;
	NSDictionary *_endPoints;
}
+ (OFFlickrContext*)contextWithAPIKey:(NSString*)key sharedSecret:(NSString*)secret;
- (OFFlickrContext*)initWithAPIKey:(NSString*)key sharedSecret:(NSString*)secret;
- (void)setAuthToken:(NSString*)token;
- (NSString*)authToken;
- (void)setEndPoints:(NSDictionary*)newEndPoints;
- (NSDictionary*)endPoints;
- (NSString*)RESTAPIEndPoint;
- (NSString*)photoURLFromID:(NSString*)photo_id serverID:(NSString*)server_id secret:(NSString*)secret size:(NSString*)size type:(NSString*)type;
@end

@interface OFFlickrContext (OFFlickrDataPreparer)
- (NSString*)prepareRESTGETURL:(NSDictionary*)parameters authentication:(BOOL)auth sign:(BOOL)sign;
- (NSString*)prepareLoginURL:(NSString*)frob permission:(NSString*)perm;
- (NSData*)prepareRESTPOSTData:(NSDictionary*)parameters authentication:(BOOL)auth sign:(BOOL)sign;
+ (NSString*)POSTDataSeparator;
@end

@interface OFFlickrContext (OFFlickrUploadHelper)
- (NSData*)prepareUploadData:(NSData*)data filename:(NSString*)filename information:(NSDictionary*)info;	 /* incl. title, description, tags, is_public, is_OFiend, is_family */
- (NSString*)uploadURL;
- (NSString*)uploadCallBackURLWithPhotos:(NSArray*)photo_ids;
- (NSString*)uploadCallBackURLWithPhotoID:(NSString*)photo_id;
@end
