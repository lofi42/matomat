#!/usr/bin/perl

package plugins::count;
use Exporter 'import';

use IO::Prompter;
use Net::SMTP;
use Matomat::Config;
use Matomat::T2S;
use Matomat::DBConnect;

my $sth = $dbh->prepare("SELECT date,count FROM plugin_count WHERE sent=0");
$sth->execute();
my $out = $sth->fetchall_arrayref;

print "The following Stats are not send right now!\n\n";

if (!@$out) {
	print "[-] No unsend stats\n";
}

foreach my $row (@$out) {
	($date,$count) = @$row;
	print "Date: $date => $count\n";
}

print "\n";

&_main;

sub _main {
my $choice = prompt 'Counter Plugin', -number, -timeout=>$timeout, -default=>'Back', -menu => [
		    'Enter count for today', 'Send unsend stats', 'Back'], 'matomat>';

		if ($choice eq "Enter count for today") {
			&_count;
			&_main;
		} elsif ($choice eq "Send unsend stats") {
			&_send;
			&_main;
		} else {
			1;
		}
}

sub _count {
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	my $day = $mday;
	my $mon = $mon+1;
	my $yea = $year+1900;
	my $date = $day.".".$mon.".".$yea;
	my $sent = 0;

	my $count = prompt 'How many people are here today?', -i;

	print "Today: $date => $count People $sent?\n";
        if ( prompt "Is this ok?", -YN ) {
		my $sth = $dbh->prepare("INSERT OR IGNORE INTO plugin_count (date,count,sent) VALUES (?,?,?)");
		$sth->execute($date, $count, $sent);
        } else {
		return;
        }
}

sub _send {

	my $countrcpt = $cfg->param('plugin_count.to');
	my $countfrom = $cfg->param('plugin_count.from');
	my $counthost = $cfg->param('plugin_count.smtphost');
	my $countcc = $cfg->param('plugin_count.cc');

	my $sth = $dbh->prepare("SELECT date,count FROM plugin_count WHERE sent=0");
	$sth->execute();
	my $out = $sth->fetchall_arrayref;

	print "The following Stats are not send right now!\n\n";

	if (!@$out) {
        	print "[-] No unsend stats\n\n";
		&_main;
	}

	foreach my $row (@$out) {
        	($date,$count) = @$row;
        	print "Date: $date => $count\n";
	}

	print "\nRCPT: $countrcpt\n";
	print "CC:   $countcc\n\n";
	
        if ( prompt "Do you realy want to send the stats now?", -YN ) {

		$smtp = Net::SMTP->new("$counthost") or die "[-] Mail could not be send!\n";
		$smtp->mail("$countfrom");
		$smtp->to("$countrcpt");
		$smtp->cc("$countcc");
	
		$smtp->data();
		$smtp->datasend("To: $countrcpt\n");
		$smtp->datasend("Cc: $countcc\n");
		$smtp->datasend("From: $countfrom\n");
		$smtp->datasend("Subject: K4CG Besucherzahlen TEST\n");
		$smtp->datasend("\n");
		$smtp->datasend("Hier die letzten Besucherzahlen\n\n");
		foreach my $row (@$out) {
        	        ($date,$count) = @$row;
        	        $smtp->datasend("Date: $date => $count\n");
        	}
		$smtp->dataend();
		$smtp->quit;

		my $sth = $dbh->prepare("UPDATE plugin_count set sent='1' WHERE sent=0");
		$sth->execute();
	} else {
		return;
	}
	
}
1;
