# JSPatchTest
使用github实现补丁下发 ，首先要接入<a href = "https://github.com/bang590/JSPatch"> JSPatch </a>
## 1.支持两种文件下发
支持JSPatch单个js文件的下发
支持JSPatch的zip压缩包的下发，zip必须包含一个main.js文件。
单个文件和压缩包只能选择其中的一种方式。若开始使用单个文件，后来使用zip文件，那么原来的文件将被覆盖
## 2.补丁下发分为两次请求
第一次返回格式及字段
主要用于版本的判断比较
```
/*
 注意：一定要返回json格式。
 请求返回字段说明：
  file_name: js文件名
  app_version: app版本号
  js_version: js文件版本号 使用Integer类型
  js_url: js文件请求地址
 */
 第二次才真正的去加载补丁包。
 ```
 
 #3.使用zip文件下发
 该方式，需要先生成RSA密钥。
 ```
#生成RSA密钥 命令行依次写入
#cd 文件夹
#openssl
#genrsa -out rsatest_private_key.pem 1024
#pkcs8 -topk8 -inform PEM -in rsatest_private_key.pem -outform PEM –nocrypt
#rsa -in rsatest_private_key.pem -pubout -out rsatest_public_key.pem
```
配置RSA密钥
```
#文本形式打开rsatest_public_key.pem替换 JPLoader.h 里的 publicKey。
#打开rsatest_private_key.pem替换tools/pack.php 里的privateKey。
```

## 4.脚本打包
复制tools包含pack.php的文件夹放在桌面（其他地方也行）。
把测试成功的main.js和其他js文件放入tools文件夹。
```
#通过命令行 cd 命令到此文件夹。
#敲入命令 php packer.php main.js other.js -o v1，文件夹下会生成一个v1.zip的包。
```
## 5.使用自定义的下发链接
找到JPLoader文件，我们不使用rootUrl的方式，所以需要修改updateToVersion方法
```
+ (void)updateToVersion:(NSInteger)version  callback:(JPUpdateCallback)callback;//原来的方法
//修改后的方法：添加一个参数，加载脚本的链接
+ (void)updateToVersion:(NSInteger)version loadURL:(NSString*)loadURL callback:(JPUpdateCallback)callback;
   // create url request
//    NSString *downloadKey = [NSString stringWithFormat:@"/%@/v%@.zip", appVersion, @(version)];
//    NSURL *downloadURL = [NSURL URLWithString:[rootUrl stringByAppendingString:downloadKey]];//
/*注释上面的两句代码，使用下面的代码替换*/
    if (!loadURL) {
        if (JPLogger) JPLogger([NSString stringWithFormat:@"JSPatch: updateToVersion: loadURL = nil"]);
        return;
    }
    NSURL *downloadURL = [NSURL URLWithString:loadURL];
```
## 6. 测试下发的zip文件
若使用 XCode8 接入，需要在项目 Capabilities 打开 Keychain Sharing 开关，否则在模拟器下载脚本后会出现 decompress error, md5 didn't match 错误（真机无论是否打开都没问题）：
<br>
TARGETS -> Capabilities -> Keychain Sharing 设置为YES .
