//
//  FSLoginViewController.m
//  FashionApp
//
//  Created by ericbbpeng(彭博斌) on 2018/5/3.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSLoginViewController.h"

@interface FSLoginViewController ()

@end

@implementation FSLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *wxLogin = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [wxLogin setTitle:@"wx" forState:UIControlStateNormal];
    wxLogin.frame = fixRect(100, self.view.bottom - 100, 50, 50);
    [wxLogin addTarget:self action:@selector(wxLoginDidTap:)];
    [self.view addSubview:wxLogin];
    
    UIButton *qqLogin = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [qqLogin setTitle:@"qq" forState:UIControlStateNormal];
    qqLogin.frame = fixRect(200, self.view.bottom - 100, 50, 50);
    [qqLogin addTarget:self action:@selector(qqLoginDidTap:)];
    [self.view addSubview:qqLogin];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLoginSuccessNotification:)
                                                 name:@"FSLOGIN_SUCCESS"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLoginFailNotification:)
                                                 name:@"FSLOGIN_FAIL"
                                               object:nil];
}

- (void)loginFailWithResult:(NSDictionary *)aDict{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FSLOGIN_FAIL" object:nil];
}

- (void)wxLoginDidTap:(id)sender{
    [FSServiceRoute syncCallService:@"FSLoginService" func:@"wxLogin" withParam:nil];
}

- (void)qqLoginDidTap:(id)sender{
    [FSServiceRoute syncCallService:@"FSLoginService" func:@"qqLogin" withParam:nil];
}

- (void)handleLoginSuccessNotification:(NSNotification *)note{
    [self.navigationController popViewControllerAnimated:NO];
    DDLogDebug(@"login success");
}

- (void)handleLoginFailNotification:(NSNotification *)note{
    DDLogError(@"login fail");
}

@end
