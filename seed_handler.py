import argparse,sys,os,glob,copy,pwd,warnings

import obspy.core
from obspy import read, UTCDateTime, Stream
from obspy import Trace as tr

class MyParser(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)

def parseArguments():
        parser=MyParser()	
        parser.add_argument('--oud', default='.',help='Output Directory')
        parser.add_argument('--fmtout', default='SAC',help='Output Format: SAC,MSEED')
        parser.add_argument('--filein', help='Input file name')
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
    with warnings.catch_warnings(record=True) as w:
        warnings.simplefilter('always')
        try:
            s = read(f,format="MSEED")
        except Exception as e:
            if len(w):
               for wm in w:
                   try:
                       l.write(str(wm.message)+"\n")
                   except:
                       pass
            try:
                l.write(str(e)+"\n")
                l.close()
                sys.exit(1)
            except:
                pass
    return s

def write_file(f,s,n,l,ns,n_o,s_o,l_o,c_o,sm_o):
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

for tr in st:
    counter+=1
    last=True if counter == len(st) else False
    network = tr.stats.network
    station = tr.stats.station
    if len(tr.stats.location)==0:
      	location=''
    else:
        location=tr.stats.location

    channel = tr.stats.channel
    sampling = tr.stats.sampling_rate

    #print("TEST: ",network,station,location,channel,sampling)
    
    if len(st) == 1: # If the input file is a single segment single channel fseed or mseed it directly writes out
       stnew = stnew + tr
       A = oud + os.sep + fileout if fileout else oud + os.sep + network + '.' + station + '.' + location + '.' + channel + '.' + ext
       write_file(args.fmtout,stnew,A,logfn,segments,network,station,location,channel,sampling)
       logfn.close()
       sys.exit(0)
    else: # If the input file is a multiple segment and/or multiple channel fseed or mseed it goes on iterating to compose the single channel stream
       if start: # First step on, setup, to check if channel level has changed at next step; this works only the first time
          start=False
          net_old=network
          sta_old=station
          loc_old=location
          cha_old=channel
          sam_old=sampling
          stnew = stnew + tr
          continue
       else:
          change=True if (network != net_old or station != sta_old or location != loc_old or channel != cha_old) else False
          A = oud + os.sep + fileout if fileout else oud + os.sep + net_old + '.' + sta_old + '.' + loc_old + '.' + cha_old + '.' + ext
          if not change or (change and start):
             stnew = stnew + tr
          if (change and not start and not last) or (not change and last):
             segments=len(stnew)
             write_file(args.fmtout,stnew,A,logfn,segments,net_old,sta_old,loc_old,cha_old,sam_old)
          if change:
             stnew=Stream()
          if last:
             stnew = stnew + tr
             segments=len(stnew)
             A = oud + os.sep + fileout if fileout else oud + os.sep + network + '.' + station + '.' + location + '.' + channel + '.' + ext
             write_file(args.fmtout,stnew,A,logfn,segments,network,station,location,channel,sampling)
          start=False
          net_old=network
          sta_old=station
          loc_old=location
          cha_old=channel
          sam_old=sampling
logfn.close()
sys.exit(0)
