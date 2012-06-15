DESCRIPTION:
============

The matomat is a mostly drunken coded perl script to manage the beverate billing
at the K4CG (http://www.k4cg.org/).



REQUIREMENTS:
=============

- Perl 
- SQLite
- festival (for the t2s feature)

Perl modules:
- DBI
- Config::Simple
- Text::FIGlet
- Digest::SHA
- IO::Prompter (Version: 0.002000)
- Term::ReadKey
- Module::Load

Install missing modules doing the following

> sudo perl -MCPAN -e "install MODULE_NAME"



INSTALL:
========

Create the matomat.db in /var/matomat/

Default user is admin with password matomat.

> sqlite3 /var/matomat/matomat.db "CREATE TABLE user (userid INTEGER PRIMARY KEY, username TEXT UNIQUE, pw_hash TEXT, privs INT, credits INT);"
> sqlite3 /var/matomat/matomat.db "INSERT INTO user  (username, pw_hash, pw_change, rfid_id, privs, credits) VALUES ('admin','$xlx37Vm8heXo192iixKl89vB6ZkFygnWBctLHy4vlSjXoAkfo4SDsGefEvocbjhBHmJdRVJXj53aoqZpjfq1ESq0IsXGimKveaXZu2ak9PzYVC6Iawz3wP8xnqnAYC1Uz$WLHrV6B/9Cpa0jrfEv1wtLz4AoifIWEXlcFeOHNnbmLW8K/qUhF//odu9T44RwZ7zeJSeuDA2CPwSZ12phcu5g',0,1000,1,0);"
> sqlite3 /var/matomat/matomat.db "CREATE TABLE drinks (drinkid INTEGER PRIMARY KEY, name TEXT UNIQUE, price INT, active INT,fixed INT,t2s TEXT);"
> sqlite3 /var/matomat/matomat.db "CREATE TABLE plugins (name TXT UNIQUE, filename TXT UNIQUE, active INT);"

Login with the admin user, change the password, add some drinks and users.


AUTHORS:
========

Nikolas Sotiriu (lofi)
lofi@sotiriu.de
http://sotiriu.de

Simon (blarz)
simon@blarzwurst.de


LICENSE:
========

"THE BEER-WARE LICENSE" (Revision 42):
lofi and blarz wrote this code. As long as you retain this notice you
can do whatever you want with this stuff. If we meet some day, and you think
this stuff is worth it, you can buy us a beer in return. 


