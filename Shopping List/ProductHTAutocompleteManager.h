//
//  HTAutocompleteManager.h
//  HotelTonight
//
//  Created by Jonathan Sibley on 12/6/12.
//  Copyright (c) 2012 Hotel Tonight. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTAutocompleteTextField.h"

@interface ProductHTAutocompleteManager : NSObject <HTAutocompleteDataSource>

@property NSManagedObjectContext* managedObjectContext;
@property NSArray* products;

- (id)initWithSharedContext:(NSManagedObjectContext *)context;

@end
