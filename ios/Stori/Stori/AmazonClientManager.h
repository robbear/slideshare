/*
 * Copyright 2010-2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>
#import <AWSSecurityTokenService/AWSSecurityTokenService.h>
#import "Constants.h"

@protocol AmazonClientManagerGoogleAccountDelegate;

@interface AmazonClientManager:NSObject<GPPSignInDelegate> {}
@property (nonatomic, strong) id<AmazonClientManagerGoogleAccountDelegate> amazonClientManagerGoogleAccountDelegate;
@property (strong, nonatomic) GPPSignIn *signIn;
@property (nonatomic) BOOL isInDisconnect;

- (void)reloadGSession;
- (void)initGPlusLogin;
- (void)initSharedGPlusLogin;
- (void)disconnectFromSharedGoogle;
- (BOOL)silentGPlusLogin;
- (BOOL)silentSharedGPlusLogin;
- (AmazonS3Client *)s3;

+ (AmazonClientManager *)sharedInstance;

- (bool)isLoggedIn;
- (bool)hasCredentials;
- (void)wipeAllCredentials;

@end

@protocol AmazonClientManagerGoogleAccountDelegate <NSObject>
- (void)googleSignInComplete:(BOOL)success withError:(NSError *)error;
- (void)googleDisconnectComplete:(BOOL)success;
@end
