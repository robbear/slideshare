//
//  TCBlobDownloadManager.m
//
//  Created by Thibault Charbonnier on 16/04/13.
//  Copyright (c) 2013 Thibault Charbonnier. All rights reserved.
//

#import "TCBlobDownloadManager.h"
#import "TCBlobDownloader.h"

@interface TCBlobDownloadManager ()
@property (nonatomic, strong) NSOperationQueue *operationQueue;
- (BOOL)createDirFromPath:(NSString *)path;
@end

@implementation TCBlobDownloadManager
@dynamic downloadCount;

#pragma mark - Init


- (id)init
{
    self = [super init];
    if (self) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _defaultDownloadPath = [NSString stringWithString:NSTemporaryDirectory()];
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static id sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}


#pragma mark - TCBlobDownloader Management


- (TCBlobDownloader *)startDownloadWithURL:(NSURL *)url
                                customPath:(NSString *)customPathOrNil
                                  delegate:(id<TCBlobDownloaderDelegate>)delegateOrNil
{
    NSString *downloadPath = [self createDirFromPath:customPathOrNil] ? customPathOrNil : self.defaultDownloadPath;
    
    TCBlobDownloader *downloader = [[TCBlobDownloader alloc] initWithURL:url
                                                            downloadPath:downloadPath
                                                                delegate:delegateOrNil];
    [self.operationQueue addOperation:downloader];
    
    return downloader;
}

- (TCBlobDownloader *)startDownloadWithURL:(NSURL *)url
                                customPath:(NSString *)customPathOrNil
                             firstResponse:(void (^)(NSURLResponse *response))firstResponseBlock
                                  progress:(void (^)(float receivedLength, float totalLength, NSInteger remainingTime))progressBlock
                                     error:(void (^)(NSError *error))errorBlock
                                  complete:(void (^)(BOOL downloadFinished, NSString *pathToFile))completeBlock
{
    NSString *downloadPath = [self createDirFromPath:customPathOrNil] ? customPathOrNil : self.defaultDownloadPath;
    
    TCBlobDownloader *downloader = [[TCBlobDownloader alloc] initWithURL:url
                                                            downloadPath:downloadPath
                                                           firstResponse:firstResponseBlock
                                                                progress:progressBlock
                                                                   error:errorBlock
                                                                complete:completeBlock];
    [self.operationQueue addOperation:downloader];
    
    return downloader;
}

- (void)startDownload:(TCBlobDownloader *)download
{
    if (download.pathToDownloadDirectory == nil) {
        download.pathToDownloadDirectory = self.defaultDownloadPath;
    }
    [self.operationQueue addOperation:download];
}

- (void)cancelAllDownloadsAndRemoveFiles:(BOOL)remove
{
    for (TCBlobDownloader *blob in [self.operationQueue operations]) {
        [blob cancelDownloadAndRemoveFile:remove];
    }
}


#pragma mark - Custom Setters


- (void)setDefaultDownloadPath:(NSString *)pathToDL
{
    if ([self createDirFromPath:pathToDL]) {
        _defaultDownloadPath = pathToDL;
    }
}

- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrent
{
    [self.operationQueue setMaxConcurrentOperationCount:maxConcurrent];
}


#pragma mark - Custom Getters


- (NSUInteger)downloadCount
{
    return [self.operationQueue operationCount];
}


#pragma mark - Internal Methods


- (BOOL)createDirFromPath:(NSString *)path
{
    if (path == nil || [path isEqualToString:@""]) {
        return NO;
    }
    
    NSError * __autoreleasing error;
    BOOL createdOrExists = [[NSFileManager defaultManager] createDirectoryAtPath:path
                                                     withIntermediateDirectories:YES
                                                                      attributes:nil
                                                                           error:&error];
    if (error) {
        // TODO
    }
    return createdOrExists;
}

@end
