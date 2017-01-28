/**
 *  MIT License
 *
 *  Copyright (c) 2017 Richard Moore <me@ricmoo.com>
 *
 *  Permission is hereby granted, free of charge, to any person obtaining
 *  a copy of this software and associated documentation files (the
 *  "Software"), to deal in the Software without restriction, including
 *  without limitation the rights to use, copy, modify, merge, publish,
 *  distribute, sublicense, and/or sell copies of the Software, and to
 *  permit persons to whom the Software is furnished to do so, subject to
 *  the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included
 *  in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 *  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 *  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *  DEALINGS IN THE SOFTWARE.
 */


#import "BigNumber.h"

#import "RegEx.h"
#include "tommath.h"

#import "NSString+Secure.h"
#import "NSData+Secure.h"

@interface BigNumber () {
    mp_int _bigNumber;
}

@end

@implementation BigNumber


#pragma mark - Life-Cycle

static BigNumber *ConstantZero = nil;
static BigNumber *ConstantOne = nil;
static BigNumber *ConstantTwo = nil;
static BigNumber *ConstantNegativeOne = nil;
static BigNumber *ConstantWeiPerEther = nil;

static BigNumber *ConstantMaxSafeUnsignedInteger = nil;
static BigNumber *ConstantMaxSafeSignedInteger = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ConstantNegativeOne = [BigNumber bigNumberWithInteger:-1];
        ConstantZero = [BigNumber bigNumberWithInteger:0];
        ConstantOne = [BigNumber bigNumberWithInteger:1];
        ConstantTwo = [BigNumber bigNumberWithInteger:2];
        ConstantWeiPerEther = [BigNumber bigNumberWithDecimalString:@"1000000000000000000"];
        
        ConstantMaxSafeSignedInteger = [BigNumber bigNumberWithHexString:@"0x7fffffffffffffff"];
        ConstantMaxSafeUnsignedInteger = [BigNumber bigNumberWithHexString:@"0xffffffffffffffff"];
    });
}

- (instancetype)init {
    self = [super init];
    if (self) {
        mp_init(&_bigNumber);
    }
    return self;
}

- (instancetype)initWithValue: (mp_digit)value {
    self = [super init];
    if (self) {
        mp_init_set(&_bigNumber, value);
    }
    return self;
}

+ (instancetype)bigNumberWithDecimalString:(NSString *)decimalString {
    static RegEx *regexHex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regexHex = [RegEx regExWithPattern:@"^-?[0-9]*$"];
    });

    if (![regexHex matchesExactly:decimalString]) { return nil; }

    BigNumber *bigNumber = [[BigNumber alloc] init];
    if (self) {
        mp_read_radix([bigNumber _bigNumber], [decimalString cStringUsingEncoding:NSASCIIStringEncoding], 10);
    }
    return bigNumber;
}

+ (instancetype)bigNumberWithHexString:(NSString *)hexString {
    static RegEx *regexHex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regexHex = [RegEx regExWithPattern:@"^-?0x[0-9A-Fa-f]*$"];
    });
    
    if (![regexHex matchesExactly:hexString]) { return nil; }
    
    if ([hexString hasPrefix:@"-"]) {
        hexString = [@"-" stringByAppendingString:[hexString substringFromIndex:3]];
    } else {
        hexString = [hexString substringFromIndex:2];
    }
    
    BigNumber *bigNumber = [[BigNumber alloc] init];
    if (self) {
        mp_read_radix([bigNumber _bigNumber], [hexString cStringUsingEncoding:NSASCIIStringEncoding], 16);
    }
    return bigNumber;
}

+ (instancetype)bigNumberWithBase36String:(NSString *)base36String {
    // checkString(hexString, @"^-?0x[1-9A-Fa-f][0-9A-Fa-f]*$");
    BigNumber *bigNumber = [[BigNumber alloc] init];
    if (self) {
        mp_read_radix([bigNumber _bigNumber], [base36String cStringUsingEncoding:NSASCIIStringEncoding], 36);
    }
    return bigNumber;
}


+ (instancetype)bigNumberWithData:(NSData *)data {
    return [BigNumber bigNumberWithHexString:[data hexEncodedString]];
}

+ (instancetype)bigNumberWithNumber:(NSNumber *)number {
    return [self bigNumberWithDecimalString:[number stringValue]];
}

+ (instancetype)bigNumberWithInteger:(NSInteger)integer {
    return [self bigNumberWithDecimalString:[[NSNumber numberWithInteger:integer] stringValue]];
}

- (void)dealloc {
    mp_clear(&_bigNumber);
}

- (mp_int*)_bigNumber {
    return &_bigNumber;
}


#pragma mark - Constants

+ (BigNumber*)constantNegativeOne {
    return ConstantNegativeOne;
}

+ (BigNumber*)constantZero {
    return ConstantZero;
}

+ (BigNumber*)constantOne {
    return ConstantOne;
}

+ (BigNumber*)constantTwo {
    return ConstantTwo;
}

+ (BigNumber*)constantWeiPerEther {
    return ConstantWeiPerEther;
}



#pragma mark - Operations

- (BigNumber*)add:(BigNumber *)other {
    BigNumber *result = [[BigNumber alloc] init];
    mp_add(&_bigNumber, [other _bigNumber], [result _bigNumber]);
    return result;
}

//- (void)iadd:(BigNumber *)other {
//    mp_add(&_bigNumber, [other _bigNumber], &_bigNumber);
//}

- (BigNumber*)sub:(BigNumber *)other {
    BigNumber *result = [[BigNumber alloc] init];
    mp_sub(&_bigNumber, [other _bigNumber], [result _bigNumber]);
    return result;
}

//- (void)isub:(BigNumber *)other {
//    mp_sub(&_bigNumber, [other _bigNumber], &_bigNumber);
//}

- (BigNumber*)mul:(BigNumber *)other {
    BigNumber *result = [[BigNumber alloc] init];
    mp_mul(&_bigNumber, [other _bigNumber], [result _bigNumber]);
    return result;
}

- (BigNumber*)div:(BigNumber *)other {
    BigNumber *result = [[BigNumber alloc] init];
    mp_div(&_bigNumber, [other _bigNumber], [result _bigNumber], NULL);
    return result;
}

- (BigNumber*)mod:(BigNumber *)other {
    BigNumber *result = [[BigNumber alloc] init];
    mp_div(&_bigNumber, [other _bigNumber], NULL, [result _bigNumber]);
    return result;
}

//- (BigNumber*)pow:(BigNumber *)other {
//    BigNumber *result = [[BigNumber alloc] init];
//    mp_expt_d(&_bigNumber, [other _bigNumber], NULL, [result _bigNumber]);
//    return result;
//}


#pragma mark - Query API

- (BOOL)isZero {
    return (mp_cmp([ConstantZero _bigNumber], &_bigNumber) == MP_EQ);
}

- (BOOL)isNegative {
    return (_bigNumber.sign == MP_NEG);
}


#pragma mark - String Operations

- (NSString*)formatString:(int)radix {
    int radixSize;
    mp_radix_size(&_bigNumber, radix, &radixSize);
    
    char result[radixSize];
    mp_toradix(&_bigNumber, result, radix);
    return [[NSString alloc] initWithCString:result encoding:NSASCIIStringEncoding];
}

- (NSString*)decimalString {
    return [self formatString:10];
}

- (NSString*)hexString {
    NSString *hexString = [self formatString:16];
    
    if (self.isNegative) {
        hexString = [hexString substringFromIndex:1];
    }

    if (hexString.length % 2) {
        hexString = [@"0" stringByAppendingString:hexString];
    }
    
    hexString = [@"0x" stringByAppendingString:hexString];
    
    if (self.isNegative) {
        hexString = [@"-" stringByAppendingString:hexString];
    }
    
    return hexString;
}

- (NSString*)base36String {
    return [self formatString:36];
}

- (BOOL)isSafeUnsignedIntegerValue {
    return (mp_cmp(&_bigNumber, [ConstantMaxSafeUnsignedInteger _bigNumber]) == MP_LT && ![self isNegative]);
}

- (BOOL)isSafeIntegerValue {
    return mp_cmp(&_bigNumber, [ConstantMaxSafeSignedInteger _bigNumber]) == MP_LT;
}

// @TODO: there are certainly better ways to do this
- (NSUInteger)unsignedIntegerValue {
    int radixSize;
    mp_radix_size(&_bigNumber, 16, &radixSize);
    
    char hexString[radixSize];
    mp_toradix(&_bigNumber, hexString, 16);
    
    NSUInteger result = 0;
    
    // Skip null-termination
    for (int i = 0; i < radixSize - 1; i++) {
        result <<= 4;
        unsigned char c = hexString[i];
        if (c <= '9') {
            result += (c - '0');
        } else if (c <= 'F') {
            result += 10 + (c - 'A');
        } else if (c <= 'f') {
            result += 10 + (c - 'a');
        }
    }
    
    return result;
}

- (NSInteger)integerValue {
    NSInteger multiplier = 1;
    BigNumber *value = self;
    if (self.isNegative) {
        multiplier = -1;
        value = [value mul:[BigNumber constantNegativeOne]];
    }
    return multiplier * [value unsignedIntegerValue];
}

- (NSData*)data {
    return [[self hexString] dataUsingHexEncoding];
}

#pragma mark - NSObject goodness

- (instancetype)copy {
    return self;
    // @TODO: Don't do all this extra conversion...
//    return [BigNumber bigNumberWithHexString:self.hexString];
}

- (NSUInteger)hash {
    return [[self decimalString] hash];
}

- (BOOL)isEqual:(id)object {
    return [self compare:object] == NSOrderedSame;
}

- (NSComparisonResult)compare:(id)other {
    if (![other isKindOfClass:[BigNumber class]]) {
        return NSOrderedDescending;
    }

    int result = mp_cmp(&_bigNumber, [((BigNumber*)other) _bigNumber]);
    if (result == MP_EQ) {
        return NSOrderedSame;
    } else if (result == MP_LT) {
        return NSOrderedAscending;
    } else {
        return NSOrderedDescending;
    }
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<BigNumber %@>", self.decimalString];
}

@end