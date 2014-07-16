#!/bin/bash

# WARNING! This is very much an ongoing WORK IN PROGRESS!

# See the following Koha bug reports for why this script is necessary:
# http://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=12584
# http://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=12577

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
FAKECONF="/tmp/koha-conf.xml"

# FIXME Check that $INSTANCECONF exists

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

echo "Updating $INSTANCEDOM"

# FIXME Update $INSTANCEDOM

# FIXME Restart Zebra

# FIXME Reindex
