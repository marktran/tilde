#!/bin/bash
FILENAME=$(gdate -r "$1" +"s%Y%d%m-%H%M%S.%N.png")
mv "$1" $FILENAME
AWS_ACCESS_KEY_ID="" AWS_SECRET_ACCESS_KEY="" aws s3 cp $FILENAME "s3://mrktrn.com/scrnshts/${FILENAME}"
rm -f $FILENAME
echo -n "https://mrktrn.com/scrnshts/${FILENAME}"|pbcopy
