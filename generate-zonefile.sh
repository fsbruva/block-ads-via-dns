#!/bin/tcsh

############################# USER CONFIG ##################################

set BIND_PREFIX="/usr/local/etc/namedb"
set BIND_ZONEFILE="ad-stevenblack"
set BLACKLIST_FILE="my_blacklist"
set WHITELIST_FILE="my_whitelist"

# StevenBlack GitHub Hosts
# Uncomment ONE line containing the filter you want to apply
# See https://github.com/StevenBlack/hosts for more combinations
set GIT_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
#set GIT_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts"
#set GIT_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/social/hosts"
#set GIT_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling/hosts"
#set GIT_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts"
#set GIT_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts"
#set GIT_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts"


############################ END USER CONFIG ##############################



# display date
date

# Set tempfiles
# All_domains will contain all domains from all lists, but also duplicates and ones which are whitelisted
set ALL_DOMAINS=`mktemp`
# Like above, but no duplicates or whitelisted URLs
set ALL_DOMAINS_UNIQ=`mktemp`
# We don't write directly to the zonefile. Instead to this temp file and copy it to the right directory afterwards
set ZONEFILE=`mktemp`
# Raw hosts file from GitHub
set RAW_HOSTS=`mktemp`

# Get the unified hosts file
fetch -q -o $RAW_HOSTS $GIT_URL

# Filter out localhost and broadcast
cat $RAW_HOSTS | grep '^0.0.0.0' | egrep -v '127.0.0.1|255.255.255.255|::1' | cut -d " " -f 2 >> $ALL_DOMAINS

# Add local blacklist
if ( -f "${BIND_PREFIX}/${BLACKLIST_FILE}" ) then
    cat "${BIND_PREFIX}/${BLACKLIST_FILE}" >> $ALL_DOMAINS
endif

# Filter out comments and empty lines
cat $ALL_DOMAINS | egrep -v '^$|#' | sort | uniq  > $ALL_DOMAINS_UNIQ

# Apply local whitelist
if ( -f "${BIND_PREFIX}/${WHITELIST_FILE}" ) then
    foreach i ( `cat "${BIND_PREFIX}/${WHITELIST_FILE}"` )
        # echo i $i
        sed -i '' "/$i/d" $ALL_DOMAINS_UNIQ
    end
endif

# Add zone information
cat $ALL_DOMAINS_UNIQ | sed -r 's:(.*):zone "\1" { type master; notify no; file "/usr/local/etc/namedb/master/null.zone.file"; };:' > $ZONEFILE

# Copy temp file to right directory
cp $ZONEFILE $BIND_PREFIX/$BIND_ZONEFILE

# Remove all tempfiles
rm $ALL_DOMAINS $ALL_DOMAINS_UNIQ $ZONEFILE $RAW_HOSTS

# Reload bind
/usr/local/sbin/rndc reload

# For logfile
echo "done"
