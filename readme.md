This repo contains units written by me, that provide whatever functionality I happened to want when building whatever project I happened to be working on. Some of those projects are hosted in my other repos. Those projects will not include a copy of these units. If you wish to compile my projects yourself, you will also need the relevant units from here.

All units here should always be considered unfinished or "in progress". They are updated as I decided to add to or remove from them, or rarely when I decide to do things correctly.

### Description of Units

#### gemarray.pas
Provides a dynamic array wrapper similar to TList (FPC) or std::vector (C++). It has functionality that I specifically wanted that TList and it's variants lacked. Additionally gemarray.pas also contains non-generic functions for Pushing to, popping from and combining arrays of types UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64, Single and Double.

#### gemaudio.pas
Provides a wrapper over some OpenAL functionality for loading and playing .wav files. Additionally, there is very basic functionality for converting bit depth and sample rates, adjusting gain and bit crushing. Don't attemtp to use the functions for find the period or time stretching. They don't work. They probably won't any time soon.

#### gembitfield.pas
Provides a class wrapper bit field operations. It could be optimized more, but as it is in all tests I've done, it's faster than traversing an array of primitive types.

#### gemclock.pas
Provides functionality for time keeping and some basic time-based event handling.

#### gemlinkedlist.pas
I wanted to make a linked list. It's probably nowhere near as performant as it could be. It does some things I personally wanted.

#### gemmath.pas
Mostly random simple math functions such as producing random numbers, clamping float and intergers to the ranges of 0..1 and 0..255 respectively, finding distances, radians and degrees, converting values to a different type, finding the direction to rotate for the least amount of rotation and angular diameter. Probably not very useful at all for anyone but me and my specific purposes.

#### gemprogram.pas
Provides a class that "wraps" or represents some attributes of the program the unit is included in. Caches PID, UID, EUID, username, effective username, commandline parameters. Adds a wrapper around Posix singal handling. Allows the programer to require root and relauch requesting root with "sudo".

#### gemrasterizer.pas
At one point I was attempting a software rasterizer. I might make another attempt at it at some point. Don't bother looking at it. It's not good. It does nothing.

#### gemtypes.pas
Contains vector, matrix and color record types as well as functions for manipulating them. These were/are being used for my own OpenGL code. They might be useful, maybe.

#### gemutil.pas
This contains all kinds of "misc" functions and a couple classes that I didn't feel warranted their own units. We have file I/O, a TGEMDirectory class that wraps directory traversal, TGEMFileStream... which is a file stream... TGEMDateStruct, which represents a date for some reason, functions for bit manipulation, string functions, memory functions and time functions. You probably need none of these... except for maybe TGEMDirectory, because as far as I know FPC doesn't have a TDirectory equivalent. If it turns out it does, then nevermind.

Also, I made a half-assed attempt at making these things compatible with FPC and Delphi, Windows and Linux.
