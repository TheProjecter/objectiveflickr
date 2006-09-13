/*
 * main.m
 * CocoaCryptoHashing
 * 
 * Copyright (c) 2004-2005 Denis Defreyne
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * 
 * - Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * 
 * - The names of its contributors may not be used to endorse or promote
 *   products derived from this software without specific prior written
 *   permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "CocoaCryptoHashing.h"

NSString *SHA1TestStrings[] = {
	@"abc",
	@"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
	@"a",
	@"0123456701234567012345670123456701234567012345670123456701234567"
};

NSString *SHA1TestStringResults[] = {
	@"a9993e364706816aba3e25717850c26c9cd0d89d",
	@"84983e441c3bd26ebaae4aa1f95129e5e54670f1",
	@"34aa973cd4c4daa4f61eeb2bdbad27316534016f",
	@"dea356a2cddd90c7a7ecedc5ebb563934f460452"
};

NSString *MD5TestStrings[] = {
	@"",
	@"a",
	@"abc",
	@"message digest",
	@"abcdefghijklmnopqrstuvwxyz",
	@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
	@"12345678901234567890123456789012345678901234567890123456789012345678901234567890"
};

NSString *MD5TestStringResults[] = {
	@"d41d8cd98f00b204e9800998ecf8427e",
	@"0cc175b9c0f1b6a831c399e269772661",
	@"900150983cd24fb0d6963f7d28e17f72",
	@"f96b697d7cb7938d525a2f31aaf161d0",
	@"c3fcd3d76192e4007dfb496cca67e13b",
	@"d174ab98d277d9f5a5611c2c9f419d9f",
	@"57edf4a22be3c955ac49da2e2107b67a"
};

int main(void)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	/* print welcome message */
	puts("CocoaCryptoHashing Test Suite");
	puts("=============================");
	
	/* print sha1 header */
	puts("");
	puts("SHA1");
	puts("----");
	
	/* perform sha1 tests */
	printf("SHA1 (\"%s\") = %s\n", [SHA1TestStrings[0] cString], [[SHA1TestStrings[0] sha1HexHash] cString]);
	printf("Should be: %s\n", [SHA1TestStringResults[0] cString]);
	
	printf("SHA1 (\"%s\") = %s\n", [SHA1TestStrings[1] cString], [[SHA1TestStrings[1] sha1HexHash] cString]);
	printf("Should be: %s\n", [SHA1TestStringResults[1] cString]);
	
	printf("SHA1 (\"%s\") = %s\n", [SHA1TestStrings[2] cString], [[SHA1TestStrings[2] sha1HexHash] cString]);
	printf("Should be: %s\n", [SHA1TestStringResults[2] cString]);
	
	printf("SHA1 (\"%s\") = %s\n", [SHA1TestStrings[3] cString], [[SHA1TestStrings[3] sha1HexHash] cString]);
	printf("Should be: %s\n", [SHA1TestStringResults[3] cString]);
	
	/* print md5 header */
	puts("");
	puts("MD5");
	puts("---");
	
	/* perform md5 tests */
	printf("MD5 (\"%s\") = %s\n", [MD5TestStrings[0] cString], [[MD5TestStrings[0] md5HexHash] cString]);
	printf("Should be: %s\n", [MD5TestStringResults[0] cString]);
	
	printf("MD5 (\"%s\") = %s\n", [MD5TestStrings[1] cString], [[MD5TestStrings[1] md5HexHash] cString]);
	printf("Should be: %s\n", [MD5TestStringResults[1] cString]);
	
	printf("MD5 (\"%s\") = %s\n", [MD5TestStrings[2] cString], [[MD5TestStrings[2] md5HexHash] cString]);
	printf("Should be: %s\n", [MD5TestStringResults[2] cString]);
	
	printf("MD5 (\"%s\") = %s\n", [MD5TestStrings[3] cString], [[MD5TestStrings[3] md5HexHash] cString]);
	printf("Should be: %s\n", [MD5TestStringResults[3] cString]);
	
	printf("MD5 (\"%s\") = %s\n", [MD5TestStrings[4] cString], [[MD5TestStrings[4] md5HexHash] cString]);
	printf("Should be: %s\n", [MD5TestStringResults[4] cString]);
	
	printf("MD5 (\"%s\") = %s\n", [MD5TestStrings[5] cString], [[MD5TestStrings[5] md5HexHash] cString]);
	printf("Should be: %s\n", [MD5TestStringResults[5] cString]);
	
	printf("MD5 (\"%s\") = %s\n", [MD5TestStrings[6] cString], [[MD5TestStrings[6] md5HexHash] cString]);
	printf("Should be: %s\n", [MD5TestStringResults[6] cString]);
	
	[pool release];
	
	return 0;
}