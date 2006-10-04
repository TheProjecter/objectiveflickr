// Shared Demo API key
// We use svn property to make this file ignores in each commit

#ifndef __OFDemoAPIKey_h
#define __OFDemoAPIKey_h

#define OFDemoAPIKey			@"cf732d5ea5a5568a50b50556e6cd0d50"
#define OFDemoSharedSecret		@"07676a799c5593b2"

#ifndef OFDemoAPIKey
	#error Please define your OFDemoAPIKey in OFDemoAPIKey.h.
#endif

#ifndef OFDemoSharedSecret
	#error Please define your OFDemoSharedSecret in OFDemoAPIKey.h.
#endif

#endif
