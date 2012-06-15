#!/usr/bin/perl

package Matomat::Config;
use Exporter 'import';
@ISA         = qw(Exporter);
@EXPORT = qw($dbfile $echobin $festivalbin $clear_string $pluginpath $font $timeout $rtrate @t2s_credits @t2s_stats @t2s_quit @t2s_pay_minus15 @t2s_pay_minus10 @t2s_pay_minus5 @t2s_badlogin);

use Config::Simple;

my $cfg = new Config::Simple('/etc/matomat.cfg') or die "[NO_MATE] Config File not found\n";
our @t2s_badlogin = $cfg->param('t2s.badlogin');
our @t2s_pay_minus5 = $cfg->param('t2s.pay_minus5');
our @t2s_pay_minus10 = $cfg->param('t2s.pay_minus10');
our @t2s_pay_minus15 = $cfg->param('t2s.pay_minus15');
our @t2s_quit = $cfg->param('t2s.quit');
our @t2s_stats = $cfg->param('t2s.stats');
our @t2s_credits = $cfg->param('t2s.credits');
our $echobin = $cfg->param('global.echo');
our $festivalbin = $cfg->param('global.festival');
our $clear_string = $cfg->param('global.clear');
our $dbfile = $cfg->param('global.database');
our $pluginpath = $cfg->param('global.pluginpath');
our $font = Text::FIGlet->new(-m=>-1,-f=>$cfg->param('global.font'));
our $timeout = $cfg->param('global.timeout');
our $rtrate = $cfg->param('global.realtime');
1;
