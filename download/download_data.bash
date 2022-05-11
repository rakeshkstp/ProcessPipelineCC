#!/bin/bash

#SBATCH --account=def-belasi01
#SBATCH --job-name=Get_L1A
#SBATCH --time=05-00:05           # time (DD-HH:MM)
#SBATCH --output=%x-%j.dout
#SBATCH --mem=1G

echo "Downloading Data"
cd ./Data/
#bash ../Codes/createlinks.bash
#bash ../Codes/Year2Monthlinks.bash


# Read the link files created in th previous section of this code
if [ -f mdlist.lst ]; then    # Monthly download list
	rm mdlist.lst
fi

nfiles=$(ls -1 *.mlink 2>/dev/null | wc -l)

if [ $nfiles -gt 0 ]; then
		ls -1 *.mlink > mdlist.lst
fi

mfile="missingfiles.lst"


if [ -f mdlist.lst ]; then
	echo "$nfiles link files are present."

  	for inputfile in `cat mdlist.lst`
  	do
    		foldername=$(sed "s/.mlink//g" <<<"$inputfile") # Define folder name to download images

    		if [ ! -d $foldername ]; then
      			mkdir $foldername	# Create folder
    		fi

    		cd $foldername	# Change directory to the newly created folder

    		year=${foldername:0:4}
		month=${foldername:4:6}

  		now=$(date +"%d-%m-%Y %T")

    		echo "Started downloading data for $month/$year at $now"
	
		# Check missing files
		rm -f $mfile

		for ifile in `cat ../$inputfile`
		do
			zipname=$(basename $ifile)
			IFS='.' read -r fileid LAC EXT <<< $zipname
			L2name="$fileid.L2_LAC"
			L1Bname="$fileid.L1B_LAC"

  			if [ ! -f $zipname ] && [ ! -f $L2name ] && [ ! -f $L1Bname ];	then
				echo $ifile >> $mfile
			fi
		done
		if [ -f $mfile ]; then
			# Download all the file links in the links file
    			cat $mfile | wget -o wget.log -nv --user=***REMOVED*** --password=***REMOVED*** --auth-no-challenge=on --keep-session-cookies -i -
			rm -f $mfile
			now=$(date +"%d-%m-%Y %T")
			echo "Download Complete at $now"
		else
			echo "NOTHING TO DOWNLOAD"
		fi
    		cd ..  # get back to the folder containing link files
  	done
fi
