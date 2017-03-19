//
//  MovesTweak.mm
//  MovesTweak
//
//  Created by Shine on 3/19/17.
//  Copyright (c) 2017 __MyCompanyName__. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#import <Foundation/Foundation.h>
#import "CaptainHook/CaptainHook.h"
#include <notify.h> // not required; for examples only
#import "transform.h"
#import "transform.c"
#import <CoreLocation/CoreLocation.h>

// Objective-C runtime hooking using CaptainHook:
//   1. declare class using CHDeclareClass()
//   2. load class using CHLoadClass() or CHLoadLateClass() in CHConstructor
//   3. hook method using CHOptimizedMethod()
//   4. register hook using CHHook() in CHConstructor
//   5. (optionally) call old method using CHSuper()


@interface MovesTweak : NSObject

@end

@implementation MovesTweak

-(id)init
{
	if ((self = [super init]))
	{
	}

    return self;
}

@end


@class ClassToHook;
CHDeclareClass(MovesActivityPointList)
CHDeclareClass(PlaceAnnotation)

CHOptimizedMethod1(self, void, MovesActivityPointList, initWithActivityJSON, NSDictionary, *dic){
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:dic];
    NSLog(@"### %@ ###",dic);
    
    id block = ^id _Nonnull(id _Nonnull obj){
        NSMutableDictionary *tmp = [obj mutableCopy];
        double x, y;
        wgs2gcj([tmp[@"lat"] doubleValue], [tmp[@"lon"] doubleValue], &x, &y);
        tmp[@"lat"] = @(x).stringValue;
        tmp[@"lon"] = @(y).stringValue;
        return tmp;
    };
    
    if([d[@"track"] count] != 0){
        d[@"track"] = [d[@"track"] map: block];
    }
    
    if([d[@"trackPoints"] count] != 0){
        d[@"trackPoints"] = [d[@"trackPoints"] map:block];
    }
    
    CHSuper1(MovesActivityPointList, initWithActivityJSON, d);
}

/** Hook PlaceAnnotation的coordinate属性get方法, 返回处理过的坐标 **/
CHOptimizedMethod0(self, CLLocationCoordinate2D, PlaceAnnotation, coordinate){
    CLLocationCoordinate2D tmpCoordinate = CHSuper0(PlaceAnnotation, coordinate);
    double x, y;
    wgs2gcj(tmpCoordinate.latitude, tmpCoordinate.longitude, &x, &y);
    tmpCoordinate.latitude = x;
    tmpCoordinate.longitude = y;
    return tmpCoordinate;
}

__attribute__((constructor)) static void entry() {
    CHLoadLateClass(MovesActivityPointList);
    CHLoadLateClass(PlaceAnnotation);
    CHHook1(MovesActivityPointList, initWithActivityJSON);
    CHHook0(PlaceAnnotation, coordinate);
}
