#!/usr/bin/perl
 
use strict;
use warnings;

# 
# 
# 
# 
# 
# 
# 
# 
# 
# 

open(IN, 'in.in') or die "nie mozna otworzych wejscia\n";
my $DBL = 20; #distance between lines
my $DBE = 10; #dsiteance between extremes
my $parameterFlag = 2;# small value like 0, 1, 2
my $o = 1;
my @shortCommand = ();
my @command = ();
my @nails;
my $htmlFlag =0;
my $extension = '.svg';

foreach(@ARGV){
    if($_ =~ /html/){
      $htmlFlag =1;
      $extension = '.html';
    }elsif($_ =~ /([0-9]+)/){
      $parameterFlag = $1;
    }
}

while(<IN>){
  my $line = $_;
  @command = split(' ', $line);
  open(OUT, '>', "out$o$extension") or die "Nie dziala out$o$extension\n";
  select OUT;
  if($htmlFlag){
    print "<!DOCTYPE html>\n<html>\n<body>\n";
  }
  commandShorter();
  string(nails());
  
  print "</svg>\n";
  
  if($htmlFlag){
    print "</body>\n</html>\n";
  }
  close OUT;
  $o++;
  @command = ();
  @shortCommand = ();
  @nails = ();
}
close IN;

sub string{
my ($width, $height, $n) = @_;
my $x;
my $y = $nails[0]{y};
my $x2;
my $flag =0;
  if(@shortCommand == 0){#bez gwozdzi
    $x = int($width/2);
    print "<path d=\"M 0 $height q $x -$DBE $width 0\" stroke=\"blue\" stroke-width=\"2\" fill=\"none\" />\n";
    return 1;
  }
  if(@shortCommand == 1){#tylko jeden lub wiecej gwozdzi ale wszystkie pod linka w prawo 
    $shortCommand[0]{com} =~ /([0-9]+)/;
    $x = $nails[$1]{x} - $DBL;
    $shortCommand[0]{com} =~ /([du])/;
    curve($x, $y, $nails[$n]{x} - $x + $DBL ,$1, 1, 0);
    $x2 = $nails[$n]{x} + $DBL;
    $flag =1;
  }
  
  $shortCommand[0]{com} =~ /([0-9]+)/;
  my $a = $1;
  $shortCommand[0]{com} =~ /([rl])/;
  my $b = $1;
  if($b eq 'r'){
    $x = $nails[$a]{x} - $DBL;
    $nails[$a]{lCounter}++;
  }elsif($b eq 'l'){
    $x = $nails[$a]{x} + $DBL;
    $nails[$a]{rCounter}++;
  }else{
    die "zhuj\n";
  }
  
  #linia do poczatku petli
  my $tmp = int($x/2);
  print "<path id=\"line\" d=\"M $x $y l -$tmp $y\" stroke=\"black\" stroke-width=\"3\" fill=\"none\" />\n";
  
  for(my $i =0; $i+1 < @shortCommand; $i++){
    $shortCommand[$i]{com} =~ /([ud])/;
    my $plane = $1;
    $shortCommand[$i]{com} =~ /([0-9]+)/;
    my $node = $1;
    $shortCommand[$i]{com} =~ /([rl])/;
    my $dir = $1;
    $shortCommand[$i+1]{com} =~ /([0-9]+)/;
    my $next = $1;
    $shortCommand[$i+1]{com} =~ /([rl])/;
    my $dirNext = $1;
        
    my $max;
    #connectet with paramFlag
    my $par = abs($shortCommand[$i]{ind}-$shortCommand[$i+1]{ind})-1;
    
    my ($u, $d) = maxCounters($shortCommand[$i]{ind}, $shortCommand[$i+1]{ind});#tra przemyslec
    if($plane eq 'u'){
      setMaxes($shortCommand[$i]{ind}, $shortCommand[$i+1]{ind}, $u+1, 0);
      $max = $u+1;
    }elsif($plane eq 'd'){
      setMaxes($shortCommand[$i]{ind}, $shortCommand[$i+1]{ind}, 0, $d+1);
      $max = $d+1;
    }else{
      die "sie zjebalo i chuj\n";
    }
    
    if($dir eq 'r' && $dir eq $dirNext){
	$x2 = $nails[$next]{x} - $DBL*$nails[$next]{lCounter};
	$nails[$next]{lCounter}++;
    }elsif($dir eq 'r'){
	$x2 = $nails[$next]{x} + $DBL*$nails[$next]{rCounter};
	$nails[$next]{rCounter}++;
    }elsif($dir eq 'l' && $dir eq $dirNext){
	$x2 = $nails[$next]{x} + $DBL*$nails[$next]{rCounter};
	$nails[$next]{rCounter}++;
    }elsif($dir eq 'l' ){
	$x2 = $nails[$next]{x} - $DBL*$nails[$next]{lCounter};
	$nails[$next]{lCounter}++;
    
    }else{
	die "sie zjebalo\n";
    }
    
    curve($x, $y, $x2 - $x ,$plane, $max, $par);
    $x = $x2;
    
  }
  
  if($flag == 0){ #jeden jedyny przypadek jesli ostatni jest u gory a przedostatni na dole
    $shortCommand[-1]{com} =~ /([ud])/;
    if($1 eq 'u'){
      $x2 = $nails[$n]{x} + $DBL*$nails[$n]{rCounter};
      curve($x, $y, $x2 - $x , 'u', $nails[$n]{uCounter}+1, 0);
    }
  }
  
  #linia na koncu petli
  $tmp = int(($width-$x2)/2);
  print "<path id=\"line\" d=\"M $x2 $y l $tmp $y\" stroke=\"black\" stroke-width=\"3\" fill=\"none\" />\n";
}

sub curve{
my ($x, $y, $x2, $mark, $max, $par) = @_;
my $ye;
  if($mark eq 'u'){
    $ye = -$DBE*($max) - $par*$parameterFlag;
  }elsif($mark eq 'd'){
    $ye = $DBE*($max) + $par*$parameterFlag;
  }else{
    die "zesralo sie\t$mark\n";
  }
  
  print "<path d=\"M $x $y c 0 $ye $x2 $ye $x2 0\" stroke=\"black\" stroke-width=\"2\" fill=\"none\" />\n";
}

sub setMaxes{ #pamietaj ze ZAWSZE JEDEN parametr $mx MUSI byc 0
my ($beg, $end, $mu, $md) = @_;
if($beg > $end){
  ($beg, $end) = ($end, $beg);
}
  for(my $i = $beg; $i < $end; $i++){
    $command[$i] =~ /([0-9]+)/;
    my $k = $1;
    if($mu != 0){
      $nails[$k]{uCounter} = $mu;
    }elsif($md != 0){
      $nails[$k]{dCounter} = $md;
    }
  }
}

sub maxCounters{
my ($beg, $end) = @_;
  if($beg > $end){
    ($beg, $end) = ($end, $beg);
  }
  $command[$beg] =~ /([0-9]+)/;
  my $up = $nails[$1]{uCounter};
  my $down = $nails[$1]{dCounter};
  for(my $i = $beg; $i < $end; $i++){
    $command[$i] =~ /([0-9]+)/;
    if($nails[$1]{uCounter} > $up){
      $up = $nails[$1]{uCounter};
    }
    if($nails[$1]{dCounter} > $down){
      $down = $nails[$1]{dCounter};
    }
  }
  return ($up, $down);
}

sub nails{

  my $n = countN();
  my ($w, $space) = countD($n);
  
  my $width = 2*$space*$DBL*($n+1)+4;#4 piksele luzu po 2 stronach
  my $height = $DBE*2*$w+4;#j.w
  my $y = $DBE*$w+2;
  push @nails ,{x => 2+$space*$DBL, y =>$y, lCounter => 1, uCounter => 1, , rCounter => 1, , dCounter => 1}; 
  my $x = $nails[0]{x};
  
  print "<svg height=\"$height\" width=\"$width\">\n";
  print "<g stroke=\"black\" stroke-width=\"1\" fill=\"red\">\n";
  print "\t<circle id=\"0\" cx=\"$x\" cy=\"$y\" r=\"3\" />\n";
  
  for(my $i =1; $i <= $n; $i++){
    push @nails, {x => 2*$space*$DBL+$nails[$i-1]{x}, y =>$y, lCounter => 1, uCounter => 1, , rCounter => 1, , dCounter => 1};
    $x = $nails[$i]{x};
    print "\t<circle id=\"$i\" cx=\"$x\" cy=\"$y\" r=\"3\" />\n";
  }
  print "</g>\n";
  return ($width, $height, $n);
}

sub countN{#pamietaj zwraca NAJWYZSZY NUMER A NIE ILOSC GWOZDZI
  $command[0] =~ /([0-9]+)/;
  my $max = $1;
  foreach(@command){
    $_ =~ /([0-9]+)/;
    if($1 > $max){
      $max = $1;
    }
  }
$max;
}

sub countD{#liczymy jakie powinny byc wymiary obrazka
my ($n) = @_;
  my @cL = (0) x $n;
  my @cR = (0) x $n;
  my @cU = (0) x $n;
  my @cD = (0) x $n;
  my $com;
  for(my $i =0; $i < @shortCommand; $i++){
    $com = $shortCommand[$i]{com};
    $com =~ /([0-9]+)/;
    my $cyf = $1;
    if($com =~ /l/){
      $cL[$cyf]++;
    }elsif($com =~ /r/){
      $cR[$cyf]++;
    }else{
      die "nosz kurwa  ja pierdole\n";
    }
  }
  for(my $i =0; $i < @command; $i++){
    $command[$i] =~ /([0-9]+)/;
    my $cyf = $1;
    if($command[$i] =~ /u/){
      $cU[$cyf]++;
    }elsif($command[$i] =~ /d/){
      $cD[$cyf]++;
    }else{
      die "i nie wracaj\n";
    }
  }
  my $m1 = maximum(@cL);
  my $m2 = maximum(@cR);
  my $m3 = maximum(@cU);
  $m1 = ($m1 > $m2)?$m1:$m2;
  $m2 = maximum(@cD);
  $m2 = ($m3 > $m2)?$m3:$m2;
  ($m2*2 , $m1);
}

sub maximum{
  my (@tab) = @_;
  my $m = $tab[0];
  foreach (@tab){
    if($m < $_){
      $m = $_;
    }
  }
  $m;
}

sub commandShorter{#skrocona komenda zeby robic wieksze krzywe
  
  my $char = 'd';  
  for(my $i =0; $i < @command; $i++){
    
    if($command[$i] =~ /$char/){
      
    }else{
      push @shortCommand, {com => $command[$i], ind => $i};
      
      if($char eq 'u'){
	$char = 'd';
      }else{
	$char = 'u';
      }
    }
  }
  
}
