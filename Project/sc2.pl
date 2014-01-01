#!/usr/bin/perl
 
use strict;
use warnings;
###############################################################
# parametr 'html' zapisuje  obrazki do pliku html
# dowolna liczba zmienia parametr parameterFlag
# parametr 'one' ustawia by gwozdzie byly numerowane od jednego nie jest wymagane oszczedza tylko pamiec
# 
# 
# program wczytuje z pliku in.in komendy do rysowania petelek na gwodziach
# komendu postaci [0-9]+[ud][rl] 
# np. komenda 1ur oznacza ze sznurek przechodzi nad gwozdziem nr 1 w prawo itp.
# 
# ###########################################################

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
my $oneFlag =0;
foreach(@ARGV){
    if($_ =~ /html/){
      $htmlFlag =1;
      $extension = '.html';
    }elsif($_ =~ /([0-9]+)/){
      $parameterFlag = $1;
    }elsif($_ =~ /one/){
      
    }
}

#glowna petla programu
while(<IN>){
  my $line = $_;
  @command = split(' ', $line);
  open(OUT, '>', "out$o$extension") or die "Nie dziala out$o$extension\n";
  select OUT;
  if($oneFlag){
    one();
  }
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

#**
# @fn string() 
# funkcja wylicza odpowiednie punkty dla krzywuch Beziera
# @param width szerokosc obrazka w pikselach
# @param height wysokosc obrazka w pikselach
# @param n ilosc gwozdzi
# @return 1 zawsze
#*
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

#**
# @fn curve()
# rysuje dla podanych parametrow krzywa Beziera
# @param x pierwsza wsp poczatku krzywej
# @param y druga wsp poczatku i konca krzywej
# @param x2 pierwsza wspolrzedna konca krzywej
# @param mark u lub d w zaleznosci czy krzywa jest wypukla dodatnio czy ujemnnie
# @param max jak bardzo krzywa powinna byc wypukla by sie chamsko nie przecinac/stykac z inna petla
# @param par kolejny parametr wypuklosci tym razem w zaleznosci jak dluga ma byc krzywa
# @return 1 zawsze
#*
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

#**
# @fn setMaxes()  
# funkcja ustawia liczniki ekstremow dla odpowiedznich gwozdzi
# jedna z wartosci mu lub md powinna byc rowna 0
# @param beg poczatkowy/koncowy indeks komendy w calym wyrazeniu
# @param end koncowy/poczatkowy indeks komendy w calym wyrazeniu
# @param mu wartosc do ustawienia w liczniku ekstremow gornych
# @param md wartosc do ustawienia w liczniku ekstremow dolnych
#
#*
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

#**
# @fn maxCounters()
# funkcja liczaca najwieksze wartosci z licznikow dla zadanego przedzialu 
# @param beg poczatkowy/koncowy indeks komendy w calym wyrazeniu
# @param end koncowy/poczatkowy indeks komendy w calym wyrazeniu
# @return (up, down) krotka zawierajaca  supermum gorne na 1 wsp i supermum dolne
#*
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

#**
# @fn nails()  
# wyznaczanie miejsc  gdze powinny znajdowac gwozdzie i rysujacy je
# @return (width, height, n) krotka zawierajac szerokosc wysokosc i ilosc gwozdzi
#*
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

#**
# @fn countN()  
# funkcja liczaca najwyzszy numer gwozdzia
# @return najwyzszy nr gwodzia
#*
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

#**
# @fn countD()  
# funkcja wyznaczajaca preferowany rozmiar obrazka
# @param najwyzszy nr gwozdzia
# @return odpowiednie parametry z ktoych łatwo wyznaczyc wysokosc i szerokosc
#*
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

#**
# @fn maximum  
# prosta funkcja wyznaczajaca najwieksza wartosc w tablicy
# @param tab tablica z ktorej chccemy najwieksza wartosc
# @return najwieksza wartosc
#*
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

#**
# @fn commandShorter()  
# funkcja skracajaca podana przez nas komenda do postaci, w ktorej na zmiane sa wartosci gora dole
# robimy to bo przy rysowaniu krzywymi tak naprawde potrzebna nam jest tyko informacja w ktorych miejscach 
# linka jako 'funkcja przyjmuje miejsca przyjmuje miejsca zerowe'
#*
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

#**
# @fn one()
# prawdopodobnie nie potrzebna funkcja ale lepiej zeby byla
# uruchamiana jest gdzy ktos numeruje gwozdzie od jedynki
# przeksztalca nasza komende tak by jednak gwozdzize byly od zera
#*
sub one{
  foreach(@command){
    $_ =~ /([0-9]+)/;
    my $t = $1 -1;
    $_ =~ s/$1/$t/;
  }
}
