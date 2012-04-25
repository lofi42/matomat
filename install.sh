#!/bin/sh

####################################################
#
# Install Script for matomat Version 0.2.0
#
####################################################

CFG_DIR=/etc/
DATA_DIR=/var/
BIN_DIR=/usr/local/bin/

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

if [ -d "$DATA_DIR/matomat" ]
        then echo "[-] Matomat Data Directory already exists."
else 
	mkdir $DATA_DIR/matomat/ 
	cp CHANGELOG.md $DATA_DIR/matomat/CHANGELOG.md
	cp README.md $DATA_DIR/matomat/README.md
	cp standard.flf $DATA_DIR/matomat/standard.flf
	echo "[+] Data Directory created."

	sqlite3 $DATA_DIR/matomat/matomat.db "CREATE TABLE user (userid INTEGER PRIMARY KEY, username TEXT UNIQUE, pw_hash TEXT, privs INT, credits INT);"
	sqlite3 $DATA_DIR/matomat/matomat.db "INSERT INTO user  (username, pw_hash, privs, credits) VALUES ('admin','r3TXgPlPRhedOewwnL/AWI3g79hG7ME6B6g05Hl3+DddJs82bhonu6xscTXeJoPRnR2HlJVsZcoNx86sX4kalw',1,1000);"
	sqlite3 $DATA_DIR/matomat/matomat.db "CREATE TABLE drinks (drinkid INTEGER PRIMARY KEY, name TEXT UNIQUE, price INT, active INT,fixed INT,t2s TEXT);"
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

