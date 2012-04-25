#!/usr/bin/perl
##############################################################

use strict;
use DBI;
use IO::Prompter;
use Text::FIGlet;
use Digest::SHA qw(sha512 sha512_base64 sha512_hex);
use Term::ReadKey;
use Config::Simple;

$ENV{'PATH'} = '/bin:/usr/bin';

my $cfg = new Config::Simple('/etc/matomat.cfg') or die "[NO_MATE] Config File not found\n";
my @t2s_badlogin = $cfg->param('t2s.badlogin');
my @t2s_pay_minus5 = $cfg->param('t2s.pay_minus5');
my @t2s_pay_minus10 = $cfg->param('t2s.pay_minus10');
my @t2s_pay_minus15 = $cfg->param('t2s.pay_minus15');
my @t2s_quit = $cfg->param('t2s.quit');
my @t2s_stats = $cfg->param('t2s.stats');
my @t2s_credits = $cfg->param('t2s.credits');
my $echobin = $cfg->param('global.echo');
my $festivalbin = $cfg->param('global.festival');
my $clear_string = $cfg->param('global.clear');
my $dbfile = $cfg->param('global.database');
my $font = Text::FIGlet->new(-m=>-1,-f=>$cfg->param('global.font'));
my $timeout = $cfg->param('global.timeout');
my $rtrate = $cfg->param('global.realtime');

my $dbargs = {AutoCommit => 1, PrintError => 1, foreign_keys => 1};
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "", $dbargs);
$dbh->do("PRAGMA foreign_keys = ON");

if ($dbh->err()) { die "[NO_MATE] DB Error $DBI::errstr\n"; }
$dbh->commit();

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

	my $pw_hash;
	my $pass = sha512_base64($password);

	my $sth = $dbh->prepare("SELECT pw_hash FROM user WHERE username=?");
	$sth->execute($user);
	my $out = $sth->fetchall_arrayref;

	foreach my $row (@$out) {
		($out) = @$row;
	}

	if ($out eq $pass) {
		&_hello($user);
		@pwent = ($user, $pass);
		&_main(@pwent);
		return;
	} else {
		&_wrong_pass;
	}
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
	my @default = ("insert coins", "stats", "loscher stuff", "change password");

        my $sth = $dbh->prepare("SELECT name FROM drinks WHERE active=1");
        $sth->execute();
        my $out = $sth->fetchall_arrayref;

        my $result;
        foreach my $row (@$out) {
		($result) = @$row;
		push(@drinks, "use $result");
        }
	my $selec = prompt 'Choose wisely...', -number, -timeout=>$timeout, -default=>'Quit', -menu => [
                @drinks,
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
                                        'Add User', 'Change Password', 'Show User', 'Add Drink', 'Edit Drink','Delete Drink',
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

	if ( prompt "Is this a Admin User?", -YN ) {
		$aflag = "1";
	} else {
		$aflag = "0";
	}

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
        my $sth = $dbh->prepare("INSERT into user (username, pw_hash, privs, credits) values(?,?,?,?)");
        $sth->execute($auser, $hashpass, $aflag, $startcredit);

	$auser = "";
	$apass = "";
	$hashpass = "";
	$startcredit = "";
	$aflag = "";
}

sub _change_pass {
	my ($user, $admin) = @_;
	&_bad_input($user);
	my $apass = "";
	my $hashpass = "";

	print "Changing password for user: $user\n\n";

	if ($admin eq "0") {
		$apass = prompt 'Enter current password:', -echo=>'*';
		$hashpass = sha512_base64($apass);

	        my $sth = $dbh->prepare("SELECT pw_hash FROM user WHERE username=?");
	        $sth->execute($user);
        	my $out = $sth->fetchall_arrayref;

        	foreach my $row (@$out) {
                	($out) = @$row;
        	}

        	if ($out ne $hashpass) {
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
	my $newhash = sha512_base64($npass);

        my $sth = $dbh->prepare("UPDATE user set pw_hash='$newhash' WHERE username=?");
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

sub _t2s {
	my @text = @_;
	my $arrCnt = scalar(@text);
	my $rand = rand($arrCnt);
	system("$echobin $text[$rand] | $festivalbin --tts");
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

sub _banner {
	print `$clear_string`;
	print STDOUT << "EOF";
============================================================================
 __    __     ______     ______   ______     __    __     ______     ______
/\\ "-./  \\   /\\  __ \\   /\\__  _\\ /\\  __ \\   /\\ "-./  \\   /\\  __ \\   /\\__  _\\
\\ \\ \\-./\\ \\  \\ \\  __ \\  \\/_/\\ \\/ \\ \\ \\/\\ \\  \\ \\ \\-./\\ \\  \\ \\  __ \\  \\/_/\\ \\/
 \\ \\_\\ \\ \\_\\  \\ \\_\\ \\_\\    \\ \\_\\  \\ \\_____\\  \\ \\_\\ \\ \\_\\  \\ \\_\\ \\_\\    \\ \\_\\
  \\/_/  \\/_/   \\/_/\\/_/     \\/_/   \\/_____/   \\/_/  \\/_/   \\/_/\\/_/     \\/_/

============================================================================

EOF
}

sub _login_banner {
	print `$clear_string`;
	print STDOUT << "EOF";
                                    =?I777777II?????II777777?=
                               7777?                           I777?
                          I77I     I77               =777777777+     I77=
                      =77I    ?777777=                I7777777777777+   =77+
                   =77=   I7777777777                  77777777777777777+   77?
                 ?77   I7777777777777                  =7777777777777777777   ?77
               77=  I777777777777777?                   7777777777777777777777   77=
             ?7I  ?77777777777777777                     77777777777777777777777   77
           +77  77777777777777777777                     7777777777777777777777777   77
          77   777777777777777777777                      77777777777777777777777777  +7=
         77  77777777777777777777777                      777777777777777777777777777+  77
       I7   777777777777777777777777                          +7777777777777I+= +777777  77
      =7   77777777777777777777?=                   +?77777777777?             ?77777777  77
      7   7777777777=          =7777777777777777777777777=                  7777777777777  7I
     77  77777+                      ==+????++=                         I7777777777777777?  7
    I7  77777777I+                    ?77    ?777?+?7777+       +I777777777777777777777777  77
    7I  77777777777777777777777777    7777   777777777777  = 777777777777777777777777777777  7
    7  77777777777777777777777777+      ?  7 I=777777777 777 =77777777777777777777777777777  77
   77  77777777777777777777777777=777        =+==   I7777 7+ 777777777777777777777777777777  +7
   77  77777777777777777777777777 I? 77         77777=7777777777777777777777777777777777777?  7
   77  77777777777777777777777777777777=   777777777+?77777777777777I7777777777II7777777777I  7
   77  77777777777777777777777777    I       777777 ?777777777777777+7777777777 77777777777+ =7
   ?7  77777777777777777777777?                 77+ 7777777777777777=7777+7777+777777777777  I7
    7  ?777777777777777777I                     +7   =77777777777777+7777 7777 777777777777  7?
    77  777777777777777                                 77777777777+77777 77 I=77777777777+  7
     7  +777777777777                                     777777777 777=77+77I777777777777  7I
     77  I777777777                                        +7777=77=777?=777 777777777777  I7
      77  7777777                                            7 777=?777777? I77777777777=  7
       77  I777                                              77777777777    77777777777   7
        77  ?                                              ?777777777777I  77777777777   7
         ?7                                               777777777777777I77777777777  77
           77                                             777777777777I==I777777777=  7I
            +7+                                           77777      ?77777777777+  77
              +7+                                         777         ?77777777   77
                77=                                       77           +77777   77=
                   77                                                    7   I7?
                     77I                                                   77
                        +77?                                           77I
                            +77I                                  =777=
                                  7777I+                   ?7777+
                                          ++?IIII7III??+=
EOF
}

sub _loscher_banner {
	print `$clear_string`;
	print STDOUT << "EOF";
============================================================================
 __         ______     ______     ______     __  __     ______     ______
/\\ \\       /\\  __ \\   /\\  ___\\   /\\  ___\\   /\\ \\_\\ \\   /\\  ___\\   /\\  == \\
\\ \\ \\____  \\ \\ \\/\\ \\  \\ \\___  \\  \\ \\ \\____  \\ \\  __ \\  \\ \\  __\\   \\ \\  __<
 \\ \\_____\\  \\ \\_____\\  \\/\\_____\\  \\ \\_____\\  \\ \\_\\ \\_\\  \\ \\_____\\  \\ \\_\\ \\_\\
  \\/_____/   \\/_____/   \\/_____/   \\/_____/   \\/_/\\/_/   \\/_____/   \\/_/ /_/

============================================================================

EOF
}
