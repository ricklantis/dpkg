#!/usr/bin/perl
#
# dselect - Debian package maintenance user interface
# mkcurkeys.pl - generate strings mapping key names to ncurses numbers
#
# Copyright © 1995 Ian Jackson <ian@chiark.greenend.org.uk>
#
# This is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

$#ARGV == 1 || die('usage: mkcurkeys.pl <filename> <curses.h>');

my (%over, %base, %name);

open(my $override_fh, '<', $ARGV[0]) || die $!;
while (<$override_fh>) {
    chomp;
    /^#/ && next;		# skip comments
    /\S/ || next;		# ignore blank lines
    /^(\w+)\s+(\S.*\S)\s*$/ || die ("cannot parse line:\n$_\n");
    $over{$1}= $2;
    $base{$1}= '';
}
close($override_fh);

my $let = 'A';
for my $i (1 .. 26) {
    $name{$i}= "^$let";
    $base{$i}= '';
    $let++;
}

our ($k, $v);

open(my $header_fh, '<', $ARGV[1]) || die $!;
while (<$header_fh>) {
    s/\s+$//;
    m/#define KEY_(\w+)\s+\d+\s+/ || next;
    my $rhs = $';
    $k= "KEY_$1";
    $_= $1;
    capit();
    $base{$k}= $_;
    $_= $rhs;
    s/(\w)[\(\)]/$1/g;
    s/\w+ \((\w+)\)/$1/;
    next unless m|^/\* (\w[\w ]+\w) \*/$|;
    $_= $1;
    s/ key$//;
    next if s/^shifted /shift / ? m/ .* .* / : m/ .* /;
    capit();
    $name{$k}= $_;
}
close($header_fh);

printf(<<'END') || die $!;
/*
 * WARNING - THIS FILE IS GENERATED AUTOMATICALLY - DO NOT EDIT
 * It is generated by mkcurkeys.pl from <curses.h>
 * and keyoverride.  If you want to override things try adding
 * them to keyoverride.
 */

END

my ($comma);

for my $i (33 .. 126) {
    $k= $i;
    $v = pack('C', $i);
    if ($v eq ',') { $comma=$k; next; }
    p();
}

## no critic (BuiltinFunctions::ProhibitReverseSortBlock)
for $k (sort {
    looks_like_number($a) ?
        looks_like_number($b) ? $a <=> $b : -1
            : looks_like_number($b) ? 1 :
                $a cmp $b
                } keys %base) {
    ## use critic
    $v= $base{$k};
    $v= $name{$k} if defined($name{$k});
    $v= $over{$k} if defined($over{$k});
    next if $v eq '[elide]';
    p();
}

for my $i (1 .. 63) {
    $k= "KEY_F($i)"; $v= "F$i";
    p();
}

$k = $comma;
$v = ',';
p();

print(<<'END') || die $!;
  { -1,              0                    }
END

close(STDOUT) || die $!;
exit(0);

sub capit {
    my $o = '';
    y/A-Z/a-z/;
    $_ = " $_";
    while (m/ (\w)/) {
        $o .= $`.' ';
        $_ = $1;
        y/a-z/A-Z/;
        $o .= $_;
        $_ = $';
    }
    $_= $o.$_; s/^ //;
}

sub p {
    $v =~ s/["\\]/\\$&/g;
    printf("  { %-15s \"%-20s },\n",
           $k.',',
           $v.'"') || die $!;
}
