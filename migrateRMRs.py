#!/bin/env python
# migrateRMRs.py - convert A1 radarMultipleRequests to A2 rmrAvailableRequests.xml
# Version 1, 2011-11-16 David Friedman

import os
import sys
try:
    import cStringIO as StringIO
except:
    import StringIO
try:
    import xml.etree.ElementTree as ET
except:
    import elementtree.ElementTree as ET

LOWER_ELEVATIONS = 1 << 13
ALL_ELEVATIONS = 1 << 14
N_ELEVATIONS = (1 << 14) | (1 << 13)

ELEVATION = 0x001
ALTITUDE = 0x002
BASELINE = 0x004
WINDOW_AZ_RAN = 0x008
STORM_SPEED_DIR = 0x010
MINI_VOLUME = 0x020
TIME_SPAN = 0x040
TIME_SPAN_MINUTES = 0x080
LAYER = 0x100
CFC_BITMAP = 0x200

productInfo = {
    180: ELEVATION, # Z
    181: ELEVATION, # Z
    186: ELEVATION, # Z
    187: ELEVATION, # Z
    94: ELEVATION, # Z
    153: ELEVATION, # HZ
    16: ELEVATION, # Z
    17: ELEVATION, # Z
    18: ELEVATION, # Z
    19: ELEVATION, # Z
    20: ELEVATION, # Z
    21: ELEVATION, # Z
    99: ELEVATION, # V
    154: ELEVATION, # HV
    182: ELEVATION, # V
    183: ELEVATION, # V
    22: ELEVATION, # V
    23: ELEVATION, # V
    24: ELEVATION, # V
    25: ELEVATION, # V
    26: ELEVATION, # V
    27: ELEVATION, # V
    185: ELEVATION, # SW
    28: ELEVATION, # SW
    29: ELEVATION, # SW
    30: ELEVATION, # SW
    155: ELEVATION, # HSW
    31: TIME_SPAN, # USP
    34: CFC_BITMAP, # CFC
    35: MINI_VOLUME, # CZ
    36: MINI_VOLUME, # CZ
    37: MINI_VOLUME, # CZ
    38: MINI_VOLUME, # CZ
    41: MINI_VOLUME, # ET
    43: ELEVATION|WINDOW_AZ_RAN, # SWR
    44: ELEVATION|WINDOW_AZ_RAN, # SWV
    45: ELEVATION|WINDOW_AZ_RAN, # SWW
    46: ELEVATION|WINDOW_AZ_RAN, # SWS
    50: BASELINE, # RCS
    51: BASELINE, # VCS
    55: ELEVATION|WINDOW_AZ_RAN|STORM_SPEED_DIR, # SRR
    56: ELEVATION|STORM_SPEED_DIR, # SRM
    57: MINI_VOLUME, # VIL
    58: MINI_VOLUME, # STI
    59: MINI_VOLUME, # HI
    61: MINI_VOLUME, # TVS
    84: ALTITUDE, # VAD
    85: BASELINE, # RCS
    86: BASELINE, # VCS
    93: ELEVATION, # DBV
    132: ELEVATION, # CLR
    133: ELEVATION, # CLD
    137: LAYER, # ULR
    139: ELEVATION, # MRU
    141: MINI_VOLUME, # MD
    143: ELEVATION, # TRU
    149: ELEVATION, # DMD
    150: TIME_SPAN, # USW
    151: TIME_SPAN, # USD
    159: ELEVATION, # ZDR
    158: ELEVATION, # ZDR
    161: ELEVATION, # CC
    160: ELEVATION, # CC
    163: ELEVATION, # KDP
    162: ELEVATION, # KDP
    165: ELEVATION, # HC
    164: ELEVATION, # HC
    173: TIME_SPAN_MINUTES, # DUA
    166: ELEVATION, # ML
}

errorCount = 0

def parseA1params(text):
    global errorCount
    
    out = {}

    # cheap: skip the -name parameter because we do not use it
    pos = text.rfind('-mnemonic')
    if pos == -1:
        pos = 0
        
        print >> sys.stderr, "error: cannot reliably parse following parameters"
        print >> sys.stderr, "  " + text.rstrip() + "\n"
        errorCount += 1
        
    words = text[pos:].split()
    i = 0
    while i < len(words):
        if words[i][0:1] == '-':
            out[words[i][1:]] = words[i+1]
            i += 2
        else:
            i += 1
    return out

def encodeAngleToTenths(decimal_angle):
    tenths = int(round(decimal_angle * 10.0))
    if tenths < 0:
        tenths = 3600 + tenths
    return tenths
        
def convertA1Elevation(a1_elev_text, a1_multiCuts):
    global errorCount
    
    pdw = 0

    a1_elev = float(a1_elev_text)
    
    if a1_elev <= 1000:
        pdw = encodeAngleToTenths(a1_elev)
        if a1_multiCuts:
            pdw |= ALL_ELEVATIONS
    elif a1_elev < 1111:
        pdw = (int(round(a1_elev)) - 1000) | N_ELEVATIONS
    elif a1_elev == 1111:
        pdw = ALL_ELEVATIONS
    elif 1992 <= a1_elev and a1_elev < 2090:
        pdw = encodeAngleToTenths(a1_elev - 2000) | LOWER_ELEVATIONS
    else:
        print >> sys.stderr, ("error: invalid input elevation '%s'" % a1_elev_text)
        errorCount += 1

    return pdw

def toTenths(text):
    return int(round(float(text) * 10))

def toTenthsN1(text):
    if text == '-1':
        return -1
    else:
        return toTenths(text)

def subtext(parent, elementName, text):
    t = ET.SubElement(parent, elementName)
    t.text = str(text)

# ==================================================
# Copied from http://effbot.org/zone/element-lib.htm
def indent(elem, level=0):
    i = "\n" + level*"  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i
# ==================================================

def processA1RMRs(f):
    global errorCount
    
    root = ET.Element('requests')
    
    n_rmrs = int(f.readline())
    while n_rmrs > 0:
        n_rmrs -= 1

        name = f.readline().rstrip()
        interval = int(f.readline())
        duration = int(f.readline())

        mr = ET.SubElement(root, 'multipleRequest')
        subtext(mr, 'duration', duration)
        subtext(mr, 'interval', interval)
        subtext(mr, 'name', name)
        
        n_reqs = int(f.readline())
        while n_reqs > 0:
            n_reqs -= 1
            
            a1_params = parseA1params(f.readline())
            dial = f.readline().split()
            dedi = f.readline().split()
            radar_set = { }
            for x in dedi + dial: 
                radar_set[x] = True
            radar_list_text = ' '.join([x.lower() for x in radar_set.keys()])

            try:
                productCode = int(a1_params['code'])
                if productCode >= 600:
                    print >> sys.stderr, ("error: a request in '%s' has invalid product code %d" % (name, productCode))
                    errorCount += 1
                    continue

                params = productInfo.get(productCode, 0)
                pdw = [0] * 6

                if params & ELEVATION:
                    pdw[2] = convertA1Elevation(a1_params['elev'],
                                                a1_params.get('multCuts','N')=='Y')
                if params & ALTITUDE:
                    pdw[2] = int(a1_params['altitude'])
                if params & BASELINE: # Not actually allowd in RMRs...
                    pdw[0] = toTenths(a1_params['endpt1azimuth'])
                    pdw[1] = toTenths(a1_params['endpt1range'])
                    pdw[2] = toTenths(a1_params['endpt2azimuth'])
                    pdw[3] = toTenths(a1_params['endpt2range'])
                if params & WINDOW_AZ_RAN:
                    pdw[0] = toTenths(a1_params['azimuth'])
                    pdw[1] = toTenths(a1_params['range'])
                if params & STORM_SPEED_DIR:
                    spd = toTenthsN1(a1_params['speed'])
                    if spd != -1:
                        pdw[3] = spd
                        pdw[4] = toTenths(a1_params['dir'])
                    else:
                        pdw[3] = spd
                        pdw[4] = 0
                if params & (TIME_SPAN|TIME_SPAN_MINUTES):
                    pdw[0] = int(a1_params['endhour'])
                    pdw[1] = int(a1_params['timespan'])
                if params & LAYER:
                    pdw[0] = int(a1_params['lowerLayer'])
                    pdw[1] = int(a1_params['upperLayer'])
                if params & CFC_BITMAP:
                    pdw[0] = 1 << (int(a1_params['segment'])) # seg1 == 0x2, seg2 == 0x4, ...
            except KeyError, exc:
                print >> sys.stderr, ("error: a request in '%s' is missing parameter %s" % (name, str(exc)))
                errorCount += 1
                continue

            e = ET.SubElement(mr, 'elements')
            subtext(e, 'radarIDs', radar_list_text)

            r = ET.SubElement(e, 'request')
            subtext(r, 'productCode', productCode)
            subtext(r, 'count', 1)
            subtext(r, 'interval', 1)
            subtext(r, 'volumeScanSelection', -1)
            for i in range(0, 6):
                subtext(r, 'pdw2%d' % i, pdw[i])

    indent(root)
    
    sio = StringIO.StringIO()
    sio.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ET.ElementTree(root).write(sio)
    return sio.getvalue()

usage="""
usage: migrateRMRs.py <path to A1 radarMultipleRequests>

Writes A2-style rmrAvailableRequests.xml to standard output.

Exit Codes:
    0 Success
    1 Failure
    2 Success, but some errors in input RMR list detected
"""

def run():
    if len(sys.argv) != 2:
        print >> sys.stderr, usage
        return 1
    sys.stdout.write(processA1RMRs(open(sys.argv[1])))
    return errorCount > 0 and 2 or 0
                       
if __name__ == '__main__':
    sys.exit(run())
