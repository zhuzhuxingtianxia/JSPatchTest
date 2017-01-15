//
//  JSPatch.h
//  JSPatch
//
//  Created by bang on 15/11/14.
//  Copyright (c) 2015 bang. All rights reserved.
//

#import <Foundation/Foundation.h>

const static NSString *rootUrl = @"";
static NSString *publicKey = @"-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDMPrkwMxpZwe+ypVR6I5uZ+NAn\nVSJI/fOAeq3DES7vQAUYZSV+zPT1JNtabFKApuN2HCI7ZRbRdXnwJK2kt9DRco6a\nB5zI9V+gkAjV/KLt8FtjFfzqGswjbhozTH3gkiyrWgJqp7s4XDz0F/wIoS/z/Skf\nay6ZuQOwqFLRvgJJQwIDAQAB\n-----END PUBLIC KEY-----";

typedef void (^JPUpdateCallback)(NSError *error);

typedef enum {
    JPUpdateErrorUnzipFailed = -1001,
    JPUpdateErrorVerifyFailed = -1002,
} JPUpdateError;

@interface JPLoader : NSObject
+ (BOOL)run;
+ (void)updateToVersion:(NSInteger)version loadURL:(NSString*)loadURL callback:(JPUpdateCallback)callback;
+ (void)runTestScriptInBundle;
+ (void)setLogger:(void(^)(NSString *log))logger;
+ (NSInteger)currentVersion;
@end
