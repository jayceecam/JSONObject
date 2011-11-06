//
//  JSONObject.h
//
//  Created by Joseph Cerra on 10/9/11.
//  Copyright (c) 2011 Joe Cerra, Inc. All rights reserved.
//
//  This code is distributed under the terms and conditions of the MIT license. 
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>


@interface NSString (JSONObjectAdditions)
- (NSString*)stringValue;
@end


@interface JSONObject : NSObject <NSCoding> {
    
    NSDictionary* originalMappings;
    NSDictionary* alternateKeyMappings;
    NSDictionary* alternateTypeMappings;
    NSDictionary* alternateCollectionMappings;
    
    NSString* _id;
    
}

@property(strong,nonatomic,readonly) NSDictionary* originalMappings;
@property(strong,nonatomic,readonly) NSDictionary* alternateKeyMappings;
@property(strong,nonatomic,readonly) NSDictionary* alternateTypeMappings;
@property(strong,nonatomic,readonly) NSDictionary* alternateCollectionMappings;

@property(strong,nonatomic) NSString* _id;


- (id)init;
- (id)initWithDictionary:(NSDictionary*)keyValueDictionary;

// maps dictionary to object (binds them)
- (void)hydrateObjectWithDictionary:(NSDictionary*)keyValueDictionary;

// remaps key/value pair to alternate key if original key is undefined
- (NSDictionary*)alternateKeyMappings;

// remaps NSDictionary values to alternate type class (only works with NSDictionary types for now)
- (NSDictionary*)alternateTypeMappings;

// adds alternate key mappings (maintains any existing mappings, overwrites any new entries)
- (void)addAlternateKeyMappings:(NSDictionary*)mappings;

// adds alternate type mappings (maintains any existing mappings, overwrites any new entries)
- (void)addAlternateTypeMappings:(NSDictionary*)mappings;

// adds alternate type mappings for elements in a collection (maintains any existing mappings, overwrites any new entries)
- (void)addAlternateCollectionTypeMappings:(NSDictionary*)mappings;

// udid string for this object
- (NSString*)udidString;

// key path of udid
+ (NSString*)udidKeyPath;

// used to bypass saving mappings
+ (BOOL)ignoreMapping;

// returns NSDictionary with udid keys and JSONObject values
+ (NSDictionary*)idMappings:(NSArray*)set;

// instantiates objects from the given result set
+ (NSArray*)objectsFromResultSet:(NSArray*)resultSet;
+ (NSArray*)objectsFromResultSet:(NSArray*)resultSet usingClass:(Class)objClass;

// ensures the object is something supported
- (BOOL)validate;


#pragma mark -
#pragma mark Overridable Methods

- (void)objectDidHydrate;



#pragma mark -
#pragma mark Helper methods

+ (void)bindObjects:(NSArray*)objects usingLookupDictionary:(NSDictionary*)lookupDictionary toObjectKeyPath:(NSString*)objKeyPath withIdKeyPath:(NSString*)idKeyPath;


@end