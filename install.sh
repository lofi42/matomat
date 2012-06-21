#!/bin/sh

####################################################
#
# Install Script for matomat Version 0.2.2 
#
####################################################

CFG_DIR=/etc/
DATA_DIR=/var/
BIN_DIR=/usr/local/bin/
LIB_DIR=/usr/lib/perl5/site_perl

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ -f "$CFG_DIR/matomat.cfg" ]
	then echo "[-] Matomat Config already exists."
else
	cp matomat.cfg $CFG_DIR/matomat.cfg
	echo "[+] Config file created."
fi

if [ -d "$LIB_DIR/Matomat" ]
	then echo "[-] Matomat Perl Module Directory already exists."
else
	cp -r Matomat $LIB_DIR
	echo "[+] Matomat Perl Modules created."
fi

if [ -d "$DATA_DIR/matomat" ]
        then echo "[-] Matomat Data Directory already exists."
else 
	mkdir $DATA_DIR/matomat/ 
	cp CHANGELOG.md $DATA_DIR/matomat/CHANGELOG.md
	cp README.md $DATA_DIR/matomat/README.md
	cp standard.flf $DATA_DIR/matomat/standard.flf
	echo "[+] Data Directory created."

	sqlite3 $DATA_DIR/matomat/matomat.db "CREATE TABLE user (userid INTEGER PRIMARY KEY, username TEXT UNIQUE, pw_hash TEXT, pw_change INT, rfid_id INT UNIQUE, privs INT, credits INT);"
	sqlite3 $DATA_DIR/matomat/matomat.db "INSERT INTO user  (username, pw_hash, pw_change, rfid_id, privs, credits) VALUES ('admin','$xlx37Vm8heXo192iixKl89vB6ZkFygnWBctLHy4vlSjXoAkfo4SDsGefEvocbjhBHmJdRVJXj53aoqZpjfq1ESq0IsXGimKveaXZu2ak9PzYVC6Iawz3wP8xnqnAYC1Uz$WLHrV6B/9Cpa0jrfEv1wtLz4AoifIWEXlcFeOHNnbmLW8K/qUhF//odu9T44RwZ7zeJSeuDA2CPwSZ12phcu5g',0,1000,1,0);"
	sqlite3 $DATA_DIR/matomat/matomat.db "CREATE TABLE drinks (drinkid INTEGER PRIMARY KEY, name TEXT UNIQUE, price INT, active INT,fixed INT,t2s TEXT);"
	sqlite3 $DATA_DIR/matomat/matomat.db "CREATE TABLE plugins (name TXT UNIQUE, filename TXT UNIQUE, active INT);"
	chmod 666 $DATA_DIR/matomat/matomat.db
	chmod 777 $DATA_DIR/matomat/
	echo "[+] Matomat.db created."
fi

if [ -f "$BIN_DIR/matomat.pl" ]
        then echo "[-] Matomat binary already exists."
else 
        cp matomat.pl $BIN_DIR/matomat.pl
        echo "[+] Matomat binary created."
fi

