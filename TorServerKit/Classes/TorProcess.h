//
//  TorProcess.h.h
//  BitmessageKit
//
//  Created by Steve Dekorte on 8/22/14.
//  Copyright (c) 2014 Adam Thorsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemInfoKit/SystemInfoKit.h>

@interface TorProcess : NSObject

@property (retain, nonatomic) SITask *torTask;
@property (retain, nonatomic) NSNumber *torSocksPort; // will try to use this and choose another if not avaiable
//@property (retain, nonatomic) NSPipe *inpipe;
@property (assign, nonatomic) BOOL runAsRelay; // otherwise runs as a local node
@property (assign, nonatomic) BOOL debug;
@property (retain, nonatomic) NSString *binaryVersion; // will try to use this and choose another if not avaiable


- (void)launch;
- (void)terminate;
- (BOOL)isRunning;

// stats - not working yet

- (NSNumber *)currentConnectionCount;
- (NSNumber *)kilobytesPerSecondDown;
- (NSNumber *)kilobytesPerSecondUp;

- (NSString *)binaryVersion;

@end
