//
//  JSPatchCode.h
//  MyPods
//
//  Created by Jion on 2017/1/3.
//  Copyright © 2017年 Youjuke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JPEngine.h"
#import "JPLoader.h"

typedef NS_ENUM(NSInteger, ZJComparisonResult)
{
    ZJOrderedAscending = -1L,//升序
    ZJOrderedSame,
    ZJOrderedDescending//降序
};

@interface JSPatchCode : NSObject
/*
 同步从网络拉回js脚本
 在.m文件中，修改github地址为你自己的git地址
 自定义修改JPLoader的 updateToVersion方法
 */
+(void)syncUpdate;

/*
 -----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDMPrkwMxpZwe+ypVR6I5uZ+NAn\nVSJI/fOAeq3DES7vQAUYZSV+zPT1JNtabFKApuN2HCI7ZRbRdXnwJK2kt9DRco6a\nB5zI9V+gkAjV/KLt8FtjFfzqGswjbhozTH3gkiyrWgJqp7s4XDz0F/wIoS/z/Skf\nay6ZuQOwqFLRvgJJQwIDAQAB\n
 -----END PUBLIC KEY-----
 
 -----BEGIN PRIVATE KEY-----
 MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBALGEwMH7lO1auVxN
 aF/qDCveyFXnvgnnuplPxRtUEbBpcVxKR29JAUKTWnvtlfKZXp/5T4wd3g+i6tlY
 U2xQeZesBdD1NYIrmYbGRxEiVHmUc/C7d8d34sB3BQPXaiBNn2OFq1l8Pn20r6CG
 ewHMfj1lrwfDlVYjLMl8E6lzSLG5AgMBAAECgYEAkOlY3UG9aiEEbbf2+005EFr1
 2UKrXLShG+QFeHChXAxHcNpmBA9piup1E/N306mlmBvR9wSusL8CzdgPib0L9Ap6
 dh3W0vJGmndF4AgeljCXe0cRPQOFdeQrI9g1txmkpSNWeMQamXoHYoDKisf2btPi
 hY/ZLy/VSErsBQxCAnECQQDl9XRoysSG0OKeoxXnY9n6sXgwlbX8WtlwBx/zgdvA
 sRajf5O5Mci417cQ+hGYOCHJKUr8wcKRbJrFHymscTPNAkEAxZ8L8QKn0XW+qQnf
 5cah5FBLGajVOD1xmhKE07sZcbz3dFvX7t/8shJV/p8cUhuwSfLMT+5wpbeC3rB5
 SWihnQJAadrLc1GjlcuiBhRciN9WACihgvvngfrwDLm644Tre5AJM8oOXjmkhDII
 ezAh2Ug9hTQU6LTos7iipgrqTA7wIQJBAL3ulWCGh9n1S1BVcD37gR7Y2MUJkhui
 WiuVPtnsCZFZ546KsucfmVNf8gxsyaBUgkMgOqNb7CIpVHtIqtkV2bUCQFDyouIP
 nAYaDx9reVnR7KL0RrPsj2HOF58JdUuS4yTLKkI34OZgKXAfmnH3Ww53HAMFYbIg
 CzMt0eUfoIFZgdc=
 -----END PRIVATE KEY-----

 
 */

@end
