#!/bin/bash

DIRNAME=$1
TAGFILE=$2

if [ -n "$DIRNAME" ]; then
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
echo "Usage : ctags.sh <root directory> <tag filename>"
exit -1
