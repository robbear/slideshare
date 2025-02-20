//
//  EditPlayFragmentController.m
//  Stori
//
//  Created by Rob Bearman on 4/1/14.
//  Copyright (c) 2014 Hyperfine Software. All rights reserved.
//

#import "EditPlayFragmentController.h"
#import "AmazonSharedPreferences.h"
#import "STOSettingsController.h"
#import "StoriListController.h"
#import "STOUtilities.h"
#import "STOPreferences.h"
#import "UIImage+Resize.h"

#define HIDE_LEFTRIGHTARROW_BUTTONS

#define ZOOM_VIEW_TAG 100
#define ZOOM_STEP 1.5

#define ALERTVIEW_DIALOG_SLIDETEXT 1
#define ALERTVIEW_DIALOG_STORITITLE 2
#define ALERTVIEW_DIALOG_OVERWRITE_AUDIO 3

#define ACTIONSHEET_REORDER 2

@interface EditPlayFragmentController ()
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (nonatomic) BOOL isRecording;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) BOOL cancelAsyncPlay;
@property (nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic) float currentZoomScale;
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center;
- (void)deleteSlideData;
- (BOOL)hasImage;
- (BOOL)hasAudio;
- (BOOL)hasText;
- (void)selectImageFromGallery;
- (void)selectImageFromCamera;
- (void)displaySlideTitleAndPosition;
- (void)displayNextPrevControls;
- (void)displayPlayStopControl;
- (void)displaySlideTextControl;
- (void)displayChoosePictureControls;
- (void)displayOverlay;
- (void)renderImage;
- (void)renameStori;
- (void)alertViewForSlideText:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)alertViewForStoriTitle:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)alertViewForOverwriteAudio:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)actionSheetForReorder:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)index;
- (void)startRecording;
- (void)stopRecording;
- (void)startPlaying;
- (void)stopPlaying;
- (NSString *)getNewImageFileName;
- (NSString *)getNewAudioFileName;
- (void)initiateReorder;
- (void)asyncAutoPlay;
- (void)imageTapDetected;
- (void)showNavAndStatusBar:(BOOL)show;
- (void)centerScaledImageInScrollView:(UIScrollView *)scrollView;
- (void)adjustScrollViewFrame;
@end

@implementation EditPlayFragmentController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    HFLogDebug(@"EditPlayFragmentController.viewDidLoad");
    
    [super viewDidLoad];
    
    self.currentZoomScale = -1.0;
    
#ifdef HIDE_LEFTRIGHTARROW_BUTTONS
    // BUGBUG - May eliminate left/right arrow navigation altogether.
    // Hide them for now, to temporarily remove them from user access.
    self.leftArrowButton.hidden = YES;
    self.rightArrowButton.hidden = YES;
#endif
    
    self.scrollView.delegate = self;
    self.scrollView.bouncesZoom = YES;
    
    [self.choosePictureLabel setTitle:NSLocalizedString(@"editplay_nopicture_text", nil) forState:UIControlStateNormal];
    
    //
    // Set the overlay view's background color alpha, rather than setting the UIView's alpha directly in Storyboard.
    // This technique allows controls layered on top of the overlay view to be fully opaque.
    //
    [self.overlayView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:OVERLAY_ALPHA]];
    
    [self setIsRecording:FALSE];
    [self setIsPlaying:FALSE];
    [self setCancelAsyncPlay:FALSE];
    
    if (self.editPlayController.editPlayMode != editPlayModeEdit) {
        [self.insertAfterButton setHidden:YES];
        [self.insertBeforeButton setHidden:YES];
    }
    
    [self renderImage];
    [self displaySlideTitleAndPosition];
    [self displayNextPrevControls];
    [self displayPlayStopControl];
    [self displaySlideTextControl];
    [self displayChoosePictureControls];
    [self displayOverlay];
}

- (void)viewDidAppear:(BOOL)animated {
    HFLogDebug(@"EditPlayControllerFragment.viewDidAppear");
    
    if (self.editPlayController.editPlayMode != editPlayModeEdit) {
        int slideIndex = [self.editPlayController getSlidePosition:self.slideUuid];
        if (slideIndex == self.editPlayController.currentSlideIndex && !self.isPlaying) {
            [self asyncAutoPlay];
        }
    }
    
    self.editPlayController.editPlayNavBarButtonDelegate = self;
}

- (void)viewWillLayoutSubviews {
    HFLogDebug(@"EditPlayFragmentController.viewWillLayoutSubviews");
    
    [self adjustScrollViewFrame];
    [self renderImage];
}

- (void)didReceiveMemoryWarning {
    HFLogDebug(@"EditPlayFragmentController.didReceiveMemoryWarning");
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    HFLogDebug(@"EditPlayFragmentController.viewWillDisappear");
    
    [super viewWillDisappear:animated];
    
    [self stopPlaying];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    HFLogDebug(@"EditPlayFragmentController.prepareForSegue: segue=%@", segue.identifier);
    
    if ([segue.identifier isEqualToString:@"SegueToEditPlayController"]) {
        EditPlayController *epc = (EditPlayController *)segue.destinationViewController;
        epc.editPlayMode = editPlayModePreview;
    }
    else if ([segue.identifier isEqualToString:@"SegueToSettingsController"]) {
        STOSettingsController *ssc = (STOSettingsController *)segue.destinationViewController;
        ssc.editPlayController = self.editPlayController;
    }
    else if ([segue.identifier isEqualToString:@"SegueToStoriListController"]) {
        StoriListController *slc = (StoriListController *)segue.destinationViewController;
        slc.editPlayController = self.editPlayController;
    }
}

- (void)initializeWithSlideJSON:(SlideJSON *)sj withSlideShareName:(NSString *)slideShareName
                       withUuid:(NSString *)slideUuid fromController:(EditPlayController *)editPlayController {
    HFLogDebug(@"EditPlayFragmentController.initializeWithSlideJSON");
    
    self.slideSharename = slideShareName;
    self.slideUuid = slideUuid;
    self.editPlayController = editPlayController;
    self.imageFileName = [sj getImageFilename];
    self.audioFileName = [sj getAudioFilename];
    self.slideText = [sj getText];
}

- (void)asyncAutoPlay {
    BOOL autoAudio = [STOPreferences getPlaySlidesAutoAudio];
    if (autoAudio && self.editPlayController.editPlayMode != editPlayModeEdit && self.hasAudio) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, AUDIO_DELAY_MILLIS * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [self startPlaying];
        });
    }
}

- (void)onEditPlayFragmentSelected {
    HFLogAlert(@"EditPlayFragmentController.onEditPlayFragmentSelected");
    
    [self displaySlideTitleAndPosition];
    [self displayNextPrevControls];
    [self displaySlideTextControl];
    [self displayOverlay];
    
    self.cancelAsyncPlay = FALSE;
    [self asyncAutoPlay];
}

- (void)onEditPlayFragmentDeselected {
    HFLogDebug(@"EditPlayFragmentController.onEditPlayFragmentDeselected");
    
    self.cancelAsyncPlay = TRUE;
    [self stopPlaying];
    [self stopRecording];
    self.currentZoomScale = -1.0;
}

- (void)showNavAndStatusBar:(BOOL)show {
    [self.navigationController setNavigationBarHidden:!show animated:TRUE];
    [[UIApplication sharedApplication] setStatusBarHidden:!show withAnimation:UIStatusBarAnimationSlide];
}

- (void)imageTapDetected {
    HFLogDebug(@"EditPlayFragmentController.imageTapDetected");

    if (self.editPlayController.editPlayMode == editPlayModeEdit) {
        return;
    }
    
    if (self.overlayView.isHidden) {
        [self showNavAndStatusBar:TRUE];
        self.editPlayController.shouldDisplayOverlay = TRUE;
        [self displayOverlay];
    }
    else {
        [self showNavAndStatusBar:FALSE];
        self.editPlayController.shouldDisplayOverlay = FALSE;
        [self displayOverlay];
    }
}

- (IBAction)onSelectPhotoSecondaryButtonClicked:(id)sender {
    [self onNavBarSelectPhotoButtonClicked];
}

- (void)onNavBarMainMenuButtonClicked {
    [self stopPlaying];
    [self stopRecording];
    
    UIActionSheet *popup = [[UIActionSheet alloc]
                            initWithTitle:NSLocalizedString(@"menu_editplay_title", nil)
                            delegate:self
                            cancelButtonTitle:nil
                            destructiveButtonTitle:nil
                            otherButtonTitles:nil];
    
    if (self.editPlayController.editPlayMode == editPlayModeEdit) {
        [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_preview", nil)];
        [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_rename", nil)];
        [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_publish", nil)];
        if ([self.editPlayController isPublished]) {
            [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_share", nil)];
        }
        [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_createnew", nil)];
        
        NSString *playTitle = nil;
        NSString *playSlideShareName = [STOPreferences getPlaySlidesName];
        if (playSlideShareName) {
            playTitle = [STOUtilities limitStringWithEllipses:[SlideShareJSON getStoriTitle:playSlideShareName] toNumChars:20];
        }
        if (playTitle && ([playTitle length] > 0)) {
            NSString *item = [NSString stringWithFormat:NSLocalizedString(@"menu_editplay_play_format", nil), playTitle];
            [popup addButtonWithTitle:item];
        }
        [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_list", nil)];
    }
    if (self.editPlayController.editPlayMode == editPlayModePlay) {
        [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_savethisphoto", nil)];
        [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_saveallphotos", nil)];
    }
    [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_settings", nil)];
    [popup addButtonWithTitle:NSLocalizedString(@"menu_cancel", nil)];
    popup.cancelButtonIndex = popup.numberOfButtons - 1;
    
    popup.tag = 1;
    [popup showInView:[UIApplication sharedApplication].keyWindow];
}

- (IBAction)onPlayStopButtonClicked:(id)sender {
    [self stopRecording];
    
    if (![self hasAudio]) {
        return;
    }
    
    if (!self.isPlaying) {
        [self startPlaying];
    }
    else {
        [self stopPlaying];
    }
}

- (void)onNavBarRecordingButtonClicked {
    [self stopPlaying];
    
    if (self.isRecording) {
        [self stopRecording];
    }
    else {
        if (self.hasAudio) {
            UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"editplay_overwriteaudio_title", nil)
                                                             message:NSLocalizedString(@"editplay_overwriteaudio_message", nil)
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"menu_cancel", nil)
                                                   otherButtonTitles:NSLocalizedString(@"menu_ok", nil), nil];
            dialog.tag = ALERTVIEW_DIALOG_OVERWRITE_AUDIO;
            [dialog show];
        }
        else {
            [self startRecording];
        }
    }
}

- (IBAction)onLeftArrowButtonClicked:(id)sender {
    [self stopRecording];
    
    int position = [self.editPlayController getSlidePosition:self.slideUuid];
    
    position--;
    if (position < 0) {
        return;
    }
    
    self.cancelAsyncPlay = TRUE;
    [self stopPlaying];
    [self.editPlayController setCurrentSlidePosition:position];
}

- (IBAction)onRightArrowButtonClicked:(id)sender {
    [self stopRecording];
    
    int position = [self.editPlayController getSlidePosition:self.slideUuid];
    int count = [self.editPlayController getSlideCount];
    
    position++;
    if (position >= count) {
        return;
    }
    
    self.cancelAsyncPlay = TRUE;
    [self stopPlaying];
    [self.editPlayController setCurrentSlidePosition:position];
}

- (IBAction)onInsertBeforeButtonClicked:(id)sender {
    [self stopRecording];
    [self stopPlaying];
    
    int selectedPosition = self.editPlayController.currentSlideIndex;
    [self.editPlayController addSlide:selectedPosition];
}
     
- (IBAction)onInsertAfterButtonClicked:(id)sender {
    [self stopRecording];
    [self stopPlaying];
    
    int selectedPosition = self.editPlayController.currentSlideIndex;
    [self.editPlayController addSlide:selectedPosition + 1];
}
     
- (void)onNavBarEditButtonClicked {
    [self stopRecording];
    [self stopPlaying];
    
    UIActionSheet *popup = [[UIActionSheet alloc]
                            initWithTitle:NSLocalizedString(@"menu_editplay_edit_title", nil)
                            delegate:self
                            cancelButtonTitle:nil
                            destructiveButtonTitle:nil
                            otherButtonTitles:nil];
    
    [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_edit_text", nil)];
    if ([self.editPlayController getSlideCount] > 1) {
        [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_edit_reorder", nil)];
    }
    [popup addButtonWithTitle:NSLocalizedString(@"menu_cancel", nil)];
    popup.cancelButtonIndex = popup.numberOfButtons - 1;
    
    popup.tag = 1;
    [popup showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)onNavBarTrashButtonClicked {
    [self stopRecording];
    [self stopPlaying];
    
    UIActionSheet *popup = [[UIActionSheet alloc]
                            initWithTitle:NSLocalizedString(@"menu_editplay_trash_title", nil)
                            delegate:self
                            cancelButtonTitle:nil
                            destructiveButtonTitle:nil
                            otherButtonTitles:nil];
    
    [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_trash_removeslide", nil)];
    if ([self hasImage]) {
        [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_trash_removeimage", nil)];
    }
    if ([self hasAudio]) {
        [popup addButtonWithTitle:NSLocalizedString(@"menu_editplay_trash_removeaudio", nil)];
    }
    [popup addButtonWithTitle:NSLocalizedString(@"menu_cancel", nil)];
    popup.cancelButtonIndex = popup.numberOfButtons - 1;
    
    popup.tag = 1;
    [popup showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)deleteSlideData {
    HFLogDebug(@"EditPlayFragmentController.deleteSlideData");
    
    [self.editPlayController deleteImage:self.slideUuid withImage:self.imageFileName];
    self.imageFileName = nil;
    [self.editPlayController deleteAudio:self.slideUuid withAudio:self.audioFileName];
    self.audioFileName = nil;
    self.slideText = nil;
    
    [self.editPlayController updateSlideShareJSON:self.slideUuid withImageFileName:nil withAudioFileName:nil withText:nil withForcedNulls:TRUE];
    
    [self displayPlayStopControl];
    [self displaySlideTitleAndPosition];
    [self displaySlideTextControl];
    [self displayChoosePictureControls];
    [self renderImage];
}

- (void)enterSlideText {
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"editplay_slidetext_dialog_title", nil)
                                                     message:NSLocalizedString(@"editplay_slidetext_dialog_message", nil)
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"menu_cancel", nil)
                                           otherButtonTitles:NSLocalizedString(@"menu_ok", nil), nil];
    dialog.alertViewStyle = UIAlertViewStylePlainTextInput;
    dialog.tag = ALERTVIEW_DIALOG_SLIDETEXT;
    
    UITextField *textField = [dialog textFieldAtIndex:0];
    textField.tag = ALERTVIEW_DIALOG_SLIDETEXT;
    textField.text = [self.editPlayController getSlideText:self.slideUuid];
    [textField setSelected:TRUE];
    textField.delegate = self;
    
    [dialog show];
}

- (void)onNavBarSelectPhotoButtonClicked {
    [self stopRecording];
    [self stopPlaying];
    
    if (self.editPlayController.editPlayMode == editPlayModeEdit) {
        UIActionSheet *popup = [[UIActionSheet alloc]
                                initWithTitle:NSLocalizedString(@"menu_editplay_image_title", nil)
                                delegate:self
                                cancelButtonTitle:nil
                                destructiveButtonTitle:nil
                                otherButtonTitles:nil];
        
        [popup addButtonWithTitle:[self hasImage] ? NSLocalizedString(@"menu_editplay_image_replacepicture", nil) : NSLocalizedString(@"menu_editplay_image_choosepicture", nil)];
        [popup addButtonWithTitle:[self hasImage] ? NSLocalizedString(@"menu_editplay_image_replacecamera", nil) : NSLocalizedString(@"menu_editplay_image_usecamera", nil)];
        [popup addButtonWithTitle:NSLocalizedString(@"menu_cancel", nil)];
        popup.cancelButtonIndex = popup.numberOfButtons - 1;
        
        popup.tag = 1;
        [popup showInView:[UIApplication sharedApplication].keyWindow];
    }
    else {
        self.cancelAsyncPlay = TRUE;
        [self stopPlaying];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)selectImageFromGallery {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
    
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (void)selectImageFromCamera {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    self.imagePickerController = imagePickerController;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)renameStori {
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"editplay_storititle_dialog_title", nil)
                                                     message:NSLocalizedString(@"editplay_storititle_dialog_message", nil)
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"menu_cancel", nil)
                                           otherButtonTitles:NSLocalizedString(@"menu_ok", nil), nil];
    dialog.alertViewStyle = UIAlertViewStylePlainTextInput;
    dialog.tag = ALERTVIEW_DIALOG_STORITITLE;
    UITextField *textField = [dialog textFieldAtIndex:0];
    textField.tag = ALERTVIEW_DIALOG_STORITITLE;
    textField.text = [self.editPlayController getSlidesTitle];
    [textField setSelected:TRUE];
    textField.delegate = self;
    
    [dialog show];
}

- (BOOL)hasImage {
    return self.imageFileName != nil;
}

- (BOOL)hasAudio {
    return self.audioFileName != nil;
}

- (BOOL)hasText {
    return (self.slideText != nil && ([self.slideText length] > 0));
}

- (void)initiateReorder {
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"editplay_reorder_title_format", nil), [self.editPlayController currentSlideIndex] + 1];
    UIActionSheet *popup = [[UIActionSheet alloc]
                            initWithTitle:title
                            delegate:self
                            cancelButtonTitle:nil
                            destructiveButtonTitle:nil
                            otherButtonTitles:nil];
    
    int count = [self.editPlayController getSlideCount];
    for (int i = 1; i <= count; i++) {
        [popup addButtonWithTitle:[NSString stringWithFormat:@"%d", i]];
    }
    
    [popup addButtonWithTitle:NSLocalizedString(@"menu_cancel", nil)];
    popup.cancelButtonIndex = popup.numberOfButtons - 1;
    
    popup.tag = ACTIONSHEET_REORDER;
    [popup showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)startRecording {
    HFLogAlert(@"EditPlayFragmentController.startRecording");
    
    if (!self.audioFileName) {
        [self setAudioFileName:[self getNewAudioFileName]];
        [self.editPlayController updateSlideShareJSON:self.slideUuid withImageFileName:self.imageFileName withAudioFileName:self.audioFileName withText:self.slideText];
    }
    
    NSDictionary *recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    [NSNumber numberWithFloat: 16000], AVSampleRateKey,
                                    [NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                    [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                    nil];
    
    NSURL *folderDirectory = [STOUtilities createOrGetSlideShareDirectory:self.slideSharename];
    NSURL *fileURL = [folderDirectory URLByAppendingPathComponent:self.audioFileName];
    
    // BUGBUG - handle error
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:fileURL settings:recordSettings error:nil];
    self.audioRecorder.delegate = self;
    self.audioRecorder.meteringEnabled = YES;
    [self.audioRecorder recordForDuration:MAX_RECORDING_SECONDS];
    [self.audioRecorder prepareToRecord];
    
    BOOL success = [self.audioRecorder record];
    if (success) {
        [self setIsRecording:TRUE];
        [self.editPlayController.recordButton setImage:[UIImage imageNamed:@"ic_stoprecording.png"] forState:UIControlStateNormal];
    }
}

- (void)stopRecording {
    HFLogDebug(@"EditPlayFragmentController.stopRecording");
    
    if (self.isRecording) {
        [self.audioRecorder stop];
        [self setIsRecording:FALSE];
    }
    
    [self.editPlayController.recordButton setImage:[UIImage imageNamed:@"ic_record.png"] forState:UIControlStateNormal];
    [self displayPlayStopControl];
}

- (NSString *)getNewImageFileName {
    return [NSString stringWithFormat:@"%@.jpg", [[NSUUID UUID] UUIDString]];
}

- (NSString *)getNewAudioFileName {
    return [NSString stringWithFormat:@"%@.%@", [[NSUUID UUID] UUIDString], AUDIO_FILE_EXTENSION];
}

- (void)startPlaying {
    HFLogDebug(@"EditPlayFragmentController.startPlaying");
    
    if (self.cancelAsyncPlay) {
        HFLogDebug(@"EditPlayFragmentController.startPlaying - cancelAsyncPlay is TRUE, so bailing");
        self.cancelAsyncPlay = FALSE;
        return;
    }
    
    NSURL *folderDirectory = [STOUtilities createOrGetSlideShareDirectory:self.slideSharename];
    NSURL *fileURL = [folderDirectory URLByAppendingPathComponent:self.audioFileName];
    
    [STOUtilities configureAudioSession];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    self.audioPlayer.delegate = self;
    self.isPlaying = TRUE;
    [self.audioPlayer play];
    
    [self.playStopButton setImage:[UIImage imageNamed:@"ic_stopplaying.png"] forState:UIControlStateNormal];
}

- (void)stopPlaying {
    HFLogDebug(@"EditPlayFragmentController.stopPlaying");
    [self.audioPlayer stop];
    self.audioPlayer = nil;
    [self.playStopButton setImage:[UIImage imageNamed:@"ic_play.png"] forState:UIControlStateNormal];
    self.isPlaying = FALSE;
}


//
// AVAudioRecorderDelegate methods
//
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    HFLogDebug(@"EditPlayFragmentController.audioRecorderDidFinishRecording:successfully:%d", flag);
    
    [self setIsRecording:FALSE];
    [self stopRecording];
}

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder {
    HFLogDebug(@"EditPlayFragmentController.audioRecorderBeginInterruption");
    
    [self setIsRecording:FALSE];
    [self stopRecording];
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags {
    HFLogDebug(@"EditPlayFragmentController.audioRecorderEndInterruption");
}


//
// AVAudioPlayerDelegate methods
//
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    HFLogDebug(@"EditPlayFragmentController.audioPlayerDidFinishPlaying:successfully:%d", flag);
    
    [self stopPlaying];
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
    HFLogDebug(@"EditPlayFragmentController.audioPlayerBeginInterruption");
    
    [self stopPlaying];
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player {
    HFLogDebug(@"EditPlayFragmentController.audioPlayerEndInterruption");
}

//
// UIImagePickerControllerDelegate methods
//

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    HFLogDebug(@"EditPlayFragmentController.imagePickerController:didFinishPickingMediaWithInfo");
    
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];

    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        // Save to the camera roll before we do anything else
        HFLogDebug(@"EditPlayFragmentController.imagePickerController:didFinishPickingMediaWithInfo - saving to camera roll");
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    
    //
    // Resize image if necessary
    //
    CGSize sz;
    if (image.size.width > image.size.height) {
        // Landscape
        sz = CGSizeMake(IMAGE_DISPLAY_WIDTH_LANDSCAPE, IMAGE_DISPLAY_HEIGHT_LANDSCAPE);
    }
    else {
        // Portrait
        sz = CGSizeMake(IMAGE_DISPLAY_WIDTH_PORTRAIT, IMAGE_DISPLAY_HEIGHT_PORTRAIT);
    }
    UIImage *resizedImage = [image resizedImageToFitInSize:sz scaleIfSmaller:FALSE];
    
    NSString *imageFileName = self.imageFileName;
    if (!imageFileName) {
        imageFileName = [self getNewImageFileName];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    self.imagePickerController = nil;
    
    BOOL success = [STOUtilities saveImage:resizedImage inFolder:self.slideSharename withFileName:imageFileName];
    if (success) {
        self.imageFileName = imageFileName;
        [self.editPlayController updateSlideShareJSON:self.slideUuid withImageFileName:self.imageFileName withAudioFileName:self.audioFileName withText:self.slideText];
    }
    else {
        HFLogDebug(@"EditPlayFragmentController.imagePickerController:didFinishPickingMediaWithInfo - failed. Bailing");
    }
    
    [self displayChoosePictureControls];
    [self renderImage];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    HFLogDebug(@"EditPlayFragmentController.imagePickerControllerDidCancel");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    self.imagePickerController = nil;
}

//
// UITextFieldDelegate methods
//
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    
    //
    // Restrict text field sizes
    //
    
    switch (textField.tag) {
        case ALERTVIEW_DIALOG_SLIDETEXT:
            return (newLength > MAX_SLIDE_TEXT_CHARACTERS) ? NO : YES;
            break;
            
        case ALERTVIEW_DIALOG_STORITITLE:
            return (newLength > MAX_STORI_TITLE_CHARACTERS) ? NO : YES;
            break;

        default:
            return TRUE;
    }
}


//
// UIAlertViewDelegate methods
//

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case ALERTVIEW_DIALOG_SLIDETEXT:
            [self alertViewForSlideText:alertView clickedButtonAtIndex:buttonIndex];
            break;
            
        case ALERTVIEW_DIALOG_STORITITLE:
            [self alertViewForStoriTitle:alertView clickedButtonAtIndex:buttonIndex];
            break;
            
        case ALERTVIEW_DIALOG_OVERWRITE_AUDIO:
            [self alertViewForOverwriteAudio:alertView clickedButtonAtIndex:buttonIndex];
            
        default:
            break;
    }
}

- (void)alertViewForOverwriteAudio:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_ok", nil)]) {
        [self startRecording];
    }
}

- (void)alertViewForSlideText:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_ok", nil)]) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSString *text = textField.text;
        
        [self.editPlayController updateSlideShareJSON:self.slideUuid withImageFileName:nil withAudioFileName:nil withText:text];
        self.slideText = [self.editPlayController getSlideText:self.slideUuid];
        
        [self displaySlideTextControl];
    }
}

- (void)alertViewForStoriTitle:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_ok", nil)]) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSString *text = textField.text;
        
        [self.editPlayController setSlideShareTitle:text];
        [self displaySlideTitleAndPosition];
    }
}

//
// UIActionSheetDelegate methods
//

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)index {
    
    if (popup.tag == ACTIONSHEET_REORDER) {
        [self actionSheetForReorder:popup clickedButtonAtIndex:index];
        return;
    }
    
    HFLogDebug(@"EditPlayFragmentController.actionSheet:clickedButtonAtIndex %d, menutitle=%@", index, [popup buttonTitleAtIndex:index]);
    
    NSString *playSlideShareName = [STOPreferences getPlaySlidesName];
    NSString *playTitle = nil;
    if (playSlideShareName) {
        playTitle = [STOUtilities limitStringWithEllipses:[SlideShareJSON getStoriTitle:playSlideShareName] toNumChars:20];
    }
    
    NSString *buttonTitle = [popup buttonTitleAtIndex:index];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_preview", nil)]) {
        [self performSegueWithIdentifier:@"SegueToEditPlayController" sender:nil];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_rename", nil)]) {
        [self renameStori];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_publish", nil)]) {
        [self.editPlayController publishSlides];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_share", nil)]) {
        [self.editPlayController shareSlides];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_createnew", nil)]) {
        [self.editPlayController createNewSlideShow];
    }
    else if ([buttonTitle isEqualToString:[NSString stringWithFormat:NSLocalizedString(@"menu_editplay_play_format", nil), playTitle]]) {
        [self.editPlayController playCurrentPlayStori];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_list", nil)]) {
       [self performSegueWithIdentifier: @"SegueToStoriListController" sender: self];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_settings", nil)]) {
        [self performSegueWithIdentifier:@"SegueToSettingsController" sender:nil];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_savethisphoto", nil)]) {
        HFLogDebug(@"Save this photo...");
        [self.editPlayController copyImageFilesToPhotosFolder:self.slideUuid];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_saveallphotos", nil)]) {
        HFLogDebug(@"Save all photos");
        [self.editPlayController copyImageFilesToPhotosFolder:nil];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_image_choosepicture", nil)] ||
             [buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_image_replacepicture", nil)]) {
        [self selectImageFromGallery];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_image_usecamera", nil)] ||
             [buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_image_replacecamera", nil)]) {
        [self selectImageFromCamera];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_trash_removeslide", nil)]) {
        int count = [self.editPlayController getSlideCount];
        if (count > 1) {
            [self.editPlayController deleteSlide:self.slideUuid withImage:self.imageFileName withAudio:self.audioFileName];
        }
        else {
            [self deleteSlideData];
        }
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_trash_removeimage", nil)]) {
        [self.editPlayController deleteImage:self.slideUuid withImage:self.imageFileName];
        self.imageFileName = nil;
        [self displayChoosePictureControls];
        [self renderImage];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_trash_removeaudio", nil)]) {
        [self.editPlayController deleteAudio:self.slideUuid withAudio:self.audioFileName];
        self.audioFileName = nil;
        [self displayPlayStopControl];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_edit_text", nil)]) {
        [self enterSlideText];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_editplay_edit_reorder", nil)]) {
        [self initiateReorder];
    }
}

- (void)actionSheetForReorder:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)index {
    NSString *buttonTitle = [popup buttonTitleAtIndex:index];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"menu_cancel", nil)]) {
        return;
    }
    
    int slideIndex = buttonTitle.intValue - 1;
    [self.editPlayController reorderCurrentSlideTo:slideIndex];
}


//
// UIScrollViewDelegate methods
//

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    //HFLogDebug(@"EditPlayFragmentController.viewForZoomingInScrollView");

    return [self.scrollView viewWithTag:ZOOM_VIEW_TAG];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    //HFLogDebug(@"EditPlayFragmentController.scrollViewDidZoom");
    
    self.currentZoomScale = scrollView.zoomScale;
    
    [self centerScaledImageInScrollView:scrollView];
}

- (void)centerScaledImageInScrollView:(UIScrollView *)scrollView {
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = scrollView.bounds.size;
    CGRect frameToCenter = self.imageView.frame;
    
    // Center horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    }
    else {
        frameToCenter.origin.x = 0;
    }
    
    // Center vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    }
    else {
        frameToCenter.origin.y = 0;
    }
    
    self.imageView.frame = frameToCenter;
}

//
// TabDetectingImageViewDelegate methods
//

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotSingleTapAtPoint:(CGPoint)tapPoint {
    HFLogDebug(@"EditPlayFragmentController.tapDetectingImageView:gotSingleTap");
    [self imageTapDetected];
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotDoubleTapAtPoint:(CGPoint)tapPoint {
    HFLogDebug(@"EditPlayFragmentController.tapDetectingImageView:gotDoubleTap: zoomScale=%f", [self.scrollView zoomScale]);

    CGRect zoomRect;
    if (self.scrollView.zoomScale == 1.0) {
        zoomRect = [self zoomRectForScale:self.scrollView.minimumZoomScale withCenter:tapPoint];
    }
    else {
        zoomRect = [self zoomRectForScale:1.0 withCenter:tapPoint];
    }

    [self.scrollView zoomToRect:zoomRect animated:YES];
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotTwoFingerTapAtPoint:(CGPoint)tapPoint {
    HFLogDebug(@"EditPlayFragmentController.tapDetectingImageView:gotTwoFingerTap");
    
    // Do nothing
    return;

    // Two-finger tap zooms out
    float newScale = [self.scrollView zoomScale] / ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
    [self.scrollView zoomToRect:zoomRect animated:YES];
}

- (void)displayOverlay {
    [self.overlayView setHidden:!self.editPlayController.shouldDisplayOverlay];
}

- (void)displayChoosePictureControls {
    BOOL hidden = self.hasImage;
    if (self.editPlayController.editPlayMode != editPlayModeEdit) {
        hidden = TRUE;
    }
    
    [self.choosePictureLabel setHidden:hidden];
    [self.selectPhotoSecondaryButton setHidden:hidden];
}

- (void)displaySlideTextControl {
    [self.slideTextView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:SLIDETEXT_ALPHA]];
    self.slideTextView.layer.cornerRadius = 5;
    self.slideTextView.layer.masksToBounds = TRUE;
    [self.slideTextView setText:self.slideText];
    [self.slideTextView sizeToFit];
    [self.slideTextView setHidden:![self hasText]];
}

- (void)displayPlayStopControl {
    [self.playStopButton setHidden:(![self hasAudio])];
}

- (void)displaySlideTitleAndPosition {
    int count = [self.editPlayController getSlideCount];
    int position = [self.editPlayController getSlidePosition:self.slideUuid];
    NSString *title = [self.editPlayController getSlidesTitle];
    
    self.storiTitleLabel.text = title;
    self.slidePositionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"slide_position_format", nil), position + 1, count];
}

- (void)displayNextPrevControls {
    int count = [self.editPlayController getSlideCount];
#ifndef HIDE_LEFTRIGHTARROW_BUTTONS
    int position = [self.editPlayController getSlidePosition:self.slideUuid];
#endif

    if (self.editPlayController.editPlayMode == editPlayModeEdit) {
        [self.insertBeforeButton setHidden:(count >= MAX_SLIDES_PER_STORI_FOR_FREE)];
        [self.insertAfterButton setHidden:(count >= MAX_SLIDES_PER_STORI_FOR_FREE)];
    }

#ifndef HIDE_LEFTRIGHTARROW_BUTTONS
    [self.leftArrowButton setHidden:(position <= 0)];
    [self.rightArrowButton setHidden:(position >= count - 1)];
#endif
}

- (void)adjustScrollViewFrame {
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    frame.size.width = frame.origin.x + frame.size.width;
    frame.size.height = frame.origin.y + frame.size.height;
    frame.origin.x = 0.0;
    frame.origin.y = 0.0;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        frame = CGRectMake(0, 0, frame.size.height, frame.size.width);
    }
    self.scrollView.frame = frame;
}

- (void)renderImage {
    HFLogDebug(@"EditPlayFragmentController.renderImage");
    
    [self.imageView removeFromSuperview];
    self.imageView.delegate = nil;
    self.imageView = nil;
    
    NSURL *fileURL = [STOUtilities getAbsoluteFilePathWithFolder:self.slideSharename withFileName:self.imageFileName];
    UIImage *image = [UIImage imageWithContentsOfFile:[fileURL path]];
    
    if (!image) {
        return;
    }
    
    [self adjustScrollViewFrame];
        
    self.imageView = [[TapDetectingImageView alloc] initWithImage:image];
    self.imageView.delegate = self;
    self.imageView.tag = ZOOM_VIEW_TAG;
    [self.scrollView setContentSize:[self.imageView frame].size];
    [self.scrollView addSubview:self.imageView];

    // Calculate minimum scale to perfectly fit image width, and begin at that scale
    float minimumZoomScale;
    
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        minimumZoomScale = [self.scrollView frame].size.height / [self.imageView frame].size.height;
    }
    else {
        minimumZoomScale = [self.scrollView frame].size.width / [self.imageView frame].size.width;
    }
    if (self.currentZoomScale < 0.0) {
        self.currentZoomScale = minimumZoomScale;
    }
    
    [self.scrollView setMinimumZoomScale:minimumZoomScale];
    [self.scrollView setZoomScale:self.currentZoomScale];
    
    if (minimumZoomScale == self.currentZoomScale) {
        [self centerScaledImageInScrollView:self.scrollView];
    }
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    CGRect zoomRect;
    
    // The zoom rect is in the content view's coordinates.
    // At a zoom scale of 1.0, it would be the size of the scrollView's bounds.
    // As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = [self.scrollView frame].size.height / scale;
    zoomRect.size.width = [self.scrollView frame].size.width / scale;
    
    // Choose an origin so as to get the right center
    zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

@end
