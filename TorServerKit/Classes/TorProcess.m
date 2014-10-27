//
//  TorProcess.m
//  BitmessageKit
//
//  Created by Steve Dekorte on 8/22/14.
//  Copyright (c) 2014 Adam Thorsen. All rights reserved.
//

#import "TorProcess.h"
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>

@implementation TorProcess

static id sharedTorProcess = nil;

+ (TorProcess *)sharedTorProcess
{
    if (sharedTorProcess == nil)
    {
        sharedTorProcess = [[self alloc] init];
    }
    
    return sharedTorProcess;
}

- (id)init
{
    self = [super init];
    return self;
}

- (NSBundle *)bundle
{
    return [NSBundle bundleForClass:self.class];
}

- (NSString *)torExePath
{
    return [self.bundle pathForResource:@"tor" ofType:@"" inDirectory: @"tor"];
}

- (NSString *)torConfigPath
{
    NSString *config = @"torrc.node";
    
    if (self.runAsRelay)
    {
        config = @"torrc.relay";
    }

    return [self.bundle pathForResource:config ofType:@"" inDirectory: @"tor"];
}

- (NSString *)bundleDataPath
{
    NSString *supportFolder = [[NSFileManager defaultManager] applicationSupportDirectory];
    NSString *bundleName = [self.bundle.bundleIdentifier componentsSeparatedByString:@"."].lastObject;
    NSString *path = [supportFolder stringByAppendingPathComponent:bundleName];
    
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    return path;
}

- (void)removeLockFile
{
    NSError *error;
    NSString *lockPath = [self.bundleDataPath stringByAppendingPathComponent:@"lock"];
    [[NSFileManager defaultManager] removeItemAtPath:lockPath error:&error];
}

- (void)launch
{
    if (_torTask)
    {
        [NSException raise:@"Tor task already running" format:nil];
    }
    
    [self removeLockFile];
    
    _torTask = [[SITask alloc] init];
    [_torTask setLaunchPath:self.torExePath];
    
    _inpipe = [NSPipe pipe];
    [_torTask setStandardInput: (NSFileHandle *)_inpipe];
    
    NSFileHandle *outFilehandle = [NSFileHandle fileHandleWithNullDevice];
    
    if (self.debug)
    {
        outFilehandle = [NSFileHandle fileHandleWithStandardOutput];
    }
    
    [_torTask setStandardOutput:outFilehandle];
    [_torTask setStandardError:outFilehandle];
    
    NSMutableArray *args = [NSMutableArray array];
    
    [args addObject:@"-f"];
    [args addObject:self.torConfigPath];
    
    [args addObject:@"--DataDirectory"];
    [args addObject:self.bundleDataPath];
    
    //if (self.torSocksPort)
    {
        //if (!self.torSocksPort || ![SIPort hasOpenPort:self.torSocksPort])
        {
            SIPort *port = [SIPort portWithNumber:@9000];
            self.torSocksPort = port.nextBindablePort.portNumber;
        }
        
        [args addObject:@"--SOCKSPort"];
        [args addObject:[NSString stringWithFormat:@"%@", self.torSocksPort]];
    }
    
    [_torTask setArguments:args];
    [_torTask addWaitOnConnectToPortNumber:self.torSocksPort];
    [_torTask launch];
}

- (void)terminate
{
    if (self.torTask)
    {
        NSLog(@"Killing tor process...");
        [_torTask terminate];
        self.torTask = nil;
    }
}

- (BOOL)isRunning
{
    return (_torTask && [_torTask isRunning]);
}

// stats

- (NSNumber *)currentConnectionCount
{
    return nil; // need to add code to grab this from logs?
}

- (NSNumber *)kilobytesPerSecondDown
{
    return nil; // need to add code to grab this from logs?
}

- (NSNumber *)kilobytesPerSecondUp
{
    return nil; // need to add code to grab this from logs?
}

@end
