#!/awips2/python/bin/python

# SVN: $Revision: 2169 $  $Date: 2011-10-18 13:13:07 -0400 (Tue, 18 Oct 2011) $
#
# TextAlarmConverter - Converts AWIPS 1 text alarm files to AWIPS2 XML
#
# Matt Foster, ITO, WFO Norman, OK
#

import sys, re
from datetime import datetime
import xml.etree.ElementTree as ElementTree

class AlarmAlert:
    def __init__(self, pil, aa, searchStr):
        self.pil = pil
        self.aa = aa
        self.searchStr = searchStr

    def getPIL(self):
        return self.pil

    def getAA(self):
        return self.aa

    def getSearch(self):
        return self.searchStr

class ProximityAlarm:
    def __init__(self, pil, aa, action, area):
        self.pil = pil
        self.aa = aa
        self.action = action
        self.area = area

    def getPIL(self):
        return self.pil

    def getAA(self):
        return self.aa

    def getAction(self):
        return self.action

    def getArea(self):
        return self.area

class TextAlarmConverter:
    def __init__(self, alarmFile):

        a1aas, a1pas = self.readA1File(alarmFile)
        a2Alarms = self.makeA2DOM(a1aas, a1pas)
        self.writeA2File(a2Alarms, alarmFile)

    def readA1File(self, afile):

        # aas is a list of AlarmAlert objects
        # pas is a list of ProximityAlarm objects
        aas = []
        pas = []

        try:
            fh = open(afile, 'r')
        except:
            print "Unable to open input file: " + afile
            sys.exit(1)

        for line in fh:
            if line.startswith("divide line") or line.startswith("#"):
                continue
            tokens = line.split()
            if len(tokens) >= 2:
                if tokens[1] == "0" or tokens[1] == "1":
                    # This is a "regular" alarm
                    pil = tokens[0]
                    aa = tokens[1]
                    search = ""
                    if len(tokens) > 2:
                        search = line.split(None, 2)[2]
                        # Strip out any leading/trailing enclosing characters
                        search = search.strip()
                        search = search.strip('\'"{}[]()')
                    alarm = AlarmAlert(pil, aa, search)
                    aas.append(alarm)
                elif re.search("alarm|alert|none", tokens[1], re.IGNORECASE) and len(tokens) == 4:
                    # This is a proximity alarm
                    pil = tokens[0]
                    aa = tokens[1]
                    action = tokens[2]
                    area = tokens[3]
                    alarm = ProximityAlarm(pil, aa, action, area)
                    pas.append(alarm)
                else:
                    print "Unrecognized alarm entry: "+line
                    continue
            else:
                continue

        return aas, pas

    def makeA2DOM(self, a1aas, a1pas):

        root = ElementTree.Element("aapaCombined")

        for aa in a1aas:
            pil = aa.getPIL()
            status = aa.getAA()
            search = aa.getSearch()
            aaNode = ElementTree.SubElement(root, "aaList")
            self.addAlarmElements(aaNode, pil, status, search=search)

        for pa in a1pas:
            pil = pa.getPIL()
            status = pa.getAA()
            action = pa.getAction()
            area = pa.getArea()
            paNode = ElementTree.SubElement(root, "paList")
            self.addAlarmElements(paNode, pil, status, action=action, area=area)

        return root

    def addAlarmElements(self, node, pil, status, search=None, action=None, area=None):
        # Add the alarm elements
        actCmd = ElementTree.SubElement(node, "actionCmd")
        if action is not None:
            actCmd.text = action
        alarm = ElementTree.SubElement(node, "alarm")
        if status == "1" or status == "Alarm":
            alarm.text = "true"
        else:
            alarm.text = "false"
        alarmType = ElementTree.SubElement(node, "alarmType")
        if area is None:
            alarmType.text = "Alarm"
        else:
            if status == "1" or status == "Alarm":
                alarmType.text = "Alarm"
            elif status == "0" or status == "Alert":
                alarmType.text = "Alert"
            else:
                alarmType.text = status
        aor = ElementTree.SubElement(node, "aor")
        isAOR = False
        if area is not None:
            if area.find("AOR") >= 0:
                aor.text = "true"
                isAOR = True
            else:
                aor.text = "false"
        else:
            aor.text = "false"

        aorDist = ElementTree.SubElement(node, "aorDistance")
        aorLabel = ElementTree.SubElement(node, "aorLabel")
        if isAOR:
            if area.find('+') > -1:
                tokens = area.split('+')
                dist = tokens[1]
                m = re.search('([0-9]+)(MI|KM)', dist, re.IGNORECASE)
                aorDist.text = m.group(1)
                aorLabel.text = m.group(2)
        now = datetime.utcnow()
        nowFmt = now.isoformat()
        recv = ElementTree.SubElement(node, "dateReceived")
        recv.text = nowFmt + "Z"
        mode = ElementTree.SubElement(node, "operationalMode")
        mode.text = "true"
        pid = ElementTree.SubElement(node, "productId")
        pid.text = pil
        ptype = ElementTree.SubElement(node, "productType")
        if area is not None:
            ptype.text = "Proximity_Alarm"
        else:
            ptype.text = "Alarm_Alert"
        searchStr = ElementTree.SubElement(node, "searchString")
        searchStr.text = search
        ugc = ElementTree.SubElement(node, "ugcList")
        if not isAOR and area is not None:
            m = re.search('UGC\-(.+)', area, re.IGNORECASE)
            ugc.text = m.group(1)

        return

    def writeA2File(self, a2alarms, a1file):

        self.indent(a2alarms)
        a2file = a1file + ".xml"
        try:
            tree = ElementTree.ElementTree(a2alarms)
            tree.write(a2file, encoding="UTF-8")
        except Exception:
            print "Error writing AWIPS 2 XML file"
            sys.exit(1)

        return

    def indent(self, elem, level=0):
        # ElementTree doesn't include pretty-printing
        i = "\n" + level*"  "
        if len(elem):
            if not elem.text or not elem.text.strip():
                elem.text = i + "  "
            for e in elem:
                self.indent(e, level+1)
                if not e.tail or not e.tail.strip():
                    e.tail = i + "  "
            if not e.tail or not e.tail.strip():
                e.tail = i
        else:
            if level and (not elem.tail or not elem.tail.strip()):
                elem.tail = i
            

def checkArgs(args):
    #print "ARGS = " + args[1]
    if len(args) != 2:
        usage()
        sys.exit(1)

    af = args[1]
    
    return af

def usage():
    print "Usage: TextAlarmConverter.py <input file>"
    return

if __name__ == '__main__':
    af = checkArgs(sys.argv)
    TextAlarmConverter(af)
