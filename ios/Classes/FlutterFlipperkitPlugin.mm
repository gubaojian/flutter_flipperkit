#import "FlutterFlipperkitPlugin.h"
#import <FlipperKit/FlipperClient.h>
#import <FlipperKitUserDefaultsPlugin/FKUserDefaultsPlugin.h>
#import <FlipperKitNetworkPlugin/FlipperKitNetworkPlugin.h>
#import <SKIOSNetworkPlugin/SKIOSNetworkAdapter.h>
#import "FlipperReduxInspectorPlugin.h"

@implementation FlutterFlipperkitPlugin {
    FlipperClient *flipperClient;
    FlipperKitNetworkPlugin *flipperKitNetworkPlugin;
    FlipperReduxInspectorPlugin *flipperKitReduxInspectorPlugin;
    FKUserDefaultsPlugin *fKUserDefaultsPlugin;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        flipperClient = [FlipperClient sharedClient];
      
        flipperKitNetworkPlugin = [FlipperKitNetworkPlugin new];
        flipperKitReduxInspectorPlugin = [FlipperReduxInspectorPlugin new];
        fKUserDefaultsPlugin = [[FKUserDefaultsPlugin alloc] initWithSuiteName:nil];
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"flutter_flipperkit"
                                     binaryMessenger:[registrar messenger]];
    FlutterFlipperkitPlugin* instance = [[FlutterFlipperkitPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"clientAddPlugin" isEqualToString:call.method]) {
        [self clientAddPlugin:call result:result];
    } else if ([@"clientStart" isEqualToString:call.method]) {
        [self clientStart:call result:result];
    } else if ([@"clientStart" isEqualToString:call.method]) {
        [self clientStop:call result:result];
    } else if ([@"pluginNetworkReportRequest" isEqualToString:call.method]) {
        [self pluginNetworkReportRequest:call result:result];
    } else if ([@"pluginNetworkReportResponse" isEqualToString:call.method]) {
        [self pluginNetworkReportResponse:call result:result];
    } else if ([call.method hasPrefix:@"pluginReduxInspector"]) {
        [flipperKitReduxInspectorPlugin handleMethodCall: call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void) clientAddPlugin:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *pluginId = call.arguments[@"id"];

    if ([pluginId isEqualToString:@"Network"]) {
        [flipperClient removePlugin:flipperKitNetworkPlugin];
        [flipperClient addPlugin:flipperKitNetworkPlugin];
    } else if ([pluginId isEqualToString:@"Preferences"]) {
        [flipperClient removePlugin:fKUserDefaultsPlugin];
        [flipperClient addPlugin:fKUserDefaultsPlugin];
    } else if ([pluginId isEqualToString:@"ReduxInspector"]) {
        [flipperClient removePlugin:flipperKitReduxInspectorPlugin];
        [flipperClient addPlugin:flipperKitReduxInspectorPlugin];
    }
    result([NSNumber numberWithBool:YES]);
}

- (void) clientStart:(FlutterMethodCall*)call result:(FlutterResult)result {
    [flipperClient start];
    result([NSNumber numberWithBool:YES]);
}

- (void) clientStop:(FlutterMethodCall*)call result:(FlutterResult)result {
    [flipperClient stop];
    result([NSNumber numberWithBool:YES]);
}

- (void) pluginNetworkReportRequest:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSMutableArray<NSDictionary<NSString *, id> *> *headers = [self convertHeader:call];
    NSString *body = [self convertBody:call];
  
    NSDictionary<NSString *, id> *requestObject = @{
                                                    @"id": call.arguments[@"requestId"],
                                                    @"timestamp": call.arguments[@"timeStamp"],
                                                    @"method": call.arguments[@"method"],
                                                    @"url": call.arguments[@"uri"],
                                                    @"headers": headers,
                                                    @"data": body ? body : [NSNull null],
                                                    };
  
    [flipperKitNetworkPlugin send:@"newRequest"
                      sonarObject:requestObject];

    result([NSNumber numberWithBool:YES]);
}

- (void) pluginNetworkReportResponse:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSMutableArray<NSDictionary<NSString *, id> *> *headers = [self convertHeader:call];
    NSString *body = [self convertBody:call];
  
    NSDictionary<NSString *, id> *responseObject = @{
                                                     @"id": call.arguments[@"requestId"],
                                                     @"timestamp": call.arguments[@"timeStamp"],
                                                     @"status": call.arguments[@"statusCode"],
//                                                     @"reason": nil,
                                                     @"headers": headers,
                                                     @"data": body ? body : [NSNull null],
                                                     };
    [flipperKitNetworkPlugin send:@"newResponse" sonarObject:responseObject];
  
    result([NSNumber numberWithBool:YES]);
}

- (NSMutableArray<NSDictionary<NSString *, id> *> *) convertHeader:(FlutterMethodCall*)call {
    NSDictionary *argHeaders = call.arguments[@"headers"];
  
    NSMutableArray<NSDictionary<NSString *, id> *> *headers = [NSMutableArray new];
    for (NSString *key in [argHeaders allKeys]) {
        NSDictionary<NSString *, id> *header = @{
                                                 @"key": key,
                                                 @"value": argHeaders[key]
                                                 };
        [headers addObject: header];
    }
    return headers;
}

- (NSString *) convertBody:(FlutterMethodCall*)call {
    NSData *data = nil;
  
    try {
        NSDictionary *argBody = call.arguments[@"body"];

        NSError *error;
        data = [NSJSONSerialization dataWithJSONObject:argBody
                                               options:NSJSONReadingMutableContainers
                                                 error:&error];
    } catch (NSException *e) { }
  
    if (data == nil) {
        try {
            NSString *jsonString = call.arguments[@"body"];
            data = [NSData dataWithBytes:jsonString.UTF8String length:jsonString.length];
        } catch (NSException *e) {}
    }
  
    return data ? [data base64EncodedStringWithOptions: 0] : nil;
}

@end
