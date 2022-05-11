#!/bin/bash
vpath=$(echo "/home/rakesh/scratch/var${2}")
export OCVARROOT=$vpath
source /home/rakesh/ocssw/OCSSW_bash.env

l2prods="ipar_UQAR,par_UQAR_0m,par_UQAR_0p,icw_uqar,COT,OOT,salb,par_UQAR_bottom,ice_frac,spm,chl_abi,chl_gabi,elev"
iNORTH=-999
iSOUTH=-999
iWEST=-999
iEAST=-999
spatres=-1		

touch l2gen.out

for zFILE in `cat ${1}`
	do
	L1A=$(sed "s/.bz2//g" <<<"$zFILE")
	GEO=$(sed "s/L1A_LAC/GEO/g" <<<"$L1A")
	L1B=$(sed "s/L1A/L1B/g" <<<"$L1A")
	ANC=$(sed "s/L1B_LAC/L1B_LAC.anc/g" <<<"$L1B")
	L2=$(sed "s/L1A/L2/g" <<<"$L1A")

	if [ ! -f "$L2" ]; then
		echo "Starting to process L2: $L2"
		if [ ! -f "$ANC" ]; then
			echo "$ANC missing, downloading ANC: $ANC"
			if [ ! -f "$L1B" ]; then
				echo "$L1B is missing, processing L1B: $L1B"
				if [ ! -f "$GEO" ]; then
					echo "$GEO is missing, processing GEO: $GEO"
					if [ ! -f "$L1A" ]; then
						echo "$L1A is missing, extracting bz2 archive: $zFILE"
						bzip2 -dkqf $zFILE
					fi
					if [ -f "$L1A" ]; then
						modis_GEO.py $L1A -o $GEO -v -d
					else
						echo "Extraction failed $L1A"
						continue
					fi 	# GEO created
				fi
				if [ -f "$GEO" ]; then
					modis_L1B.py $L1A -y -z -v
				else 
					echo "$GEO is not created"
					continue
				fi
			fi
			if [ -f "$L1B" ]; then		
				getanc.py $L1B -v
				status=$?
				mv *.anc ../ 2>/dev/null
				if [ $status -eq 0 ] && [ -f $ANC ]; then
					echo "Ancillary data is downloaded successfully: $ANC"
				else
			        	echo "Cannot download ancillary data."
			        	rm $ANC
				fi
			else
				echo "$L1B is not created"
				continue
			fi
		fi 				# ANC created
		
		if [ -f "$ANC" ]; then
			singularity exec -B /scratch /home/rakesh/SeaDAS_CC.sif /usr/local/SeaDAS/ocssw/bin/l2gen ifile=$L1B geofile=$GEO ofile=$L2 par=$ANC l2prod=$l2prods north=$iNORTH south=$iSOUTH east=$iEAST west=$iWEST resolution=$spatres maskcloud=1 maskland=1 maskglint=1 aer_opt=-20 >> l2gen.out
			L2size=$(wc -c <"$L2")
			if [ $L2size -lt 1000000 ]; then
				echo "$L2 is very small or corrupt"
			  	rm $L2
				rm $ANC
				rm $L1B
				rm $L1A
				rm $GEO
				continue
			fi
		else
			echo "$ANC is not created"
			continue
		fi

		if [ -f "$L2" ]; then
			rm $zFILE
			rm $ANC
			rm $L1B
			rm $GEO
			rm $L1A
		else
			rm $ANC
	                rm $L1B
	                rm $GEO
	                rm $L1A
		fi
	fi 			# L2 created
done
