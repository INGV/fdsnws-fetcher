import argparse,sys,os,glob,copy,pwd,warnings

import obspy.core
from obspy import read, UTCDateTime, Stream
from obspy import Trace as tr
from pyrocko import (pile, io, util)
from pyrocko import obspy_compat
obspy_compat.plant()

class MyParser(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)

def parseArguments():
        parser=MyParser()	
        parser.add_argument('--oud',    default='.',help='Output Directory')
        parser.add_argument('--fmtout', default='SAC',help='Output Format: SAC,MSEED')
        parser.add_argument('--filein', help='Input file name')
        parser.add_argument('--verbose',help='If given, prints too much',action='store_true')
        if len(sys.argv)==1:
            parser.print_help()
            sys.exit(2)
        args=parser.parse_args()
        return args

def fillwave(st):
       fwe=0
       try:
           st.merge(method=0, fill_value='interpolate', interpolation_samples=0)
       except Exception as e:
           wout="Merge & Fill: Fallito\n" + str(e) + "\n"
           logfn.write(wout)
           fwe=1
           logfn.close()
           sys.exit(fwe)
       return (st),fwe

def read_file(f,l):
    s=False
    with warnings.catch_warnings(record=True) as w:
        warnings.simplefilter('always')
        try:
            s = read(f,format="MSEED")
        except Exception as e:
            try:
                l.write(str(e)+": obspy error messages\n===> NOW Trying toswitch to pyrocko decoding\n")
            except:
                print("Error writing Log file during obspy alternative")
            try:
                s = pile.make_pile([f]).to_obspy_stream()
            except Exception as p:
                if len(w):
                    for wm in w:
                        try:
                            l.write(str(wm.message)+": general read warning messages\n")
                        except:
                            pass
                try:
                    l.write(str(p)+": pyrocko error messages\n")
                except:
                    print("Error writing Log file during pyrocko alternative")
                l.close()
                sys.exit(1)
    return s

def write_file(f,s,n,l,ns,n_o,s_o,l_o,c_o,sm_o):
    ns = 1 if not ns else ns
    try:
        if f == 'SAC':
           s,err = fillwave(s)
        else:
           err = 0

        if err == 0:
           try:
               s.write(n, format=f)
               wout='File '+n+' written from '+str(ns)+' segments' + '\n'
               l.write(wout)
           except:
               wout="Error writing: "+n_o+s_o+l_o+c_o+str(sm_o)+'\n'
               l.write(wout)
        else:
           wout="Error filling: "+n_o+s_o+l_o+c_o+str(sm_o)+'\n'
           l.write(wout)
    except:
        wout="Error merging: "+n_o+s_o+l_o+c_o+str(sm_o)+'\n'
        l.write(wout)

############################################
args = parseArguments()
verb = True if args.verbose else False
if args.filein:
   filein=args.filein
else:
   print("\n--filein is mandatory\n")
   sys.exit()

if args.fmtout:
   ext=args.fmtout.lower()
else:
   ext=''

oud=args.oud

try:
    logfn=open('seed_handler.Log','w')
except:
    print("\nError opening log file\n")

fileout=False

try:
   fileout=args.fileout
except:
   pass

# Loading input file mseed into stream() st
st = read_file(filein,logfn)
if not st:
   print("Problem reading filein ",filein)
   sys.exit(1)

# Single stream cumulating the per channel segments
stnew=Stream()

# Initial setup
start=True
net_old=""
sta_old=""
loc_old=""
cha_old=""
sam_old=""
counter=0
written=False
for tr in st:
    segments=False
    counter+=1
    last=True if counter == len(st) else False
    try:
       network = tr.stats.network
    except:
       network = ''
    try:
       station = tr.stats.station
    except:
       station = ''
    try:
       location = tr.stats.location
    except:
      location=''
    try:
       channel = tr.stats.channel
    except:
       channel = ''
    try:
       sampling = tr.stats.sampling_rate
    except:
       wout = 'Unrecoverable error: tr.stats.sampling_rate is empty\n'
       logfn.write(wout)
       sys.exit(2)

    if verb:
                print("TEST: ",network,station,location,channel,sampling)
    
    if len(st) == 1: # If the input file is a single segment single channel fseed or mseed it directly writes out
       if verb:
                print("Case: Len == 1","Written=",written)
       stnew = stnew + tr
       A = oud + os.sep + fileout if fileout else oud + os.sep + network + '.' + station + '.' + location + '.' + channel + '.' + ext
       write_file(args.fmtout,stnew,A,logfn,segments,network,station,location,channel,sampling)
       logfn.close()
       sys.exit(0)
    else: # If the input file is a multiple segment and/or multiple channel fseed or mseed it goes on iterating to compose the single channel stream
       if start: # First step on, setup, to check if channel level has changed at next step; this works only the first time
          if verb:
                print("Case: Start == True","Written=",written)
          start=False
          net_old=network
          sta_old=station
          loc_old=location
          cha_old=channel
          sam_old=sampling
          stnew = stnew + tr
          written=False
          continue
       else:
          if verb:
                print("Case: Start == False")
          change=True if (network != net_old or station != sta_old or location != loc_old or channel != cha_old) else False
          if verb:
                print("Change == ",change)
          A = oud + os.sep + fileout if fileout else oud + os.sep + net_old + '.' + sta_old + '.' + loc_old + '.' + cha_old + '.' + ext
          if not change or (change and start):
             if verb:
                print("Case: not change or (change and start)","Written=",written)
             stnew = stnew + tr
             written=False
          if (change and not start and not last) or (not change and last):
             if verb:
                print("Case: (change and not start and not last) or (not change and last)","Written=",written,"Writing ",stnew)
             segments=len(stnew)
             write_file(args.fmtout,stnew,A,logfn,segments,net_old,sta_old,loc_old,cha_old,sam_old)
             written=True
          if change:
             if verb:
                print("Case: only change true",stnew,"Written=",written,"Last=",last,"Start=",start)
             if written and not last:
                if verb:
                   print("Case: only change true, written true  and last false")
                stnew=Stream()
                stnew = stnew + tr
                if verb:
                   print("Updating stnew",stnew)
                written=False
             if not written and last:
                if verb:
                   print("Case: only change true, written true  and last true (penultima forma d'onda pero'")
                segments=len(stnew)
                write_file(args.fmtout,stnew,A,logfn,segments,net_old,sta_old,loc_old,cha_old,sam_old)
                written=True
                stnew=Stream()
          if last:
             if verb:
                print("Case: only last true","Written=",written)
             stnew = stnew + tr
             segments=len(stnew)
             A = oud + os.sep + fileout if fileout else oud + os.sep + network + '.' + station + '.' + location + '.' + channel + '.' + ext
             write_file(args.fmtout,stnew,A,logfn,segments,network,station,location,channel,sampling)
             written=True
          start=False
          net_old=network
          sta_old=station
          loc_old=location
          cha_old=channel
          sam_old=sampling
logfn.close()
sys.exit(0)
