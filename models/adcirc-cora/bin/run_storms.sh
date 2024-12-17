#!/bin/bash
#
#  sh run_storms.sh --maxrun 22 --configfile florence_ex2.yml

set -e       # exit immediately on error
set -x       # verbose with command expansion
set -u       # forces exit on undefined variables

Usage () {
    echo "sh run_storms.sh --maxrun N --configfile config.yml"
}

if [ $# = 0 ] ; then
    Usage
    exit 0
fi

## Environment
#MyHOME=/save/ec2-user/cora-runs/ADCIRC
MyHOME=`pwd`
User=`env |grep "\<USER\>" | awk -F= '{print $2}'`

# bring in functions
. ${MyHOME}/bin/functions.sh

#check shell version
if [ ${BASH_VERSION:0:1} -lt 4 ] ; then 
    red "Must run in Bash version >=4.\n"
    exit 1
fi

# process command line args
GETOPT='getopt'
if [[ `uname` == "Darwin" ]]; then 
    GETOPT='/usr/local/opt/gnu-getopt/bin/getopt'
fi
OPTS=`$GETOPT -o m,c,v --long verbose,packageonly,maxrun:,configfile: -n 'parse-options' -- "$@"`
if [ $? != 0 ]
then
    echo "Failed to parse commandline."
    Usage
    exit 1
fi
eval set -- "$OPTS"

# set commandline option defaults
VERBOSE=false
SKIPDOWNLOAD=false
DEBUG=false
MaxRunning=1
configfile="configs/config.yml"
PackageOnly=false

while true ; do
    case "$1" in
        -v) VERBOSE=true; shift;;
        -s) SKIPDOWNLOAD=true; shift;;
        -d) DEBUG=true; shift;;
        --packageonly) PackageOnly=true; shift;;
        --verbose) VERBOSE=true; shift;;
        --configfile) configfile=$2; shift 2;;
        --maxrun) MaxRunning=$2; shift 2;;
    --) shift; break;;
esac
done

# bring in config variables
Main_ExtraTag=""  # default
eval $(parse_yaml $configfile "")

# override any config params with commandline options
# only a few config params can be overridden
#if $PackageOnly ; then
#echo PackageOnly is true
#else
#echo PackageOnly is false
#fi

# exec the module script
#. ${MyHOME}/bin/mods.sh

#NetCDF metadata, needed if OutputFormat=="netCDF"
netCDF_comments="$Main_ProjectName.$Main_Experiment"
netCDF_host="`uname -n`"

## Directory and File locations
CommDir="$Main_ProjectHome/common"           ## master/template model files (fort.15, fort.26, ...)
BinDir="$Main_ProjectHome/bin"
AdcBinDir="$Main_ADCIRCHome"
GridDir="$Main_ProjectHome/Grids"
TrackDir="$Main_ProjectHome/TracksToRun"
WindDir="$Main_ProjectHome/../Forcing/Winds/ERA5/<Track_Name>"
RiverDir="$Main_ProjectHome/Rivers/runs/<Track_Name>"
HotStartDir="$Main_ProjectHome/HotStarts/$Main_Experiment"
MainArch="$Main_ProjectHome"
WorkDir=$MainArch

# ADCIRC/SWAN grid definition (files must be in $GridDir)
GridName=$Grid_Name
GridExtension=$Grid_Extension
GridNameAbbrev=$Grid_NameAbbrev

DWLCDir="$Main_ProjectHome/../Forcing/DynWatLevCor/ERA5/$GridNameAbbrev/<Year>"
ExperimentDir="ERA5/$GridNameAbbrev"

# Runtime template files
Fort15FileMaster="$CommDir/fort.15.$GridName.template"
Fort26FileMaster="$CommDir/fort.26.master"
SwanInitFileMaster="$CommDir/swaninit.master"
RunDesc="$Main_ProjectName:$GridName:$Main_Experiment Sims"

## Machine/scheduler variables
## define job manager; these vars are sed'd into a template file
## called submit.$Machine.$Job_Manager.template in $CommDir
Machine=`hostname -s`
HostName=$Machine
#HostCheck="false"
#ProcessorsPerNode[0]=1
#NumberOfNodes[0]=`echo "$NumberOfCores/${ProcessorsPerNode[0]}" | bc`

white "Running on $HostName\n"
## Check hostname
#if [ "$HostCheck" == "true" ] ; then
#        if [[  "$HostName" != "ht3" && "$HostName" != "ht4"  ]] ; then
#            red "This MUST run on the compute host, ht3 or ht4. Terminal.\n"
#            exit 1
#        fi
#fi

## Nodal attributes
#declare -a NodalAttributes
#natts=`set | grep '^Fort15_nodatt' | wc -l `
#white "Number of nodal attributes =  $natts\n"
#for i in `seq $natts` ; do
#        na=`printf "%s_%d" Fort15_nodatt $i`
#        eval nav='$'$na
#        NodalAttributes[$[i-1]]=$nav
#        white "   $i: $nav\n"
#done
#echo ${NodalAttributes[*]}

if [ "$Main_PackageOnly" -eq 1 ] ; then
    if [ "$Main_Submit" -eq 1 ] ; then
        red "You must set Submit to 0 if PackageOnly is 1. Terminal.\n"
        echo 1
    fi
    MaxRunning=-1
    #Step="Prep"
fi

## Definition-dependent switches
if [ "$Fort15_WinPreSrc" == "owi" ] ; then
    WindFac="1.09"
elif [ "$Fort15_WinPreSrc" == "hbl" ] ; then
    WindFac="1.00"
elif [ "$Fort15_WinPreSrc" == "wrf" ] ; then
    WindFac="1.00"
else
    red "Unknown WinPreSrc type ($Fort15_WinPreSrc)\n"
    exit 1
fi

if [ "$Main_OutputFormat" = "netCDF" ] ; then
    OutputFormatNumber="-5"
else
    OutputFormatNumber="-1"
fi

PREPEXE="adcprep$Main_ExtraTag"
if [ "$Fort15_Coupled" -eq "1" ] ; then
    ADCEXE="padcswan$Main_ExtraTag"
    NRS="3"
    NWSNRS=`echo "-$NRS*100+$Fort15_NWS" | bc`
else
    ADCEXE="padcirc$Main_ExtraTag"
    NRS="0"
    NWSNRS=`echo "$Fort15_NWS" | bc`
fi

GridFile="$GridDir/$GridName.$GridExtension"
NodalAttributeFile="$GridDir/$GridName.13"
yellow "\nLooking for common input files ...\n"
#echo "DecompDir=$DecompDir"

if [ ! -e "$AdcBinDir/$ADCEXE" ] ; then
    red "Model File $AdcBinDir/$ADCEXE DNE. Terminal.\n"
    exit 1
fi
white "*** Found $AdcBinDir/$ADCEXE\n"

if [ ! -e "$AdcBinDir/$PREPEXE" ] ; then
    red "Model File $AdcBinDir/$PREPEXE DNE. Terminal.\n"
    exit 1
fi
white "*** Found $AdcBinDir/$PREPEXE\n"

if [ ! -e "$Fort15FileMaster" ] ; then
    red "Master Fort.15  File $Fort15FileMaster DNE. Terminal.\n"
    exit 1
fi
white "*** Found $Fort15FileMaster\n"

if [ ! -e "$GridFile" ] ; then
    red "Grid File $GridFile DNE. Terminal.\n"
    exit 1
fi
white "*** Found $GridFile\n"

if [ ! -e $NodalAttributeFile ] ; then
    red "Grid Nodal Attribute File $NodalAttributeFile  DNE. Terminal.\n"
    exit 1
fi
white "*** Found $NodalAttributeFile\n"

if [ "$Main_AssumeDecomp" -eq "1" ] ; then
    if [ ! -d $DecompDir ] ; then
        red "Decomp dir $DecompDir DNE. Terminal.\n"
        exit 1
    fi
fi

if [ "$Fort15_Coupled" -eq "1" ] ; then
    if [ ! -e "$Fort26FileMaster" ] ; then
        red "Master Fort.26  File $Fort26FileMaster DNE. Terminal.\n"
        exit 1
    fi
    white "*** Found $Fort26FileMaster\n"

    if [ ! -e "$SwanInitFileMaster" ] ; then
        red "Master SwanInit  File $SwanInitFileMaster DNE. Terminal.\n"
        exit 1
    fi
    white "*** Found $SwanInitFileMaster\n"
fi

if [ ! -d $WorkDir ] ; then
    red "$WorkDir does not exist.  Please create.\n"
    exit 1
else
    white  "*** WorkDir=$WorkDir\n"
fi

if [ ! -d "$WorkDir/$ExperimentDir" ] ; then
    red "$WorkDir/$ExperimentDir does not exist.  Please create.\n"
    exit 1
else
    white "*** WorkDir/ExperimentDir=$WorkDir/$ExperimentDir\n"
fi

if [ -z "$MaxRunning" ] ; then
    red "Must specify MaxRunning on commandline.\n"
    exit 1
fi
if [ ! -d $TrackDir ] ; then
    red "$TrackDir does not exist.  Please create.\n"
    exit 1
else
    white  "*** TrackDir=$TrackDir\n"
fi

green "Found them all.  Continuing...\n\n"

# Get list of possible tracks to run
cd $TrackDir
yellow "Checking for tracks in $TrackDir... \n"
if [ "$(ls -A ./)" ]; then
    white "*** $TrackDir has tracks.\n"
    green "Proceeding... \n"
else
    red "\nTrack Dir $TrackDir is Empty\n" 
    exit 0
fi

if [ $Fort15_NWS = "16" ] ; then
    TrackExtension='22'
else
    TrackExtension='trk'
fi

# check to see if directory is empty
#if [ -z "$( ls -A ./ )" ] ; then
#    echo "$TrackDir is empty.  No storms to run.  Exiting."
#    exit 0
#fi

# Then, delete tracks that are already archived, just in case...
#for ThisTrack in `ls -d *` ; do
#    temp=`echo $ThisTrack | awk -F. '{print $1}'`
#    #file="$MainArch/$ExperimentDir/$temp/maxele.63"
#    temp="$ThisTrack$Main_ExtraTag"
#    file="$MainArch/$ExperimentDir/$temp/run.complete"
#    if [ -e $file ] ; then
#        echo "$temp is already done, cleaned up, and archived."
#        # make sure track file is deleted
#        rm -rf $TrackDir/$ThisTrack
#    fi
#done

# check again to see if directory is empty
if [ -z "$( ls -A ./ )" ] ; then
    green "$TrackDir is empty.  No storms to run.  Exiting.\n"
    exit 0
fi

if [ $Fort15_NWS = "16" ] ; then
    Tracks=`ls *.22`
else
    Tracks=`ls *.trk`
fi

cd $MyHOME

yellow "\nChecking for running and available jobs ... \n"
NumberOfRemainingJobs=0
for track in $Tracks ; do
    NumberOfRemainingJobs=$((NumberOfRemainingJobs+1))
done
green "NumberOfRemainingJobs= $NumberOfRemainingJobs\n"

# before doing anything, look for runs to clean up
if [ "$Main_CleanUpDoneRuns" -eq "1" ] ; then
    if [ $WorkDir == $MainArch ] ; then
        red "Work Dir and Archive Dir are the same.  Not Cleaning up!!\n"
    else
        cd "$WorkDir/$ExperimentDir"
        pwd
        if [ "$( ls -A )" ] ; then
            for ThisTrack in `ls -d *` ; do
                echo Checking $ThisTrack
                #if [[ -e $ThisTrack/maxele.63 && -e $ThisTrack/fort.80 ]] ; then
                if [[ -e $ThisTrack/maxele.63 ]] ; then
                    echo $ThisTrack/maxele.63 exists.  Clean this run up...
                    cd $ThisTrack
                    find ./ -name '*grd' -o -name 'fort*13'  | xargs rm -rf
                    find ./ -name fort.14 -o -name timeofmaxele.63 | xargs rm -rf
                    find ./ -name 'padcirc' -o -name 'padcswan*' | xargs rm -rf
                    find ./ -name 'adcprep*' -o -name 'partmesh.txt'| xargs rm -rf
                    find ./ -name 'metis_graph.txt' -o -name 'fort.80' | xargs rm -rf
                    find ./ -name 'fort.221' -o -name 'fort.222' | xargs rm -rf
                    find ./ -name 'fort.221.nc' -o -name 'fort.222.nc' | xargs rm -rf
                    find ./ -name 'PE*' | xargs rm -rf
                    cd ../
                    echo '   Copying ...'
                    cp -r $ThisTrack $MainArch/$ExperimentDir/$RunDir
                    rm -rf $ThisTrack/*
                    echo `date --utc` > $ThisTrack/job.archived
                    # make sure track file is deleted
                    rm -rf $TrackDir/$ThisTrack.$TrackExtension
                elif [ -e $ThisTrack/maxele.63 ] ; then
                    echo $ThisTrack is already done and cleaned up.
                    # make sure track file is deleted
                    rm -rf $TrackDir/$ThisTrack.$TrackExtension
                elif [ -e $ThisTrack/job.archived ] ; then
                    echo $ThisTrack is already archived.
                    rm -rf $TrackDir/$ThisTrack.$TrackExtension
                fi
            done
        else
            echo No runs yet in "$WorkDir/$ExperimentDir"
        fi
    fi
    cd ../
fi

if [ "$Main_CleanUpOnly" -eq  "1" ] ; then
    green "CleanUpOnly specified.  Exiting.\n"
    exit 0
fi

if  [ ! "$( ls -A $TrackDir )" ] ; then
    green "Track directory is empty.  Terminating.\n"
    exit 0
fi

# AWS is unlimited, disabling this for now
# res=`eval $Job_StatusCommand`
# NumberOfRunningJobs=`echo "$res" | grep $User | grep Reanalysis | wc -l `
# CanRun=$(( $MaxRunning - $NumberOfRunningJobs ))
# white "Maximum Number Of Concurrent Jobs Allowed = $MaxRunning\n"
# white "Number Of Jobs Remaining in Track Directory = $NumberOfRemainingJobs\n"
# white "Number Of Running Jobs = $NumberOfRunningJobs\n"

CanRun=1
white "CanRun = $CanRun\n"

if [ $CanRun -lt  1 ] ; then
    red "Max Number of running jobs ($MaxRunning) reached.  Exiting.\n"
    exit 1
fi
green "$CanRun jobs will fit.  Continuing...\n\n"

j=0
k=0
for ThisTrack in $Tracks ; do
    # check to see if track is running

    ThisRunDir="$ThisTrack$Main_ExtraTag"

    if [ ! -e "$Main_Experiment/$ThisRunDir/maxele.63.nc" ]; then
        k=$((k+1))
        ListToRun[$k]=$ThisTrack
    fi

    let jk=$j+$k
    if [ $j -ge $CanRun ] ; then
        green "$j jobs already running. Exiting...\n"
        exit 0
    fi

    if [ $jk -ge $CanRun ]; then
        break
    fi
done
green "List To Run ($k) : ${ListToRun[*]}\n"
echo " "

# make $ExperimentDir if needed
#echo "$WorkDir/$ExperimentDir" 
#if [ ! -d "$WorkDir/$ExperimentDir" ] ; then
#    mkdir "$WorkDir/$ExperimentDir"
#fi

# stage and exec jobs
cd "$WorkDir/$ExperimentDir"
white "\nWorking in `pwd`\n"

for ((k=1; k <= ${#ListToRun[*]} ; k++)) ;  do

    ThisTrackFile=${ListToRun[$k]}
    ThisTrack=`echo $ThisTrackFile | sed 's/\.trk\|\.22//'`
    ThisRunDir="$ThisTrack$Main_ExtraTag"
    ThisYear=$ThisTrack

    white "\nSetting up $ThisRunDir simulation ... \n\n"
    if [ ! -d $ThisRunDir ]; then
        white "*** $ThisRunDir DNE. Making  ...\n"
        mkdir $ThisRunDir
    else
        if [ -e $ThisRunDir/maxele.63.nc ] ; then
            white "****** $ThisRunDir/maxele.63.nc file already exists. Skipping..."
            # delete track file from Tracks dir
            rm -rf $TrackDir/$ThisTrackFile
            continue
        fi
    fi
    cd $ThisRunDir

    cp $TrackDir/$ThisTrackFile .
    green "*** Copied $ThisTrackFile to here.\n"

    # get hotstart file if needed
    white "*** Hot/Coldstart prepping...\n"

    if [ $Fort15_IHOT != "0" ] ; then

        hssrc="$HotStartDir"
        white "****** HotStartDir = $hssrc\n"

        hstartnum=${Fort15_IHOT: -2}
        white "****** HotStartNum = $hstartnum\n"

        if  [ ${#Fort15_IHOT} == 3 ] ; then
            hstartext=".nc"
        else
            hstartext=""
        fi 
        white "****** HotStartExt = $hstartext\n"

        f68filename=`printf "fort.%s%s" $hstartnum $hstartext`
        white "****** HotStartFile = $f68filename\n"

        if [ ! -e "/$HotStartDir/$f68filename" ] ; then
            red "Hotstart file $f68filename DNE. Terminal. "
            exit 1
        fi
        ln -sf "$HotStartDir/$f68filename" .

        # get RndayOffset
        if [ "${hstartext: -2}" = "nc" ] ; then
            RndayOffset=`ncdump -h  $f68filename  | grep -i "rnday =" | awk '{print $3}'`
        else
            RndayOffset=`$AdcBinDir/hstime -f $f68filename`
            RndayOffset=`echo "scale=2;$RndayOffset/86400." | bc`
        fi

        DRAMP=`echo $Fort15_DRAMP  | sed 's/<RndayOffset>/'$RndayOffset'/'`

        white "****** DRAMP = $DRAMP\n"

    else
        white "****** Coldstarting.\n"
        RndayOffset="0."
    fi

    white "*** Wind/Pre prepping...\n"
    if [ $Fort15_NWS = "-12" ] || [ $Fort15_NWS = "14" ] ; then
        
	if [ $Fort15_NWS = "-12" ]; then
            white "****** Using HBL winds (NWS=-12) ...\n"
        fi
        if [ $Fort15_NWS = "14" ]; then
            white "****** Using netCDF winds (NWS=14) ...\n"
        fi

    	src=`echo $WindDir | sed "s/<Track_Name>/$ThisTrack/"`

        white "****** Linking wind/pre files from $src to here ...\n"
        ln -fs $src/fort.* .

        if [ $Fort15_WithBasin == "1" ] ; then
            if [ ! -e $Fort15_BasinPreFile ] ; then
                red "Basin Pre file $Fort15_BasinPreFile DNE. Terminal.\n"
                exit 1
            elif [ ! -e $Fort15_BasinWinFile ] ; then
                red "Basin Win file $Fort15_BasinWinFile DNE. Terminal.\n"
                exit 1
            fi
        fi
        if [ $Fort15_WithRegion == "1" ] ; then
            if [ ! -e $Fort15_RegionPreFile ] ; then
                red "Region Pre file $Fort15_RegionPreFile DNE. Terminal.\n"
                exit 1
            elif [ ! -e $Fort15_RegionWinFile ] ; then
                red "Region Win file $Fort15_RegionWinFile DNE. Terminal.\n"
                exit 1
            fi
        fi

        # write out a fort.22 control file
	if [ $Fort15_NWS = "-12" ]; then
            echo $(($Fort15_WithBasin+$Fort15_WithRegion)) > fort.22
            echo 0 >> fort.22
            echo $WindFac >> fort.22
	fi

	if [ $Fort15_NWS = "14" ]; then
	    echo "&nws14control" > fort.22
            echo "NWS14NC_WindMultiplier=1.09," >> fort.22
	    echo "/" >> fort.22
        fi

        if [ $Fort15_WithBasin == "1" ] ; then
            # check times in win,pre files
            white "****** Checking times in Basin win/pre files... \n"
            temp=`$BinDir/OwiTimes.sh $Fort15_BasinPreFile`
            set -- $temp
            BasinPreStartDate=$2
            BasinPreEndDate=$3
            BasinPreInc=$4
            BasinPreLength=$5

            temp=`$BinDir/OwiTimes.sh $Fort15_BasinWinFile`
            set -- $temp
            BasinWinStartDate=$2
            BasinWinEndDate=$3
            BasinWinInc=$4
            BasinWinLength=$5

            white "****** Basin Pre,Win Time Increments = $BasinPreInc, $BasinWinInc\n"
            white "****** Basin Pre,Win Time Lengths = $BasinPreLength, $BasinWinLength\n"
            white "****** Basin Pre,Win StartDates = $BasinPreStartDate, $BasinWinStartDate\n"

            if [ "$BasinPreInc" != "$BasinWinInc" ] ; then
                red "Time increment in Basin files not equal.\n"
                exit 1
            elif [ "$BasinPreLength" != "$BasinWinLength" ] ; then
                red "Time Length in Basin files not equal.\n"
                exit 1
            elif [ "$BasinPreStartDate" != "$BasinWinStartDate" ] ; then
                red "Start Date in Basin files not equal.\n"
                exit 1
            fi
            white "****** Basin files OK.\n"
        fi

        if [ $Fort15_WithRegion == "1" ] ; then
            # check times in win,pre files
            white "****** Checking times in Region win/pre files...\n"
            temp=`$BinDir/OwiTimes.sh $Fort15_RegionPreFile`
            set -- $temp
            RegionPreStartDate=$2
            RegionPreEndDate=$3
            RegionPreInc=$4
            RegionPreLength=$5

            temp=`$BinDir/OwiTimes.sh $Fort15_RegionWinFile`
            set -- $temp
            RegionWinStartDate=$2
            RegionWinEndDate=$3
            RegionWinInc=$4
            RegionWinLength=$5

            white "****** Region Pre,Win Time Increments = $RegionPreInc, $RegionWinInc\n"
            white "****** Region Pre,Win Time Lengths = $RegionPreLength, $RegionWinLength\n"
            white "****** Region Pre,Win StartDates = $RegionPreStartDate, $RegionWinStartDate\n"

            if [ "$RegionPreInc" != "$RegionWinInc" ] ; then
                red "Time increment in Region files not equal.\n"
                exit 1
            elif [ "$RegionPreLength" != "$RegionWinLength" ] ; then
                red "Time Length in Region files not equal.\n"
                exit 1
            elif [ "$RegionPreStartDate" != "$RegionWinStartDate" ] ; then
                red "Start Date in Region files not equal.\n"
                exit 1
            fi
            green "****** Region files OK.\n"

            if [ "$BasinPreLength" != "$RegionPreLength" ] ; then
                red "Time Length in Pre files not equal. \n"
                exit 1
            elif [ "$BasinWinLength" != "$RegionWinLength" ] ; then
                red "Time Length in Win files not equal. \n"
                exit 1
            fi
            green "****** Time parameters in Basin and Region files are consistent.\n"
        fi

        if [ "x$Fort15_RNDAY" == "x" ]; then
            # compute RNDAY from length of wind/pre files
            RNDAY=$(echo "scale=6; $BasinPreLength + $RndayOffset" | bc)
        else
            RNDAY=$Fort15_RNDAY
        fi
        white "****** RNDAY=$RNDAY\n"

        WTIMINC=$(echo "scale=6; $BasinPreInc * 60" | bc)
        RSTIMINC=$WTIMINC
        WRSTIMINC="$WTIMINC"
        white  "****** WTIMINC=$WTIMINC\n"
        if [ "$Fort15_Coupled" -eq "1" ] ; then
            white  "****** RSTIMINC=$RSTIMINC\n"
            WRSTIMINC="$WTIMINC $RSTIMINC"
        fi
    else
        white "Using symmetric Holland model (NWS=16)\n"

        cp $TrackDir/$ThisTrackFile .
        ln -s $ThisTrackFile fort.22
        RNDAY=`wc -l $ThisTrackFile |awk '{print $1}'`
        RNDAY=$(echo "scale=6; ($RNDAY-1)/24 + $RndayOffset" | bc)
    fi
    green "*** Wind/Pre ready.\n"

    # get river files if needed
    if [ $Fort15_IncludeRivers = "1" ] ; then
        white "*** River BC prepping...\n"
        if [ $Main_ProjectName = "NSF-HSEES" ] ; then
            p1=`echo  $ThisTrack| awk -F_ '{print $1}'`
            p2=`echo  $ThisTrack| awk -F_ '{print $2}'`
            p3=`echo  $ThisTrack| awk -F_ '{print $3}'`
            res=`echo  $ThisTrack| awk -F_ '{print $4}'`
            ens=`echo  $ThisTrack| awk -F_ '{print $5}'`
            temptrkname=`printf "%s_%s_%s\/%s\/%s" $p1 $p2 $p3 $res $ens`
            src=`echo $RiverDir | sed "s/<Track_Name>/$temptrkname/"`
        else
            src=`echo $src | sed "s/Winds/Rivers/"`
        fi
        white  "****** Getting River BC file from $src ...\n"
        if [ ! -e "/$src/fort.20" ] ; then
            echo "River file $src/fort.20 DNE. Terminal. "
            exit 1
        fi
        ln -fs "$src/fort.20" .
        green "*** Rivers ready.\n"
    else
        green  "****** No Rivers in this run (\$Fort15_IncludeRivers == 0)\n"
    fi

    NTIP=0
    if $Fort15_NTIP; then
        NTIP=1
    fi

    NBFR=0
    if $Fort15_NBFR; then
        NBFR=1
    fi

    # compute output spooling
    NSPOOLE=`echo "$Fort15_LocalOutputInterval/$Fort15_DT" | bc`
    NSPOOLGE=`echo "$Fort15_GlobalOutputInterval/$Fort15_DT" | bc`
    # compute TOUTFE, ending output time
    TOUTFE="395.9583333333333"
    ttest=`isleapyear $ThisYear`
    #echo "$ThisYear $ttest $TOUTFE"
    if [ $ttest == "1" ] ; then
        TOUTFE=`echo "$TOUTFE+1" | bc`
    fi
    white "*** TOUTFE=$TOUTFE\n"

    white "*** Prepping grid ...\n"
    ln -sf $NodalAttributeFile fort.13
    ln -sf $GridFile fort.14
    #ln -sf $AdcBinDir/$ADCEXE .
    #ln -sf $AdcBinDir/$PREPEXE .

    #white "****** Check summing grid and nodal attribute files...\n"
    #cksum $NodalAttributeFile  > fort.13.cksum
    #cksum $GridFile  > fort.14.cksum

    temp=$(($ThisYear-1))
    ColdStartDate="1  12 $temp 00"
    # 2017-12-01 00:00:00
    netCDF_basedate=`printf "%d-12-01 00:00:00" $temp`

    ## Modify fort.15 template
    white "*** Modifying fort.15 ...\n"
    echo "s/<RunDesc>/$RunDesc/"   > sed.script
    echo "s/<MODEL>/$ADCEXE/"     >> sed.script
    echo "s/<RNDAY>/$RNDAY/"       >> sed.script
    echo "s/<NTIP>/$Fort15_NTIP/"        >> sed.script
    echo "s/<DT>/$Fort15_DT/"       >> sed.script
    echo "s/<DRAMP>/$Fort15_DRAMP/"       >> sed.script
    echo "s/<IHOT>/$Fort15_IHOT/"         >> sed.script
    echo "s/<NWS>/$NWSNRS/"        >> sed.script
    echo "s/<WTIMINC>/$WRSTIMINC/" >> sed.script
    echo "s/<NSPOOLE>/$NSPOOLE/" >> sed.script
    echo "s/<NSPOOLGE>/$NSPOOLGE/" >> sed.script
    echo "s/<TOUTSE>/$Fort15_TOUTSE/" >> sed.script
    echo "s/<TOUTFE>/$TOUTFE/" >> sed.script
    echo "s/<OUTPUTFORMAT>/$OutputFormatNumber/" >> sed.script

    if [ "$Main_OutputFormat" == "netCDF" ] ; then
        white "****** Setting netCDF metadata in fort.15 file...\n"
        echo "s/<netCDF_title>/$netCDF_title/" >> sed.script
        echo "s/<netCDF_institution>/$netCDF_institution/" >> sed.script
        echo "s/<netCDF_source>/$netCDF_source/" >> sed.script
        echo "s/<netCDF_history>/$netCDF_history/" >> sed.script
        echo "s#<netCDF_references>#$netCDF_references#" >> sed.script
        echo "s/<netCDF_comments>/$netCDF_comments/" >> sed.script
        echo "s#<netCDF_host>#$netCDF_host#" >> sed.script
        echo "s/<netCDF_convention>/$netCDF_convention/" >> sed.script
        echo "s/<netCDF_contact>/$netCDF_contact/" >> sed.script
        echo "s/<netCDF_basedate>/$netCDF_basedate/" >> sed.script
    else
        white "****** Deleting netCDF markers in fort.15 template file...\n"
        echo "/<netCDF_title>/d" >> sed.script
        echo "/<netCDF_institution>/d" >> sed.script
        echo "/<netCDF_source>/d" >> sed.script
        echo "/<netCDF_history>/d" >> sed.script
        echo "/<netCDF_references>/d" >> sed.script
        echo "/<netCDF_comments>/d" >> sed.script
        echo "/<netCDF_host>/d" >> sed.script
        echo "/<netCDF_convention>/d" >> sed.script
        echo "/<netCDF_contact>/d" >> sed.script
        echo "/<netCDF_basedate>/d" >> sed.script
    fi
    sed -f sed.script $Fort15FileMaster > fort.15

    # edit for nodal tides
    if $Fort15_NTIP | $Fort15_NBFR; then
        # compute nodal tide adjustments
        green "*** Computing nodal tide adjustments.\n"
        echo "s/<ColdStartDate>/$ColdStartDate/"     > sed.script
        echo "s/<RNDAY>/$RNDAY/"     >> sed.script
        temp="$CommDir/tide_factor.template"
        sed -f sed.script $temp > temp.1
        $BinDir/tide_factors > /dev/null
        sed -i -e '/<TidalPotentialBlock>/{r fort.15.tpf' -e 'd}' fort.15 
        sed -i -e '/<TidalElevationBlock>/{r fort.15.obc' -e 'd}' fort.15 
    fi

    if [ "$Fort15_StationFile" != "None" ] ; then
        green "*** Inserting station list.\n"
        cp $CommDir/$Fort15_StationFile stalist
        sed -i -e '/<StationFile>/{r stalist' -e 'd}' fort.15 
        rm stalist
    fi

    if [ "$Fort15_DynWatLevCor" != "None" ] ; then
        green "*** Inserting DynWatLevCor file spec.\n"
        temp=`echo $DWLCDir| sed "s/<Year>/$ThisYear/"`
        temp="$temp/$ThisYear.dat"
        ln -sf $temp .
        cat >> fort.15 <<EOL
        &dynamicWaterLevelCorrectionControl dynamicWaterLevelCorrectionFileName='$ThisYear.dat',
        dynamicWaterLevelCorrectionMultiplier=-1.00,
        dynamicWaterLevelCorrectionRampStart=0.0,
        dynamicWaterLevelCorrectionRampEnd=86400.0,
        dynamicWaterLevelCorrectionRampReferenceTime='coldstart' /
EOL
    fi

    ## Modify fort.26 template
    preptime=`date`
    tpwd=`pwd`
    if [ "$Fort15_Coupled" -eq "1" ] ; then
        white "****** Prepping coupled run ...\n"
        white "****** Modifying fort.26 ... \n"
        echo "s/<SIMNAME>/$Main_Experiment/" > sed.script
        echo "s/<TITLE1>/$ThisTrack/" >> sed.script
        echo "s/<TITLE2>/$preptime/" >> sed.script
        echo "s#<TITLE3>#$tpwd#" >> sed.script
        echo "s/<RSTIMINC>/$RSTIMINC/" >> sed.script
        echo "s/<WAVEOUTPUTTIMINC>/$RSTIMINC/" >> sed.script

        yyyymmdd=${BasinWinStartDate:0:8}
        hr=${BasinWinStartDate:8:2}
        mn=${BasinWinStartDate:10:2}
        ss="00"
        if [ -z $mn ] ; then
            mn="00"
        fi
        WAVESTARTTIME="$yyyymmdd.$hr$mn$ss"
        white  "****** $BasinWinStartDate : $yyyymmdd $hr $mn : $WAVESTARTTIME\n"
        yyyymmdd=${BasinWinEndDate:0:8}
        hr=${BasinWinEndDate:8:2}
        mn=${BasinWinEndDate:10:2}
        ss="00"
        if [ -z $mn ] ; then
            mn="00"
        fi
        WAVEENDTIME="$yyyymmdd.$hr$mn$ss"

        echo "s/<WAVESTARTTIME>/$WAVESTARTTIME/" >> sed.script
        echo "s/<WAVEENDTIME>/$WAVEENDTIME/" >> sed.script
        sed -f sed.script $Fort26FileMaster > fort.26
        sed "s/<SIMNAME>/$ThisTrack/" $SwanInitFileMaster > swaninit
    fi

    NumberOfDecomposeCores=$((Job_NumberOfCores - Job_NumberOfWriterCores))

    if [ "$Main_AssumeDecomp" -eq "1" ] ; then
        red "Not supported.\n"
        exit 1
    elif [ $Main_DontPrep -eq "1" ] ; then
        yellow "*** DontPrep set to one.  Not prepping or submitting." 
        echo " "
        # delete trk file from Tracks dir
        rm -rf $TrackDir/$ThisTrackFile
        cd ../
        continue
    elif [ $Main_PrepInSubmit -ne "1" ] ; then
        white "*** Decomposing problem:\n"
        white "****** PartMesh:\n"
        $AdcBinDir/$PREPEXE --np $NumberOfDecomposeCores --partmesh > diag.partmest
        white "****** Prepall:\n"
        $AdcBinDir/$PREPEXE --np $NumberOfDecomposeCores --prepall > diag.prepall
    else
        white "****** Putting decomposition commands into job script.\n"
    fi

    #    if [ $HotStartDir !=  None ] ; then
    #
    #        echo HotstartDir=$HotStartDir
    #
    #        if [ ! -e "$HotStartDir/fort.68" ] ; then
    #            echo "Needed Hotstart file $HotStartDir/fort.68 DNE. Terminal."
    #            exit 1
    #        fi
    #        cp $HotStartDir/fort.68 .
    #
    #        echo "   Localizing fort.68 ..."
    #            echo "$NumberOfCores" > adcprep.inp
    #            echo "6" >> adcprep.inp
    #            echo "68" >> adcprep.inp
    #        nice $PREPEXE < adcprep.inp >> adcprep.log
    #        IHOT=68
    #    fi    # end if [ $HotStartDir !=  None ] ; then

    #    echo "   Localizing fort.15 ..."
    #        echo "$NumberOfCores" > adcprep.inp
    #        echo "4" >> adcprep.inp
    #        echo "fort.14" >> adcprep.inp
    #        echo "fort.15" >> adcprep.inp
    #    if [ $Coupled -eq 1 ] ; then
    #            echo "fort.26" >> adcprep.inp
    #    fi
    #    nice $PREPEXE < adcprep.inp >> adcprep.log

    if [ "$Main_Submit" -eq "1" ]; then
        ThisJobName=$Main_ProjectName.$ThisTrack.$GridNameAbbrev
        if [ "$Fort15_Coupled" -eq "1" ] ; then
            ThisJobName="$ThisJobName.Coupled"
        fi
        white "****** Submitting job $ThisJobName ... \n"

        #        n=0

        #       n=$(((k+1)%3))
        #        if [ $n -ne 0 ] ; then n=1; fi

        echo "s/<JobName>/$ThisJobName/" > sed.script
        echo "s/<NumberOfCores>/${Job_NumberOfCores}/" >> sed.script
        echo "s/<PPN>/${Job_ProcessorsPerNode}/" >> sed.script
        echo "s/<WallTime>/$Job_WallTime/" >> sed.script
        echo "s/<ModelName>/$ADCEXE/" >> sed.script
        echo "s#<ProjectHome>#$Main_ADCIRCHome#" >> sed.script
        if [ "$Job_NumberOfWriterCores" -gt "0" ]; then
            temp="-W $Job_NumberOfWriterCores"
            echo "s/<WriterCores>/$temp/" >> sed.script
        else
            echo "s/<WriterCores>//" >> sed.script
        fi
        if [ "$Job_Queue" != "None" ]; then
            echo "s/<Queue>/$Job_Queue/" >> sed.script
        else
            echo "/<Queue>/d" >> sed.script
        fi
        if [ "$Job_Partition" != "None" ]; then
            echo "s/<Partition>/$Job_Partition/" >> sed.script
        else
            echo "/<Partition>/d" >> sed.script
        fi
        if [ "$Job_Reservation" != "None" ]; then
            echo "s/<Reservation>/$Job_Reservation/" >> sed.script
        else
            echo "/<Reservation>/d" >> sed.script
        fi

        if [ "$Main_PrepInSubmit" == "1" ]; then
            temp="\$PHOME/$PREPEXE --np ${NumberOfDecomposeCores} --partmesh"
            echo "s!#PrepLine1!$temp!" >> sed.script
            temp="\$PHOME/$PREPEXE --np ${NumberOfDecomposeCores} --prepall"
            echo "s!#PrepLine2!$temp!" >> sed.script
        fi

        sed -f sed.script $CommDir/submit.$Job_Manager.template > submit.me

        #sleep 3

        #jobid=`$Job_SubmitCommand < submit.me`

	# We can go either direction in the sandbox with some updates
	# Normally this is the last step when launching a run, not the first.
	# Probably not the safest thing to do using backticks with a variable
	# We will just use bash to launch it in the background and return a pid

	bash submit.me
        result=$?
	echo "Run finished"

	#jobid=$!
        #green "****** JobID =  $jobid\n"
    fi

    # delete trk file from Tracks dir
    rm -rf $TrackDir/$ThisTrackFile

    cd ../

    echo ' '
done

green "\nFinished Loop\n"

exit
