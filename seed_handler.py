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

with warnings.catch_warnings(record=True) as w:
    warnings.simplefilter('always')
    try:
        st = read(filein,format="MSEED")
    except Exception as e:
        if len(w):
           for wm in w:
               try:
                   logfn.write(str(wm.message)+"\n")
               except:
                   pass
        try:
            logfn.write(str(e)+"\n")
            logfn.close()
            sys.exit(1)
        except:
            pass

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
      	location=''
    else:
        location=tr.stats.location

    channel = tr.stats.channel
    sampling = tr.stats.sampling_rate
    
    if len(st) == 1:
       stnew = stnew + tr
       if args.fmtout == 'SAC':
          stnew,fwerr = fillwave(stnew)
       else:
          fwerr=0

       if fileout:
          A = oud + os.sep + fileout
       else:
          A  = oud + os.sep + network + '.' + station + '.' + location + '.' + channel + '.' + ext
       if fwerr == 0:
          try:
              stnew.write(A, format=args.fmtout)
          except:
              wout="Error writing: "+network+station+location+channel+'\n'
              logfn.write(wout)
          logfn.close()
          sys.exit(0)
    else:
       if start == 0:
          start=1
          net_old=network
          sta_old=station
          loc_old=location
          cha_old=channel
          sam_old=sampling
          stnew = stnew + tr
          continue
       else:
          if ((network != net_old or station != sta_old or location != loc_old or channel != cha_old) and start != 0) or (counter == len(st) and start != 0):
             if counter == len(st):
                stnew = stnew + tr
                #wout=str(tr)+'\n'
                #logfn.write(wout)
             if fileout:
                A = oud + os.sep + fileout
             else:
                A  = oud + os.sep + net_old + '.' + sta_old + '.' + loc_old + '.' + cha_old + '.' + ext
             segments=len(stnew)
             try:
                 if args.fmtout == 'SAC':
                    stnew,fwerr = fillwave(stnew)
                 else:
                    fwerr = 0

                 if fwerr == 0:
                    try:
                        stnew.write(A, format=args.fmtout)
                        wout='File '+A+' written from '+str(segments)+' segments' + '\n'
                        logfn.write(wout)
                    except:
                        wout="Error writing: "+net_old+sta_old+loc_old+cha_old+str(sam_old)+'\n'
                        logfn.write(wout)
                 else:
                    wout="Error filling: "+net_old+sta_old+loc_old+cha_old+str(sam_old)+'\n'
                    logfn.write(wout)
             except:
                 wout="Error merging: "+net_old+sta_old+loc_old+cha_old+str(sam_old)+'\n'
                 logfn.write(wout)
             stnew=Stream()
          if counter != len(st):
             stnew = stnew + tr
             #wout=str(tr)+'\n'
             #logfn.write(wout)
             start=1
             net_old=network
             sta_old=station
             loc_old=location
             cha_old=channel
             sam_old=sampling
logfn.close()
sys.exit(0)
