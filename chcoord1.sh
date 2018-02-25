#!/bin/bash

INPUTFN=/home/oleg/tmp/vid/in.mp4
mkdir out

NUMFRAMES=$(ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=nb_read_frames -count_frames  -of default=nokey=1:noprint_wrappers=1   "${INPUTFN}" )
INHEIGHT=$(ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=height  -of default=nokey=1:noprint_wrappers=1   "${INPUTFN}" )
INWIDTH=$(ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=width  -of default=nokey=1:noprint_wrappers=1   "${INPUTFN}" )

ffmpeg -i "${INPUTFN}" -vf fps=30 out/in_%03d.bmp
OUTWIDTH=$(( NUMFRAMES ))
OUTHEIGHT=$(( NUMFRAMES * INHEIGHT / INWIDTH ))
for f in out/st_*.bmp
do
    mogrify -resize ${OUTWIDTH}x${OUTHEIGHT} "${f}"
done 

NF0=$(( NUMFRAMES - 1 )); # number of frames from zero

for OUTFRAME in `seq -w 1 ${NUMFRAMES}`
do
    ## remove leading zeroes
    shopt -s extglob
    echo "OUTFNUM=${OUTFRAME##+(0)}"
    OUTFNUM=${OUTFRAME##+(0)} 
    OUTFRAMELIST=""
for frame in `seq -w 0 ${NF0}` ;
do
    f1=0
    i0=$(( OUTFNUM - 1 ))
    i1=$((OUTFNUM))
    convert out/in_${frame}.bmp -crop 1x222+${i1}+0 /dev/shm/out_${frame}_${OUTFRAME}.bmp
    f1=$(( f1 + 1 ))
    OUTFRAMELIST="${OUTFRAMELIST} /dev/shm/out_${frame}_${OUTFRAME}.bmp"
done
    convert ${OUTFRAMELIST} +append output_${OUTFRAME}.png
    rm ${OUTFRAMELIST} &> /dev/null
    echo DONE: output_${OUTFRAME}.png
done

ffmpeg -i output_%03d.png -c:v libx264 -vf fps=30 -pix_fmt yuv420p out.mp4