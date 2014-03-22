//
//  ShoppingTrip.h
//  Shopping List
//
//  Created by Mario Cecchi on 3/22/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ShoppingList, ShoppingTripItem;

@interface ShoppingTrip : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) ShoppingList *list;
@property (nonatomic, retain) NSSet *items;
@end

@interface ShoppingTrip (CoreDataGeneratedAccessors)

- (void)addItemsObject:(ShoppingTripItem *)value;
- (void)removeItemsObject:(ShoppingTripItem *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end
