//
//  EditPlayController.h
//  Stori
//
//  Created by Rob Bearman on 4/1/14.
//  Copyright (c) 2014 Hyperfine Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GooglePlus/GooglePlus.h>
#import "AmazonClientManager.h"
#import "AWSS3Provider.h"
#import "SlideShareJSON.h"
#import "StoriDownload.h"
#import "PlayStoriNotifier.h"
#import "AsyncImageCopy.h"

@protocol EditPlayControllerNavBarButtonDelegate <NSObject>
- (void)onNavBarEditButtonClicked;
- (void)onNavBarTrashButtonClicked;
- (void)onNavBarSelectPhotoButtonClicked;
- (void)onNavBarMainMenuButtonClicked;
- (void)onNavBarRecordingButtonClicked;
@end

typedef enum EditPlayMode {
    editPlayModeEdit = 0,
    editPlayModePlay = 1,
    editPlayModePreview = 2
} EditPlayMode;

@interface EditPlayController : UIViewController
    <UIPageViewControllerDataSource, UIPageViewControllerDelegate, AmazonClientManagerGoogleAccountDelegate, AWSS3ProviderDelegate, UIAlertViewDelegate, StoriDownloadDelegate, PlayStoriNotifierDelegate, AsyncImageCopyDelegate>

@property (strong, nonatomic) id<EditPlayControllerNavBarButtonDelegate> editPlayNavBarButtonDelegate;
@property (strong, nonatomic) IBOutlet UIButton *selectPhotoButton;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;
@property (strong, nonatomic) IBOutlet UIButton *editButton;
@property (strong, nonatomic) IBOutlet UIButton *mainMenuButton;
@property (strong, nonatomic) IBOutlet UIButton *trashButton;
@property (strong, nonatomic) IBOutlet UIImageView *editPlayImageView;
@property (nonatomic) EditPlayMode editPlayMode;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) SlideShareJSON *ssj;
@property (strong, nonatomic) NSString *slideShareName;
@property (strong, nonatomic) NSString *userUuid;
@property (nonatomic) int currentSlideIndex;
@property (nonatomic) int pendingSlideIndex;
@property (nonatomic) BOOL shouldDisplayOverlay;

- (void)addSlide:(int)newIndex;
- (void)deleteSlide:(NSString *)slideUuid withImage:(NSString *)imageFileName withAudio:audioFileName;
- (void)deleteImage:(NSString *)slideUuid withImage:(NSString *)imageFileName;
- (void)deleteAudio:(NSString *)slideUuid withAudio:(NSString *)audioFileName;
- (void)updateSlideShareJSON:(NSString *)slideUuid withImageFileName:(NSString *)imageFileName withAudioFileName:(NSString *)audioFileName withText:(NSString *)slideText;
- (void)updateSlideShareJSON:(NSString *)slideUuid withImageFileName:(NSString *)imageFileName withAudioFileName:(NSString *)audioFileName withText:(NSString *)slideText withForcedNulls:(BOOL)forceNulls;
- (NSString *)getSlideText:(NSString *)slideUuid;
- (int)getSlideCount;
- (int)getSlidePosition:(NSString *)slideUuid;
- (NSString *)getSlidesTitle;
- (void)setSlideShareTitle:(NSString *)title;
- (void)setCurrentSlidePosition:(int)position;
- (void)createNewSlideShow;
- (void)publishSlides;
- (void)shareSlides;
- (BOOL)isPublished;
- (void)reorderCurrentSlideTo:(int)slideIndex;
- (void)disconnectFromGoogle;
- (void)notifyForDownloadRequest:(BOOL)downloadIsForEdit withUserUuid:(NSString *)userUuid withName:(NSString *)slideShareName;
- (void)download:(BOOL)downloadIsForEdit withUserUuid:(NSString *)userUuid withName:(NSString *)slideShareName;
- (void)copyImageFilesToPhotosFolder:(NSString *)slideUuid;
- (void)playCurrentPlayStori;

@end
