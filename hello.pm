#!/usr/bin/perl

package plugins::hello;
use Exporter 'import';

use Matomat::Config;
use Matomat::T2S;

print "Hello World\n";
&_t2s("Hello World");
1;
