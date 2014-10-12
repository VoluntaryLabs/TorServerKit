//
//  TorProcess.m
//  BitmessageKit
//
//  Created by Steve Dekorte on 8/22/14.
//  Copyright (c) 2014 Adam Thorsen. All rights reserved.
//

#import "TorProcess.h"
#import <SystemInfoKit/SystemInfoKit.h>

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

- (NSString *)torDataDirectory
{
    //NSString *folderName = @".tor";
    NSString *folderName = [self.bundle.bundleIdentifier componentsSeparatedByString:@"."].lastObject;
    NSString *path = [[self serverDataFolder] stringByAppendingPathComponent:folderName];
    
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    return path;
}

- (void)launch
{
    [SIProcessKiller sharedSIProcessKiller]; // kill old processes
    
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
    [args addObject:self.torDataDirectory];
    
    if (self.torSocksPort)
    {
        [args addObject:@"--SOCKSPort"];
        [args addObject:[NSString stringWithFormat:@"%@", self.torSocksPort]];
    }
    
    [_torTask setArguments:args];
    [_torTask launch];
    
    if (![_torTask isRunning])
    {
        NSLog(@"tor task not running after launch");
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
