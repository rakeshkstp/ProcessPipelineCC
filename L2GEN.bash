#!/bin/bash
#SBATCH --account=def-belasi01
#SBATCH --array=1-5
#SBATCH --time=07-00:00           # time (DD-HH:MM)
#SBATCH --mem=2G
#SBATCH --output=%x-%j.out

i=${1}
re='^[0-9]+$'

if ! [[ $i =~ $re ]] ; then
	echo "Syntax is: \"sbatch -J <jobname> L2GEN.bash <folder number>\""   
	echo "ERROR: Enter valid folder number to run" >&2; exit 1
fi

module load singularity/3.5
module load python/3.8

virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index --upgrade pip
pip install requests

echo "Running L2GEN"
cd ./Data/

foldername=$(sed -n "${i}p" folder.lst)

if [ -d $foldername ] ; then
	cd $foldername
else
	echo "INVALID FOLDERNAME"
	exit
fi

echo "Entered $(pwd)"

if [ -f dir.lst ]; then
	d=$(cat dir.lst | wc -l)
	if [ $d -eq 0 ]; then
		rm dir.lst
	fi
fi

if [ ! -f dir.lst ]; then
	/bin/ls -1d */ > dir.lst
fi
echo "dir.lst contains:"
cat dir.lst

vpath=$(echo "/home/rakesh/scratch/var$i")
export OCVARROOT=$vpath

echo "Starting task $SLURM_ARRAY_TASK_ID"
DIR=$(sed -n "${SLURM_ARRAY_TASK_ID}p" dir.lst)
cd $DIR
echo "Present working directory is $(pwd)"
../../../Codes/l2gen.bash pimagelist.lst $i
cd ..  # get back to the folder containing link files
