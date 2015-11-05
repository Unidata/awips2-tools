"""Module GFE_unmangler:

   Module to unmangle AWIPS 1 GFE filenames.  GFE allows names of edit areas,
   tools, procedures, etc. to have names in the GUI to have characters like
   '/', '&', etc. that may cause problems if used in the actual filename. GFE
   translated (i.e.,  mangled) these characters to special codes that were used
   in the actual filenames. This module will unmagle the GFE filename and
   report if there are some characters in the unmangled name that may cause
   file problems because they are shell meta characters.  Note that a '/' in the
   unmangled name will be forced to '_'.  Change STable below to change what
   character is substituted for the special code in the mangler filename.
   The extension will also be changed to .py. 

   This module has one public function, unmangler, which takes a filename to
   unmangle, and returns the unmangled filename.  Prints warnings about special
   characters (given by warnChars) to stdout.

Author: Paul Jendrowski NOAA/NWS  WFO RNK, Blacksburg, VA
        paul.jendrowski@noaa.gov

SVN: $Revision: 823 $  -  $Date: 2011-04-25 14:50:12 +0000 (Mon, 25 Apr 2011) $
"""

# List of extensions for GFE python files.
GFE_suffixes=['UserPython', 'Config', 'SmartTool','Tool',
              'Procedure', 'Utility', 'TextUtility', 'TextProduct',
             ]

#---------------------------------------------------------------------
# Tables for manged ifpServer names - From GFE baseline code
#---------------------------------------------------------------------
# CTable used for mangling
CTable = { ' ': '_CA', '!': '_CB', '"': '_CC', '#': '_CD', '$': '_CE',
        '%': '_CF', '&': '_CG', "'": '_CH', '(': '_CI', ')': '_CJ',
        '*': '_CK', '+': '_CL', ',': '_CM', '-': '_CN', '.': '_CO',
        '/': '_CP', ':': '_DK', ';': '_DL', '<': '_DM', '=': '_DN',
        '>': '_DO', '?': '_DP', '@': '_EA', '[': '_FL', '\\': '_FM',
        ']': '_FN', '^': '_FO', '_': '_FP', '`': '_GA', '{': '_HL',
        '|': '_HM', '}': '_HN', '~': '_HO' }
# STable used for unmangling
STable = { '_CA' : ' ', '_CB' : '!', '_CC' : '"', '_CD' : '#', '_CE' : '$',
        '_CF' : '%', '_CG' : '&', '_CH' : "'", '_CI' : '(', '_CJ' : ')',
        '_CK' : '*', '_CL' : '+', '_CM' : ',', '_CN' : '-', '_CO' : '.',
        '_CP' : '/', '_DK' : ':', '_DL' : ';', '_DM' : '<', '_DN' : '=',
        '_DO' : '>', '_DP' : '?', '_EA' : '@', '_FL' : '[', '_FM' : '\\',
        '_FN' : ']', '_FO' : '^', '_FP' : '_', '_GA' : '`', '_HL' : '{',
        '_HM' : '|', '_HN' : '}', '_HO' : '~' }

def _mangledName(name):
    """Convert name to GFE mangled name.

    From GFE baseline code."""
    
    fname = ''
    for c in name:
        if CTable.has_key(c):
           fname = fname + CTable[c]
        else:
           fname = fname + c
    return fname

def _normalName(mangledName):
    """Convert GFE mangled name to a import name.

    From GFE baseline code."""
    
    name = ''
    specialMode = ''
    for c in mangledName:
        if c == '_':
            specialMode = '_'
        elif len(specialMode) > 0 and len(specialMode) <= 3:
            specialMode = specialMode + c
            if len(specialMode) == 3:
                if STable.has_key(specialMode):
                    name = name + STable[specialMode]
                    specialMode = ''
        else:
           name = name + c
    return name

def _testName(name,testchars):
    """Test if name has some flagged characters. Return 1 if so."""
    for c in testchars:
        if c in name:
            return 1
    return 0

def unmangler(f,ext, warnChars='&<>|:'):
    """Unmangle an AWIPS 1 GFE fileaname and warn about shell meta characters
       in the filename.
    """
    name = _normalName('.'.join(f.split('.')[0:-1]))
    if _testName(name,warnChars):
        print 'WARNING: "' + name + '.' + f.split('.')[-1] + \
              '" contains one or more of: "' + warnChars +'" that might cause file access problems'
    if '/' in name:
        print 'WARNING: "' + name + '.' + f.split('.')[-1] +'"' + \
              '" contains the "/" character.  It has been changed to "_"'
        name = name.replace('/','_')
    return name + ext
