#!/bin/bash

nfmax=5 
fnum=${1}
re='^[0-9]+$'

if ! [[ $nfmax =~ $re ]] ; then
	echo "Syntax is: \"bash Structure_L2.bash <instances> <folder number>\""   
	echo "ERROR: Enter valid number of instances to run" >&2; exit 1
fi

if ! [[ $fnum =~ $re ]] ; then
	echo "Syntax is: \"bash Structure_L2.bash <instances> <folder number>\""   
	echo "ERROR: Enter valid folder number" >&2; exit 1
fi

create_imagelist ()
{	if [ -f imagelist.lst ]; then
			rm imagelist.lst
	fi
	nfiles=$(ls -1 *.bz2 2>/dev/null | wc -l)
	if [ $nfiles -gt 0 ]; then
		echo "$nfiles L1A images are present in $FOLDER folder."
		ls -1 *.bz2 > imagelist.lst
		echo "Imagelist is created"
	else
		echo "No L1A images present in $FOLDER exiting."
		exit
	fi
}

echo "Creating L2GEN structure"
cd ./Data/

if [ -f folder.lst ]; then
	foldername=$(sed -n ${fnum}p folder.lst)
	cd $foldername
	wfolder=$(pwd)
	echo "Entering $wfolder"	
	# Create list of the downloaded images
	create_imagelist

    	#calculate number of files
    	nfiles="$(cat imagelist.lst 2>/dev/null | wc -l)";
	#echo "$nfiles files are present in this folder"

    	if [ $nfiles -gt 0 ]; then
      		nr=$(($nfiles / $nfmax));
      		echo "Creating folder with $nr files"
      		nf=1;
      		lcount=1;
      		while [ "$nf" -le "$nfmax" ]; do
        		F="$foldername-$nf"
			if [ -d $F ]; then
				rm -r $F
        		fi
			mkdir $F
        		cd $F
			echo "Creating pimagelist.lst for $F"
        		nf=$((nf+1));
        		nla=0;
        		if [ ! -f pimagelist.lst ]; then
        			while [ "$nla" -le "$nr" ] && [ "$lcount" -le "$nfiles" ]; do
        				echo $(sed ''$lcount'q;d' ../imagelist.lst) >> pimagelist.lst
        				lcount=$((lcount+1));
        				nla=$((nla+1));
        			done
				if [ -f pimagelist.lst ]; then
					sed -i -e 's/^/..\//' pimagelist.lst
				else
					touch pimagelist.lst
				fi
			fi
			echo "Exiting $F"
        		cd ..
      		done
    	fi
	echo "Exiting $foldername"
   	cd ..  # get back to the folder containing link files
fi
cd ..

module load python/3.8

source /home/rakesh/env/bin/activate
pip install requests

echo "Removing log files"
rm -f "${fnum}_${foldername}"-*.out

if [ -d $wfolder ]; then
	vpath=$(echo "/home/rakesh/scratch/var$fnum")
	if [ -d $vpath ]; then
		echo "Deleting everything inside $vpath"
		rm -r $vpath
	fi
	export OCVARROOT=$vpath
	echo "Updating Luts"
	update_luts.py aqua -v
	jobname="${fnum}_${foldername}"
	echo "Giving jobs for $jobname, $nfiles L1A files are present and folder id is $fnum."
	sbatch -J $jobname L2GEN.bash $fnum
else
	echo "$foldername is not present. No jobs present. Exiting ..."
fi
