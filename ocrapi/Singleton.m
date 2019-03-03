//
//  Singleton.m
//  AppFall3
//
//  Created by Brad Chessin on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Singleton.h"

@implementation Singleton

@synthesize dictionary;
@synthesize croppedImage;
@synthesize ocrConnection;
@synthesize reocrDict;
@synthesize infoRow;

static Singleton* _sharedMySingleton = nil;

+(Singleton*)sharedSingleton
{
	@synchronized([Singleton class])
	{
		if (!_sharedMySingleton)
			_sharedMySingleton = [[self alloc] init];
        
		return _sharedMySingleton;
	}
    
	return nil;
}

+(id)alloc
{
	@synchronized([Singleton class])
	{
		NSAssert(_sharedMySingleton == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedMySingleton = [super alloc];
		return _sharedMySingleton;
	}
    
	return nil;
}

-(id)init {
	self = [super init];
	if (self != nil) {
		// initialize stuff here
	}
    
	return self;
}

- (void)dealloc {
    [super dealloc];
    [_sharedMySingleton release];
}

@end
