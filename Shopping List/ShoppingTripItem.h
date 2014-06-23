//
//  ShoppingTripItem.h
//  Shopping List
//
//  Created by Mario Cecchi on 3/22/14.
//  Reviewed by Yaohua Liang on 23/06/14.
//
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ShoppingItem.h"

@class ShoppingTrip;

@interface ShoppingTripItem : ShoppingItem

@property (nonatomic, retain) NSNumber * myPrice;
@property (nonatomic, retain) ShoppingTrip *trip;

@end
