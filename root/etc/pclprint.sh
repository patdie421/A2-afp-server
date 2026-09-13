DATE=$(date +"%Y%m%d-%H%M%S")
FILENAME=/data/prints/PDF/"jetdirect-$DATE".pdf

/usr/local/bin/gpcl6 -dNOSAFE -dNOPAUSE -LPCL  -sDEVICE=pdfwrite -sOutputFile=$FILENAME -

chmod 666 $FILENAME
chown nobody:nogroup $FILENAME
