//
//  ShoppingList.h
//  Shopping List
//
//  Created by Mario Cecchi on 3/22/14.
//  Reviewed by Yaohua Liang on 23/06/14.
//
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ShoppingItem, ShoppingTrip;

@interface ShoppingList : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *products;
@property (nonatomic, retain) NSSet *trips;
@end

@interface ShoppingList (CoreDataGeneratedAccessors)

- (void)addProductsObject:(ShoppingItem *)value;
- (void)removeProductsObject:(ShoppingItem *)value;
- (void)addProducts:(NSSet *)values;
- (void)removeProducts:(NSSet *)values;

- (void)addTripsObject:(ShoppingTrip *)value;
- (void)removeTripsObject:(ShoppingTrip *)value;
- (void)addTrips:(NSSet *)values;
- (void)removeTrips:(NSSet *)values;

@end
