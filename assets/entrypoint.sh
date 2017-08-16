#!/bin/bash

set -e

PATH=$LIBREOFFICE_HOME/program:$PATH

if [ "$1" == "run" ]
then
	echo soffice --nofirststartwizard --nologo --headless --norestore --invisible  --accept='socket,host=0.0.0.0,port=9100,tcpNoDelay=1;urp'
	exec soffice --nofirststartwizard --nologo --headless --norestore --invisible  --accept='socket,host=0.0.0.0,port=9100,tcpNoDelay=1;urp'
else
	exec "$@"
fi

