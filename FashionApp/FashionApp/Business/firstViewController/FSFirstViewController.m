//
//  ViewController.m
//  FashionApp
//
//  Created by 1 on 2018/4/9.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSFirstViewController.h"
#import "FSCameraViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import "QQWalletConfigManager.h"
#import "FSUploadHelpService.h"
#import "FSLoginViewController.h"

CFDataRef data;
SInt32 messageID = 0x1111; // Arbitrary
CFTimeInterval timeout = 10.0;
CFMessagePortRef localPort;
CFMessagePortRef localPort111;
static NSMachPort *g_mainPort = nil;


@interface FSFirstViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate,NSMachPortDelegate>
{
    TestNetwork *t;
}
@property(nonatomic, strong)NSString *uploadTempFilePath;
@end

@implementation FSFirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor redColor];
    
    UIButton *bt = [[UIButton alloc] initWithFrame:fixRect(100, 100, 100, 100)];
    bt.backgroundColor = [UIColor greenColor];
    [bt addTarget:self action:@selector(testbt) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bt];


    
    UIButton *bt2 = [[UIButton alloc] initWithFrame:CGRectMake(bt.bottom, FIXSIZE(200), FIXSIZE(100), FIXSIZE(120))];
    bt2.backgroundColor = [UIColor yellowColor];
    [bt2 addTarget:self action:@selector(testCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bt2];
    
    UIButton *bt3 = [[UIButton alloc] initWithFrame:CGRectMake(bt.left, bt2.bottom, FIXSIZE(100), FIXSIZE(120))];
    bt3.backgroundColor = [UIColor blueColor];
    [bt3 addTarget:self action:@selector(testLogin) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bt3];
    
    [[QQWalletConfigManager sharedManager] requestConfigWhenLoginOrReconnect];
    
    [self testMachPort];

    [FSServiceRoute asyncCallService:@"FSMsgService" func:@"subcripitonBusiMsgForCmd:recvPushMsg:" withParam:@{@"tagcont123ent":self} completion:^(NSDictionary *info) {
        DebugLog(@"msginfo=%@",info);
    }];

    
}



static CFDataRef Callback(CFMessagePortRef port,
                          SInt32 messageID,
                          CFDataRef data,
                          void *info)
{
    DebugLog(@"message");
    return nil;
}

static CFDataRef Callback11(CFMessagePortRef port,
                          SInt32 messageID,
                          CFDataRef data,
                          void *info)
{
    DebugLog(@"message11");
    return nil;
}


- (void)testMachPort
{

    localPort =
    CFMessagePortCreateLocal(nil,
                             CFSTR("com.example.app.port.server"),
                             Callback,
                             nil,
                             nil);
    CFRunLoopSourceRef runLoopSource =
    CFMessagePortCreateRunLoopSource(nil, localPort, 0);

    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       runLoopSource,
                       kCFRunLoopCommonModes);
    
    localPort111 =
    CFMessagePortCreateLocal(nil,
                             CFSTR("com.example.app.port.server"),
                             Callback11,
                             nil,
                             nil);
    CFRunLoopSourceRef runLoopSource11 =
    CFMessagePortCreateRunLoopSource(nil, localPort111, 0);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       runLoopSource11,
                       kCFRunLoopCommonModes);
    
//    NSPort *tempPort = [NSMachPort portWithMachPort:0x2222];//[[NSMachPort alloc]initWithMachPort:44815];
//////    NSMessagePort *msgPort = [];
////
////    [tempPort setDelegate:self];
//
//    [[NSRunLoop currentRunLoop] addPort:g_mainPort forMode:NSDefaultRunLoopMode];
//    [[NSRunLoop currentRunLoop]runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];

}

- (void)handlePortMessage:(id )message
{
    NSArray *array = [message valueForKeyPath:@"components"];
    DebugLog(@"handMsg");
}
//- (CGRect)rect:(CGFloat)x y:(cg)
//{
//    CGRect rect={0};
//    rect.origin.x = FIXSIZE(x);
//    rect.origin.y = FIXSIZE(y);
//    rect.size.width = FIXSIZE(width);
//    rect.size.height = FIXSIZE(height);
//    return rect;
//}

- (void)tttt
{
    DebugLog(@"tttttttt89");
}
- (void)testbt
{
//    [self performSelector:@selector(tttt) withObject:nil];
    
//    CFMessagePortRef remortPort =
//    CFMessagePortCreateLocal(nil,
//                             CFSTR("com.example.app.port.server111"),
//                             nil,
//                             nil,
//                             nil);
    CFMessagePortRef remortPort = CFMessagePortCreateRemote(nil, CFSTR("com.example.app.port.server"));
    CFDataRef my_cfdata = CFBridgingRetain([@"hello" dataUsingEncoding:4]);
    SInt32 status =
    CFMessagePortSendRequest(remortPort,
                             0,
                             my_cfdata,
                             timeout,
                             timeout,
                             NULL,
                             NULL);
    if (status == kCFMessagePortSuccess) {
        DebugLog(@"message send");
    }
    
    return ;
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    NSString *requiredMediaType1 = ( NSString *)kUTTypeMovie;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    NSArray *arrMediaTypes=[NSArray arrayWithObjects:requiredMediaType1,nil];
    [picker setMediaTypes: arrMediaTypes];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
    
//    DDLogDebug(@"ddlogdebug_111111");
//    if(!t)
//    {
//        t = [[TestNetwork alloc] init];
//    }
//    [t sendMsg];
//    DDLogInfo(@"ddloginfo_111111");
//    DDLogVerbose(@"ddlogverbose_1111111");
//    DDLogError(@"ddlogerror_1111111");
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSURL *sourceURL = [info objectForKey:UIImagePickerControllerMediaURL];
    NSURL *newVideoUrl ; //一般.mp4
    NSString* tempPath = [self TempFilePathWithExtension:@"mp4"];
    newVideoUrl = [NSURL fileURLWithPath:tempPath];
    self.uploadTempFilePath = tempPath;
    //self.imagePreviewView.image = image;
    [picker dismissViewControllerAnimated:NO completion:^{
        
    }];
    [self convertVideoQuailtyWithInputURL:sourceURL outputURL:newVideoUrl completeHandler:nil];
    
    
    
    
    //    UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
    //    [UIImagePNGRepresentation(image) writeToFile:tempPath atomically:YES];
    //    self.uploadTempFilePath = tempPath;
    //    self.imagePreviewView.image = image;
    //    [picker dismissViewControllerAnimated:NO completion:^{
    //
    //    }];
}

- (void) convertVideoQuailtyWithInputURL:(NSURL*)inputURL
                               outputURL:(NSURL*)outputURL
                         completeHandler:(void (^)(AVAssetExportSession*))handler
{
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    //  NSLog(resultPath);
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse= YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         switch (exportSession.status) {
             case AVAssetExportSessionStatusCancelled:
                 NSLog(@"AVAssetExportSessionStatusCancelled");
                 break;
             case AVAssetExportSessionStatusUnknown:
                 NSLog(@"AVAssetExportSessionStatusUnknown");
                 break;
             case AVAssetExportSessionStatusWaiting:
                 NSLog(@"AVAssetExportSessionStatusWaiting");
                 break;
             case AVAssetExportSessionStatusExporting:
                 NSLog(@"AVAssetExportSessionStatusExporting");
                 break;
             case AVAssetExportSessionStatusCompleted:
                 NSLog(@"AVAssetExportSessionStatusCompleted");
                 self.uploadTempFilePath = [outputURL path];
                 break;
             case AVAssetExportSessionStatusFailed:
                 NSLog(@"AVAssetExportSessionStatusFailed");
                 break;
         }
     }];
}

-(NSString *) TempFilePathWithExtension:(NSString*) extension{
    NSString* fileName = [NSUUID UUID].UUIDString;
    NSString* path = NSTemporaryDirectory();
    path = [path stringByAppendingPathComponent:fileName];
    path = [path stringByAppendingPathExtension:extension];
    return path;
}

- (void)testCamera{
    
    DDLogDebug(@"显示ddlogdebug");
    DDLogInfo(@"显示ddlonginfo");
    DDLogVerbose(@"333333333ddddd");
    
    NSPort *currentPort = [[NSPort alloc] init];
//    [[NSRunLoop currentRunLoop]addPort:mainPort forMode:NSDefaultRunLoopMode];
    NSData *he = [@"testPort" dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *testa = [NSMutableArray arrayWithObject:he];
    
    NSPort *recvPort = [NSMachPort portWithMachPort:64566];
    
    [recvPort sendBeforeDate:[NSDate date] msgid:100 components:testa from:currentPort reserved:0];
    return;
    
//    FSCameraViewController *vc = [[FSCameraViewController alloc] init];
//    [self.navigationController pushViewController:vc animated:YES];
    if(!t)
    {
        t = [[TestNetwork alloc] init];
    }
//    if(self.uploadTempFilePath)
    {
        [t sendMsg:self.uploadTempFilePath];
    }

}

- (void)testLogin{
    UIViewController *vc = [[FSLoginViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

@interface TestNetwork () <FSUploadCallBack>
{
    FSUploadConfig *config;
    FSUploadHelpService  *service;
    int a;
}
@end

@implementation TestNetwork

- (instancetype)init
{
    if(self = [super init])
    {
        service = [[FSUploadHelpService alloc] init];
        [FSServiceRoute asyncCallService:@"FSMsgService" func:@"subcripitonBusiMsgForCmd:recvPushMsg:" withParam:@{@"tagcont123ent":self} completion:^(NSDictionary *info) {
            DebugLog(@"msginfo=%@",info);
        }];
    }
    return self;
}

//- (NSString *)serviceName
//{
//    return @"VAC.KiddyTestServer.KiddyTestObj";
//}
//
//- (NSString *)funcName
//{
//    return @"json";
//}
//
//- (NSString *)requestJceClass
//{
//    return @"QZJVacJsonReq";
//}
//
//- (NSString *)responseJceClass
//{
//    return @"QZJVacJsonReq";
//}

- (void)haha
{
    
}

- (void)uploadFinish:(NSDictionary *)dict resourcePath:(NSString *)path error:(NSError *)error
{
    DebugLog(@"testUploasFinish=%@ path=%@",dict, path);
}

- (void)uploadProcess:(NSString *)path sendByte:(long long)sendByte totalByte:(long long)totalBtype
{
    DebugLog(@"testUploasProcess=%lld dd=%lld path=%@",sendByte,totalBtype, path);
}

//针对多个files上传，都上传完了后的回调
- (void)commitFinish:(NSDictionary *)dict error:(NSError *)error
{
    DebugLog(@"testcommitFinish=%@",dict);
}

- (NSDictionary *)busiInfoCommit:(NSDictionary*)uploadInfo
{
    return uploadInfo;
}

- (void)sendMsg:(NSString *)videoPath
{
    config = [[FSUploadConfig alloc] init];
    
    
    
    NSString *tmpDir = NSTemporaryDirectory();
//    NSString *path = [NSString stringWithFormat:@"%@%@",tmpDir,@"video.mp4"];
    NSString *path = [NSString stringWithFormat:@"%@%@",tmpDir,@"1234.png"];
    NSString *path1 = [NSString stringWithFormat:@"%@%@",tmpDir,@"2345.png"];
//    if(a==0)
//    {
        config.fileUploadPaths = @[path,path1];
//        a++;
//    }
//    else
//    {
//        config.fileUploadPaths = @[path1];
//    }
//    config.videoUploadPath = path;
    config.resourceType = UPLoadReousrce_picture;
//    config.resourceType = UPLoadReousrce_video;
    config.signatureServantName = @"Style.FeedOperationServer.FeedOperationObj";
    config.signaturefuncName = @"ApplyUpload";
    config.commitServantName = @"Style.FeedOperationServer.FeedOperationObj";
    config.commitfuncName = @"PublishFeed";
    config.comitReqJceName = @"FSStylePublishFeedReq";
    config.comitRspJceName = @"FSStylePublishFeedRsp";
    [service uploadFile:config callback:self];
    
///Users/a1/Library/Developer/CoreSimulator/Devices/11EC494F-91D6-4889-9F4D-58768B5BEBCD/data/Containers/Data/Application/131C1B54-3E3F-458D-98A1-3B4A64C87724/tmp/1234.mp4
    
//    NSString *tmpDir = NSTemporaryDirectory();
//    NSString *path = [NSString stringWithFormat:@"%@%@",tmpDir,@"1234.mp4"];
//    [self upLoadVideoPath:path result:^(NSDictionary *result, int retCode) {
//
//    } procee:^(NSInteger bytesUpload, NSInteger bytesTotal) {
//
//    }];
    
//    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
////    [dict setObject:@"VAC.KiddyTestServer.KiddyTestObj" forKey:@"servantName"];
////    [dict setObject:@"json" forKey:@"funcName"];
////    [dict setObject:@"QZJVacJsonReq" forKey:@"requestJceClass"];
////    [dict setObject:@"QZJVacJsonReq" forKey:@"responseJceClass"];
//    [dict setObject:@[@"121",@"23344"] forKey:@"input_list"];
//    [dict setObject:@"1213" forKey:@"input"];
//    [dict setObject:@{@"1111":@"22222"} forKey:@"input_map"];
//
//        NSMutableDictionary *mdict = [self packetReqParamSerName:@"VAC.KiddyTestServer.KiddyTestObj" funcName:@"json" reqJceName:@"QZJVacJsonReq" resposeJceName:@"QZJVacJsonReq" busDict:dict];
//
//    [self sendRequestDict:mdict completion:^(NSDictionary *busDict, NSError *bizError) {
//
//    }];
//    NSData *data = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
//    [self sendRequestData:data cmd:@"srf_proxy" completion:^(NSString *cmd, NSData *data, NSError *bizError) {
//
//    }];
    
//    [FSServiceRoute  syncCallService:@"FSLoginService" func:@"qqlogin" withParam:nil];
}
- (void)dealloc
{
    DebugLog(@"ceshi");
}
@end
