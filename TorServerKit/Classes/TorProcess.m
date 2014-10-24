//
//  TorProcess.m
//  BitmessageKit
//
//  Created by Steve Dekorte on 8/22/14.
//  Copyright (c) 2014 Adam Thorsen. All rights reserved.
//

#import "TorProcess.h"
#import <SystemInfoKit/SystemInfoKit.h>
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
    
    [SIProcessKiller sharedSIProcessKiller]; // kill old processes

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(terminate)
                                                 name:NSApplicationWillTerminateNotification
                                               object:nil];
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
    NSString *lockPath = [self.bundleDataPath stringByAppendingPathComponent:@"lock"];
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:lockPath error:&error];
    
}

- (void)launch
{
    if (_torTask)
    {
        [NSException raise:@"Tor task already running" format:nil];
    }
    
    [self removeLockFile];
    
    _torTask = [[NSTask alloc] init];
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
        //if (!self.torSocksPort || ![SINetwork.sharedSINetwork hasOpenPort:self.torSocksPort])
        {
            self.torSocksPort = [SINetwork.sharedSINetwork firstBindablePortBetween:@9000 and:@10000];
        }
        
        [args addObject:@"--SOCKSPort"];
        [args addObject:[NSString stringWithFormat:@"%@", self.torSocksPort]];
    }
    
    [_torTask setArguments:args];
    [_torTask launch];
    
    //sleep(1);
    
    if (![_torTask isRunning])
    {
        //NSLog(@"tor task not running after launch");
        [NSException raise:@"tor task not running after launch" format:nil];
    }
    else
    {
        [SIProcessKiller.sharedSIProcessKiller onRestartKillTask:_torTask];
    }
}

- (void)terminate
{
    if (self.torTask)
    {
        NSLog(@"Killing tor process...");
        [SIProcessKiller.sharedSIProcessKiller removeKillTask:_torTask];
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
