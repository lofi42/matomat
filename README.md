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

> sudo perl -MCPAN -e "install <MODULE_NAME>"



INSTALL:
========

Create the matomat.db in /var/matomat/

Default user is admin with password matomat.

> sqlite3 /var/matomat/matomat.db "CREATE TABLE user (userid INTEGER PRIMARY KEY, username TEXT UNIQUE, pw_hash TEXT, privs INT, credits INT);"
> sqlite3 /var/matomat/matomat.db "INSERT INTO user  (username, pw_hash, privs, credits) VALUES ('admin','r3TXgPlPRhedOewwnL/AWI3g79hG7ME6B6g05Hl3+DddJs82bhonu6xscTXeJoPRnR2HlJVsZcoNx86sX4kalw',1,1000);"
> sqlite3 /var/matomat/matomat.db "CREATE TABLE drinks (drinkid INTEGER PRIMARY KEY, name TEXT UNIQUE, price INT, active INT,fixed INT,t2s TEXT);"
> sqlite3 /var/matomat/matomat.db "CREATE TABLE plugins (name TXT UNIQUE, filename TXT UNIQUE, active INT);"

Login with the admin user, change the password, add some drink and users.


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


