//
//  EditPlayController.h
//  Stori
//
//  Created by Rob Bearman on 3/31/14.
//  Copyright (c) 2014 Hyperfine Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlideJSON.h"
#import "EditPlayPageController.h"

@class EditPlayPageController;

@interface EditPlayController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *userIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *userEmailLabel;
@property (weak, nonatomic) IBOutlet UIButton *listStorisButton;
@property (strong, nonatomic) LoginViewController *loginViewController;


@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) NSString *imageFileName;
@property (strong, nonatomic) NSString *audioFileName;
@property (strong, nonatomic) NSString *slideText;
@property (strong, nonatomic) NSString *slideUuid;
@property (strong, nonatomic) NSString *slideSharename;
@property (weak, nonatomic) EditPlayPageController *editPlayPageController;

- (void)initializeWithSlideJSON:(SlideJSON *)sj withSlideShareName:(NSString *)slideShareName withUuid:(NSString *)slideUuid fromPageController:(EditPlayPageController *)editPlayPageController;

@end
