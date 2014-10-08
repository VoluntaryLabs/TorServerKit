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

- (void)launch
{
    [SIProcessKiller sharedSIProcessKiller]; // kill old processes
    
    // Check for pre-existing process
    NSString *torPidFilePath = [[[self serverDataFolder] stringByAppendingPathComponent:@"tor"] stringByAppendingPathExtension:@"pid"];
    
    //NSString *torPid = [[NSString alloc] initWithContentsOfFile:torPidFilePath encoding:NSUTF8StringEncoding error:NULL];
    

    
    _torTask = [[NSTask alloc] init];
    _inpipe = [NSPipe pipe];
    
    // Set the path to the python executable
    NSBundle *mainBundle = [NSBundle bundleForClass:self.class];
    NSString * torPath = [mainBundle pathForResource:@"tor" ofType:@"" inDirectory: @"tor"];
    NSString * torConfigPath = [mainBundle pathForResource:@"torrc" ofType:@"" inDirectory: @"tor"];
    NSString * torDataDirectory = [[self serverDataFolder] stringByAppendingPathComponent: @".tor"];
    
    [_torTask setLaunchPath:torPath];
    
    NSFileHandle *nullFileHandle = [NSFileHandle fileHandleWithNullDevice];
    [_torTask setStandardOutput:nullFileHandle];
    [_torTask setStandardInput: (NSFileHandle *) _inpipe];
    [_torTask setStandardError:nullFileHandle];
    
    if (self.torPort)
    {
        NSArray *args = [NSArray arrayWithObjects:@"-f", torConfigPath,
                           @"--DataDirectory", torDataDirectory,
                           @"--PidFile", torPidFilePath,
                           @"--SOCKSPort", self.torPort,
                           nil];
        
        [_torTask setArguments:args];
    }
    else
    {
        NSArray *args = [NSArray arrayWithObjects:@"-f", torConfigPath,
                           @"--DataDirectory", torDataDirectory,
                           @"--PidFile", torPidFilePath,
                            nil
                           ];
        
        [_torTask setArguments:args];
    }
    
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
    NSLog(@"Killing tor process...");
    [_torTask terminate];
    self.torTask = nil;
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
