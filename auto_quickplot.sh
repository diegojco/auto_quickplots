#!/bin/sh
#
# Automatized Quickplots.
#
# Authors: Renate Brokopf (Quickplots script)
#          Diego Jiménez de la Cuesta Otero (Automatization)
#
# This script processes your output data and, based in your inputs, generates
# job scripts for generating more diagnostic plots.
#
# It can manage several experiments at a time.
#
# Modify until before the job script writing.
# You can set the variables with relevant values for your case.
#
# But modify the code itself under your responsibility.
# First, understand the code or ask me. There are some advanced topics as
# pattern recognition with regex in grep or sed.
#
# For questions about the job script, ask Renate Brokopf. She is the expert. I
# only added an abstraction layer around the job script.
#
# Quickplot.job original file that I used as template can be found at:
#
# /pool/data/ECHAM6/post/QuickScripts/QuickPlot.job
#
# At the bottom of job script you can find information for further types than
# annual climatological quickplots. For that end, you will need to modify
# my code to calculate the corresponding climatologies. We can work on it
# together or you can add this functionality on your own way.
#
# You can run the written Quickplot.job by yourself or using the flag
# actplot with value 1. If this is the setting, then the script will run
# sequentially over the Quickplot.job files for each processed experiment. This
# is quick, compared to the processing part.
#
# Also, the calc flag allows you to toggle on/off the processing. If you
# toggle it off, then it will ignore the processing and generation of scripts,
# and will pass directly to the execution of them. Obviously, there will be a
# failure if the scripts are not yet written. If you toggle it off and the
# actplot flag is also set to 0, then the script will do nothing, except for a
# list of experiments.
#
# If you modified the code, please make clear that you modified it, what is the
# modification and include references to us... and, of course, add you as an
# author.
#

workdir=/work/<project>/<user>/; # Where is your model.
scratchdir=/scratch/<letter>/<user>/quickplotproc/; # Where you dump process files.
mod=<mod>; # Model name.
experimenter=<ide>; # Identifier of your experiments.
actplot=1; # Flag to run the plotting code (actplot=1)... or not.
calc=0; # Flag to run the plotting code without processing.

expsman=; # If you want to pass a list of preselected experiments.
if [ ${expsman} ];
 then
  exps=${expsman};
 else
  exps=$(ls ${workdir}${mod}/experiments | grep "^${experimenter}");
fi

filetype='ATM LOG BOT';
type=ANN;
count=0;

echo;
echo "Experiment list.";
echo;
for exp in ${exps};
 do
  count=$(( count+1 ));
  echo "${count}: ${exp}";
done
countt=${count};
count=0;
echo;
sleep 5;

if [ ${calc} = 1 ];
 then
  for exp in ${exps};
   do
    count=$(( count+1 ));
    echo "Processing experiment ${exp} (${count} / ${countt}) to ingest it in quickplots";
    echo;
    echo " 1. Getting/Creating the necessary paths";
    expdir=${workdir}${mod}/experiments/${exp};
    expdirsc=${scratchdir}${mod}/experiments/${exp};
    mkdir -p ${expdirsc};
    expdatadir=${expdir}/outdata/echam6;
    echo "  Path of experiment    : ${expdir}";
    echo "  Path of scratch space : ${expdirsc}";
    echo "  Path of ECHAM6 data   : ${expdatadir}";
    echo;
    sleep 5;
    echo " 2. Creating/Checking path for storage";
    expquickdir=${expdir}/quickplot;
    mkdir -p ${expquickdir};
    echo "  Path of quickplots    : ${expquickdir}";
    echo;
    sleep 5;
    echo " 3. Calculating dates from data files/previous quickplots";
    startdate=$(ls ${expdatadir} | head -1 | rev | cut -d'.' -f2 | cut -d'_' -f1 | rev);
    if [ -s ${expquickdir}/finalyears ];
     then
      estartdate=$(( $(cat ${expquickdir}/finalyears | tail -1)+1 ));
     else
      estartdate=${startdate};
    fi
    enddate=$(ls ${expdatadir} | tail -1 | rev | cut -d'.' -f2 | cut -d'_' -f1 | rev);
    echo enddate >> ${expquickdir}/finalyears;
    echo "  Start date            : 01.01.${startdate}";
    echo "  Effective start date  : 01.01.${estartdate}";
    echo "  End date              : 12.31.${enddate}";
    echo;
    sleep 5;
    echo " 4. Processing data";
    for ftype in ${filetype};
     do
      echo "  i. Processing ${ftype}:";
      echo "   Gathering files...";
      if [ ${estartdate} -eq ${enddate} ];
       then
        listfiles=$(ls ${expdatadir} | grep "[.]*_${ftype}_[.]*" | grep "[.]*_${enddate}.grb");
       else
        listfiles=$(ls ${expdatadir} | grep "[.]*_${ftype}_[.]*" | sed -n "/[.]*_${estartdate}.grb/,/[.]*_${enddate}.grb/p");
      fi
      cd ${expdatadir};
      cdo cat ${listfiles} ${expdirsc}/${exp}_echam6_${ftype}_mm.grb;
      echo "   Calculating climatology...";
      cdo timmean ${expdirsc}/${exp}_echam6_${ftype}_mm.grb ${expquickdir}/${ftype}_${startdate}-${enddate}_${type};
    done
    echo;
    sleep 5;
    cd ${expquickdir}
    echo " 5. Writing job script for experiment ${exp}"
    cat > Quickplot.job << EOSCRPT
#!/bin/sh
#
set -e
#####################################################
#
# Please adjust the following variables in the script
# explanation see below
#

TYP=${type}

EXP=${exp}
YY1=${startdate}
YY2=${enddate}


NAME=\${YY1}-\${YY2}_\${TYP}
COMMENT='Modif. DJC. ECHAM6 T63L47'

atm_RES=63
oce_RES=GR15
# Lev 199 or 95 or 47 possible
LEV=47
# ERAinterim (1979-2008) or (1979-1999)
TO=2008

BOT=1
ATM=1
LOG=1

# summary table: if LONG=1 all included codes else LONG=0 only some codes
TAB=0
LONG=1

WORKDIR=${expquickdir}

#######################################################
#
date
#
if [ "\$ATM" = "0" -a "\$BOT" = "0" -a "\$TAB" = "0"  -a "\$LOG" = "0" ]
then
 echo nothing to do  ATM=0 BOT=0 TAB=0 LOG=0
fi


QUELLE=/pool/data/ECHAM6/post/quickplots/slf_slm
QUELLE=/pool/data/ECHAM6/post/QuickScripts/
export QUELLE
echo QUELLE path \$QUELLE
fractional_mask=0
export fractional_mask
echo fractional_mask \$fractional_mask

   FIXCODE=/pool/data/ECHAM6/post/FixCodes
   PLTDIR=\${WORKDIR}/\${EXP}_\${TYP}
  if [ ! -d \${PLTDIR} ] ; then
    mkdir \${PLTDIR}
    echo \${PLTDIR}
  fi

cd \${PLTDIR}
pwd

# Load modules if needed
MODULES=
if type ncl > /dev/null 2>&1
then
    :
else
    case `hostname` in
    login*|mistral*) NCL_MODULE=ncl ;;
    *)                 NCL_MODULE=ncl  ;;
    esac
    MODULES="\$MODULES \$NCL_MODULE"
fi

if [ "\$MODULES" ]
then
    . \$MODULESHOME/init/ksh
    module load \$MODULES
fi

###################### table ####################
#
if [ "\$TAB" = "1" ]
then
#
if [ "\$fractional_mask" = "1" ]
then
  cp \${FIXCODE}/F\${atm_RES}\${oce_RES}_SLF F_LAND
else
  cp \${FIXCODE}/F\${atm_RES}\${oce_RES}_LAND F_LAND
fi

cp \${FIXCODE}/F\${atm_RES}\${oce_RES}_GLACIER F_GLACIER
#
#/mnt/lustre01/pf/zmaw/m214091/echam-dev/util/quickplots/TABLE_job
#exit 99
#
\${QUELLE}/TABLEslf_slm_job \$TYP \$NAME  \${EXP} \${YY1} \${YY2} \$WORKDIR \$LONG
echo '####################################################'
echo you find your plots in
echo \${PLTDIR}
echo '#####################################################'

#
fi
#
#--------------- QUICKPLOTS ---------------------
#
if [ "\$BOT" = "1" ]
then

MEANTIME="(\${YY1}-\${YY2})"
cat >var.txt << eof00
\$NAME
\$TYP
\$EXP
\$MEANTIME
\$COMMENT
\$PLTDIR
eof00
#
cp \${FIXCODE}/F\${atm_RES}\${oce_RES}_LAND F_LAND
#
\${QUELLE}/PREPAREbot_erain_ncl \$TYP \$NAME \$atm_RES \$TO \$WORKDIR
#
ncl  \${QUELLE}/BOT_page.ncl

ncl  \${QUELLE}/BOT_single.ncl


echo '####################################################'
echo  you find your plots in
echo \${PLTDIR}
echo '#####################################################'


set +e
rm Ubusy_*.nc   var.txt var1.txt
rm -f   datum   F_LAND
set -e

fi
############################################################
if [ "\$ATM" = "1" ]
then
echo ATM

MEANTIME="(\${YY1}-\${YY2})"
cat >var.txt << eof00
\$NAME
\$TYP
\$EXP
\$MEANTIME
\$COMMENT
\$PLTDIR
eof00
#
\${QUELLE}/PREPAREatm_erain_ncl \$TYP \$NAME \$atm_RES \$TO \$WORKDIR
#

  ncl  \${QUELLE}/ATM_lola_page.ncl
  ncl  \${QUELLE}/ATM_lola_single.ncl

  ncl  \${QUELLE}/ATM_zon_page.ncl
  ncl  \${QUELLE}/ATM_zon_single.ncl

echo '####################################################'
echo  you find your plots in
echo \${PLTDIR}
echo '#####################################################'

set +e
rm Ubusy_*.nc   var.txt var1.txt
rm   -f   datum   F_LAND
set -e
fi
#####
# logarithm polt for the upper atmosphere
# you need minimum 47 leves see below
#########################################
if [ "\$LOG" = "1" ]
then
echo LOG

MEANTIME="(\${YY1}-\${YY2})"
cat >var.txt << eof00
\$NAME
\$TYP
\$EXP
\$MEANTIME
\$COMMENT
\$PLTDIR
eof00

#

\${QUELLE}/PREPAREatmlog_erain_ncl \$TYP \$NAME \$atm_RES \$TO \$LEV \$WORKDIR

  ncl  \${QUELLE}/ATM_zon_log_page.ncl

  ncl  \${QUELLE}/ATM_zon_log_single.ncl



echo '####################################################'
echo  you find your plots in
echo \${PLTDIR}
echo '#####################################################'

rm -f Ubusy_*.nc   var.txt var1.txt
rm  -f  datum
fi
exit

#Please adjust the following variables in the script:
#
# EXP= experiment number, appears in the caption of the plots
#
# COMMENT= the comment appears in the subtitle of the plots
#          maximum length 20 characters
# TYP= average to compare with ERAinterim-data(1979-1999)or (1979-2008)
#      ANN(annual), DJF(Dec-Feb), MAM(mar-may)  JJA(jul-aug), SON(sep-nov),
#      JAN ... DEC
#
# YY1= start date, appears in the caption of the plots
# YY2= end date, appears in the caption of the plots
#
#
# NAME= XXX name of data files (maximum length 10 characters)
# WORKDIR= working directory (containing the input data BOT_XXX and ATM_XXX)
#
# atm_RES= atmospheric grid resolution 31 63 127
#          (used for ERA40-data and
#           used for land-sea and glacier mask,
#           if code 172, 194, 232 not included in BOT_XXX)
#
# oce_RES= ocean grid resolution GR15 GR30 TP04 TP10
#          (used for land-sea and glacier mask,
#           if code 172, 194, 232 not included in BOT_XXX)
#
# ATM= 1 plot atmosphere data
#      0 no plot of atmospheric data
# BOT= 1 plot surface data
#      0 no plot of surface data
# TAB= 1 summary table
#      0 no summary table
#      the fractional land-sea mask (code194) is used to compute the table
#      the table program needs code 97 (ice cover), otherwise you can not
#      take any surface code
# fractional_mask= 1 fractional land sea mask code179 (slf)
#                = 0 non-fractional land sea mask code172 (slm)
# LONG= 1 print all bottom codes
#       0 prints only a selection of codes
#         (4,97,142,143,150,164,167,178,179,210,211,230,231,191,192)
#
#       the table program needs code 97 (ice cover),
#       otherwise you con take any surface code
#
#       the plot program expects the following two files:
#                BOT_XXX (surface data, containing at least:
#                            code: 97 ice cover
#                                 140 soil wetness
#                                 150 vertical integral of cloud ice
#                                 151 sea level pressure
#                                 164 total cloud cover
#                                 167 2 m temperature
#                                 169 surface temperature
#                                 180 zonal wind stress
#                                 230 column water vapor
#                                 231 vertical integral of cloud liquid water
#                                 004 total precipitation
#                                     (alternatively, codes 142 plus 143) )
#
#                ATM_XXX (atmosphere data, with the following pressure levels
#                         in hPa:  1000,925,850,775,700,600,500,400,300,250,
#                                   200,150,100,70,50,30,10
#                         containing at least:
#                             code:130 temperature
#                                  131 zonal wind
#                                  132 meridional wind
#                                  133 specific humidity
#                                  149 velocity potential
#                                  153 cloud liquid water
#                                  154 cloud ice
#                                  156 geopotential height
#                                  157 relative humidity
#                                  223 cloud cover)
#
#                LOG_XXX (atmosphere data,
#                         e.g. with the following pressure 47 levels in hPa:
#                         100900,99500,97100,93900,90200,86100,81700,77200,
#                         72500,67900,63300,58800,54300,49900,45700,41600,
#                         37700,33900,30402,27015,23833,20867,18116,15578,
#                         13239,11066,9102,7406,5964,4752,3743,2914,2235,1685,
#                         1245,901,637,440,296,193,122,74,43,23,11,4,1
#
#
#                         containing at least:
#                             code:130 temperature
#                                  131 zonal wind
#                                  132 meridional wind
EOSCRPT
    chmod 744 Quickplot.job;
  done
fi

if [ ${actplot} = 1 ];
 then
  for exp in ${exps};
   do
    echo;
    sleep 5;
    expquickdir=${workdir}${mod}/experiments/${exp}/quickplot;
    echo "Executing job script for ${exp}...";
    cd ${expquickdir};
    ./Quickplot.job;
    echo "Ended execution of job script.";
    sleep 10;
  done
fi
