/* Copyright Airship and Contributors */

#import "UASchedule+Internal.h"
#import "UAAirshipAutomationCoreImport.h"
#import "UAInAppMessage+Internal.h"
#import "UAScheduleDeferredData+Internal.h"

NSUInteger const UAScheduleMaxTriggers = 10;

@implementation UAScheduleBuilder

- (instancetype)init {
    self = [super init];
    if (self) {
        self.limit = 1;
    }

    return self;
}

@end

@interface UASchedule()
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, assign) UAScheduleType type;
@property(nonatomic, strong) id data;
@property(nonatomic, assign) NSInteger priority;
@property(nonatomic, copy) NSArray *triggers;
@property(nonatomic, assign) NSUInteger limit;
@property(nonatomic, strong) NSDate *start;
@property(nonatomic, strong) NSDate *end;
@property(nonatomic, strong) UAScheduleDelay *delay;
@property(nonatomic, copy) NSString *group;
@property(nonatomic, assign) NSTimeInterval interval;
@property(nonatomic, assign) NSTimeInterval editGracePeriod;
@property(nonatomic, copy) NSDictionary *metadata;
@property(nonatomic, strong) UAScheduleAudience *audience;

@end


@implementation UASchedule

+ (instancetype)scheduleWithActions:(NSDictionary *)actions
                       builderBlock:(void(^)(UAScheduleBuilder *builder))builderBlock {
    UAScheduleBuilder *builder = [[UAScheduleBuilder alloc] init];
    builderBlock(builder);
    return [[self alloc] initWithData:actions type:UAScheduleTypeActions builder:builder];
}

+ (instancetype)scheduleWithMessage:(UAInAppMessage *)message
                       builderBlock:(void(^)(UAScheduleBuilder *builder))builderBlock {
    UAScheduleBuilder *builder = [[UAScheduleBuilder alloc] init];
    builderBlock(builder);
    return [[self alloc] initWithData:message type:UAScheduleTypeInAppMessage builder:builder];
}

+ (instancetype)scheduleWithDeferredData:(UAScheduleDeferredData *)deferredData
                            builderBlock:(void(^)(UAScheduleBuilder *builder))builderBlock {
    UAScheduleBuilder *builder = [[UAScheduleBuilder alloc] init];
    builderBlock(builder);
    return [[self alloc] initWithData:deferredData type:UAScheduleTypeDeferred builder:builder];
}

+ (instancetype)scheduleWithType:(UAScheduleType)scheduleType
                        dataJSON:(id)JSON
                    builderBlock:(void(^)(UAScheduleBuilder *builder))builderBlock {

    id data = [self parseDataForType:scheduleType JSON:JSON];

    if (!data) {
        return nil;
    }

    UAScheduleBuilder *builder = [[UAScheduleBuilder alloc] init];
    builderBlock(builder);
    return [[self alloc] initWithData:data type:scheduleType builder:builder];
}

- (BOOL)isValid {
    if (!self.triggers.count || self.triggers.count > UAScheduleMaxTriggers) {
        return NO;
    }

    if ([self.start compare:self.end] == NSOrderedDescending) {
        return NO;
    }

    if (self.delay && !self.delay.isValid) {
        return NO;
    }

    return YES;
}

- (instancetype)initWithData:(id)data
                        type:(UAScheduleType)type
                     builder:(UAScheduleBuilder *)builder {
    self = [super init];
    if (self) {
        self.data = data;
        self.type = type;
        self.identifier = builder.identifier ?: [NSUUID UUID].UUIDString;
        self.priority = builder.priority;
        self.triggers = builder.triggers ?: @[];
        self.limit = builder.limit;
        self.group = builder.group;
        self.delay = builder.delay;
        self.start = builder.start ?: [NSDate distantPast];
        self.end = builder.end ?: [NSDate distantFuture];
        self.editGracePeriod = builder.editGracePeriod;
        self.interval = builder.interval;
        self.metadata = builder.metadata ?: @{};
        self.audience = builder.audience;
    }

    return self;
}

- (BOOL)isEqualToSchedule:(UASchedule *)schedule {
    if (!schedule) {
        return NO;
    }

    if (![self.identifier isEqualToString:schedule.identifier]) {
        return NO;
    }

    if (![self.metadata isEqualToDictionary:schedule.metadata]) {
        return NO;
    }

    if (self.type != schedule.type) {
        return NO;
    }

    if (self.priority != schedule.priority) {
        return NO;
    }

    if (self.limit != schedule.limit) {
        return NO;
    }

    if (self.interval != schedule.interval) {
        return NO;
    }

    if (self.editGracePeriod != schedule.editGracePeriod) {
        return NO;
    }

    if (![self.start isEqualToDate:schedule.start]) {
        return NO;
    }

    if (![self.end isEqualToDate:schedule.end]) {
        return NO;
    }

    if (![self.data isEqual:schedule.data]) {
        return NO;
    }

    if (self.triggers != schedule.triggers && ![self.triggers isEqualToArray:schedule.triggers]) {
        return NO;
    }

    if (self.group != schedule.group && ![self.group isEqualToString:schedule.group]) {
        return NO;
    }

    if (self.delay != schedule.delay && ![self.delay isEqualToDelay:schedule.delay]) {
        return NO;
    }

    if (self.audience != schedule.audience && ![self.audience isEqual:schedule.audience]) {
        return NO;
    }

    return YES;
}


#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[UASchedule class]]) {
        return NO;
    }

    return [self isEqualToSchedule:(UASchedule *)object];
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    result = 31 * result + [self.identifier hash];
    result = 31 * result + [self.metadata hash];
    result = 31 * result + [self.start hash];
    result = 31 * result + [self.end hash];
    result = 31 * result + [self.group hash];
    result = 31 * result + [self.triggers hash];
    result = 31 * result + [self.data hash];
    result = 31 * result + [self.delay hash];
    result = 31 * result + [self.audience hash];
    result = 31 * result + self.editGracePeriod;
    result = 31 * result + self.interval;
    result = 31 * result + self.type;
    result = 31 * result + self.limit;
    result = 31 * result + self.priority;
    return result;
}

- (NSString *)dataJSONString {
    switch (self.type) {
        case UAScheduleTypeActions:
            return [NSJSONSerialization stringWithObject:self.data];
        case UAScheduleTypeInAppMessage: {
            UAInAppMessage *message = (UAInAppMessage *)self.data;
            return [NSJSONSerialization stringWithObject:[message toJSON]];
        }
        case UAScheduleTypeDeferred: {
            UAScheduleDeferredData *deferred = (UAScheduleDeferredData *)self.data;
            return [NSJSONSerialization stringWithObject:[deferred toJSON]];
        }
    }
}

+ (nullable id)parseDataForType:(UAScheduleType)scheduleType JSON:(id)JSON {
    switch (scheduleType) {
        case UAScheduleTypeInAppMessage: {
            NSError *error;
            UAInAppMessage *message = [UAInAppMessage messageWithJSON:JSON error:&error];
            if (!error && message) {
                return message;
            } else {
                UA_LERR(@"Invalid schedule data: %@ error: %@", JSON, error);
                return nil;
            }
        }

        case UAScheduleTypeActions: {
            return JSON;
        }

        case UAScheduleTypeDeferred: {
            NSError *error;
            UAScheduleDeferredData *deferred = [UAScheduleDeferredData deferredDataWithJSON:JSON error:&error];
            if (!error && deferred) {
                return deferred;
            } else {
                UA_LERR(@"Invalid schedule data: %@ error: %@", JSON, error);
                return nil;
            }
        }
    }

    UA_LERR(@"Unexpected type %lu", scheduleType);
    return nil;
}

@end

