// Shared Demo API key
// We use svn property to make this file ignores in each commit

#ifndef __OFDemoAPIKey_h
#define __OFDemoAPIKey_h

#define OFDemoAPIKey			@""
#define OFDemoSharedSecret		@""

#ifndef OFDemoAPIKey
	#error Please define your OFDemoAPIKey in OFDemoAPIKey.h.
#endif

#ifndef OFDemoSharedSecret
	#error Please define your OFDemoSharedSecret in OFDemoAPIKey.h.
#endif

#endif
