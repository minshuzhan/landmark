#!/usr/bin/perl

#############################################################################
#
# v11.27.01  fixed start_over_query & start_over_message...
#
# v11.13.01  added a '+' to the line below (split by punctuation to
#            prepare for phoneme conversion...) 
#	     @words = split (/[ !#,.?:;\(\)]+/, $_);                ###
#
# v10.11.01  palindrome!!
#            revised option c text.
#            revised option c's output file header.
#
# v10.02.01  removed soft palate/larynx/constricted glottis/slack vocal fold
#               choices.
#            removed [+/-] option from 
#               lips/blade/body/lateral/rhotic/spread glottis choices.
#
#            when to add dipthongs?  (ai/oi/au)
#
# v09.04.01  added a subroutine, list_constraints, that is called
#            from make_db. the routine adds a list of the chosen constraints
#            for each phoneme to the header of the output file.
#
# v08.30.01  i added peramaters to make_pf_db and to phoneme_search, 
#            which didn't seem able to see one & two/hone & htwo
#
#            this version combines dbMaker.pl and phonefind.pl,
#            allowing users to search for a phoneme or pair
#            of phonemes based on features or general attributes.
#
#            this version only utilizes the start_over_query when 'c'
#            is the chosen task and the given constraints don't result
#            in any valid pairs.
#
##############################################################################


print "\n***********************************************************************\n";
print "***********************************************************************\n";

                                     ### some global variables
$purpose = "";                               ### make purpose global
$printswitch = 0;                            ### print to file? f default
$pairswitch = 0;                             ### pair of phonemes? f default
$displayswitch = 0;                          ### display on screen? f default
$phfindswitch = 0;

purpose_query();                             ###

                                    # for later use with multiple DBs
#print "\nWhich utterance database would you like to use?\n";
#$uttdb = <STDIN>;
#chomp($uttdb);

$uttdb = "utts.txt";

$input = "$uttdb";                  # database of utterances
open (IN, "<$input") || die "\nfailure to open utterance db: $!\n";            
@lines = <IN>;                      # read file into an array
close (IN);                         # close input file like a good person    
#print "\n";                        # gimme room, man                 

#$length = @lines;                  # length of array            ###
                                    # remove db header
do { shift(@lines); } until ($lines[0] =~ /1/); 

@originalutts = @lines;             # save utts with numbers for later 
chomp(@originalutts);               # a little formatting for output
@lineswithapostrophes = ();         # for kinda formatted lines      

format_lines();                     # call formatting subroutine
                                    # read the lexicon into an array
$input = "lexicon.lex";             # database of utterances
open (IN, "<$input") || die "\nfailure to open lexicon: $!\n";
                 
@lex = <IN>;                        # read lexicon into an array   
close (IN);                         # close input file like a good person

shift(@lex);                        # shift off the header

format_lexicon();                   # call lexicon formatting subroutine

@phonelines = @lines;               # make a parallel array for the phonemes

convert_to_phones();                # extract phonemes from utterances

$length = @lines;                                                 

delegate_tasks();                   # steer to proper subroutine

print "\n***********************************************************************\n";
#print "*************************     FIN     *************************\n";  
print "***********************************************************************\n\n";

sub purpose_query                                                 ###
{
    $errorct = 0;
    print "\nWhat would you like to do? (no caps, please)";
    print "\n\n   a) search for occurrences of a specific pair of phonemes ";
    print "(screen display)";
    print "\n   b) search for occurrences of a specific pair of phonemes ";
    print "(write to file)";
    print "\n   c) search for phoneme pairs that contain specific features ";
    print "(write to file)\n"; 
#    print "\n   d) search for single phonemes that contain specific features"; 
#    print " (write to file)\n";
  TRYAGAIN:                                # give the user one more chance
    {                                      # for good input
      $purpose = <STDIN>;
      chomp($purpose);
      if($purpose =~ /\b[a-c]\b/){}        # valid?
      else 
      { 
	  $errorct ++;
	  if($errorct =~ /[1-3]/)
	  {
	      print "Invalid choice.  Please choose 'a', 'b', or 'c'\n";
	      redo TRYAGAIN; 
	  }
	  else 
	  {
	      print "$purpose is not a valid choice either.\n";
	      print "Three strikes, you're out...\n\n";
	      exit; 
	  }                   # bad, bad user... 
      }
    }
} ## end purpose_query

sub delegate_tasks
{
    if($purpose eq "a")                    # phonefind screen display
    { 
      $printswitch = 0;                    # don't print to file
      $pairswitch = 1;                     # pair of phonemes
      $displayswitch = 1;                  # display on screen
      $phfindswitch = 1;
      phone_find();
    }
    elsif($purpose eq "b")                 # phonefind to file (want this?)
    { 
      $printswitch = 1;                    # print to file
      $pairswitch = 1;                     # pair of phonemes
      $displayswitch = 0;                  # display on screen
      $phfindswitch = 1;
      phone_find();
    }
    elsif($purpose eq "c")                 # db with given features
    { 
      $printswitch = 1;                    # print to file
      $pairswitch = 1;                     # pair of phonemes
      $displayswitch = 0;                  # display on screen
      $phfindswitch = 0;
      make_db();
    }
#    elsif($purpose eq "d") {}              # single phoneme db w/given features
#    { 
#      $printswitch = 1;                    # don't print to file
#      $pairswitch = 0;                     # single phoneme
#      $displayswitch = 0;                  # display on screen
#      $phfindswitch = 0;
#      make_db();
#    }
}

#############################################
############################## subroutines ##
#############################################

sub phone_find
{
#print "\nin phone_find\n";                # input phoneme pair from user
  print "\nVALID PHONEMES: (iy ih ey eh ae aa ao ow ah uw uh rr er ex p t k b d g"; 
  print "\n    	         f v th dh s z sh zh ch dj m n ng r l w y h)";
  print "\nEnter a phoneme: ";
  $pone = <STDIN>;
  print "Enter another phoneme: ";
  $ptwo = <STDIN>;
  chomp($pone);
  chomp($ptwo);
  $length = @lines;
  $found = "false";
  $count = 0;
  @setfind = ();                      # empty array to hold locations
  phone_search($pone, $ptwo);              # call searching subroutine 
  if($printswitch)                    # if any found, make db
  { 
    if($count != 0) { make_pf_db($pone, $ptwo, @setfind); }   ### gave perameters
  }
} ## end phone_find

sub make_pf_db
{
  my($one, $two, @setfind) = @_;                             ### gave perameters
    
  print "\nWhat would you like to name the file of pair locations?\n";
  $dbName = <STDIN>;

  open (OUT, ">$dbName") || die "\nfailure to create $dbName: $!\n"; 
                                              # header
  print OUT "#################################################################\n";
  print OUT "#  Locational analysis of a given phoneme pair in $uttdb\n";
  print OUT "#  \tFirst phoneme: $one\n";
  print OUT "#  \tSecond phoneme: $two\n";  
  if($count eq 1)
  { print OUT "#  The specified phoneme sequence occurs once.\n"; }
  else
  { print OUT "#  The specified phoneme sequence occurs $count times.\n"; }
  print OUT "#################################################################\n";

  foreach(@setfind) { print OUT "$_\n"; }

  close (OUT);                       # close output file like a good person 

  start_over_query();  
}

sub make_db
{ 
  $whereami = "getfirst";
  #print "\n";
###################### do i need to search +/- vowel/cons/glide/nasal ??

  print "\nYou will be prompted to enter constraints for each of two";
  print "\nphonemes.  Enter all choices (with a space between each)";
  print "\nbefore you hit return.  [+/-] attributes should be entered";
  print "\nas the proper letter followed by + or - (ex: s+).";
  print "\nIf neither is specified, + will be chosen as the default.";
  print "\nConstraints are as follows:\n";

 CONSTRAINTS:
 {
  print "\na)  all valid phonemes        b) vowels             c) non-vowels";  
  print "\nd)  true consonants           e) glides             f) nasals"; 
  print "\ng)  stops                     h) fricatives         i) affricates";
  print "\nj)  fricatives & affricates   k) lips               l) tongue blade";
  print "\nm)  tongue body               n) lateral            o) rhotic ";
  print "\np)  continuant[+/-]           q) sonorant[+/-]      r) strident[+/-]";
  print "\ns)  round[+/-]                t) reduced[+/-]       u) anterior[+/-]";
  print "\nv)  distributed[+/-]          w) high[+/-]          x) low[+/-]";
  print "\ny)  back[+/-]                 z) nasal[+/-]";
  print "\naa) adv.tongue root[+/-]     ab) const. tongue root[+/-]";
  print "\nac) stiff vocal folds[+/-]   ad) spread glottis"; 
  print "\n\n";

  if ($whereami eq "getsecond") { goto GETSECOND; } # the very very scary goto 
 }

  GETFIRST:
    {
	print "Please select constraints for the first ";
	print "phoneme (ex: g ac-):\n";
	$firstChoice = <STDIN>;
	chomp($firstChoice);
#	print " FirstChoice=$firstChoice ";
	@tempfirst = split(/ /, $firstChoice);
	@errors = ();                               # hold error characters
	$badinput = "false";
	foreach(@tempfirst)                         # valid input?
	{                                           # think it finally works (!)
	    if (/(^[a-z]\b)|(^[p-z][\+\-]\b)|(^a[a-c][\+\-]?\b)|(^ad\b)/)
	    {}           
	    else
	    {   
		$badinput = "true";                 # set bad flag
		push (@errors, $_);                 # add error to list
	    }    
	}
	if($badinput eq "true")
	{
	    print "Invalid choices: "; 
	    foreach(@errors) { print "$_ "; }
	    print "\nDo you need to see the constraint list again? (y/n)  ";
	    $a = <STDIN>;
	    chomp($a);
	    if ($a eq "y") { goto CONSTRAINTS; }    # the very very scary goto
	    else { redo GETFIRST; }
	}
#	print " BadInput=$badinput ";
        
    } ## end GETFIRST
  GETSECOND:
    {
	$whereami = "getsecond";
	print "Please select constraints for the second ";
	print "phoneme (ex: a z- gg+):\n";
	$secondChoice = <STDIN>;
	chomp($secondChoice);
	@tempsecond = split(/ /, $secondChoice);
	@errors = ();                               # hold error characters
	$badinput = "false";
	foreach(@tempsecond)                        # valid input?
	{                                           # i think this finally works
	    if (/(^[a-z]\b)|(^[p-z][\+\-]\b)|(^a[a-c][\+\-]?\b)|(^ad\b)/) 
#	    if (/(^[a-z]\b)|(^[k-z][\+\-]\b)|(^a[a-i][\+\-]?\b)/)
	    {}           
	    else
	    {   
		$badinput = "true";                 # set bad flag
		push (@errors, $_);                 # add error to list
	    }    
	}
	if($badinput eq "true")
	{
	    print "Invalid choices: "; 
	    foreach(@errors) { print "$_ "; }
	    print "\nDo you need to see the constraint list again? (y/n)  ";
	    $a = <STDIN>;
	    chomp($a);
	    if ($a eq "y") { goto CONSTRAINTS; }    # the very very scary goto
	    else { redo GETSECOND; }
	}
#	print "\n";
    } ## end GETSECOND

#  print " FirstChoice=$firstChoice ";
#  print " SecondChoice=$secondChoice ";

  @first = split(/ /, $firstChoice);
  @phones1 = review_constraints(@first);

  @second = split(/ /, $secondChoice);
  @phones2 = review_constraints(@second);

  if((@phones1)&&(@phones2))      # if valid phonemes to search, make db
  {
    print "\nWhat would you like to name the file of generated pairs?\n";
    $dbName = <STDIN>;

                    ## move all print OUT stuff down to customize header?
    open (OUT, ">$dbName") || die "\nfailure to create $dbName: $!\n"; 
                                              # header
    print OUT "##############################################################\n";
    print OUT "#  Frequency analysis of phoneme pairs in $uttdb, given the\n";
    print OUT "#  following constraints:\n#\n";
    print OUT "#    First phoneme:";
    print OUT list_constraints(@first);        # list first phoneme's constraints
    print OUT "\n";
    print OUT "#    Second phoneme:";
    print OUT list_constraints(@second);       # list second phoneme's constraints
    print OUT "\n";
    print OUT "#\n";
    print OUT "#  Entries list the pair itself and the frequency count,\n";
    print OUT "#  followed by the location of the occurrence.  Location\n";
    print OUT "#  is given as the utterance number and the word or words \n";
    print OUT "#  in which the pair was located.\n";
    print OUT "#\n";   
    print OUT "##############################################################\n";
    print OUT "\n";

    $h=0;
    foreach $hone(@phones1) 
    {
#    $hone = $_;
        $h++;
        $m=0;
        foreach $htwo(@phones2)
        {
#	$htwo = $_;
	  $count = 0;
	  $found = "false";
	  @setfind = ();

################################################ 
######################### phone_search called ##
################################################
                                   # entries for this pair of phonemes
	  $thiscell = join("\n", phone_search($hone, $htwo));
                                   # add the phoneme set, count, and the 
                                   # locations to the db entry
	  $HoH{$hone}{$htwo} = "[$hone $htwo]\nCount: $count\n$thiscell";
                                   # if the sequence occurs,
                                   # append the entry to the database file
	    if ($count > 0){ print OUT "$HoH{$hone}{$htwo}\n"; }
          $m++;
        }
    }
    close (OUT);                       # close output file like a good person 

    start_over_query();
  } ## end ifvalid phonemes exist
  
  else { start_over_message(); }
} ## end make_db


sub list_constraints
{
  my(@choices) = @_;            # make choice list local
  $ch = "";                     # to hold the list of constraints
    
  foreach(@choices)
  {
     
      if($_ eq "a")   { $ch .= " any valid phoneme,"; }
    elsif($_ eq "b")  { $ch .= " vowel,"; }
    elsif($_ eq "c")  { $ch .= " non-vowel,"; }
    elsif($_ eq "d")  { $ch .= " true consonant,"; }
    elsif($_ eq "e")  { $ch .= " glide,"; }
    elsif($_ eq "f")  { $ch .= " nasal,"; }
    elsif($_ eq "g")  { $ch .= " stop,"; }
    elsif($_ eq "h")  { $ch .= " fricative,"; }
    elsif($_ eq "i")  { $ch .= " affricate,"; }
    elsif($_ eq "j")  { $ch .= " fricative or affricate,"; }

    elsif($_ eq "k")  { $ch .= " lips,"; }
    elsif($_ eq "l")  { $ch .= " tongue blade,"; }
    elsif($_ eq "m")  { $ch .= " tongue body,"; }
    elsif($_ eq "n")  { $ch .= " lateral,"; }
    elsif($_ eq "o")  { $ch .= " rhotic,"; }

    elsif(($_ eq "p+") || ($_ eq "p"))  { $ch .= " +continuant,"; }
    elsif($_ eq "p-")                   { $ch .= " -continuant,"; }
    elsif(($_ eq "q+") || ($_ eq "q"))  { $ch .= " +sonorant,"; }
    elsif($_ eq "q-")                   { $ch .= " -sonarant,"; }
    elsif(($_ eq "r+") || ($_ eq "r"))  { $ch .= " +strident,"; }
    elsif($_ eq "r-")                   { $ch .= " -strident,"; }
    elsif(($_ eq "s+") || ($_ eq "s"))  { $ch .= " +round,"; }
    elsif($_ eq "s-")                   { $ch .= " -round,"; }
    elsif(($_ eq "t+") || ($_ eq "t"))  { $ch .= " +reduced,"; }
    elsif($_ eq "t-")                   { $ch .= " -reduced,"; }
    elsif(($_ eq "u+") || ($_ eq "u"))  { $ch .= " +anterior,"; }
    elsif($_ eq "u-")                   { $ch .= " -anterior,"; }
    elsif(($_ eq "v+") || ($_ eq "v"))  { $ch .= " +distributed,"; }
    elsif($_ eq "v-")                   { $ch .= " -distributed,"; }
    elsif(($_ eq "w+") || ($_ eq "w"))  { $ch .= " +high,"; }
    elsif($_ eq "w-")                   { $ch .= " -high,"; }
    elsif(($_ eq "x+") || ($_ eq "x"))  { $ch .= " +low,"; }
    elsif($_ eq "x-")                   { $ch .= " -low,"; }
    elsif(($_ eq "y+") || ($_ eq "y"))  { $ch .= " +back,"; }
    elsif($_ eq "y-")                   { $ch .= " -back,"; }
    elsif(($_ eq "z+") || ($_ eq "z"))  { $ch .= " +nasal,"; }
    elsif($_ eq "z-")                   { $ch .= " -nasal,"; }
    elsif(($_ eq "aa+") || ($_ eq "aa")){ $ch .= " +adv. tongue root,"; }
    elsif($_ eq "aa-")                  { $ch .= " -adv. tongue root,"; }
    elsif(($_ eq "ab+") || ($_ eq "ab")){ $ch .= " +const. tongue root,"; }
    elsif($_ eq "ab-")                  { $ch .= " -const. tongue root,"; }
    elsif(($_ eq "ac+") || ($_ eq "ac")){ $ch .= " +stiff vocal folds,"; }
    elsif($_ eq "ac-"){ $ch .= " -stiff vocal folds,"; }

    elsif($_ eq "ad")                   { $ch .= " spread glottis,"; }
  } ## end foreach

  chop ($ch);                      # remove final comma
  return ($ch);                  # add list to header
}



sub weed_out                      # given new set, removes mismatches 
{
    my(@new) = @_;                # bring in the new class
    foreach $i(@perm)             # for every perm element
    {
       foreach (@new)             # check for match in new class
       {                             
	  if ($i eq $_)           # if match, store in temp
	  { 
	     push (@temp, $_); 
	  }
       }
    }
    return @temp;
} ## end weed_out

sub format_lines
{
    chomp(@lines);                 # get rid of extra newlines
                                   # for every line input...
    foreach (@lines)
    {
                      # ...sub all numbers,periods,&spaces with nothing
	s/\d+\. +//;   
                                   # sub punct. strings with one space
	s/[ !#,.?:;\(\)]+/ /g;
                                   # sub change comments with nothing
	s/(\/\* \w* ([\w\/]* ?)*\*\/)//;
    }              
                                   # maintain caps&single quotes for later
    @lineswithapostrophes = @lines;   
                                  
    foreach (@lines) 
    { 
	tr/A-Z/a-z/;               # convert everything to lowercase
	s/(\')//g;                 # sub apostrophes&single quotes w/nothing
    }
} ## end format_lines

sub format_lexicon
{
    foreach (@lex)                 # for every line in the lexicon...
    {                                  
	s/\d+\) //;                # sub number-paren-space with nothing    
	@entry = split (/\(/, $_); # split by left paren
	chomp($entry[1]);          # remove newline from phonemes
	chop($entry[1]);           # remove right paren from phonemes
	chop($entry[1]);           # remove space from phonemes
	for($i=0; $i<3; $i++)      # remove spaces from word
	{ 
	    chop($entry[0]); 
	}      
	$refined = "$entry[0]" . "_" . "$entry[1]";
	$_ = $refined;	           # put reformatted entry back in lex
    }
} ## end format_lexicon

sub convert_to_phones
{      
    foreach (@phonelines)          # for every utterance in the copied array
    {                           
#        $thisline = $_;            # hold line for error messages
	                           # split the utterance into single words    
	@words = split (/[ !#,.?:;\(\)]+/, $_);                 ###
#	@words = split (/[ !#,.?:;\(\)]/, $_); 

	$phoneline = "";           # scalar to store phoneme string @ this level
	$myphones = "";            # scalar to store each word's phonemes
	WORDS: foreach (@words)           # for every word in the utterance
	{
	    $thisword = $_;        # hold a copy of the word
	    $found = "false"; # keep track: found or not
	    foreach (@lex)         # for every entry in the lexicon
	    {                      # split into word & phoneme strings
		@thislex = split(/_/, $_);
                               # if the held word matches the word entry
		if ($thisword eq $thislex[0])
		{                  # save the phonemes & make a "found" note
		    $myphones = $thislex[1];
		    $found = "true";
		    last;          # then break out of lexicail search
		}
	    }
	                       # replace the word with its phonemes and append
                               # it to the current line w/a # 
	    if($found eq "true")
	    {
		$phoneline .= "$myphones";
		$phoneline .= "#"; 
	    }
	    else               # if not found in lexicon, search dictionary
	    { 
	        $oneortwo = "one";         # checking whole or part?
	        $pronlexcount = 0;      # captains log
		    
	        search_pronlex($thisword, $oneortwo);
		    
	        if($found eq "false")
	        {          # not anywhere, try breaking off prefix
		    try_prefix();
		    if($found eq "false") # truly nonexistant?
		    { no_where_no_how(); }
		}
	    }
	}
#	print "\n$phoneline";
	$_ = $phoneline;           # record this element in phonelines
    }
} ## end convert_to_phones

sub search_pronlex
{
######################################
#   entry example in pronlex.txt:
#       abated	.xb'et.Id
######################################

    my($theword, $numofwords) = @_;           # name the perameters
    @dphns = ();

    $pronIn = "proper pronlex file here";
#   print "\nsearching pronlex for $theword";

    if    ($theword =~ /^[a-c]/) { $pronIn = "pronlex_A-C.txt"; }
    elsif ($theword =~ /^[d-h]/) { $pronIn = "pronlex_D-H.txt"; }
    elsif ($theword =~ /^[i-o]/) { $pronIn = "pronlex_I-O.txt"; }
    elsif ($theword =~ /^[p-s]/) { $pronIn = "pronlex_P-S.txt"; }
    elsif ($theword =~ /^[t-z]/) { $pronIn = "pronlex_T-Z.txt"; }
 
#    print " in: $pronIn";
  
    open (PRONLEX, "<$pronIn") || die "\nfailure to open $pronIn: $!\n";

    while ($entry = <PRONLEX>) 
    { 
	@line = split ' ', $entry;
	if( $line[0] eq $theword )  
	{
	    $found = "true"; 
                                                 # split by diacritics
	    @syls = split (/['\-`*<]/, $line[1]);
	    $_ = join ("", @syls);               # join without diacritics
	    @dphns = split (//, $_);             # put phonemes in array
	    @phns = ();                    # empty @ to push converted phonemes

            convert_my_phones();
            last;                                # break out of while
        } # end if	
    }

    close (PRONLEX);

    if($found eq "true")
    {
        if($numofwords eq "one")
        {
	    $myphones = join(" ", @phns);      # turn the phonemes into a string
	    $phoneline .= " $myphones";        # add them to the line of phonemes
            $phoneline .= "#";                 # with # in betw word's phonemes
	}
	else                        # working with a prefix/root situation
	{ 
	     $myphones = join(" ", @phns);
	     $phoneline .= " $holdmyphones $myphones";
	     $phoneline .= "#";
        }
    }
    
} ## end search_pronlex

sub convert_my_phones
{
    for($idx = 0; $dphns[$idx]; $idx++)
    {
	$_ = $dphns[$idx];
	                                   # if in need of conversion
        if(/[AaIiEe\@WY\^cOoUuRx\|XCJSZTDG]/ )
        {
	    if(/A/){ push (@phns, "ah"); }
	    elsif(/a/){ push (@phns, "aa"); }
	    elsif(/i/){ push (@phns,"iy"); }
	    elsif(/I/){ push (@phns, "ih"); }
	    elsif(/E/){ push (@phns, "eh"); }
	    elsif(/e/){ push (@phns, "ey"); }
	    elsif(/\@/){ push (@phns, "ae"); }
	    elsif(/W/){ push (@phns, "aa aw"); }
	    elsif(/Y/){ push (@phns, "aa iy"); }
	    elsif(/\^/){ push (@phns, "ah"); }	
	    elsif(/c/){ push (@phns, "ao"); }
	    elsif(/O/){ push (@phns, "ao iy"); }
	    elsif(/o/){ push (@phns, "ow"); }
	    elsif(/U/){ push (@phns, "uh"); }
	    elsif(/u/){ push (@phns, "uw"); }
	    elsif(/R/){ push (@phns, "rr"); }
	    elsif(/X/){ push (@phns, "rr"); }
	    elsif(/x/){ push (@phns, "ex"); }
	    elsif(/\|/){ push (@phns, "ex"); }
	    elsif(/C/){ push (@phns, "ch"); }
            elsif(/J/){ push (@phns, "dj"); }
            elsif(/S/){ push (@phns, "sh"); }
            elsif(/Z/){ push (@phns, "zh"); }
            elsif(/T/){ push (@phns, "th"); }
            elsif(/D/){ push (@phns, "dh"); } 
            elsif(/G/){ push (@phns, "ng"); }
	}                          
        elsif(/[NML]/)              # else to lower case & push
        { 
	    tr/A-Z/a-z/;
	    push (@phns, $_); 
	}
        elsif(/[nml]/)              # or just push
        { push (@phns, $_); }
        elsif(/[rwyh]/)
	{ push (@phns, $_); }   
        elsif(/[ptkdbg]/)
	{ push (@phns, $_); }
        elsif(/[szfv]/)
        { push (@phns, $_); }
    }                              # end for(phonemes left in dphns)
} ## end convert_my_phones

sub prefix_search
{
    my($myroot) = @_;
    $oneortwo = "two";
    $pronlexcount = 0;

    $found = "false";
    search_pronlex($myroot, $oneortwo);
} ## end prefix_search

sub no_where_no_how                   # not in lex or dict, enter them yourself!
{
    print "\n\n$thisword not found in lexicon or either dictionary.";
    print "\nEnter a string of phonemes: ";
    
    $myphones = <STDIN>;                       # read user's phonemes
    chomp($myphones);                          # lose the newline

    $phoneline .= " $myphones";             # add them to the line of phonemes
    $phoneline .= "#";                     # with # betw each word's phonemes
} ## end no_where_no_how

sub phone_search
{
    my($one, $two) = @_;
    
    for ($i = 0; $i < $length; $i++)        # $i = utterance counter
    {
	$phonestring = $phonelines[$i];     # phonemestring = current line
	$_ = $phonestring;                  # the thing i'm thinking of...  
   
        $oneloc = 0;              # keep track of location in each case
	$twoloc = 0;
	$threeloc = 0;
	$fourloc = 0;

	$onewc = 0;                         # word count within utt.
	$twowc = 0;
	$threewc = 0;
	$fourwc = 0;

	$onect = 0;               # how many matches in each case
	$twoct = 0;
	$threect = 0;
	$fourct = 0;
	
	$thiscase = "";
              
	CASE1: foreach (/( $one $two#)/g)    # case 1: end/one word
	{
	  $thiscase = "CASE1";
	  $sequence = " $one $two#";
	  $oneloc = find_it($sequence, $oneloc, $onect, $thiscase, $onewc);
	}
	CASE2: foreach (/( $one $two )/g)    # case 2: start or mid/one word 
	{
	  $thiscase = "CASE2";
	  $sequence = " $one $two ";
	  $twoloc = find_it($sequence, $twoloc, $twoct, $thiscase, $twowc);
	} 
        CASE3: foreach (/( $one# $two#)/g)   # case 3: end and whole/two words
	{
	  $thiscase = "CASE3";
	  $sequence = " $one# $two#";
	  $threeloc = find_it($sequence, $threeloc, $threect, 
			      $thiscase, $threewc);
	}
	CASE4: foreach (/( $one# $two )/g)   # case 4: end and start/two words
	{
	  $thiscase = "CASE4";
	  $sequence = " $one# $two";
	  $fourloc = find_it($sequence, $fourloc, $fourct, $thiscase, $fourwc);
	}
    }
#    print "\nfound=$found";
    if($phfindswitch && ($found eq "false")) 
    {
#	print "\nSorry, the specified phoneme sequence does not occur in the database.\n";
	start_over_message();                                                           ###
    }   
#    if($found eq "false") {}    ### take out {}
#    { start_over_message(); }
    elsif($phfindswitch && $displayswitch)
    {
      if($count eq 1)
      { 
        print "\n\nThe specified phoneme sequence occurs once.\n"; 
      }
      else
      { 
        print "\n\nThe specified phoneme sequence occurs $count times.\n";
      }
      
      start_over_query();
    }
    return (@setfind);
} ## end phone_search

sub find_it
{                            # seq = phoneme positioning,
                             # loc = location in string (for this case),
                             # ct = how many occurances (this case),
                             # case = which case,
    my($seq, $loc, $ct, $case, $phwc) = @_;              # perameter name

    $ct++;                   # captain's log: been here  
#    if($phfindswitch && $displayswitch)           ### if phonefind to screen
#    {   print "\n$originalutts[$i]"; }        ### moved down
	                     # as long as there are more matches, continue 
                             # starting with last loc, get index of next match
    if ( index($phonestring, $seq, $loc) != (-1)) # while index isn't invalid
    {
        $loc = index($phonestring, $seq, $loc);   # loc = index of next match
    }
    else { last $case; }                          # otherwise break out
	                     
    @phlettersearch = split(//, $phonestring);
    $phwc = 0; 	                         
                             # until the beginning of the match
    for($k = 0; $k < $loc; $k++)
    {
	if ($phlettersearch[$k] eq "#")
       	{
       	   $phwc++; 
       	}
    }   
	                                    # split by spaces
    @wordsearch = split (/ /, $lineswithapostrophes[$i]);
    $theword = $wordsearch[$phwc];
                                    # in case a second word is needed
    $thenextword = $wordsearch[$phwc + 1];
	    

    $found = "true";                  
    $count++;                       # increment occurance number
    $loc++;
	                                    # get proper utterance number
    $numend = index($originalutts[$i], ".");
    $uttnum = substr($originalutts[$i], 0, $numend);

    if($pairswitch)                  ### if a,b,c
    {
      if($displayswitch)           ### if phonefind to screen
      {
        if(($case eq "CASE1") || ($case eq "CASE2")) # if one word
        { push(@setfind, "\n      [$theword]"); }
        else { push(@setfind, "\n      [$theword, $thenextword]"); }
	  
	print "\n$originalutts[$i]";
        print "$setfind[-1]";      # print last element
      }
      elsif($phfindswitch)         ### if phonefind to db
      {
	if(($case eq "CASE1") || ($case eq "CASE2")) # if one word
        { push(@setfind, "\n$originalutts[$i]\n      [$theword]"); }
        else 
	{                                                  ###
	  push(@setfind, "\n$originalutts[$i]\n      [$theword, $thenextword]");
	}
      }
      else                         ### if pair dbMaker
      {                            # push to found list
	if(($case eq "CASE1") || ($case eq "CASE2")) # if one word
	{ push(@setfind, "\t\t$uttnum: $theword"); }
	else { push(@setfind, "\t\t$uttnum: $theword $thenextword"); }
      }
    }
    else                             ### if single dbMaker
    {
      push(@setfind, "\t\t$uttnum: $theword");
    }
                                     # push word(s) to found list
    return $loc;                     ### return loc to w/in scope
} ## end find_it

sub start_over_message
{
    if($purpose eq "c")                                              #####
    {   print "\nSorry, no pairs exist with the given constraints.\n"; }
    elsif(($purpose eq "a") || ($purpose eq "b"))
    {
        print "\nSorry, that phoneme sequence does not"; 
        print " occur in the database.";
    }
    else
    {   
	print "\nSorry, that combination of constraints does not ";
	print "occur in the database."; 
    }
    
    start_over_query();
}

sub start_over_query
{    
#    print "\nWould you like to search the same utterance database for ";
#    print "something else? (y or n)\n";
    print "\nWould you like to search for something else? (y or n)\n";
    $ans = <STDIN>;
    chomp($ans);
    if ($ans eq "y") 
    {
	purpose_query();
	delegate_tasks();
    }
#    else
#    {
#	print "\n***************************************************************\n";
#	print "*************************     FIN     *************************\n";  
#	print "***************************************************************\n\n";
#	exit;
#    }
}

sub try_prefix
{                                        
    if  ($thisword =~ /^ante/){
	$holdmyphones = "ae n t iy";
	$theroot = substr($thisword, 4, 100);
	prefix_search($theroot);
    }                                        
    elsif($thisword =~ /^anti/){
	$holdmyphones = "ae n t aa iy";
	$theroot = substr($thisword, 4, 100);
	prefix_search($theroot);
    }                                        
    elsif($thisword =~ /^ana/){
	$holdmyphones = "ae n ex";
	$theroot = substr($thisword, 3, 100);
	prefix_search($theroot);
    }                                       
    elsif($thisword =~ /^an/){
	$holdmyphones = "ae n";
	$theroot = substr($thisword, 2, 100);
	prefix_search($theroot);
    }                                       
    elsif($thisword =~ /^ad/){
	$holdmyphones = "ae d";
	$theroot = substr($thisword, 2, 100);
	prefix_search($theroot);
    }                                       
    elsif($thisword =~ /^a/){
	$holdmyphones = "ey";
	$theroot = substr($thisword, 1, 100);
	prefix_search($theroot);
    }                                      
    elsif($thisword =~ /^counter/){
	$holdmyphones = "k aa aw n t rr";
	$theroot = substr($thisword, 7, 100);
	prefix_search($theroot);
    }                                     
    elsif($thisword =~ /^contra/){
	$holdmyphones = "k aa n t r ex";
	$theroot = substr($thisword, 6, 100);
	prefix_search($theroot);
    }                                        
    elsif($thisword =~ /^con/){
	$holdmyphones = "k aa n";
	$theroot = substr($thisword, 3, 100);
	prefix_search($theroot);
    }                                        
    elsif($thisword =~ /^co/){
	$holdmyphones = "k ow";
	$theroot = substr($thisword, 2, 100);
	prefix_search($theroot);
    }                                       
    elsif($thisword =~ /^de/){
	$holdmyphones = "d eh";
	$theroot = substr($thisword, 2, 100);
	prefix_search($theroot);
    }                                  
    elsif($thisword =~ /^di/){
	$holdmyphones = "d iy";
	$theroot = substr($thisword, 2, 100);
	prefix_search($theroot);
    }                      
    elsif($thisword =~ /^endo/){
	$holdmyphones = "eh n d ow";
	$theroot = substr($thisword, 4, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^extra/){
	$holdmyphones = "eh k s t r ex";
	$theroot = substr($thisword, 5, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^ex/){
	$holdmyphones = "eh k s";
	$theroot = substr($thisword, 2, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^ec/){
	$holdmyphones = "eh k";
	$theroot = substr($thisword, 2, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^en/){
	$holdmyphones = "eh n";
	$theroot = substr($thisword, 2, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^homo/){
	$holdmyphones = "h ow m ow";
	$theroot = substr($thisword, 4, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^hyper/){
	$holdmyphones = "h aa iy p rr";
	$theroot = substr($thisword, 5, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^infra/){
	$holdmyphones = "ih n f r ex";
	$theroot = substr($thisword, 5, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^inter/){
	$holdmyphones = "ih n t rr";
	$theroot = substr($thisword, 5, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^intra/){
	$holdmyphones = "ih n t r ex";
	$theroot = substr($thisword, 5, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^in/){
	$holdmyphones = "ih n";
	$theroot = substr($thisword, 2, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^di/){
	$holdmyphones = "d iy";
	$theroot = substr($thisword, 5, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^micro/){
	$holdmyphones = "m aa iy k r ow";
	$theroot = substr($thisword, 5, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^meta/){
	$holdmyphones = "m eh t ex";
	$theroot = substr($thisword, 4, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^omni/){
	$holdmyphones = "aa m n i y";
	$theroot = substr($thisword, 4, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^pant/){
	$holdmyphones = "p ae n t";
	$theroot = substr($thisword, 4, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^pan/){
	$holdmyphones = "p ae n";
	$theroot = substr($thisword, 3, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^para/){
	$holdmyphones = "p ae r ex";
	$theroot = substr($thisword, 4, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^peri/){
	$holdmyphones = "p eh r iy";
	$theroot = substr($thisword, 4, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^post/){
	$holdmyphones = "p ow s t";
	$theroot = substr($thisword, 4, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^per/){
	$holdmyphones = "p rr";
	$theroot = substr($thisword, 3, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^pre/){
	$holdmyphones = "p r iy";
	$theroot = substr($thisword, 3, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^pro/){
	$holdmyphones = "p r ow";
	$theroot = substr($thisword, 3, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^red/){
	$holdmyphones = "r eh d";
	$theroot = substr($thisword, 3, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^re/){
	$holdmyphones = "r iy";
	$theroot = substr($thisword, 2, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^super/){
	$holdmyphones = "s uw p rr";
	$theroot = substr($thisword, 5, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^supra/){
	$holdmyphones = "s uw p r ex";
	$theroot = substr($thisword, 5, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^syn/){
	$holdmyphones = "s ih n";
	$theroot = substr($thisword, 3, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^sub-/){
	$holdmyphones = "s ah b";
	$theroot = substr($thisword, 3, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^sub/){
	$holdmyphones = "s ex b";
	$theroot = substr($thisword, 3, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^se/){
	$holdmyphones = "s ey";
	$theroot = substr($thisword, 2, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^trans/){
	$holdmyphones = "t r ae n s";
	$theroot = substr($thisword, 5, 100);
	prefix_search($theroot);
    }
    elsif($thisword =~ /^un/){
	$holdmyphones = "ah n";
	$theroot = substr($thisword, 2, 100);
	prefix_search($theroot);
    }
 
} ## end try_prefix

sub review_constraints
{
  my(@choices) = @_;
  @temp = ();
  @perm = ();                       
                          # choices commented out are empty sets or redundant
  COMPARE: foreach(@choices)         # from standard.label; still contains er
  {
    if($_ eq "a"){                             
      @all= qw( iy ih ey eh ae aa ao ow ah uw uh rr er ex p t k b d g 
		     f v th dh s z sh zh ch dj m n ng r l w y h );
      if($_ eq $choices[0]) { @perm = @all; }              # first iteration?
      else { @perm = weed_out(@all); }
    }
    elsif($_ eq "b"){ 
      @vowels= qw( iy ih ey eh ae aa ao ow ah uw uh rr er ex );   
      if($_ eq $choices[0]) { @perm = @vowels; } 
      else { @perm = weed_out(@vowels); }
    }
    elsif($_ eq "c"){                             
      @nonVowels= qw(p t k b d g f v th dh s z sh zh ch dj m n ng r l w y h );
      if($_ eq $choices[0]) { @perm = @nonVowels; } 
      else { @perm = weed_out(@nonVowels); }  
    }
    elsif($_ eq "d"){                       
      @trueConsonants= qw( p t k b d g f v th dh s z sh zh ch dj m n ng );
      if($_ eq $choices[0]) { @perm = @trueConsonants; } 
      else { @perm = weed_out(@trueConsonants); }  
    }
    elsif($_ eq "e"){                          
      @glides= qw( r l w y h );                   # glides only
      if($_ eq $choices[0]) { @perm = @glides; }  
      else { @perm = weed_out(@glides); } 
    }
    elsif($_ eq "f"){               
      @nasals= qw( n m ng );                      # nasals    
      if($_ eq $choices[0]) { @perm = @nasals; } 
      else { @perm = weed_out(@nasals); }     
    }
    elsif($_ eq "g"){                        
      @stops= qw( p t k b d g );                  # stops only
      if($_ eq $choices[0]) { @perm = @stops; } 
      else { @perm = weed_out(@stops); }  
    }
    elsif($_ eq "h") {                                    
      @fricatives= qw( f v th dh s z sh zh );     # fricatives only
      if($_ eq $choices[0]) { @perm = @fricatives; } 
      else { @perm = weed_out(@fricatives); }  
    }
    elsif($_ eq "i"){                           
      @affricates= qw( ch dj );                   # affricates only 
      if($_ eq $choices[0]) { @perm = @affricates; } 
      else { @perm = weed_out(@affricates); }         
    }
    elsif($_ eq "j"){                      
      @fricAndAffs= qw( f v th dh s z sh zh ch dj ); # fricatives & affricates
      if($_ eq $choices[0]) { @perm = @fricAndAffs; }  
      else { @perm = weed_out(@fricAndAffs); } 
    }
    elsif($_ eq "k"){                        
      @lips= qw( p b f v m w );
      if($_ eq $choices[0]) { @perm = @lips; } 
      else { @perm = weed_out(@lips); }  
    }
    elsif($_ eq "l"){                        
      @tongueBlade= qw( rr er t d th dh s z sh zh ch dj n r l y );
      if($_ eq $choices[0]) { @perm = @tongueBlade; } 
      else { @perm = weed_out(@tongueBlade); }
    }
    elsif($_ eq "m"){                      
      @tongueBody= qw( k g ng );
      if($_ eq $choices[0]) { @perm = @tongueBody; }  
      else { @perm = weed_out(@tongueBody); } 
    }
    elsif($_ eq "n"){                 
      @lateral= qw( l );
      if($_ eq $choices[0]) { @perm = @lateral; }  
      else { @perm = weed_out(@lateral); } 
    }
    elsif($_ eq "o"){                          
      @rhotic= qw( r );
      if($_ eq $choices[0]) { @perm = @rhotic; } 
      else { @perm = weed_out(@rhotic); }  
    }
    elsif(($_ eq "p+") || ($_ eq "p")){        
      @continuant= qw( f v th dh s z sh zh );
      if($_ eq $choices[0]) { @perm = @continuant; } 
      else { @perm = weed_out(@continuant); }  
    }
    elsif($_ eq "p-"){                        
      @mcontinuant= qw( p t k b d g ch dj m n ng l );
      if($_ eq $choices[0]) { @perm = @mcontinuant; } 
      else { @perm = weed_out(@mcontinuant); }  
    }
    elsif(($_ eq "q+") || ($_ eq "q")){                      
      @sonorant= qw( m n ng l );
      if($_ eq $choices[0]) { @perm = @sonorant; }  
      else { @perm = weed_out(@sonorant); } 
    }
    elsif($_ eq "q-"){                         
      @msonorant= qw( p t k b d g f v th dh s z sh zh ch dj );
      if($_ eq $choices[0]) { @perm = @msonorant; }  
      else { @perm = weed_out(@msonorant); } 
    }
    elsif(($_ eq "r+") || ($_ eq "r")){                                 
      @strident= qw( s z sh zh ch dj );
      if($_ eq $choices[0]) { @perm = @strident; } 
      else { @perm = weed_out(@strident); }  
    }
    elsif($_ eq "r-"){                     
      @mstrident= qw( v th dh );
      if($_ eq $choices[0]) { @perm = @mstrident; }  
      else { @perm = weed_out(@mstrident); } 
    }
    elsif(($_ eq "s+") || ($_ eq "s")){                         
      @round= qw( ao ow uw uh w );
      if($_ eq $choices[0]) { @perm = @round; }   
      else { @perm = weed_out(@round); }
    }
    elsif($_ eq "s-"){             
      @mround= qw( aa ah er rr p b m f v m );
      if($_ eq $choices[0]) { @perm = @mround; }   
      else { @perm = weed_out(@mround); }
    }
    elsif(($_ eq "t+") || ($_ eq "t")){              
      @reduced= qw( er ex );
      if($_ eq $choices[0]) { @perm = @reduced; } 
      else { @perm = weed_out(@reduced); }  
    }
    elsif($_ eq "t-"){                          
      @mreduced= qw( rr );
      if($_ eq $choices[0]) { @perm = @mreduced; }  
      else { @perm = weed_out(@mreduced); } 
    }
    elsif(($_ eq "u+") || ($_ eq "u")){                          
      @anterior= qw( t d th dh s z n l );
      if($_ eq $choices[0]) { @perm = @anterior; }  
      else { @perm = weed_out(@anterior); } 
    }
    elsif($_ eq "u-"){                        
      @manterior= qw( rr er sh zh ch dj r y );
      if($_ eq $choices[0]) { @perm = @manterior; }   
      else { @perm = weed_out(@manterior); }
    }
    elsif(($_ eq "v+") || ($_ eq "v")){                
      @distributed= qw( sh zh ch dj y );
      if($_ eq $choices[0]) { @perm = @distributed; } 
      else { @perm = weed_out(@distributed); }  
    }
    elsif($_ eq "v-"){                     
      @mdistributed= qw( t d s z n );
      if($_ eq $choices[0]) { @perm = @mdistributed; } 
      else { @perm = weed_out(@mdistributed); }  
    }
    elsif(($_ eq "w+") || ($_ eq "w")){                  
      @high= qw( iy ih uw uh k g ng w y );
      if($_ eq $choices[0]) { @perm = @high; } 
      else { @perm = weed_out(@high); }  
    }
    elsif($_ eq "w-"){             
      @mhigh= qw( ey eh ae aa ao ow ah rr er ex r l ); 
      if($_ eq $choices[0]) { @perm = @mhigh; }   
      else { @perm = weed_out(@mhigh); }
    }
    elsif(($_ eq "x+") || ($_ eq "x")){                   
      @low= qw( ae aa ao );
      if($_ eq $choices[0]) { @perm = @low; }  
      else { @perm = weed_out(@low); } 
    }
    elsif($_ eq "x-"){                       
      @mlow= qw( iy ih ey eh ow ah uw uh rr er ex k g ng r l w y ); 
      if($_ eq $choices[0]) { @perm = @mlow; } 
      else { @perm = weed_out(@mlow); }  
    }
    elsif(($_ eq "y+") || ($_ eq "y")){                   
      @back= qw( aa ao ow ah uw uh rr er k g ng r l w );
      if($_ eq $choices[0]) { @perm = @back; } 
      else { @perm = weed_out(@back); }  
    }
    elsif($_ eq "y-"){                   
      @mback= qw( iy ih ey eh ae y );
      if($_ eq $choices[0]) { @perm = @mback; }  
      else { @perm = weed_out(@mback); } 
    }
    elsif(($_ eq "z+") || ($_ eq "z")){                   
      @nasal= qw( m n ng );
      if($_ eq $choices[0]) { @perm = @nasal; }  
      else { @perm = weed_out(@nasal); } 
    }
    elsif($_ eq "z-"){                 
      @mnasal= qw( r l );
      if($_ eq $choices[0]) { @perm = @mnasal; }  
      else { @perm = weed_out(@mnasal); } 
    }
    elsif(($_ eq "aa+") || ($_ eq "aa")){             
      @advTongueRoot= qw( iy ey ow uw w y );
      if($_ eq $choices[0]) { @perm = @advTongueRoot; }  
      else { @perm = weed_out(@advTongueRoot); } 
    }
    elsif($_ eq "aa-"){           
      @madvTongueRoot= qw( ih eh ae aa ao ah uh rr er ex );  
      if($_ eq $choices[0]) { @perm = @madvTongueRoot; } 
      else { @perm = weed_out(@madvTongueRoot); }  
    }
    elsif(($_ eq "ab+") || ($_ eq "ab")){             
      @constTongueRoot= qw( aa ao );
      if($_ eq $choices[0]) { @perm = @constTongueRoot; }  
      else { @perm = weed_out(@constTongueRoot); } 
    }
    elsif($_ eq "ab-"){                       
      @mconstTongueRoot= qw( iy ih ey eh ae ow ah uw uh rr er ex w y );
      if($_ eq $choices[0]) { @perm = @mconstTongueRoot; } 
      else { @perm = weed_out(@mconstTongueRoot); }  
    }
    elsif(($_ eq "ac+") || ($_ eq "ac")){                      
      @stiffVocalFolds= qw( p k f th s sh ch );
      if($_ eq $choices[0]) { @perm = @stiffVocalFolds; }  
      else { @perm = weed_out(@stiffVocalFolds); } 
    }
    elsif($_ eq "ac-"){                     
      @mstiffVocalFolds= qw( b d g v dh z zh dj );
      if($_ eq $choices[0]) { @perm = @mstiffVocalFolds; }  
      else { @perm = weed_out(@mstiffVocalFolds); } 
    }
    elsif($_ eq "ad"){                    
      @spreadGlottis= qw( h );
      if($_ eq $choices[0]) { @perm = @spreadGlottis; } 
      else { @perm = weed_out(@spreadGlottis); }  
    }
  }

  return @perm;
} ## end review_constraints








