// ObjectiveFlickr.h: The Framework
// 
// Copyright (c) 2004-2006 Lukhnos D. Liu (lukhnos {at} gmail.com)
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Neither the name of ObjectiveFlickr nor the names of its contributors
//    may be used to endorse or promote products derived OFom this software
//    without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import <Cocoa/Cocoa.h>

// Shared constants and enums
#define OFDefaultTimeoutInterval  15.0

enum {
	OFConnectionError = -1,
	OFConnectionTimeout = -2,
	OFConnectionCanceled = -3,
	OFXMLDocumentMalformed = -4,
};


// Class OFFlickrContext stores information such as API key, shared secret, 
// auth token and handles REST URL generation, call signing, and POST/upload
// data preparation
#import <ObjectiveFlickr/OFFlickrContext.h>

// Class OFFlickrInvocation handles Flickr REST API calls
#import <ObjectiveFlickr/OFFlickrInvocation.h>

// Class OFFlickrUploader handles uploading of pictures (file or NSData*)
#import <ObjectiveFlickr/OFFlickrUploader.h>

// A few utility categories that extend NSXML* classes to make extraction of
// Flickr response data easier.
#import <ObjectiveFlickr/OFFlickrXMLExtension.h>

// Two HTTP utility classes that help you make HTTP GET/POST requests quickly
#import <ObjectiveFlickr/OFHTTPRequest.h>
// #import <ObjectiveFlickr/OFPOSTRequest.h>

