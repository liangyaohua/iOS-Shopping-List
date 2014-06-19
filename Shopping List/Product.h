//
//  Product.h
//  Shopping List
//
//  Created by Mario Cecchi on 3/22/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ShoppingItem;

@interface Product : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *inItem;
@property (nonatomic, retain) NSNumber * price;
@property (nonatomic, retain) NSNumber * stock;

@end

@interface Product (CoreDataGeneratedAccessors)

- (void)addInItemObject:(ShoppingItem *)value;
- (void)removeInItemObject:(ShoppingItem *)value;
- (void)addInItem:(NSSet *)values;
- (void)removeInItem:(NSSet *)values;

@end
