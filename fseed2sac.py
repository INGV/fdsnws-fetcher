import argparse,sys,os,glob,copy,pwd,warnings
import getpass

import obspy.core
from obspy import read, UTCDateTime, Stream
from obspy import Trace as tr

# Version 2.1

def get_username():
    return pwd.getpwuid( os.getuid() )[ 0 ]

class MyParser(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)
def parseArguments():
        parser=MyParser()	
        parser.add_argument('--oud', default='.',help='Output Directory for Sac Files')
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


############################################
user=get_username()
args = parseArguments()
filein=args.filein
ext=args.fmtout.lower()
oud=args.oud
logfn=open('fseed2sac.Log','w')

fileout=False
try:
   fileout=args.fileout
except:
   pass

USER = getpass.getuser()
with warnings.catch_warnings(record=True) as w:
    warnings.simplefilter('always')
    try:
        st = read(filein,format="MSEED")
    except Exception as e:
        if len(w):
           for wm in w:
               logfn.write(str(wm.message)+"\n")
        logfn.write(str(e)+"\n")
        logfn.close()
        sys.exit(1)
start=0
stnew=Stream()

net_old=""
sta_old=""
loc_old=""
cha_old=""
sam_old=""
counter=0
for tr in st:
    counter+=1
    network = tr.stats.network
    station = tr.stats.station
    if len(tr.stats.location)==0:
      	location='--'
    else:
        location=tr.stats.location
    channel = tr.stats.channel
   
    samplin = tr.stats.sampling_rate
    
    if len(st) == 1:
       stnew = stnew + tr
       stnew,fwerr = fillwave(stnew)
       if fileout:
          A = oud + os.sep + fileout
       else:
          A  = oud + os.sep + station + '.' + channel + '.' + network + '.' + location
       try:
           stnew.write(A, format=args.fmtout)
       except:
           wout="Error writing: "+network+station+location+channel+'\n'
           logfn.write(wout)
       logfn.close()
       sys.exit(0)
    else:
       if start == 0:
          pass
   
       if ((network != net_old or station != sta_old or location != loc_old or channel != cha_old) and start != 0) or (counter == len(st) and start != 0):
          A  = oud + os.sep + sta_old + '.' + cha_old + '.' + net_old + '.' + loc_old
          try:
              stnew,fwerr = fillwave(stnew)
              if fwerr == 0:
                 try:
                     stnew.write(A, format=args.fmtout)
                 except:
                     wout="Error writing: "+net_old+sta_old+loc_old+cha_old+str(sam_old)+'\n'
                     logfn.write(wout)
          except:
              wout="Error merging: "+net_old+sta_old+loc_old+cha_old+str(sam_old)+'\n'
              logfn.write(wout)
          stnew=Stream()
          stnew = stnew + tr
       else:
          stnew = stnew + tr
          wout=str(tr)+'\n'
          logfn.write(wout)
       start=1
   
       net_old=network
       sta_old=station
       loc_old=location
       cha_old=channel
       sam_old=samplin
    
logfn.close()
sys.exit(0)
