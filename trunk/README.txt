ObjectiveFlickr
Version 0.9.5 (2007-02-14)

ObjectiveFlickr is a Flickr API framework that makes it easy to 
develop Flickr applications using Objective-C and Cocoa.

Getting Started

The easy way is to visit the site: http://lukhnos.org/objectiveflickr ,
download a copy of the latest build, in which you'll find pre-built
demos and ObjectiveFlickr.framework with which you can start writing your
own Flickr application right away!

Building from Source

Nota bene: By default, ObjectiveFlickr.xcodeproj DOES NOT build everything.
This is because I have removed the API key and shared secret from 
OFDemoAPIKey.h -- it's not proper to put your own API key and shared secret
in a public source repository.

Therefore, by default, only the framework target (ObjectiveFlickr) is built.

I'm constantly improving the framework. Any feedback or patch is always
welcome. At the same time, please visit http://lukhnos.org/objectiveflickr
for updates and tutorials (how to write your own first OS X Flickr app, etc.).

Cheers,
lukhnos (lukhnos {at} gmail {dot} com)
