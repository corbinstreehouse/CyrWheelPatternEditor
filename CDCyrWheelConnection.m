//
//  CDCyrWheelConnection.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/1/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDCyrWheelConnection.h"
#import "CDCyrWheelPattern.h"

static const char *CDWheelCommandToPath[] = {
    "command/next_pattern", //CDCyrWheelCommandNextPattern,
    "command/prior_pattern", //CDCyrWheelCommandPriorPattern,
    "command/next_sequence", // CDCyrWheelCommandNextSequence,
    "command/prior_sequence", // CDCyrWheelCommandPriorSequence,
    "command/restart_sequence", //CDCyrWheelCommandRestartSequence,
    "command/start_calibration", // CDCyrWheelCommandStartCalibrating,
    "command/end_calibration", //CDCyrWheelCommandEndCalibrating,
    "command/cancel_calibration", //CDCyrWheelCommandEndCalibrating,
    "command/start_saving_gyro_data", // CDCyrWheelCommandStartSavingGyroData,
    "command/end_saving_gyro_data", // CDCyrWheelCommandEndSavingTyroData,
};
#include <arpa/inet.h>

@interface NSString(IPValidation)

- (BOOL)isValidIPAddress;


@end

@implementation NSString (IPValidation)

- (BOOL)isValidIPAddress
{
    const char *utf8 = [self UTF8String];
    int success;
    
    struct in_addr dst;
    success = inet_pton(AF_INET, utf8, &dst);
    if (success != 1) {
        struct in6_addr dst6;
        success = inet_pton(AF_INET6, utf8, &dst6);
    }
    
    return (success == 1 ? TRUE : FALSE);
}

@end

@interface CDCyrWheelConnection() {
@private
    RKObjectManager *_objectManager;
}

@property (readonly, retain) RKObjectManager *objectManager;

@end

@implementation CDCyrWheelConnection

- (id)init {
    self = super.init;
    return self;
}

- (NSURL *)_baseURL {
    NSAssert(self.name != nil, @"name must be set before accessing the object");
    // always add .local, unless it is there
    NSString *host = self.name;
    if (host.isValidIPAddress) {
        
    } else if (![self.name hasSuffix:@".local"]) {
        host = [host stringByAppendingString:@".local"];
    }
  //  return [[NSURL alloc] initWithScheme:@"http" host:host path:@"/"];
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", host]];
}

- (void)_initializeManagerIfNeeded {
    if (_objectManager == nil) {
        AFHTTPClient* client = [[AFHTTPClient alloc] initWithBaseURL:[self _baseURL]];
        
        // HACK: Set User-Agent to Mac OS X so that Twitter will let us access the Timeline
        [client setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]]];
        
        //we want to work with JSON-Data
        [client setDefaultHeader:@"Accept" value:RKMIMETypeJSON];
//        [client setDefaultHeader:@"Accept" value:RKMIMEType];
        //    [client setDefaultHeader:@"Accept" value:RKMIMETypeXML];
        
        // Initialize RestKit
        _objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
        
        // Setup our object mappings
        RKObjectMapping *wheelSequenceMapping = [RKObjectMapping mappingForClass:[CDCyrWheelSequence class]];
        [wheelSequenceMapping addAttributeMappingsFromDictionary:@{ @"name" : @"name", @"editable" : @"editable" }];
        
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:wheelSequenceMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
        [_objectManager addResponseDescriptor:responseDescriptor];
        
        RKObjectMapping *requestMapping = [RKObjectMapping requestMapping]; // objectClass == NSMutableDictionary
        [requestMapping addAttributeMappingsFromArray:@[ @"name", @"editable", @"action"]];
        

//        RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[Article class] rootKeyPath:@"article" method:RKRequestMethodAny];
        RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[CDCyrWheelSequence class] rootKeyPath:@"sequences" method:RKRequestMethodAny];
        [_objectManager addRequestDescriptor:requestDescriptor];
        
        RKObjectMapping *patternRequestMapping = [RKObjectMapping requestMapping]; // objectClass == NSMutableDictionary
        [patternRequestMapping addAttributeMappingsFromArray:@[ @"patternEndCondition", @"patternType"]];
         RKRequestDescriptor *requestDescriptor2 = [RKRequestDescriptor requestDescriptorWithMapping:patternRequestMapping objectClass:[CDCyrWheelPattern class] rootKeyPath:nil method:RKRequestMethodAny];
         [_objectManager addRequestDescriptor:requestDescriptor2];

        
        [_objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[CDCyrWheelSequence class] pathPattern:@"/sequences/:name" method:(RKRequestMethodDELETE | RKRequestMethodGET)]];
        [_objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[CDCyrWheelSequence class] pathPattern:@"/sequences/:name/:action" method:RKRequestMethodPOST]];
//        [manager.router.routeSet addRoute:[RKRoute routeWithClass:[GGSegment class] pathPattern:@"/segments/:segmentID\\.json" method:RKRequestMethodGET]];
     //   [_objectManager.router.routeSet addRoute:[RKRoute routeWithName:@"play_sequence" pathPattern:@"/sequences/:name/play" method:RKRequestMethodPOST]];


    }
}

- (RKObjectManager *)objectManager {
    [self _initializeManagerIfNeeded];
    return _objectManager;
}

@synthesize name;

-(void)dealloc {
    self.name = nil;
    _objectManager = nil;
}

- (BOOL)isAlive {
    return YES;
}


- (void)sendCommand:(CDCyrWheelCommand)command success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
 {
    // Changing commands means we have to update our array
    NSParameterAssert(command >= 0 && command <= CDCyrWheelCommandEndSavingGyroData);
    NSParameterAssert((CDCyrWheelCommandEndSavingGyroData + 1) == (sizeof(CDWheelCommandToPath) / sizeof(char*)));
    
    const char *commandPathStr = CDWheelCommandToPath[command];
    
    NSString *commandPath = [NSString stringWithCString:commandPathStr encoding:NSUTF8StringEncoding];
    [self.objectManager getObject:nil path:commandPath parameters:nil success:success failure:failure];
}

- (void)uploadNewSequence:(CDCyrWheelSequence *)sequence atURL:(NSURL *)url success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    NSError *error = NULL;
    // bah, main thread...slow!
    NSData *data = [[NSData alloc] initWithContentsOfURL:url options:0 error:&error];
    if (data != nil) {
        // Serialize the Article attributes then attach a file
        NSMutableURLRequest *request = [self.objectManager multipartFormRequestWithObject:sequence method:RKRequestMethodPOST path:@"/sequences/add" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:data
                                    name:@"new_file"
                                fileName:sequence.name
                                mimeType:@"application/x-pattern"]; //
     
        }];
        RKObjectRequestOperation *operation = [self.objectManager objectRequestOperationWithRequest:request success:success failure:failure];
        [self.objectManager enqueueObjectRequestOperation:operation]; // NOTE: Must be enqueued rather than started
    } else if (error) {
        if (failure) {
            failure(nil, error);
        }
    }
}

//- (void)request:(RKRequest *)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
//    NSLog
//}


- (void)getSequencesWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self.objectManager getObject:nil path:@"/sequences/" parameters:nil success:success failure:failure];
}

- (void)cancelAllObjectRequests {
    [self.objectManager cancelAllObjectRequestOperationsWithMethod:RKRequestMethodAny matchingPathPattern:@"/sequences/"];
}

- (void)playSequence:(CDCyrWheelSequence *)sequence {
    // Don't know how to pass an extra parameter
//    NSString *path = [[self.objectManager.router URLForObject:sequence method:RKRequestMethodGET] relativeString];
    // Don't care if it fails...
    sequence.action = @"play";
    [self.objectManager postObject:sequence path:nil parameters:nil success:NULL failure:NULL];
    sequence.action = nil;
}

- (void)deleteSequences:(NSArray *)sequences success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {

}

- (void)deleteSequence:(CDCyrWheelSequence *)sequence {
    // Don't know how to pass an extra parameter
    //    NSString *path = [[self.objectManager.router URLForObject:sequence method:RKRequestMethodGET] relativeString];
    // Don't care if it fails...
//    sequence.action = @"play";
    [self.objectManager deleteObject:sequence path:nil parameters:nil success:NULL failure:NULL];
    // TODO: reload]
}

- (void)setDynamicPatternItem:(CDCyrWheelPattern *)pattern {
    [self.objectManager postObject:pattern path:nil parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSLog(@"cool");
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"not coool");
    }];
    
}


@end
