/*
    NSRotationGestureRecognizer.h
    Application Kit
    Copyright (c) 2013-2021, Apple Inc.
    All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <AppKit/NSGestureRecognizer.h>
#import <AppKit/AppKitDefines.h>

NS_ASSUME_NONNULL_BEGIN
APPKIT_API_UNAVAILABLE_BEGIN_MACCATALYST

API_AVAILABLE(macos(10.10))
@interface NSRotationGestureRecognizer : NSGestureRecognizer

@property CGFloat rotation; // in radians
@property CGFloat rotationInDegrees;
@end

API_UNAVAILABLE_END
NS_ASSUME_NONNULL_END
