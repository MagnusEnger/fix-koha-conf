#!/bin/bash

# WARNING! This is very much an ongoing WORK IN PROGRESS!

# FIXME File permissions! 

# Check that we are root
if [ "$(whoami)" != "root" ]; then
    echo "Sorry, you are not root."
    exit 1
fi

# Check that we got one argument after the script name
if [ "$#" != 1 ]; then
    echo "Usage: $0 instancename"
    exit 1
fi

INSTANCE=$1
INSTANCEDIR="/etc/koha/sites/$INSTANCE"
INSTANCECONF="$INSTANCEDIR/koha-conf.xml"
INSTANCECONFBACKUP="$INSTANCECONF.bak"
INSTANCEDOM="$INSTANCEDIR/zebra-biblios-dom.cfg"
INSTANCEDOMBACKUP="$INSTANCEDOM.bak"
# FIXME Use a fake conf files for testing during development
FAKECONF="/tmp/koha-conf.xml"
FAKEDOM="/tmp/dom.cfg"

## CONFIG-FILE

# Check that $INSTANCECONF exists
if [ ! -e $INSTANCECONF ]; then
    echo "$INSTANCECONF does not exist"
    exit 1
fi

echo "Updating config for $INSTANCE"

echo "Updating $INSTANCECONF..."

# Make a backup
# FIXME Should be mv
cp "$INSTANCECONF" "$INSTANCECONFBACKUP"
# Put the new koha-conf.xml in place
cp "./koha-conf.xml.template" $FAKECONF

# Replace the instancename
perl -pi -e "$/=undef; s/__INSTANCENAME__/$INSTANCE/g" $FAKECONF

# Replace passwords
biblioserverpassword="$(    xmlstarlet sel -t -v "yazgfs/serverinfo[@id='biblioserver']/password" $INSTANCECONF )"
authorityserverpassword="$( xmlstarlet sel -t -v "yazgfs/serverinfo[@id='authorityserver']/password" $INSTANCECONF )"
publicserverpassword="$(    xmlstarlet sel -t -v "yazgfs/serverinfo[@id='publicserver']/password" $INSTANCECONF )"
configpass="$( xmlstarlet sel -t -v "yazgfs/config/pass" $INSTANCECONF )"
perl -pi -e "$/=undef; s/__BIBLIOSERVERPASSWORD__/$biblioserverpassword/g" $FAKECONF
perl -pi -e "$/=undef; s/__AUTHORITYSERVERPASSWORD__/$authorityserverpassword/g" $FAKECONF
perl -pi -e "$/=undef; s/__PUBLICSERVERPASSWORD__/$publicserverpassword/g" $FAKECONF
perl -pi -e "$/=undef; s/__CONFIGPASSWORD__/$configpass/g" $FAKECONF

echo "done"

## DOM CONFIG

echo "Updating $INSTANCEDOM..."

# Check that $INSTANCECONF exists
if [ -e $INSTANCEDOM ]; then
    echo "$INSTANCEDOM exists, creating a backup..."
    # FIXME Should be mv
    cp "$INSTANCEDOM" "$INSTANCEDOMBACKUP"
fi

# Move the new config file into place
cp "./zebra-biblios-dom.cfg.template" $FAKEDOM

# Replace the instancename
perl -pi -e "$/=undef; s/__INSTANCENAME__/$INSTANCE/g" $FAKEDOM

echo "done"

# Restart Zebra
echo "Going to restart Zebra..."
koha-restart-zebra $INSTANCE
echo "done"

# FIXME Reindex
echo "Going to do a full reindex, this might take some time..."
koha-rebuild-zebra -f $INSTANCE
echo "done!"
