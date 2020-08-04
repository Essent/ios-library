/* Copyright Airship and Contributors */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents the possible error conditions when deserializing data from JSON.
 */
typedef NS_ENUM(NSUInteger, UAScheduleDeferredDataErrorCode) {
    /**
     * Indicates an error with the JSON definition.
     */
    UAScheduleDeferredDataErrorCodeInvalidJSON,
};

/**
 * Deferred schedule data.
 */
@interface UAScheduleDeferredData : NSObject
/**
 * The URL.
 */
@property(nonatomic, readonly) NSURL *URL;

/**
 * Flag for retrying the URL  if the request times out.
 */
@property(nonatomic, readonly, getter=isRetriableOnTimeout) BOOL retriableOnTimeout;

/**
 * Factory method.
 * @param URL The URL.
 * @param retriableOnTimeout `YES` to retry on timeout, otherwise `NO`.
 */
+(instancetype)deferredDataWithURL:(NSURL *)URL
                retriableOnTimeout:(BOOL)retriableOnTimeout;
/**
 * Class factory method for constructing deferred data from JSON.
 *
 * @param json JSON object that defines the data.
 * @param error An NSError pointer for storing errors, if applicable.
 * @return A fully configured instance of UAScheduleDeferredData or nil if JSON parsing fails.
 */
+ (nullable instancetype)deferredDataWithJSON:(id)json
                                        error:(NSError * _Nullable *)error;
/**
 * Method to return the data as its JSON representation.
 *
 * @returns JSON representation of the data.
 */
- (NSDictionary *)toJSON;

@end

NS_ASSUME_NONNULL_END
