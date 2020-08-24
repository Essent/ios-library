/* Copyright Airship and Contributors */

#import "UAAttributeAPIClient+Internal.h"
#import "UARuntimeConfig.h"
#import "UAUtils+Internal.h"
#import "UAirship.h"
#import "UAAnalytics+Internal.h"
#import "NSJSONSerialization+UAAdditions.h"
#import "NSURLResponse+UAAdditions.h"
#import "UAJSONSerialization.h"
#import "UAAttributePendingMutations.h"
#import "UAAPIClient.h"

NSString *const UAChannelsAPIPath = @"/api/channels/";
NSString *const UAAttributePlatformSpecifier = @"/attributes?platform=";
NSString *const UAAttributePlatform = @"ios";

NSString *const UANamedUserAPIPath = @"/api/named_users/";
NSString *const UAAttributeSpecifier = @"/attributes";

@interface UAAttributeAPIClient()
@property (nonatomic, copy) NSURL *(^URLFactoryBlock)(UARuntimeConfig *, NSString *);
@end

@implementation UAAttributeAPIClient


- (instancetype)initWithConfig:(UARuntimeConfig *)config
                       session:(UARequestSession *)session
               URLFactoryBlock:(NSURL *(^)(UARuntimeConfig *, NSString *))URLFactoryBlock {
    self = [super initWithConfig:config session:session];
    if (self) {
        self.URLFactoryBlock = URLFactoryBlock;
    }
    return self;
}

+ (instancetype)channelClientWithConfig:(UARuntimeConfig *)config {
    NSURL *(^URLFactoryBlock)(UARuntimeConfig *, NSString *) = ^NSURL *(UARuntimeConfig *config, NSString *identifier) {
        NSString *attributeEndpoint = [NSString stringWithFormat:@"%@%@%@%@%@", config.deviceAPIURL, UAChannelsAPIPath, identifier, UAAttributePlatformSpecifier, UAAttributePlatform];
        return [NSURL URLWithString:attributeEndpoint];

    };

    return [UAAttributeAPIClient clientWithConfig:config
                                          session:[UARequestSession sessionWithConfig:config]
                                  URLFactoryBlock:URLFactoryBlock];
}

+ (instancetype)namedUserClientWithConfig:(UARuntimeConfig *)config {
    NSURL *(^URLFactoryBlock)(UARuntimeConfig *, NSString *) = ^NSURL *(UARuntimeConfig *config, NSString *identifier) {
        NSString *attributeEndpoint =  [NSString stringWithFormat:@"%@%@%@%@", config.deviceAPIURL, UANamedUserAPIPath, identifier, UAAttributeSpecifier];
        return [NSURL URLWithString:attributeEndpoint];
    };

    return [UAAttributeAPIClient clientWithConfig:config
                                          session:[UARequestSession sessionWithConfig:config]
                                  URLFactoryBlock:URLFactoryBlock];
}

+ (instancetype)clientWithConfig:(UARuntimeConfig *)config
                         session:(UARequestSession *)session
                 URLFactoryBlock:(NSURL *(^)(UARuntimeConfig *, NSString *))URLFactoryBlock {
    return [[UAAttributeAPIClient alloc] initWithConfig:config session:session URLFactoryBlock:URLFactoryBlock];
}

- (void)updateWithIdentifier:(NSString *)identifier
          attributeMutations:(UAAttributePendingMutations *)mutations
           completionHandler:(void (^)(NSUInteger, NSError * _Nullable))completionHandler {

    UA_LTRACE(@"Updating attributes for identifier: %@ with attribute payload: %@.", identifier, mutations);

    if (!self.enabled) {
        UA_LDEBUG(@"Disabled");
        return;
    }

    NSData *payloadData = [UAJSONSerialization dataWithJSONObject:mutations.payload
                                                          options:0
                                                            error:nil];

    UARequest *request = [UARequest requestWithBuilderBlock:^(UARequestBuilder *builder) {
        builder.URL = self.URLFactoryBlock(self.config, identifier);
        builder.method = @"POST";
        builder.username = self.config.appKey;
        builder.password = self.config.appSecret;
        builder.body = payloadData;
        [builder setValue:@"application/vnd.urbanairship+json; version=3;" forHeader:@"Accept"];
        [builder setValue:@"application/json" forHeader:@"Content-Type"];
    }];

    [self.session dataTaskWithRequest:request retryWhere:^BOOL(NSData *data, NSURLResponse *response) {
        return [response hasRetriableStatus];
    } completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            UA_LTRACE(@"Update finished with error: %@", error);
            completionHandler(0, error);
        } else {
            NSHTTPURLResponse *httpResponse = nil;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                httpResponse = (NSHTTPURLResponse *) response;
            }

            UA_LTRACE(@"Update of %@ finished with status: %ld", httpResponse.URL, (unsigned long)httpResponse.statusCode);
            completionHandler(httpResponse.statusCode, error);
        }
    }];
}

@end
