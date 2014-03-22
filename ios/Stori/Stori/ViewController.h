//
//  ViewController.h
//  Stori
//
//  Created by Rob Bearman on 3/1/14.
//  Copyright (c) 2014 Hyperfine Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GooglePlus/GooglePlus.h>
#import "AmazonClientManager.h"
#import "AWSS3Provider.h"
#import "LoginViewController.h"

@class GPPSignInButton;

@interface ViewController : UIViewController <AmazonClientManagerGoogleAccountDelegate, AWSS3ProviderDelegate>

@property (weak, nonatomic) IBOutlet UILabel *userIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *userEmailLabel;
@property (weak, nonatomic) IBOutlet UIButton *amazonLoginButton;
@property (weak, nonatomic) IBOutlet UIButton *disconnectButton;
@property (weak, nonatomic) IBOutlet UIButton *testS3Button;
@property (weak, nonatomic) IBOutlet UIButton *listStorisButton;

@property (strong, nonatomic) LoginViewController *loginViewController;
@property (strong, nonatomic) AWSS3Provider *awsS3Provider;

@end
