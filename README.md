# Block ads and malware via local DNS server
# Fork of https://github.com/mueller-ma/block-ads-via-dns
# Adapted to run on FreeBSD using tcsh (no dependencies), and to redirect
# all traffic to local webserver (192.168.0.10 in example).
# This method is described here: https://charlieharvey.org.uk/page/adblocking_with_bind_apache

# Installation
## FreeBSD ( or Nas4Free jail)
- Install DNS Server: `pkg install bind911` or `portmaster dns/bind911` 
- Go to the bind directory: `cd /usr/local/etc/namedb/`
- Add this to named.conf: `include "/usr/local/etc/namedb/ad-stevenblack";`
- Create /usr/local/etc/namedb/master/null.zone.file and add this:
````
$TTL    86400   ; one day
@       IN      SOA     ads.example.com. hostmaster.example.com. (
               2014090101
                    28800
                     7200
                   864000
                    86400 )
                NS      my.dns.server.org
                A       192.168.0.10
@       IN      A       192.168.0.10
*       IN      A       192.168.0.10
````
- The above NS and host values are arbitrary.
- Your /usr/local/etc/namedb/named.conf.options should contain something like this, 
in addition to your normal zone/slave/master setup config:
````
include "/usr/local/etc/namedb/ad-stevenblack";

logging{
  channel simple_log {
    file "/var/log/query.log" versions 3 size 5m;
    severity warning;
    print-time yes;
    print-severity yes;
    print-category yes;
  };
  category default{
    simple_log;
  };
};

options {
        // All file and path names are relative to the chroot directory,
        // if any, and should be fully qualified.
        directory       "/usr/local/etc/namedb/working";
        pid-file        "/var/run/named/pid";
        dump-file       "/var/dump/named_dump.db";
        statistics-file "/var/stats/named.stats";
check-names master ignore;
allow-query {192.168.0.0/24;
};
````
- cd to your src directory `cd /usr/local/src/`
- Download generate-zonefile.sh `fetch https://raw.githubusercontent.com/fsbruva/block-ads-via-dns/master/generate-zonefile.sh`
- Make it executable `chmod +x generate-zonefile.sh`
- Run generate-zonefile.sh `./generate-zonefile.sh`

## Router / DHCP Server
- Give your DNS server a static IP, and add to the DCHP server config

## Optional
- Add local blacklist and whitelist in /usr/local/etc/namedb/ & ensure filename matches value in `generate-zonefile.sh`
  (default: `my_blacklist` and `my_whitelist`)
- Create cronjob: `/bin/tcsh -e /usr/local/src/generate-zonefile.sh`
- Choose which StevenBlack GitHub unified hosts to use in `generate-zonefile.sh`
