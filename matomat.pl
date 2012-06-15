#!/usr/bin/perl
##############################################################

use strict;
use IO::Prompter;
use Text::FIGlet;
use Digest::SHA qw(sha512 sha512_base64 sha512_hex);
use Term::ReadKey;
use Config::Simple;
use Module::Load;

# Matomat Modules
use Matomat::Config;
use Matomat::T2S;
use Matomat::Banner;
use Matomat::DBConnect;

$ENV{'PATH'} = '/bin:/usr/bin';

&_login;

sub _login {
	&_login_banner;
	if ($rtrate == 1) { 
		my $rate = &_current_rate;
		print ~~$font->figify(-A=>"Preis: $rate");
	}
	my @pwent = &_prompt_for_login;

	my $user = $pwent[0];
	my $password = $pwent[1];
	my $pass;

	my $sth = $dbh->prepare("SELECT pw_hash FROM user WHERE username=?");
	$sth->execute($user);
	my $out = $sth->fetchall_arrayref;

	foreach my $row (@$out) {
		($out) = @$row;
	}

	# Migration Stuff
	# XXX FIX XXX
	if ($out =~ m/^\$/) {
		my @storedhash = split(/\$/, $out);
		my $storedsalt = @storedhash[1];
		my $storedpass = @storedhash[2];
		my @saltpass = &_hash_password($storedsalt,$password);
		my $pass = $saltpass[1];
		if ($storedpass eq $pass) {
			&_hello($user);
			@pwent = ($user, $pass);
			&_main(@pwent);
			return;
		} else {
			&_wrong_pass;
		}
	} else {
		my $noSalthash = sha512_base64($password);

		if ($out eq $noSalthash) {
			my $salt = &_genSalt(128);
			my @salthash = &_hash_password($salt, $password);
			my $pass = '$'.@salthash[0].'$'.$salthash[1];

		        my $sth = $dbh->prepare("UPDATE user set pw_hash='$pass' WHERE username=?");
		        $sth->execute($user);

	                &_hello($user);
       		        @pwent = ($user, $pass);
                	&_main(@pwent);
                	return;
        	} else {
                	&_wrong_pass;
        	}
	} 

	#if ($out eq $pass) {
	#	&_hello($user);
	#	@pwent = ($user, $pass);
	#	&_main(@pwent);
	#	return;
	#} else {
	#	&_wrong_pass;
	#}
}

sub _hello {
	my $name = $_[0];
	print "\n\nHi $name ...\n\n";
	&_t2s("hi $name");
}

sub _wrong_pass {
	print "\n[NO_MATE] Wrong Login!!!\n";
	&_t2s(@t2s_badlogin);
	&_login;
}

sub _main {
	my $user = $_[0];
	&_banner;

	&_read_credit($user);

	my $selec = &_main_menu;
	print "SELECTION: $selec\n";
	if ($selec =~ m/^use/) {
		&_banner;
		my @param = ($user, $selec);
		&_use_drink(@param);
		&_breake;
	} elsif ($selec =~ m/^shoot/) {
		&_banner;
		my @param = ($user, $selec);
		&_load_plugin(@param);
		&_breake;
	} elsif ($selec eq "insert coins") {
		&_banner;
		&_add_coins;
		&_breake;
	} elsif ($selec eq "stats") {
		&_banner;
		&_read_stat($user);
		&_breake;
	} elsif ($selec eq "loscher stuff") {
		&_loscher_banner;
		&_loscher_menu;
		&_breake;
	} elsif ($selec eq "change password") {
		&_banner;
		&_change_pass($user, "0");
		&_breake;
	} elsif ($selec eq "Quit") {
		print "Bye Bye ...\n";
		&_t2s(@t2s_quit);
		&_login;
	}
	&_quit;
}

sub _quit {
	&_banner;
	my $quit = prompt 'Main Menu or Quit ...', -number, -timeout=>$timeout, -default=>'Quit', -menu => [
		'Main Menu',
		'Quit'], 'matomat>';
	if ($quit eq "Main Menu") {
		&_main;
	} else {
		print "Bye Bye ...\n";
		$dbh->disconnect();
		&_t2s(@t2s_quit);
		&_login;
	}
}

sub _loscher_breake {
        my $breake = prompt 'Losche Menu Mainn Menu or Quit ...', -number, -timeout=>$timeout, -default=>'Loscher Menu', -menu => [
		'Loscher Menu',
                'Main Menu',
                'Quit'], 'matomat>';
        if ($breake eq "Main Menu") {
                &_main;
	} elsif ($breake eq "Loscher Menu") {
		&_loscher_menu;
        } else {
                print "Bye Bye ...\n";
                &_t2s(@t2s_quit);
                &_login;
        }
}

sub _breake {
	my $breake = prompt 'Main Menu or Quit ...', -number, -timeout=>$timeout, -default=>'Main Menu', -menu => [
		'Main Menu',
		'Quit'], 'matomat>';
	if ($breake eq "Main Menu") {
		&_main;
	} else {
		print "Bye Bye ...\n";
		&_t2s(@t2s_quit);
		&_login;
	}
}

sub _main_menu {
	my @drinks;
	my @plugins;
	my @default = ("insert coins", "stats", "loscher stuff", "change password");

        my $sth = $dbh->prepare("SELECT name FROM drinks WHERE active=1");
        $sth->execute();
        my $out = $sth->fetchall_arrayref;

        my $result;
        foreach my $row (@$out) {
		($result) = @$row;
		push(@drinks, "use $result");
        }

	my $sth = $dbh->prepare("SELECT name FROM plugins WHERE active=1");
        $sth->execute();
        my $out = $sth->fetchall_arrayref;

        my $result;
        foreach my $row (@$out) {
                ($result) = @$row;
                push(@plugins, "shoot $result");
        }


	my $selec = prompt 'Choose wisely...', -number, -timeout=>$timeout, -default=>'Quit', -menu => [
                @drinks,
		@plugins,
		@default,
                'Quit'], 'matomat>';
}

sub _prompt_for_login {
	my $user = prompt 'User:' ;
	&_bad_input($user);
	my $passwd = prompt 'Password:', -echo=>'*';
	my @pwent = ($user, $passwd);
	return @pwent;
}

sub _read_credit {
	my $user = $_[0];
	&_bad_input($user);

        my $sth = $dbh->prepare("SELECT credits FROM user WHERE username=?");
        $sth->execute($user);
        my $out = $sth->fetchall_arrayref;

	my $result;
        foreach my $row (@$out) {
                ($result) = @$row;
        }
	print "Hi $user ... you have\n\n";
	my $credit=$result/100;
	$credit = sprintf("%.2f", $credit);
	print ~~$font->figify(-A=>"$credit credits");
	print "\n";
	if ($result =~ m/^-/) {
		print ~~$font->figify(-A=>"TIME2PAY!");
	                if ($result <= -1500) {
        	                &_t2s(@t2s_pay_minus15);
                        } elsif ($result <= -1000) {
                                &_t2s(@t2s_pay_minus10);
                        } elsif ($result <= -500) {
                                &_t2s(@t2s_pay_minus5);
                        }
	}
        print "\n\n\n";
}

sub _read_stat {
	my $user = $_[0];
	&_bad_input($user);
	my $userid;
	my $dname;
	my $credit;
	my $dout;

	# Get userid and credit
	my $sth = $dbh->prepare("SELECT credits,userid FROM user WHERE username=?");
        $sth->execute($user);
        my $out = $sth->fetchall_arrayref;

        foreach my $row (@$out) {
                ($credit,$userid) = @$row;
        }
	$credit=$credit/100;
	$credit = sprintf("%.2f", $credit);


        print "Hi $user ... you have\n\n";
        print ~~$font->figify(-A=>"$credit credits\n");

	# Get stats
	my $sth = $dbh->prepare("SELECT name FROM drinks WHERE active=1");
        $sth->execute();
        my $out = $sth->fetchall_arrayref;

        foreach my $row (@$out) {
                ($dname) = @$row;
		my $dtable=$dname."_stats";
		my $sth = $dbh->prepare("SELECT usage FROM $dtable WHERE userid=?");
        	$sth->execute($userid);
        	my $sout = $sth->fetchall_arrayref;
	
		foreach my $srow (@$sout) {
                	($dout) = @$srow;
			print ~~$font->figify(-A=>"$dname: $dout\n");
        	}
        }
	print "\n\n\n";
	&_t2s(@t2s_stats);
}

sub _use_drink {
	my $user = $_[0];
	&_bad_input($user);
	my $drink = $_[1];
	$drink=~s/use //;
	my $userid;
	my $usage;
	my $t2s;
	my $fixed;
	my $price;
	my $rate;

	my $sth = $dbh->prepare("SELECT userid FROM user WHERE username=?");
	$sth->execute($user);
	my $out = $sth->fetchall_arrayref;

        foreach my $row (@$out) {
                ($userid) = @$row;
        }

        my $sth = $dbh->prepare("SELECT price,fixed FROM drinks WHERE name=?");
        $sth->execute($drink);
        my $out = $sth->fetchall_arrayref;

        foreach my $row (@$out) {
                ($price,$fixed) = @$row;
        }

	if ($fixed == 1) {
		$rate = $price;
	} else {
		$rate = &_current_rate;
		$rate = $rate*100;
	}


        my $sth = $dbh->prepare("SELECT credits FROM user WHERE username=?");
        $sth->execute($user);
        my $out = $sth->fetchall_arrayref;

        my $result;
        foreach my $row (@$out) {
                ($result) = @$row;
        }

	my $credit=$result;
	$credit=$credit-$rate;

        my $ocredit=$credit/100;
        $ocredit = sprintf("%.2f", $ocredit);

	print "Hi $user ... your new credit is $ocredit \n\n";

        my $sth = $dbh->prepare("UPDATE user set credits='$credit' WHERE username=?");
        $sth->execute($user);

	my $dtable=$drink."_stats";
	# Get current stat
	my $sth = $dbh->prepare("SELECT usage FROM $dtable WHERE userid=?");
        $sth->execute($userid);
	my $out = $sth->fetchall_arrayref;

        foreach my $row (@$out) {
                ($usage) = @$row;
        }

	$usage=$usage+1;
	# Update stat 
	my $sth = $dbh->prepare("INSERT OR IGNORE INTO $dtable (userid, usage) VALUES (?,?)");
	$sth->execute($userid, $usage);

        my $sth = $dbh->prepare("UPDATE $dtable set usage='$usage' WHERE userid=?");
        $sth->execute($userid);

        if ($sth) {
                print "\n[MORE_MATE] Success\n\n";

        	# T2S stuff
        	my $sth = $dbh->prepare("SELECT t2s FROM drinks WHERE name=?");
        	$sth->execute($drink);
        	my $out = $sth->fetchall_arrayref;

		my @a;
       		foreach my $row (@$out) {
	                ($t2s) = @$row;
			@a = split(/,/, $t2s, 3);
        	}
        	&_t2s(@a);
                &_main;
        } else {
                print "\n[NO_MATE] Something failed!\n\n";
                sleep 3;
                &_main;
        }

	
}

sub _add_coins {
	my $user = $_[0];
	&_bad_input($user);

	# Get current credits
	my $sth = $dbh->prepare("SELECT credits FROM user WHERE username=?");
	$sth->execute($user);
        my $out = $sth->fetchall_arrayref;

	my $result;
        foreach my $row (@$out) {
                ($result) = @$row;
        }
	my $credit = $result;
	my $ocredit=$credit/100;
	$ocredit = sprintf("%.2f", $ocredit);

	print "Current Credit: $ocredit\n";
	my $coins = prompt "How much did you pay?\nmatomat> ", -integer;
	&_bad_input($coins);

	$coins=$coins*100;
	$credit=$credit+$coins;

	# Update credits
        my $sth = $dbh->prepare("UPDATE user set credits='$credit' WHERE username=?");
	$sth->execute($user);

	$credit=$credit/100;
	$credit = sprintf("%.2f", $credit);
	
	if ($sth) {
		print "ok\n";
		print "New Credit: $credit\n";
	} else {
		print "fail\n";
	}

	&_t2s(@t2s_credits);
}

sub _loscher_menu {
	my $user = $_[0];
	&_bad_input($user);

	my $sth = $dbh->prepare("SELECT privs FROM user WHERE username=?");
        $sth->execute($user);
        my $out = $sth->fetchall_arrayref;

	my $result;
        foreach my $row (@$out) {
                ($result) = @$row;
        }

	if ($result == "1") {
		print "Hi Master aka $user ...\n\n";
		my $choice = prompt 'Add User or Back to Main ...', -number, -timeout=>$timeout, -default=>'Main Menu', -menu => [
                                        'Add User', 'Change Password', 'Show User', 'Add Drink', 'Edit Drink','Delete Drink', 'Plugins',
                                        'Main Menu'], 'matomat>';

			if ($choice eq "Add User") {
		                &_add_user;
			} elsif ($choice eq "Show User") {
				&_show_user;
				&_loscher_breake;
			} elsif ($choice eq "Add Drink") {
				&_add_drink;
			} elsif ($choice eq "Edit Drink") {
                                &_edit_drink;
                        } elsif ($choice eq "Delete Drink") {
                                &_delete_drink
			} elsif ($choice eq "Plugins") {
				&_plugins
	                } elsif ($choice eq "Change Password") {
        	                my $username = prompt "Change password of user: ";
				&_bad_input($username);
                        	&_change_pass($username, "1");
               		} else {
                        	&_main;
                	}
                } else {
			print "\n[NO_MATE] You don't have loscher rights!!!\n";
                        sleep 2;
                        &_main;
	} 
}

sub _add_user {
	my $auser = prompt 'Enter Username:';
	&_bad_input($auser);
	my $apass = prompt 'Enter Password:', -echo=>'*';
	my $hashpass = sha512_base64($apass);
	my $startcredit = prompt 'Start credits:', -i;
	&_bad_input($startcredit);
	$startcredit=$startcredit*100;
	my $aflag;
	my $changepass;

	if ( prompt "Is this a Admin User?", -YN ) {
		$aflag = "1";
	} else {
		$aflag = "0";
	}
	
        if ( prompt "Force Password change?", -YN ) {
                $changepass = "1";
        } else {
                $changepass = "0";
        }

	my $rfid_id = prompt 'Enter RFID ID:', -i;

        # Get usernames
        my $sth = $dbh->prepare("SELECT username FROM user");
        $sth->execute();
        my $out = $sth->fetchall_arrayref;

        my $result;
        foreach my $row (@$out) {
                ($result) = @$row;
		if ($result =~ m/^$auser/) {
			print "\n[NO_MATE] Sorry ... User already exists in matomatdb!!\n\n";
			&_loscher_menu;
		}
        }

        # Add new user
        my $sth = $dbh->prepare("INSERT into user (username, pw_hash, pw_change, rfid_id, privs, credits) values(?,?,?,?,?,?)");
        $sth->execute($auser, $hashpass, $changepass, $rfid_id, $aflag, $startcredit);

	$auser = "";
	$apass = "";
	$hashpass = "";
	$startcredit = "";
	$aflag = "";
	$changepass = "";
	$rfid_id = "";
}

sub _change_pass {
	my ($user, $admin) = @_;
	&_bad_input($user);
	my $apass = "";
	my $hashpass = "";

	print "Changing password for user: $user\n\n";

	if ($admin eq "0") {
		$apass = prompt 'Enter current password:', -echo=>'*';

	        my $sth = $dbh->prepare("SELECT pw_hash FROM user WHERE username=?");
	        $sth->execute($user);
        	my $out = $sth->fetchall_arrayref;

                foreach my $row (@$out) {
                        ($out) = @$row;
                }

                my @storedhash = split(/\$/, $out);
                my $storedsalt = @storedhash[1];
                my $storedpass = @storedhash[2];
                my @saltpass = &_hash_password($storedsalt,$apass);
                my $pass = $saltpass[1];

        	if ($storedpass ne $pass) {
			print "\n[NO_MATE] Your current password is not correct\n\n";
			sleep 3;
                        &_change_pass($user, $admin);
        	}
	}
	my $npass = prompt 'Enter new password:', -echo=>'*';
	my $dpass = prompt 'Again new password:', -echo=>'*';

	if ($npass ne $dpass) {
		print "\n[NO_MATE] Passwords differ... LEARN TO TYPE!\n\n";
		sleep 3;
		&_change_pass($user, $admin);
	}

        my $salt = &_genSalt(128);
        my @salthash = &_hash_password($salt, $npass);
        my $pass = '$'.@salthash[0].'$'.$salthash[1];

        my $sth = $dbh->prepare("UPDATE user set pw_hash='$pass' WHERE username=?");
        $sth->execute($user);

        if ($sth) {
		print "\n[MORE_MATE] Password change successful!\n\n";
		sleep 3;
		&_main;
        } else {
		print "\n[NO_MATE] Something failed!\n\n";
		sleep 3;
		&_main;
        }
}

sub _show_user {
	# Temp Function
	my @users;
	my $privs;
	my $credits;
        # Get usernames
        my $sth = $dbh->prepare("SELECT username FROM user");
        $sth->execute();
        my $out = $sth->fetchall_arrayref;

        my $result;
        foreach my $row (@$out) {
                ($result) = @$row;
		push(@users, $result);
        }
        my $selec = prompt 'Seclect User...', -number, -timeout=>$timeout, -default=>'Quit', -menu => [@users], 'matomat>'; 

	# Get current credits
        my $sth = $dbh->prepare("SELECT privs, credits FROM user WHERE username=?");
        $sth->execute($selec);
        my $out = $sth->fetchall_arrayref;

        my $result;
        foreach my $row (@$out) {
                ($privs,$credits) = @$row;
        }
	print "User $selec has Privs: $privs and Credits: $credits\n";
}

sub _add_drink {
	my $active;
	my $fixed;
	my $dname = prompt "Name of the drink: ";	
	&_bad_input($dname);
	my $dprice = prompt "Price of the drink (e.g. 100 = 1,00 EUR) :", -i;
	&_bad_input($dprice);
	my $t2s = prompt "t2s output: (e.g. Cheers, hmm tasty) :";
	&_bad_input($t2s);

        if ( prompt "Activate the drink?", -YN ) {
                $active = "1";
        } else {
                $active = "0";
        }

	if ( prompt "Is the price fixed?", -YN ) {
                $fixed = "1";
        } else {
                $fixed = "0";
        }


        my $sth = $dbh->prepare("SELECT name FROM drinks");
        $sth->execute();
        my $out = $sth->fetchall_arrayref;

        my $result;
        foreach my $row (@$out) {
                ($result) = @$row;
		if($result eq $dname) {
			print "[NO_MATE] Name already in use\n";
			sleep 3;
			&_loscher_menu;
		}
        }

        my $sth = $dbh->prepare("INSERT into drinks (name, price, active, fixed, t2s) values(?,?,?,?,?)");
        $sth->execute($dname, $dprice, $active, $fixed, $t2s);
	
	$dname=$dname."_stats";
	my $sth = $dbh->do("CREATE TABLE $dname (userid INTEGER UNIQUE, usage INT, FOREIGN KEY(userid) REFERENCES user(userid))");
	if($sth){
		print "[MORE_MATE] Success\n";
	} else {
		print "[NO_MATE] Something went wrong... $DBI::errstr\n";
	}
}

sub _edit_drink {
        my @drinks;

        my $sth = $dbh->prepare("SELECT name FROM drinks");
        $sth->execute();
        my $out = $sth->fetchall_arrayref;

        my $result;
        foreach my $row (@$out) {
                ($result) = @$row;
                push(@drinks, "$result");
        }

        my $selec = prompt 'Select Drink to edit...', -number, -timeout=>$timeout, -default=>'Quit', -menu => [
                @drinks,
                'Go To Main Menu',
                'Quit'], 'matomat>';

        if ($selec eq "Go To Main Menu") {
                &_main;
        } elsif ($selec eq "Quit") {
                print "Bye Bye ...\n";
                &_t2s(@t2s_quit);
                &_login;
        } else {
		my $active;
		my $fixed;
        	my $dprice = prompt "Price of the drink (e.g. 100 = 1,00 EUR) :",-i;
		&_bad_input($dprice);
        	my $t2s = prompt "t2s output: (e.g. \"Cheers\", \"hmm tasty\") :";
		&_bad_input($t2s);
	        if ( prompt "Activate the drink?", -YN ) { 	
       		        $active = "1";
        	} else {
               		$active = "0";
        	}

	        if ( prompt "Is the price fixed?", -YN ) {
       			$fixed = "1";
        	} else {
                	$fixed = "0";
        	}


		my $sth = $dbh->prepare("UPDATE drinks set price='$dprice', active='$active', fixed='$fixed' t2s='$t2s' WHERE name='$selec'");
        	$sth->execute();

                if($sth){
                        print "[MORE_MATE] Success\n";
                } else {
                        print "[NO_MATE] Something went wrong... $DBI::errstr\n";
                }
        }
}

sub _delete_drink {
        my @drinks;

        my $sth = $dbh->prepare("SELECT name FROM drinks");
        $sth->execute();
        my $out = $sth->fetchall_arrayref;

        my $result;
        foreach my $row (@$out) {
                ($result) = @$row;
                push(@drinks, "$result");
        }

        my $selec = prompt 'Select Drink to delete...', -number, -timeout=>$timeout, -default=>'Quit', -menu => [
                @drinks,
		'Go To Main Menu',
                'Quit'], 'matomat>';
	
	if ($selec eq "Go To Main Menu") {
		&_main;
        } elsif ($selec eq "Quit") {
                print "Bye Bye ...\n";
                &_t2s(@t2s_quit);
                &_login;
        } else {
	        if ( prompt "Do you realy want to delete this drink?", -YesNo ) {
		        my $dname=$selec."_stats";
			my $sth = $dbh->do("DROP TABLE $dname");
			my $sth = $dbh->do("DELETE from drinks WHERE name='$selec'");

        		if($sth){
				print "[MORE_MATE] Success\n";
			} else {
				print "[NO_MATE] Something went wrong... $DBI::errstr\n";
        		}
        	} else {
			&_loscher_menu;
		}
        }
}

sub _plugins {
	my @plugins;
	my $aflag;
        my $sth = $dbh->prepare("SELECT name FROM plugins");
        $sth->execute();
        my $out = $sth->fetchall_arrayref;

        my $result;
        foreach my $row (@$out) {
                ($result) = @$row;
                push(@plugins, "disable or enable $result");
        }

	my $selec = prompt "Plugins...", -number, -timeout=>$timeout, -default=>'Go To Main Menu', -menu => [
		'Import Plugin',
		@plugins,
		'Go To Main Menu',
		'Quit'], 'matomat>';

        if ($selec eq "Go To Main Menu") {
                &_main;
        } elsif ($selec eq "Quit") {
                print "Bye Bye ...\n";
                &_t2s(@t2s_quit);
                &_login;
        } elsif ($selec eq "Import Plugin") {
		# XXX FIX!!!
		my $files = `ls $pluginpath`;
		my $selec = prompt "Select the Plugin...", -number, -timeout=>$timeout, -default=>'Go To Main Menu', -menu=>$files => [
			'Go To Main Menu',
                	'Quit'], 'matomat>';

		if ($selec eq "Go To Main Menu") {
			&_main;
		} elsif ($selec eq "Quit") {
			print "Bye Bye ...\n";
			&_t2s(@t2s_quit);
			&_login;
		} else {
	        	my $pluginname = prompt "Name of the Plugin: ";
        		&_bad_input($pluginname);

			my $sth = $dbh->prepare("INSERT OR IGNORE INTO plugins (name, filename, active) VALUES (?,?,0)");
	        	$sth->execute($pluginname, $pluginpath.$selec);

			print $selec."\n";
		}
	} else {
		my $name;
		my $filename;
		my $active;
		$selec=~s/disable or enable //;

		print "\n$selec Setting ...\n";
		my $sth = $dbh->prepare("SELECT name,filename,active FROM plugins WHERE name=?");
		$sth->execute($selec);
		my $out = $sth->fetchall_arrayref;

		my $result;
		foreach my $row (@$out) {
			($name, $filename, $active) = @$row;
		}
		print "Name: $name\nFilename: $filename\nActive: $active\n\n";
		if ($active == 0) {
			if ( prompt "Do you want to activate this plugin?", -YN) {
				$aflag = "1";
			} else {
				$aflag = "0";
			}
		} elsif ($active == 1) {
			if ( prompt "Do you want to deactivate this plugin?", -YN) {
                                $aflag = "0";
                        } else {
                                $aflag = "1";
                        }
		}
	        my $sth = $dbh->prepare("UPDATE plugins set active='$aflag' WHERE name=?");
       		$sth->execute($selec);
	}
}

sub _load_plugin {
        my $user = $_[0];
        &_bad_input($user);
        my $plugin = $_[1];
        $plugin=~s/shoot //;
	my $filename;

	my $sth = $dbh->prepare("SELECT filename FROM plugins WHERE name=?");
	$sth->execute($plugin);
	my $out = $sth->fetchall_arrayref;

	my $result;
        foreach my $row (@$out) {
	        ($filename) = @$row;
        }

	load $filename;
	delete $INC{"$filename"};
}

sub _current_rate {
	# Only if the default price is 1,00 EUR/$
	my $full_credit=0;
	my $cash=0;
	my $credit;

	if ($rtrate == 0) {
		my $rate = 1;
		$rate = sprintf("%.2f", $rate);
		return $rate;
	}

	my $cusers = $dbh->selectrow_array("SELECT COUNT(*) FROM user",  undef);
	#print $cusers."\n";

        my $sth = $dbh->prepare("SELECT credits FROM user");
        $sth->execute();
        my $out = $sth->fetchall_arrayref;

        foreach my $row (@$out) {
                ($credit) = @$row;
		$full_credit=$full_credit+$credit;
        }
        $full_credit=$full_credit/100;
        $full_credit = sprintf("%.2f", $full_credit);


	my $cashrate=$full_credit/$cusers*2;
	$cashrate = sprintf("%.0f", $cashrate);
	my $rate = 100-$cashrate;
	$rate = $rate/100;
	$rate = sprintf("%.2f", $rate);

	return $rate;
}

sub _bad_input {
	my $string = $_[0];
	chomp($string);
	
	if ($string !~ /^[a-zA-Z0-9\s,]*$/) {
		print "[NO_MATE] BAD Character detected! Use [a-zA-Z0-9]\n";
                &_t2s("try harder!");
		sleep 3;
                &_login;
	}
		
		
}

sub _hash_password {
	my @arg = @_;
	my $salt = @arg[0];
	my $password = @arg[1];
	my $string = $salt.$password;	
	my $hash = sha512_base64($string);
	my $i = 0;

	# Over 9000
	while ($i < 9001) {
		$hash = sha512_base64($hash);
		$i++;
	}
	return($salt, $hash);
}

sub _genSalt
{
    my $saltsize = shift;
    my @char = ('a'..'z', 'A'..'Z', 0..9);
    my $randsalt = join '',
           map $char[rand @char], 0..$saltsize;

    return $randsalt;
}

