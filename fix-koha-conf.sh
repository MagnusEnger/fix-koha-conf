#!/bin/bash

# WARNING! This is very much an ongoing WORK IN PROGRESS!

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

## CONFIG-FILE

# Check that $INSTANCECONF exists
if [ ! -e $INSTANCECONF ]; then
    echo "$INSTANCECONF does not exist"
    exit 1
fi

echo "Updating config for $INSTANCE"

echo "Updating $INSTANCECONF..."

# Make a backup
mv "$INSTANCECONF" "$INSTANCECONFBACKUP"
# Put the new koha-conf.xml in place
cp "./koha-conf.xml.template" $INSTANCECONF
# Fix permissions
chown root:$INSTANCE-koha $INSTANCECONF
chmod 0640 $INSTANCECONF

# Replace the instancename
perl -pi -e "$/=undef; s/__INSTANCENAME__/$INSTANCE/g" $INSTANCECONF

# Replace passwords
biblioserverpassword="$(    xmlstarlet sel -t -v "yazgfs/serverinfo[@id='biblioserver']/password"    $INSTANCECONFBACKUP )"
authorityserverpassword="$( xmlstarlet sel -t -v "yazgfs/serverinfo[@id='authorityserver']/password" $INSTANCECONFBACKUP )"
publicserverpassword="$(    xmlstarlet sel -t -v "yazgfs/serverinfo[@id='publicserver']/password"    $INSTANCECONFBACKUP )"
configpass="$(              xmlstarlet sel -t -v "yazgfs/config/pass"                                $INSTANCECONFBACKUP )"
perl -pi -e "$/=undef; s/__BIBLIOSERVERPASSWORD__/$biblioserverpassword/g"       $INSTANCECONF
perl -pi -e "$/=undef; s/__AUTHORITYSERVERPASSWORD__/$authorityserverpassword/g" $INSTANCECONF
perl -pi -e "$/=undef; s/__PUBLICSERVERPASSWORD__/$publicserverpassword/g"       $INSTANCECONF
perl -pi -e "$/=undef; s/__CONFIGPASSWORD__/$configpass/g"                       $INSTANCECONF

echo "done"

## DOM CONFIG

echo "Updating $INSTANCEDOM..."

# Check that $INSTANCECONF exists
if [ -e $INSTANCEDOM ]; then
    echo "$INSTANCEDOM exists, creating a backup..."
    mv "$INSTANCEDOM" "$INSTANCEDOMBACKUP"
fi

# Move the new config file into place
cp "./zebra-biblios-dom.cfg.template" $INSTANCEDOM
# Fix permissions
chown root:$INSTANCE-koha $INSTANCEDOM
chmod 0640 $INSTANCEDOM

# Replace the instancename
perl -pi -e "$/=undef; s/__INSTANCENAME__/$INSTANCE/g" $INSTANCEDOM

echo "done"

# Restart Zebra
echo "Going to restart Zebra..."
koha-restart-zebra $INSTANCE
echo "done"

# Reindex
echo "Going to do a full reindex, this might take some time..."
koha-rebuild-zebra -f $INSTANCE
echo "done!"
