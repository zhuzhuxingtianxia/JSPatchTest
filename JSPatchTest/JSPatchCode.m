//
//  JSPatchCode.m
//  MyPods
//
//  Created by Jion on 2017/1/3.
//  Copyright © 2017年 Youjuke. All rights reserved.
//

#import "JSPatchCode.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <netdb.h>

#define kJSPatchVersion(appVersion)   [NSString stringWithFormat:@"JSPatchVersion_%@", appVersion]

/*
 注意：一定要返回json格式。
 请求返回字段说明：
  file_name: js文件名
  app_version: app版本号
  js_version: js文件版本号 使用Integer类型
  js_url: js文件请求地址
 */

@implementation JSPatchCode
static BOOL _async;
+(void)asyncUpdate:(BOOL)async{
    //
    [JPLoader run];
    _async = async;
    //建议使用这种:路径中使用app的名字和app版本号命名，这样方便管理
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleNameKey];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *requestUrl = pacthRequestUrl(appName,appVersion);
    [JSPatchCode patchVersionCheck:requestUrl];
    
    /*
    //用于测试
    if (1) {
        //加载单个js文件
        [JSPatchCode patchVersionCheck:@"https://raw.githubusercontent.com/hotJSPatch/jsv/master/patchVersion"];
        
    }else{
        //加载zip文件
        //建议:路径中使用app的名字和app版本号命名，这样方便管理
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleNameKey];
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *requestUrl = [NSString stringWithFormat:@"https://github.com/hotJSPatch/%@%@/raw/master/patchVersion",appName,appVersion];
        [JSPatchCode patchVersionCheck:requestUrl];
    }
    */
}
static dispatch_semaphore_t semaphore;
+(void)patchVersionCheck:(NSString*)urlStr{
    //======因为下面的请求使用同步请求方法=================
    //会出现在没网的情况下卡在启动界面，所以在请求之前检测网络状态
    if (![JSPatchCode isUserNetOK]) {
        //获取补丁文件名
        NSString *patchFileName = [JSPatchCode currentJSFileName];
        //获取本地补丁文件
        [JSPatchCode getJSPatchWithFileName:patchFileName];
        return;
    }
    
    //使用信号量阻塞线程，实现同步请求
    //创建信号量
    if (!_async) {
        semaphore = dispatch_semaphore_create(0);
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    
    NSURLSessionDataTask *dataTask= [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSRange range = [string rangeOfString:@"{"];
            if (range.location == NSNotFound) {
                NSLog(@"error: network get data not a Dictionary or other error");
                return;
            }
            
            NSString *dicString = [string substringFromIndex:range.location];
            NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:[dicString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
            //版本管理
            [JSPatchCode mangerJSPatchVersion:resultDic];
        }else{
            //如果失败执行本地脚本
            //获取补丁文件名
            NSString *patchFileName = [JSPatchCode currentJSFileName];
            //获取本地补丁文件
            [JSPatchCode getJSPatchWithFileName:patchFileName];
            //发送信号
            if (!_async) {
                dispatch_semaphore_signal(semaphore);
            }
            
        }
        
    }];
    [dataTask resume];
    //等待
    if (!_async) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
}

+(void)mangerJSPatchVersion:(NSDictionary*)patchDic{
    //判断app版本是否对应
    if (patchDic && [JSPatchCode compareVersionNumber:patchDic[@"app_version"]] ==ZJOrderedSame) {
        //返回的补丁版本>本地的补丁版本
        if ([patchDic[@"js_version"] integerValue] > [JSPatchCode currentJSVersion]) {
            //获取最新的补丁版本
            [JSPatchCode jsPatchLoading:patchDic];
        }else if ([patchDic[@"js_version"] integerValue] == [JSPatchCode currentJSVersion]){
            //获取本地补丁文件
            [JSPatchCode getJSPatchWithFileName:patchDic[@"file_name"]];
            //发送信号
            if (!_async) {
                dispatch_semaphore_signal(semaphore);
            }
            
        }else if ([patchDic[@"js_version"] integerValue] < [JSPatchCode currentJSVersion]){
            //版本回滚
            [JSPatchCode removeLocalJSPatch];
            //重新获取回滚补丁
            [JSPatchCode jsPatchLoading:patchDic];
        }
        
    }else if (patchDic && [JSPatchCode compareVersionNumber:patchDic[@"app_version"]] ==ZJOrderedDescending){
        //更新了新的app版本，则删除本地脚本
        [JSPatchCode removeLocalJSPatch];
        //发送信号
        if (!_async) {
            dispatch_semaphore_signal(semaphore);
        }
    }
    
}

+(void)jsPatchLoading:(NSDictionary*)dict{
    NSString *urlString = dict[@"js_url"];
    if (!urlString || [urlString rangeOfString:@"http"].location == NSNotFound) {
        NSLog(@"get js_url failure");
        return;
    }
    NSString *filename = [urlString lastPathComponent];
    NSString *pathExtension = filename.pathExtension;
    if ([pathExtension isEqualToString:@"zip"]) {
        //执行下载zip压缩包
        [JPLoader updateToVersion:[dict[@"js_version"] integerValue] loadURL:dict[@"js_url"] callback:^(NSError *error) {
            if (!error) {
                 [JPLoader run];
                //保存最新补丁版本号和补丁文件名
                [JSPatchCode saveLatestJSVersion:[dict[@"js_version"] integerValue]];
                [JSPatchCode saveLatestJSFileName:dict[@"file_name"]];
                
            }
            //发送信号
            if (!_async) {
                dispatch_semaphore_signal(semaphore);
            }
        }];
        
    }else if ([pathExtension isEqualToString:@"js"]){
        [JPEngine startEngine];
        // 从网络拉回js脚本执行
        NSURLSessionDataTask *dataTask= [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (!error) {
                NSString *script = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                [JPEngine evaluateScript:script];
                //保存最新补丁版本号和补丁文件名
                [JSPatchCode saveLatestJSVersion:[dict[@"js_version"] integerValue]];
                [JSPatchCode saveLatestJSFileName:dict[@"file_name"]];
                //保存补丁数据到本地
                [JSPatchCode saveJSPatchToLocal:script fileName:dict[@"file_name"]];

            }
            //发送信号
            if (!_async) {
                dispatch_semaphore_signal(semaphore);
            }
        }];
        [dataTask resume];
    }
    
}

#pragma mark -- 数据管理
+(void)saveJSPatchToLocal:(NSString*)script fileName:(NSString*)filename{
    // script directory
    NSString *scriptDirectory = [self fetchScriptDirectory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:scriptDirectory]){
        [[NSFileManager defaultManager] createDirectoryAtPath:scriptDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *newFilePath = [scriptDirectory stringByAppendingPathComponent:filename];
    [[script dataUsingEncoding:NSUTF8StringEncoding] writeToFile:newFilePath atomically:YES];
    
    if (TARGET_IPHONE_SIMULATOR) {
        NSArray *subPaths = [NSHomeDirectory() componentsSeparatedByString:@"/"];
        
        NSString *path = [NSString stringWithFormat:@"Users/%@/Desktop/%@",subPaths[2],filename];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:path]) {
            [fileManager createFileAtPath:path contents:nil attributes:nil];
        }
        newFilePath = [NSString stringWithFormat:@"\n//文件保存路径：%@\n",newFilePath];
        script = [newFilePath stringByAppendingString:script];
        BOOL save = [[script dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];
        if (save) {
            NSLog(@"save to write file success");
        }else{
            NSLog(@"save failure");
        }
    }
    
    
}
+(void)getJSPatchWithFileName:(NSString*)fileName{
    NSString *scriptDirectory = [self fetchScriptDirectory];
    NSString *scriptPath = [scriptDirectory stringByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]){
        [JPEngine startEngine];
        [JPEngine evaluateScriptWithPath:scriptPath];
    }
}
+(void)removeLocalJSPatch{
    NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *scriptDirectory = [libraryDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"JSPatch/"]];
    if ([[NSFileManager defaultManager] removeItemAtPath:scriptDirectory error:nil]) {
        NSLog(@"remove sucess");
    }else{
        NSLog(@"remove failure");
    }
    
}

+ (NSString *)fetchScriptDirectory
{
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *scriptDirectory = [libraryDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"JSPatch/%@/", appVersion]];
    return scriptDirectory;
}

+ (NSInteger)currentJSVersion
{
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSInteger jsV = [[NSUserDefaults standardUserDefaults] integerForKey:kJSPatchVersion(appVersion)];
    return jsV;
}
+(void)saveLatestJSVersion:(NSInteger)version{
    if (!version) {
        return;
    }
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [[NSUserDefaults standardUserDefaults] setInteger:version forKey:kJSPatchVersion(appVersion)];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
+ (NSString*)currentJSFileName
{
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *filekey = [NSString stringWithFormat:@"JSPatchFileName_%@",appVersion];
    NSString *jsFileNam = [[NSUserDefaults standardUserDefaults] valueForKey:filekey];
    return jsFileNam;
}
+(void)saveLatestJSFileName:(NSString*)fileName{
    if (!fileName) {
        return;
    }
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *filekey = [NSString stringWithFormat:@"JSPatchFileName_%@",appVersion];
    [[NSUserDefaults standardUserDefaults] setValue:fileName forKey:filekey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -- app版本比较
+ (ZJComparisonResult)compareVersionNumber:(NSString*)str{
    if ([str rangeOfString:@"."].location != NSNotFound) {
        str = [str stringByAppendingString:@".0"];
    }
    NSArray *netVersionArr = [str componentsSeparatedByString:@"."];
    //build版本
    NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    if ([currentVersion rangeOfString:@"."].location != NSNotFound) {
        currentVersion = [currentVersion stringByAppendingString:@".0"];
    }
    NSArray *localVersionArr = [currentVersion componentsSeparatedByString:@"."];
    if (netVersionArr.count>localVersionArr.count) {
       NSMutableArray *tempArr = [NSMutableArray arrayWithArray:localVersionArr];
        [tempArr addObject:@"0"];
        localVersionArr = (NSArray*)tempArr;
    }else if (netVersionArr.count<localVersionArr.count){
        NSMutableArray *tempArr = [NSMutableArray arrayWithArray:netVersionArr];
        [tempArr addObject:@"0"];
        netVersionArr = (NSArray*)tempArr;
    }
    for (NSInteger i = 0; i<localVersionArr.count; i++) {
        NSInteger netVersion = [netVersionArr[i] integerValue];
        NSInteger localVersion = [localVersionArr[i] integerValue];
        if (netVersion > localVersion) {
            return ZJOrderedAscending;
        }else if (netVersion < localVersion){
            return ZJOrderedDescending;
        }
        
    }
    
    return ZJOrderedSame;
}
/********************************************************/
/*
 判断网络
 */
+(BOOL)isUserNetOK{
    if ([self networkWhenRequest] == 0) {
        return NO;
    }
    return YES;
}
+(NSInteger)networkWhenRequest{
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)
    struct sockaddr_in6 address;
    bzero(&address, sizeof(address));
    address.sin6_len = sizeof(address);
    address.sin6_family = AF_INET6;
#else
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
#endif
    
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&address);
    SCNetworkReachabilityFlags flags;
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    
    if (!didRetrieveFlags)
    {
        NSLog(@"Error. Could not recover network reachability flags");
        return NO;
    }
    
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));
    //不知道的状态
    NSInteger status = -1;
    //无网络状态
    if (isNetworkReachable == NO) {
        status = 0;
    }
#if	TARGET_OS_IPHONE
    //移动网络状态
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = 1;
    }
#endif
    //wifi状态
    else {
        status = 2;
    }
    
    return status;
}



@end
