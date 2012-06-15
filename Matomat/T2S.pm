#!/usr/bin/perl

package Matomat::T2S;
use Exporter 'import';
@EXPORT = qw(_t2s);

use Matomat::Config;

sub _t2s {
        my @text = @_;
        my $arrCnt = scalar(@text);
        my $rand = rand($arrCnt);
        system("$echobin $text[$rand] | $festivalbin --tts");
}
