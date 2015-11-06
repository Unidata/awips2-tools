
Feb 27, 2014


Setting up the bundle converter.

In order to use this prototype, stage all the files in the
same directory, in an environment that has access to an
old D-2D localization data set.  One should also have all
the standard old D-2D environment variables set.  The only
binary executable is now statically linked, so it should be
able to run on any A-II machine.

If one needs to run this on a machine that does not have a
working old D-2D environment, three files are provided that support
implementing just enough of this enviroment to allow the bundle
conversion to function.  The script grabFromD-2D.csh is meant to
be run on a machine with an old D-2D environment; it tars up just
enough of that environment to support bundle conversion.  The
resulting tar (convBundStage.tgz) is meant to be untarred into
the directory /awips/fxa on whatever machine one wants to perform
the bundle conversion.  This directory should first be created if
it does not exist. Once these files have been untarred, sourcing
the file convBund.cshsrc or convBund.bashsrc will set up the environment
variables needed to allow the program convertBundles to function.  Be aware
that convBund.cshsrc and convBund.bashsrc are meant to be sourced, not run
as a command; convBund.cshsrc should be used in a C shell and
convBund.bashsrc should be used in a Bourne shell.

The program convertBundles does the work; the rest of the files
are supporting data.

The program convertBundles will try to locate a version of the
file LevelMappingFile.xml.  By default it will try to find it
somewhere under /usr/local/viz/cave/plugins/.  Alternatively, it
will look under $CAVE_ROOT/, or one could stage a version of
LevelMappingFile.xml in the same directory as convertBundles is in.
If your site has a customized LevelMappingFile.xml, you might not be
able to rely on convertBundles to find it.  The customized version
of this file lives in the directory:

  /awips2/edex/data/utility/cave_static/site/LLL/volumebrowser/

where LLL is your site id.  This directory is not mounted on all
machines, and so the best bet is to manually ftp it to the
same directory convertBundles is staged in on whatever host you
are running convertBundles from.

You should be able to run the program convertBundles from anywhere,
as long as it is staged in the same directory as the supporting data.


Running and testing the bundle converter.

There are two primary usages for the bundle converter program:

    convertBundles netcdfPath
    convertBundles netcdfPath xmlPath ...

In these idealized usage examples, netcdfPath is the full path to
any old style D-2D netcdf bundle file.  The first usage writes the
text of a Cave xml bundle to stdout.  For the second usage, xmlPath
is the full path to any file to write the text of a Cave xml bundle to;
there can be any number of netcdfPath - xmlPath pairs.  Optionally, one
can supply a leading literal 'a' argument.  If a useable 'overlay' entry
does not already exist for a given depict key in BundleConversionInfo.txt,
the 'a' argument will cause the file overlay-kkkk.xml (where kkkk is the
depict key for the overlay) to automatically get used if it exists.
More complete usage documentation for the convertBundles program can
be found in the convertBundles.doc file.

One does not necessarily have to be in the same directory as the 
convertBundles program in order to successfully run it.  However,
the convertBundles program and all its associated metadata do need to
all be staged together in the same directory.

Be advised that there are no smarts in the convertBundles program as far as
organizing bundle files in the file system.  All this knows how to do is
convert old D-2D netcdf bundle files to A-II xml bundles. You have to tell
it specifically what files to use as input and output. In a legacy system,
netcdf bundles typically reside at a path like:

  /awips2/fxa/userPrefs/$USER/procedureName/FXA.*

For now, probably the best way to test individual converted bundles is to dump
them in your home directory on your Cave host.  Then you can load them using
the file chooser dialog on Cave located at:

  Cave -> Load/Save Displays -> Load Displays...

With this version of the converter is a new script called convertProc.csh.
In the legacy D-2D, what we call a procedure is implemented by a directory
that contains netcdf bundle files plus an index file.  The analogous data
structure in A-II is totally self contained in a single xml file.  The script
convertProc.csh takes the path of one procedure directory as an argument
and tries to produce an A-II procedure xml file, written to the current
working directory; the name of the output file will be reported by the
script to stdout.  Many procedure directories may have spaces in the
directory name, and in that case one may need to quote the procedure directory
path.  This script uses the literal 'a' option with the convertBundles
program, so it will automatically try to pick up files named
overlay-kkkk.xml (where kkkk is the depict key for the overlay) if
they exist in the converter directory.  Here is where one can
place procedure xml files for testing:

  /awips2/edex/data/utility/cave_static/user/$USER/procedures/

Note that one needs to be on a server machine (not an lx) to write into
cave_static/.

In the current implementation, this should be able to convert any VB overlay
that A-II actually implements.  It will also convert just about any radar image
except for mosaics with composite reflectivity, and it will probably
convert most radar graphics.  Satellite images, redbook graphics, raob skew-Ts
and profiler time-heights should all be fully implemented.  Nearly all
multi-level plan view plots (including profiler and Raob) are in place, plus
one metar plot, the standard hourly plot.  Lightning, severe weather plots,
local warnings, and SPC watch displays have been implemented as well.  Besides
map backgrounds that are scale defaults, only point map backgrounds have been
implemented.

Be advised that while most overlays will be converted, there are many
overlays that will not.  If there is a particular overlay that the
converter is not yet designed to handle, but the user considers necessary,
the user is referred to the next section, entitiled "Customizing the
bundle converter."

The bundle converter has gotten mature enough such that if the documentation
says a particular type of overlay should be implemented, but it fails
to get translated, it should be reported as a bug in the bundle
converter.  One caveat to this is that there are still some things
that the legacy D-2D can load but Cave cannot.  Another caveat is that
there are certain things that can be loaded on Cave through the menus,
but if you create a bundle in Cave and then try to reload using the
Cave generated bundle, it will fail.  If either of these things is
true, this should be reported as a Cave bug rather than as a bug in
the bundle converter.

In order to make it easier to diagnose errors in the converter, the
path of the legacy netcdf bundle file that was used to produce each
A-II format xml bundle is encoded as a comment near the beginning of the
xml for each bundle.  Furthermore, if the converter fails to produce
xml for individual overlays, a brief description of the overlay in
question and what the problem was is also encoded as a comment in place
of the xml for the overlay.

As this is written (Jan 31, 2012) bugs in the bundle converter should
be reported to Ashley Kells (Ashley.Kells@noaa.gov) and/or James Ramer
(james.e.ramer@noaa.gov).


Customizing the bundle converter.

For any radar, VB, or satellite image displays that cannot be successfully
be encoded into an xml bundle, GSD will take responsibility for seeing
to it that these are addressed.  However, for other types of displays,
especially those where an overlay xml file is supplied for one specific
depict key, it is hoped that people outside of GSD can be leveraged to
fill out the set of displays that can be successfully handled.

Any time there is a feature in the system that can be customized,
keeping those customizations up to date and merged with new functionality
in the main release is always an issue.  In order keep the amount of
manual merging associated with bundle converter customizations to 
a minimum, a separate directory has been established for holding local
extenstions to the converter.  This directory is pointed to by the
environment variable SITE_BUNDLE_INFO; this allows the user to specify
the path to this as they see fit.  Furthermore, a separate file,
LocalBundleInfo.txt, has been established for making overlay conversion
entries that extend the default set of entries in BundleConversionInfo.txt.

The files convBund.cshsrc and convBund.bashsrc will attempt to make a
default definition of the SITE_BUNDLE_INFO environment variable, assuming
it is not already set.  The default definition will be reported if this
occurs.

To successfully craft a new overlay conversion entry to place in the
file $SITE_BUNDLE_INFO/LocalBundleInfo.txt, at a minimum one needs either
the depict key or the depictable type.  If one runs locateKey.csh with a
legend or legend fragment as an argument, it will attempt to lookup that
overlay in the legacy D-2D tables and print out the information needed for
overlay conversion entries.

The easiest way to implement a specific xml file for an overlay is
to first load the product of interest on Cave, then unload everything
except the overlay in question, including the map backgrounds (unless it
is a map background one is trying to implement).  Then save the bundle
to a file using the chooser dialog on Cave located at:

  Cave -> Load/Save Displays -> Save Editor Displays...

Your overlay specific xml is then everything in that file from the first
line with <resource> to the last line with </resource>.  Two recent
changes to the convertBundles program simplify preparing an overlay
xml file.  First, when convertBundles is reading xml files that are
meant to function as overlay xml, it will automatically strip out anything
before the first <resource> and after the last </resource>.  If anything
stripped in this manner is not whitespace, a warning message will be printed
to stderr.  Second, convertBundles can now be called in a way specifically
designed to prepare overlay xml files, using a literal lowercase o flag,
like so:

  convertBundles o bundleDump.xml overlaySpecific.xml

To complete the implementation of your new overlay, place a file with
the data for the overlay in $SITE_BUNDLE_INFO/, and add an entry to 
$SITE_BUNDLE_INFO/LocalBundleInfo.txt that looks like this:

  overlay     |   kkkk        |  myOverlaySpecific.xml

where 'overlay' is literal and 'kkkk' is the depict key, most easily
looked up using the locateKey.csh script described previously.

It is still possbile to customize by placing overlay specific xml
in the same directory as the main converter is installed and directly
editing BundleConversionInfo.txt.  However, it is recommended to
make use of a directory that SITE_BUNDLE_INFO points to and to put your
overlay conversion entries in LocalBundleInfo.txt.  If there are
redundant entries in both BundleConversionInfo.txt and LocalBundleInfo.txt,
this might be a bit confusing to maintain, but it will not hurt anything.
If two similar entries made in both files have the same first and second
column but different data in the last column, the entry in LocalBundleInfo.txt
will be preferred.

To maintain the ability to extend the entries in BundleConversionInfo.txt
using the LocalBundleInfo.txt file, one must never remove or change the
#include line at the very end of BundleConversionInfo.txt.  Also, if
a version of BundleConversionInfo.txt is placed in the $SITE_BUNDLE_INFO/
directory, it will completely displace the one in the main directory,
so this is not recommended.

When a new version of the converter is installed, you want to 
be on the lookout for instances where your customized functionality
might be overriding new and preferred functionality in the default
converter.  This can occur where you have similar entries in both
BundleConversionInfo.txt and LocalBundleInfo.txt, where the first
two vertical bar delimited fields are the same but the last one is
different.  This can also occur where you have overlay xml files
with the exact same name in both the default converter directory and
in the $SITE_BUNDLE_INFO/ directory.

Any data file that supports the converter and lives in the converter
directory (for example LevelMappingFile.xml or a2satInfo.txt) can also
be placed in the $SITE_BUNDLE_INFO/ directory, and that file will take
precedence over a version of that file in main directory. Doing this
protects those updates from being overwritten by upgrading the converter.
For LevelMappingFile.xml, it is probably not a good practice to do this.
However, it could conceivably make sense to do this with a version of
a2satInfo.txt for for OCONUS sites.


Cave refuses to accept my converted procedure, now what?

Note:
   As of 11.9, and possibly earlier, it appears that changes have been made
   that will guarantee that any procedure file that is well formed xml
   will be always be accepted into the procedure GUI. However, we will
   retain this section for a couple of releases just in case.

As the Cave has evolved, the bundle xml associated with
certain overlays has changed from release to release.

In Cave, a procedure is a single xml file containing potentially
dozens of bundles, and each bundle in a procedure xml file can
potentially contain a dozen or more overlays.  When the Cave
procedure parser encounters an overlay encoded in a manner
that was valid in a previous release but is no longer valid,
the behavior varies.  Sometimes, it will just ignore that
overlay and go on.  However, there are certain inter-release
inconsistencies that cause the procedure parser to refuse
to process any part of the procedure; this is presented to
the user as an "XML deserialization" error.  When this occurs,
one release inconsistency in one overlay of one bundle can
potentially invalidate an entire procedure with perhaps hundreds
or even thousands of overlays. 

The only way to remedy this situation is to first identify the specific
overlay of the specific bundle that is causing the problem.  The
convertProc.csh script normally reports how many bundles it did convert.
An alternate usage of convertProc.csh allows the user to set a maximum
number of bundles to convert, like so, where n is the maximum:

  convertProc.csh n procDir

One would start by converting half the bundles and then attempting to
load the partially converted procedure in Cave.  A failure indicates the
problem is in the first half of the procedure; success would indicate the
problem is in the second half.  Continue narrowing this down using a binary
search until the offending bundle had been identified.  This may sound
daunting, but in theory a bad bundle in a procedure with 250 bundles can
be identified in only 8 or 9 tries.  Once one has identified the offending
bundle, one can use a similar option with the convertBundles program to
identify the offending overlay.  The following command can tell you how
many overlays are in a legacy netcdf bundle file:

  ncdump -h pathToNetcdfBundleFile | head -n 3

And the following usage of convertBundles allows the user to set a maximum
number of overlays to convert in the bundle:

  convertBundles n pathToNetcdfBundleFile myTestBundle.xml

Once you know which overlay is the offending overlay, you can install new
overlay specific xml for that overlay as detailed in the previous section.
Alternatively, one could eliminate the offending overlay from your procedure
before converting it.


More information on the format of overlay templates.

In the set of xml files supplied with the converter, once sees a number
of instances where text between two at signs (@) occurs.  The first category
of these are symbols that result in a direct text replacement and are
specifically tailored for a particular display type.  In general, these are
fully implemented and users should not need to place them in their own overlay
specific xml.  Here is the current set of those symbols:

 @VRTSCL_NAME@  @BOTTOM@  @TOP@  @VUNIT@
 @LINE_ID@  @LINE_STR@  @POINT_LAT@  @POINT_LON@ @POINT_LETTER@
 @VB_SOURCE@  @VB_LEGEND@  @VB_FIELD@ @VB_TITLE@
 @VB_LEVEL_ONE@  @VB_LEVEL_TYPE@  @VB_LEVEL_TWO@ 
 @PERT_IDX@ @DB_NAME@   @STATION_TABLE@ @STATION_INFO@ @STATION_ID@
 @EXTRA_XML@  @LAT_MIN@  @LAT_MAX@  @LON_MIN@  @LON_MAX@
 @RADAR_ID@  @RADAR_MSG_CODE@  @CODE_LIST@  @TILT_MIN@  @TILT_MAX@
 @SAT_CHANNEL@  @SAT_SECTOR@  @SAT_ENTITY@
 @WMO_ID@ @NNN_LIST@
 @ENV_MIN_X@  @ENV_MAX_X@  @ENV_MIN_Y@  @ENV_MAX_Y@  @MAX_RANGE_X@
 @PROJ_NAME@  @PROJ_LAT@  @PROJ_LON@ 

Another category includes a couple of symbols that result in a very specific
substitution, but that do have general use.  The first is the symbol
@OVERLAY_LEGEND@, which as its name suggests gets replaced with the legend
of the overlay.  The second is @COLOR_MAP_INFO@, which must be included
in any image overlay, and needs to appear on a line by itself in the following
context:

           <capability xsi:type="colorMapCapability">
                 @COLOR_MAP_INFO@
           </capability>

Another general use symbol is @FORCE_ONE_PANEL@, which is only meant
to occur in a file entered into the conversion info as a `depiction'
entry type.  If present, it gets removed and triggers behavior where
multi-panel displays are converted to a single panel display with
all the overlays consolidated into that one panel.

Most of the rest of the symbols discussed here have arguments.
A symbol with arguments generally appears on a line by itself and
looks like this:

@NAME_OF_SYMBOL,argument1,argument2@

In all the idealized examples we will show here, a comma will used as the
delimeter between arguments.  However, there are several different argument
delimeters that can be used, just in case one of the arguments needs to have
a comma in it.  Be advised that the same argument delimeter must be used for
the entire symbol, but different symbols can have different argument delimeters.
Here is the set of available alternate delimeters:

   " \ ' - . / : ; ` |

Also, the text of a symbol with arguments is allowed to span multiple lines
as long as the last non-space character on the line is a delimeter or the
terminating at sign.  A multi-line symbol could look like this:

@NAME_OF_SYMBOL,argument1,argument2,
                argument3,argument4,argument5,
                argument6,argument7@

For all symbols with arguments, spaces adjacent to the delimeters and
trailing at sign do not become part of the arguments.  However, no spaces
are allowed between the symbol name and the first delimeter. In all cases,
the text of the symbol itself is stripped once it has been used to direct
some modificaton of the text, and in most cases it does not matter where
in the text the symbol appears.

The symbol with the name DATA_KEY_TEXT is used to pull text into an overlay
template that is specific to individual data keys.  It has one argument that
is the name of the file from which to pull in text to represent each data key.
For the @DATA_KEY_TEXT symbol, it does matter where in the text it appears;
this controls the point in the main xml template where the datakey text is
inserted. A file pulled in this way can have its own nested occurence of a
@DATA_KEY_TEXT symbol in some circumstances. Sometimes this symbol occurs
with no file name argument, in which case there must be an entry in
BundleConversionInfo.txt with the 'datakey' type active for the
overlay template.  For the most part, the needed occurences of the
@DATA_KEY_TEXT symbol are fully implemented and users should not need to
place them in their own overlay specific xml.

For many instances of plan view plots in the legacy D-2D, the 13th vertical
bar delimited field in the depict key contains the so-called 'extra info',
which is a series of comma delimited strings.  In the legacy D-2D, the extra
info performs a symbol value substitution in the associated design file, and
this is used in much the same way in the bundle converter.  For depict key
2500, which is the 500MB raob plot, the extra info contains levelMB and
500.  In the corresponding xml overlay template, this results in @levelMB@
being replaced with 500.  This is the only situation where additional symbols
can be defined dynamically based on the nature of the overlay being
converted, and symbols so defined never have arguments.

Furthermore, conversions based on the extra info can be made more
flexible using the @TRANSLATE symbol. Here is an example of an instance of 
using the @TRANSLATE symbol:

  @TRANSLATE,levelIdx,0,0.5km,1,750m,2,1km,3,1250m,4,1.5km@

What this means is that where the extra info by itself would cause
@levelIdx@ to be replaced by 0, now it will be replaced by 0.5km,
where it would be replaced by 1, now it will be replaced by 750m,
etc.

As more of the plan view plots get implemented, users may find themselves
creating additional xml templates that interact with the extra info in these 
ways. 

Finally, there are four additional ways in which symbols can cause
the xml to be modified, and these are not limited in any way to a particular
type of display.  The first, and simplest, is the symbol @REPLACE, which
looks like this:

   @REPLACE,textToReplace,textToInsert,textToReplace,textToInsert@

There can any number of replace-insert pairs.  Changes to the text driven
by the @REPLACE symbol are specifically designed NOT to change text within
other symbols.

The next general means of symbol driven text modification is the
@REPLACE_FOR_KEY symbol.  It has three usages:

    @REPLACE_FOR_KEY,DEPICT,depictkey,textToReplace,textToInsert@
    @REPLACE_FOR_KEY,DATA,datakey,textToReplace,textToInsert@
    @REPLACE_FOR_KEY,key,textToReplace,textToInsert@

The first usage performs the text replacement only if the supplied key
is the same as the depict key for the D-2D overlay.  The second usage
performs the text replacement only if the supplied key is the same as
one of the data keys for the D-2D overlay.  The third usage can match
either depict or data keys.  In all cases, there can be any number
of key-replace-insert triplets.  Furthermore, if the key supplied
has a leading tilde (~), then that means perform the replacement if
the key provided does NOT match.  The @REPLACE_FOR_KEY symbol is also
designed to avoid changing text within other symbols.

The final two general means of symbol driven text modification actually
involve pairs of symbols working in concert, and here it does matter
where in the text the symbols are placed.  The symbols involved are a
@REMOVE_FOR_KEY symbol paired with an @END_REMOVE@ symbol, or a
@REMOVE_BY_SUBSTR symbol, also paired with an @END_REMOVE@ symbol.
In each case, depending on a test specified by the contents of the
leading symbol, all text between the two symbols may get stripped from
the resulting xml for the overlay.  The contents of both of the symbols
themselves are always stripped, of course.  There can be any number of
instances of these symbol pairs, but they cannot be nested or overlap
in their range.  A corollary to this is that one should be very cautious
about placing a @DATA_KEY_TEXT symbol inside one of these symbol pairs.

The arguments for the @REMOVE_FOR_KEY symbol are a list of keys to
test against the depict and/or set of data keys for the overlay.
As with the @REPLACE_FOR_KEY symbol, a leading tilde (~) means the test is
true if the specified key is not in the keys for the overlay, and the
optional leading DEPICT and DATA arguments can restrict which keys are
tested against.  By default, as soon as one of the keys tests true,
testing stops and the text between the symbol pair is removed.  An optional
leading AND_TEST argument means that in order for the text to be removed,
all keys must test true.

The arguments for the @REMOVE_BY_SUBSTR symbol are a set of strings to
test against the contents of the entire text of the overlay xml.  Again,
a leading tilde (~) means the test is true if the specified string is not
found in the text of the overlay xml, and the optional leading AND_TEST
argument means all strings must test true before the text will be removed.
This is designed such that when searching for substrings within the text
of the overlay, text within symbols will not be searched.

While the @REPLACE_FOR_KEY symbol and the @REMOVE_FOR_KEY symbol can only
operate within an individual overlay, the @REPLACE and @REMOVE_BY_SUBSTR
symbols can be used in other contexts.  If placed in an overlay
specific xml, @REPLACE and @REMOVE_BY_SUBSTR will still only affect
that overlay, but it is also meaningful to place these substitutions in
other input xml files that are not necessarily overlay specific.
