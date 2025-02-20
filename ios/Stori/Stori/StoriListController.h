//
//  StoriListController.h
//  Stori
//
//  Created by Rob Bearman on 3/20/14.
//  Copyright (c) 2014 Hyperfine Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWSS3Provider.h"
#import "EditPlayController.h"

@interface StoriListController : UITableViewController <UITableViewDataSource, UITableViewDelegate, AWSS3ProviderDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) EditPlayController *editPlayController;

@end
