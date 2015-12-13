#!/usr/bin/perl -w
use strict;
use utf8;
binmode STDOUT, ':utf8';

my $count = 0;

my @rowdata = (
[7,3,1,1,7],
[1,1,2,2,1,1],
[1,3,1,3,1,1,3,1],
[1,3,1,1,6,1,3,1],
[1,3,1,5,2,1,3,1],
[1,1,2,1,1],
[7,1,1,1,1,1,7],
[3,3],
[1,2,3,1,1,3,1,1,2],
[1,1,3,2,1,1],
[4,1,4,2,1,2],
[1,1,1,1,1,4,1,3],
[2,1,1,1,2,5],
[3,2,2,6,3,1],
[1,9,1,1,2,1],
[2,1,2,2,3,1],
[3,1,1,1,1,5,1],
[1,2,2,5],
[7,1,2,1,1,1,3],
[1,1,2,1,2,2,1],
[1,3,1,4,5,1],
[1,3,1,3,10,2],
[1,3,1,1,6,6],
[1,1,2,1,1,2],
[7,2,1,2,5],

[7,2,1,1,7],
[1,1,2,2,1,1],
[1,3,1,3,1,3,1,3,1],
[1,3,1,1,5,1,3,1],
[1,3,1,1,4,1,3,1],
[1,1,1,2,1,1],
[7,1,1,1,1,1,7],
[1,1,3],
[2,1,2,1,8,2,1],
[2,2,1,2,1,1,1,2],
[1,7,3,2,1],
[1,2,3,1,1,1,1,1],
[4,1,1,2,6],
[3,3,1,1,1,3,1],
[1,2,5,2,2],
[2,2,1,1,1,1,1,2,1],
[1,3,3,2,1,8,1],
[6,2,1],
[7,1,4,1,1,3],
[1,1,1,1,4],
[1,3,1,3,7,1],
[1,3,1,1,1,2,1,1,4],
[1,3,1,4,3,3],
[1,1,2,2,2,6,1],
[7,1,3,2,1,1]
);

my @known;
push @known, [(undef) x 25] for 1 .. 25;
$known[3][$_] = 1 for (3,4,12,13,21);
$known[8][$_] = 1 for (6,7,10,14,15,18);
$known[16][$_] = 1 for (6,11,16,20);
$known[21][$_] = 1 for (3,4,9,10,15,20,21);

my @solutionrows;

foreach my $row (@rowdata) {
  my $sum;
  $sum += $_ for @$row;                          # sum of black squares
  my @gaps = (26-$sum-@$row,(1)x(@$row-1),0);    # initialize white squares most leftmost

  my @solutionrow;
  &shuffle($row, \@gaps, 1, \@solutionrow);

  push @solutionrows, \@solutionrow;
}

print "$count\n";

# Iterative Cull
my $lastcount = 0;
while (1) {
  #first cull solutions which do not fit known black squares
  for (my $row=0;$row<50;$row++) {
    for (my $solution=0; $solution < scalar @{$solutionrows[$row]}; $solution++) {
      for (my $i=0; $i < 25; $i++) {
        my $k=($row<25)?(\$known[$row][$i]):(\$known[$i][$row-25]);
        if (defined($$k) and $$k != $solutionrows[$row][$solution][$i]) {
          splice(@{$solutionrows[$row]}, $solution, 1);
          $solution--; #move index back one after deleting element
          $count--; #update approx solution space count
          last;
        }
      }
    }
  }

  exit if ($lastcount == $count); # no more solutions culled since last pass
  $lastcount = $count;

  #then determine squares which have only one solution based on row-by-row analysis
  for (my $row=0;$row<50;$row++) {
    next if ((scalar @{$solutionrows[$row]})==0);
    my @sum = (0)x25;
    for (my $solution=0; $solution < scalar @{$solutionrows[$row]}; $solution++) {
      $sum[$_] += $solutionrows[$row][$solution][$_] for (0 .. 24);
    }
    for (my $i=0; $i < 25; $i++) {
      my $k=($row<25)?(\$known[$row][$i]):(\$known[$i][$row-25]);
      $$k=$solutionrows[$row][0][$i] if (($sum[$i]==0) or ($sum[$i]==scalar @{$solutionrows[$row]}));
    }
  }
  
  print "$count\n";
  print join('', map{defined($_)?(($_==1)?"\x{2588}"x2:'  '):"\x{2591}"x2 } @{$_})."\n" for @known;

  #repeat this process until we've culled all we can
}

#see how many are left... then decide how to:
#traverse all possible remaining combinations recursively, elliminating those not compatible with other solutions

sub shuffle {
  my $row = shift;
  my $gaps = shift;
  my $depth = shift;
  my $solutions = shift;

  my @rowraw;
  push @rowraw, ((0)x($$gaps[$_]),(1)x($row->[$_])) for (0 .. $#{$row});
  push @rowraw, (0)x($$gaps[-1]);

  push @$solutions, \@rowraw;
  $count++;

  if ($$gaps[0]>0) {
    $$gaps[0]--;
    for (my $a=$depth; $a <= $#{$gaps}; $a++) {
      my @child = @$gaps;
      $child[$a]++;
      &shuffle($row, \@child, $a, $solutions);
    }
  }
}

