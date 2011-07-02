#!/bin/bash

function getext {
ext=""
IFS='.' read -ra ADDR <<< "$1"
for i in "${ADDR[@]}"; do
	ext="$i"
done
echo $ext
}

MAKETYP=$1
DIRNAME=$2
TAGFILE=$3

if [ -n "$DIRNAME" ]; then
	if [ "$MAKETYP" == "-f" ]; then
		PROJECT_ROOT=$4
		SRCFILE=$5
		if [ -n "$TAGFILE" ]; then
			if [ -f $TAGFILE ]; then
				rm -f $TAGFILE
			fi

			if [ -n "$SRCFILE" ]; then
				EXT=$(getext $SRCFILE)
				if [ -n "$EXT" ]; then
					DEPFILE=${SRCFILE/.$EXT/.d}
					cd $DIRNAME
					if [ -f $TEMP/$DEPFILE ]; then
						rm -f $TEMP/$DEPFILE
					fi
					make -f $VIMPER_HOME/make/cpp/makedep.mk PROJECT_ROOT=$PROJECT_ROOT $TEMP/$DEPFILE
					TEMPDEPFILE=$TEMP/tempdep.out
					if [ -f $TEMPDEPFILE ]; then
						rm -f $TEMPDEPFILE
					fi
					sed '/\:/d;s/\\//g;'  /tmp/$DEPFILE > $TEMPDEPFILE

					if [ -f $TEMPDEPFILE ]; then
						for file in `cat $TEMPDEPFILE`;
						do
							if [ -f ${file} ]; then
								#echo 'Generating tags for ${file}...'
								ctags -a -f $TAGFILE --c++-kinds=+pl --fields=+iaS --sort=yes --extra=+q ${file}
							fi
						done
					fi
					ctags -a -f $TAGFILE --c++-kinds=+pl --fields=+iaS --sort=yes --extra=+q ${DIRNAME}/${SRCFILE}
					rm -f $TEMP/$DEPFILE
					exit 0
				fi
			fi
		fi
		echo "Usage : ctags.sh -d|-f <root directory> <tag filename> <project root> <src file>"
		exit -1
	fi
	if [ "$MAKETYP" == "-d" ]; then
		cd $DIRNAME
		echo "Building dependencies for project root $DIRNAME..."
		make depend
		if [ -n "$TAGFILE" ]; then
			if [ -f $TAGFILE ]; then
				rm -f $TAGFILE
			fi

			echo "Generating tags for $DIRNAME to $TAGFILE..."

			TEMPDEPFILE=$TEMP/tempdep.out
			if [ -f $TEMPDEPFILE ]; then
				rm -f $TEMPDEPFILE
			fi

			find $DIRNAME -type f -name "*.d" -exec sed '/\:/d;s/\\//g;' {} >> $TEMPDEPFILE \;
			if [ -f $TEMPDEPFILE ]; then
				for file in `cat $TEMPDEPFILE`;
				do
					if [ -f ${file} ]; then
						#echo 'Generating tags for ${file}...'
						ctags -a -f $TAGFILE --c++-kinds=+pl --fields=+iaS --sort=yes --extra=+q ${file}
					fi
				done
			fi
			ctags -a -f $TAGFILE --c++-kinds=+pl --fields=+iaS --extra=+q --sort=yes  -R $DIRNAME
			exit 0
		fi
	fi
fi
echo "Usage : ctags.sh -d|-f <root directory> <tag filename> [src file]"
exit -1
