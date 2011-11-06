//
//  JSONObject.m
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

#import "JSONObject.h"

#define kKeyMappings @"originalMappings"
#define kKeyClass @"class"



@implementation NSString (JSONObjectAdditions)
- (NSString*)stringValue {
    return self;
}
@end


@interface JSONObject ()

@property(strong,nonatomic) NSDictionary* originalMappings;
@property(strong,nonatomic) NSDictionary* alternateKeyMappings;
@property(strong,nonatomic) NSDictionary* alternateTypeMappings;
@property(strong,nonatomic) NSDictionary* alternateCollectionMappings;
@property(strong,nonatomic) NSMutableSet* remappedCollections;

- (NSString*)udidStringForKeyPath:(NSString*)keyPath;

@end


@implementation JSONObject

@synthesize originalMappings;
@synthesize alternateKeyMappings;
@synthesize alternateTypeMappings;
@synthesize alternateCollectionMappings;
@synthesize remappedCollections;
@synthesize _id;


- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self) {
        NSString* class = [aDecoder decodeObjectForKey:kKeyClass];
        Class clazz = NSClassFromString(class);
        if ([[self class] isSubclassOfClass:clazz]) {
            NSDictionary* mappings = [aDecoder decodeObjectForKey:kKeyMappings];
            [self hydrateObjectWithDictionary:mappings];
        }
        else {
            // remap to correct class
            self = [[clazz alloc] initWithCoder:aDecoder];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.originalMappings forKey:kKeyMappings];
    [aCoder encodeObject:NSStringFromClass([self class]) forKey:kKeyClass];
}

- (id)init {
    self = [super init];
    if (self) {
        self.alternateKeyMappings = [NSDictionary dictionaryWithObjectsAndKeys:@"_id", @"id", nil];
        self.alternateTypeMappings = [NSDictionary dictionaryWithObjectsAndKeys:[NSString class], @"id", nil];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*)keyValueDictionary {
    self = [self init];
    if (self) {
        [self hydrateObjectWithDictionary:keyValueDictionary];
    }
    return self;
}

- (void)hydrateObjectWithDictionary:(NSDictionary*)keyValueDictionary {
    self.originalMappings = keyValueDictionary;
    if (![[self class] ignoreMapping]) {
        [self setValuesForKeysWithDictionary:keyValueDictionary];
    }
    [self objectDidHydrate];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    Class alternateClass = [[self alternateTypeMappings] objectForKey:key];
    
    if (alternateClass && ![value isKindOfClass:alternateClass]) {
        if ([value isKindOfClass:[NSDictionary class]] &&  [alternateClass isSubclassOfClass:[JSONObject class]]) {
//            NSLog(@"remapping value class from %@ to <%@:JSONObject>", @"NSDictionary", NSStringFromClass(alternateClass));
            JSONObject* obj = [[alternateClass alloc] init];
            [obj addAlternateKeyMappings:alternateKeyMappings];
            [obj addAlternateTypeMappings:alternateTypeMappings];
            [obj hydrateObjectWithDictionary:value];
            [self setValue:obj forKey:key];
            return;
        }
        if (alternateClass && ![value isKindOfClass:alternateClass]) {
//            NSLog(@"attemping remap of value class from %@ to %@", NSStringFromClass([value class]), NSStringFromClass(alternateClass));
            if ([value isKindOfClass:[NSString class]]) {
                if ([NSURL isSubclassOfClass:alternateClass]) {
                    [self setValue:[NSURL URLWithString:value] forKey:key];
                    return;
                }
                else if ([NSDate isSubclassOfClass:alternateClass]) {
                    [self setValue:[NSDate dateWithTimeIntervalSince1970:[value doubleValue] / 1000] forKey:key];
                    return;
                }
            }
            else if ([value isKindOfClass:[NSDecimalNumber class]]) {
                if ([NSDate isSubclassOfClass:alternateClass]) {
                    [self setValue:[NSDate dateWithTimeIntervalSince1970:[value doubleValue] / 1000] forKey:key];
                    return;
                }
                if ([NSString isSubclassOfClass:alternateClass]) {
                    [self setValue:[value stringValue] forKey:key];
                    return;
                }
            }
        }
        NSLog(@"failed remap of value class from %@ to %@", NSStringFromClass([value class]), NSStringFromClass(alternateClass));
        return;
    }
    
    Class alternateCollectionClass = [[self alternateCollectionMappings] objectForKey:key];
    if ([value isKindOfClass:[NSArray class]] && [value count] && ![remappedCollections containsObject:key]) {
//        NSLog(@"remapping alternate collection class %@ for key %@", NSStringFromClass(alternateCollectionClass), key);
        if (self.remappedCollections == nil) {
            self.remappedCollections = [NSMutableSet setWithCapacity:1];
        }
        [remappedCollections addObject:key];
        NSMutableArray* arr = [NSMutableArray arrayWithCapacity:[value count]];
        for (NSDictionary* item in value) {
            JSONObject* obj = [[alternateCollectionClass alloc] init];
            [obj addAlternateKeyMappings:alternateKeyMappings];
            [obj addAlternateTypeMappings:alternateTypeMappings];
            [obj hydrateObjectWithDictionary:item];
            [arr addObject:obj];
        }
        [self setValue:[arr copy] forKey:key];
        return;
    }
    
    NSString* alternateKey = [[self alternateKeyMappings] objectForKey:key];
    if (alternateKey) {
//        NSLog(@"remapping key %@ to alternate key %@", key, alternateKey);
        [self setValue:value forKey:alternateKey];
        return;
    }
    
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"found undefined key %@ for value %@", key, value);
}

- (void)addAlternateKeyMappings:(NSDictionary*)mappings {
    if (self.alternateKeyMappings) {
        NSMutableDictionary* mDict = [NSMutableDictionary dictionaryWithDictionary:self.alternateKeyMappings];
        [mDict addEntriesFromDictionary:mappings];
        self.alternateKeyMappings = [mDict copy];
    }
    else {
        self.alternateKeyMappings = mappings;
    }
}

- (void)addAlternateTypeMappings:(NSDictionary*)mappings {
    if (self.alternateTypeMappings) {
        NSMutableDictionary* mDict = [NSMutableDictionary dictionaryWithDictionary:self.alternateTypeMappings];
        [mDict addEntriesFromDictionary:mappings];
        self.alternateTypeMappings = [mDict copy];
    }
    else {
        self.alternateTypeMappings = mappings;
    }
}

- (void)addAlternateCollectionTypeMappings:(NSDictionary*)mappings {
    if (self.alternateCollectionMappings) {
        NSMutableDictionary* mDict = [NSMutableDictionary dictionaryWithDictionary:self.alternateCollectionMappings];
        [mDict addEntriesFromDictionary:mappings];
        self.alternateCollectionMappings = [mDict copy];
    }
    else {
        self.alternateCollectionMappings = mappings;
    }
}

- (NSString*)udidString {
    return [self udidStringForKeyPath:[[self class] udidKeyPath]];
}

- (NSString*)udidStringForKeyPath:(NSString*)keyPath {
    id udid = [self valueForKeyPath:keyPath];
    if ([udid isKindOfClass:[NSNumber class]]) {
        return [udid stringValue];
    }
    if ([udid isKindOfClass:[NSString class]]) {
        return udid;
    }
    NSLog(@"no udid for keyPath %@", keyPath);
    return @"no_id";
}

- (BOOL)validate {
    return YES;
}

+ (BOOL)ignoreMapping {
    return NO;
}

+ (NSString*)udidKeyPath {
    return @"_id";
}

- (void)objectDidHydrate {
}


+ (NSDictionary*)idMappings:(NSArray*)set {
    NSMutableDictionary* mappings = [NSMutableDictionary dictionaryWithCapacity:[set count]];
    for (JSONObject* obj in set) {
        [mappings setValue:obj forKey:[obj udidString]];
    }
    return [mappings copy];
}

+ (NSArray*)objectsFromResultSet:(NSArray*)resultSet {
    NSMutableArray* arr = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary* d in resultSet) {
        [arr addObject:[[[self class] alloc] initWithDictionary:d]];
    }
    return [arr copy];
}

+ (NSArray*)objectsFromResultSet:(NSArray*)resultSet usingClass:(Class)objClass {
    NSMutableArray* arr = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary* d in resultSet) {
        [arr addObject:[[objClass alloc] initWithDictionary:d]];
    }
    return [arr copy];
}

+ (void)bindObjects:(NSArray*)objects 
usingLookupDictionary:(NSDictionary*)lookupDictionary 
    toObjectKeyPath:(NSString*)objKeyPath 
      withIdKeyPath:(NSString*)idKeyPath {
    
    for (JSONObject* obj in objects) {
        NSString* objectId = [obj udidStringForKeyPath:idKeyPath];
        id object = [lookupDictionary objectForKey:objectId];
        if (object) {
            [obj setValue:object forKeyPath:objKeyPath];
        }
    }
}

- (NSUInteger)hash {
    int prime = 31;
    int result = 1;
    result = prime * result + [_id hash] * 7717;
    return result;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    if ([self _id] && ![other _id])
        return NO;
    if (![self _id] && [other _id])
        return NO;
    if ([self _id] && [other _id])
        return [self._id isEqual:[other _id]];
    return NO;
}



@end