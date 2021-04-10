#!/bin/bash
#!/home/busybox/busybox-1.32.1/busybox sh

# Copyright (c) April 5th, 2021 arlusf@github, all rights reserved
# this version does not offer any license agreement
# no warranty is expressed, provided or implied
name='  espdiff.sh  version 5.0'
# deploys clairvoyance(tm) 6 incursive engine to read diff intent
# tested with xterm, lxterminal, rxvt, screen, tmux
# 256color and 24bit direct-color support
# ECMA-48 conformance

##  help
#
#      >$  ./espdiff.sh help

##  install
#    project:  configuration file, registration file or hard-coded
#    shell:    move busybox shebang to first line as required
#    options:  confirm general options below

###  hard-coded
## uncomment to define default project paths
 # projectdir="$HOME"'/path/to/project/base'
 # sourcedir='current'
 # targetdir='previous'

###  general options
## locate configfile in a secure area
readonly configfile="$HOME"'/.local/.espdiffrc'
 # configfile='/root/espdiff/.espdiffrc' # embedded devices
readonly mdsum='12f747c66f2602751b7961e4c62eb616' # configfile
 # mdsum='unlocked' # disable md5 verification
## session location for project registration
sessiondir="$HOME"
## where to create report directory
tmpdir='/tmp'
 # tmpdir='/run/user/1000' # systemd tmpfs, user owned
## restriction on names in project registration file
allowchars='a-zA-Z0-9/\_. -' # literal dash - last

###  format options
columns="$(stty size)" # generally available
lines="$columns"; lines="${lines% *}"
columns="${columns#* }"
 # columns="$(tput cols)"; lines="$(tput lines)" # alternate method
 # columns=153; lines=40 # static over-ride


found(){ [ -f "$1" ] && echo 'exists' || echo 'not found'; }
edhelp="
##  usage:
#    espdiff.sh ( man ) ( page | keep | term )  file ( file2 )  |  dir1  dir2
#    man  - read the manual, arguments are optional
"
edman(){
echo "
$name

##  small project diff - compare source files with target folder
#    side by side + line numbers + 256 & 24-bit color + multi-process
#    numbering up to 9999 is presented in the middle column
#    the line number of missing lines reflects those of the target file
#    additions and context lines are to the right
#    deletions are on the left hand side
#    sub-folder contents are briefly evaluated
$edhelp
##  display-mode argument: file or directory arguments may follow
#    (when not specified)  all reports display in one page with less
#   page  - navigate each report separately with less  ( :n  :p  :x  = )
#   keep  - write report files to current or project folder, no display
#   term  - standard output to terminal

##  file and directory arguments are solitary or subject to display mode
#
#   file argument:
#   file  ~ compare the specified project file, or  ' ? '  list project files
#
#   dir argument:
#   dir   ~ compare the specified project folder
#
#   extra-project file arguments:
#   file  file2  ~ compare file with file2
#
#   extra-project directory arguments:
#   dir1  dir2  ~ compare files in dir1 with dir2


##  resource configuration file over-rides hard-coded definitions
#   skip  - ignore resource file - given before any other arguments
#    this file is not sanitized, use with care, md5 verified
#
#      $configfile  $(found "$configfile")


##  project registration ( .esprj ) file properties have final priority
#    espdiff.sh looks in current, then parent, then session dir
#    once found and registered as the session project, looking stops
#    if not found, prior registration will be used instead
#
#      .esprj  $(found '.esprj')
#      ../.esprj  $(found '../.esprj')
#      session $sessiondir.esprj  $(found "$esprj")
#
##  to view the current register, invoke espdiff.sh with  ' make '
#
#    registration files are sanitized for allowed and correct sequences
#    path and color names are restricted to the following characters:
#      '$allowchars'
#    any lines not accepted are sent to stderr
#
#    sample format:
#     (paths are required to register a project)
#
#      projectdir='/home/path/to/project'
#      sourcedir='current'
#      targetdir='previous/version'
#
#    projectdir is path to the project base folder
#    sourcedir and targetdir are relative to projectdir
#
#    lines and columns format over-ride is permitted
#      columns='$columns'
#      lines='$lines'
#
##  explicit project registration:
#    ' register '  project file in  ' path( name ) '  as session project" |
less
exit
}

## utf-8
#   variable width characters are translated to '?'

##  core performance test
#    project reports are parsed but not displayed
#    shows concurrent process limiting, no post-processing
#
#      >$  time ./espdiff.sh test

###  system options
umask 066 # user only permissions for new files
# maximum number of simultaneous diff processes (main loop)
dproclimit=1
# use external link instead of busybox builtins
alias diff="$( which diff )" # -y option
alias less="$( which less )" # -r option

###  project options
context=1 #  lines of leading and tailing context
glob='*' # default, process all files in source folder
# enable 24bit depth direct-color test for 'colors' and 'make' options
testdirect='false'
# color palette may be redefined in project registration file
# 256color names are sourced from configuration file
# 24bit direct-color names are user-supplied
#
#    show color definitions:
#      >$  ./espdiff.sh make
#    show color swatch:
#      >$  ./espdiff.sh colors
#

##  terminal control sequences
# C0 code bytes (7-bit, 0-127, control 0-31)
esc=$'\033' # 27 0x1b ascii escape key-code ^[
st=$esc'\' # ST
bell=$'\007' # BEL
osc=$esc']' # Operating System Command  OSC Ps ; Pt BEL (xterm)
# Ps=0 change icon name and window title ; Pt=text  BEL or ST (\e\\)
titlepre=$osc'0;' # OSC + change window title
titletxt='espdiff.sh' # Pt
csi="$esc"'[' # CSI - Control Sequence Introducer
bold=$csi'1m' # m is final character for CSI
reset=$csi'0m'
normal=$csi'22m' # not bold, not faint
reverse=$csi'7m'
fgc=$csi'38;5;' # CSI + set foreground indexed-color
fdc=$csi'38;2;' # foreground direct-color sequence
# relict form: '\e[38:2::R:G:Bm' ITU-T Recommendation T.416, aka ISO/IEC 8613-6
# color-space is to be specified within the consecutive double colon syntax
# (future use... color-space, tolerance, alpha?)
bdc=$csi'48;2;' # background direct-color
bkg=$csi'48;5;' # background 256color
# default colors, 256color index
# 'gfmt' diff symbol  <|>
clrbg=$bkg'235m';   typ_clrbg='background color'
clrbrf=$fgc'103m';  typ_clrbrf='brief section header'
clrerr=$fgc'124m';  typ_clrerr='error'
clrmsf=$fgc'172m';  typ_clrmsf='missing file'
clrsmd=$fgc'185m';  typ_clrsmd='changed to line'
clrtmd=$fgc'186m';  typ_clrtmd='changed from line and gfmt'
clrnew=$fgc'159m';  typ_clrnew='added line'
clrrmv=$fgc'101m';  typ_clrrmv='removed text'
clrtxt=$fgc'188m';  typ_clrtxt='context line, separator and type'
clrsrc=$fgc'108m';  typ_clrsrc='source line-number and gfmt, new file'
clrtgt=$fgc'130m';  typ_clrtgt='target line-number and gfmt'
clrttl=$fgc'195m';  typ_clrttl="header ($bold bold $normal)"
clrdcs=$fdc'128;128;128m'
typ_clrdcs='24bit direct-color sample'
nam_clrdcs='darker gray' # 24bit color names are user specified
# 256color index to X11R4 name is sourced from configuration file


ramps(){
 c=0
 while [ $(( c += 1 )) -le "$columns" ]; do
  [ $c -gt 255 ] && gradient=255 || gradient=$c
  greyscale="$greyscale$bdc$gradient;$gradient;${gradient}m "
  rramp="$rramp$bdc$gradient;0;0m "
  gramp="$gramp${bdc}0;$gradient;0m "
  bramp="$bramp${bdc}0;0;${gradient}m "
 done
 printf '%s\n%s\n%s\n%s\n' "$greyscale" "$rramp" "$gramp" "$bramp"
}


project(){
 # project support utilities
 # generate a registration file or show color swatches
 [ "$testdirect" = true ] && colors="$colors"'|dcs'
 if [ "$1" = 'gen' ]; then
  pdirlen=${#projectdir}
  [ "$pdirlen" -lt ${#sourcedir} ] && pdirlen=${#sourcedir}
  [ "$pdirlen" -lt ${#targetdir} ] && pdirlen=${#targetdir}
  pdirlen=$(( pdirlen + 4 ))
  pdirlen='%-'"$pdirlen"'s'
  printf '\nprojectdir='"$pdirlen"'# project base path\n' "'$projectdir'"
  printf 'sourcedir='"$pdirlen"' # relative from projectdir\n' "'$sourcedir'"
  printf 'targetdir='"$pdirlen"' # relative from projectdir\n' "'$targetdir'"
  printf 'titletxt=%-14s    # project title\n' "'$titletxt'"
 else # 'show'
  printf '%b\n' "$bgline"
  ascii='AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz 0123456789'
  ascii="${ascii::${#bgpoly}}" # truncate and pad
  aspace="${bgpoly:${#ascii}}"; ascii="$ascii$aspace"
  sample="
$ascii
$bold$ascii
$reverse$bgpoly
$bgpoly$reset
$bgline
"
 fi
 if [ -n "$xnam" ]; then # 256color names from configuration file
  x=-1; IFS=','; for b in $xnam; do eval "xnam$(( x += 1 ))=$b"; done
  #! eval can be dangerous... but so is ${!var}
 fi
 IFS=\|
 for color in $colors; do
  color='clr'"$color"
  typ='typ_'"$color"
  nam='nam_'"$color"
  eval "colr=\$$color"
  cidx="${colr:7:-1}"
  if [ "${colr::${#fgc}}" = "$fgc" ]; then
   # $colr begins with '$fgc'
   key='$fgc'
   eval "nam=\"\$xnam$cidx\""
   # $fgc and $bkg sequences use configured names
  elif [ "${colr::${#bkg}}" = "$bkg" ]; then
   key='$bkg'
   eval "nam=\"\$xnam$cidx\""
  else
   eval "nam=\"\$$nam\""
   [ "${colr::${#fdc}}" = "$fdc" ] && key='$fdc' || key='$bdc'
  fi
  : "${nam:='unnamed'}"
  eval "typ=\$$typ"
  if [ "$1" = 'gen' ]; then
   [ "$color" = 'clrbg' ] && fcol='' || fcol=$colr
   instr "$key" '$fdc $bdc' &&
    printf '%snam_%s\n' "$fcol" "$color='$nam'" &&
     nam="user custom"
   color="$color=$key'${colr#*[25];}'"
   printf '%s%-27s# %-24s%s\n' "$fcol" "$color" "$nam" "$typ$clrbg"
  else # 'show'
   [ "$color" = 'clrbg' ] && continue
   padline "$clrbg$colr" "'$nam'   $typ" "$sample"
  fi
 done
 [ "$1" = 'show' ] && [ "$testdirect" = 'true' ] && ramps
 printf '%s\n' "$reset$bgpoly"
 exit
}


sanitize(){
 scolor="$colors"'|dcs' # permit direct-color sample in project registration
 regx="((context='[1-9]')"
 regx="$regx|(testdirect='(true|false)')"
 regx="$regx|((columns|lines)='[0-9]{1,4}')"
 regx="$regx|((targetdir|sourcedir|projectdir)='[$allowchars]{3,80}')"
 regx="$regx|((titletxt|nam_clr($scolor))='[$allowchars]{3,25}')"
 num='[0-9]{1,3}'
 cdirect="$num"'[;:]'"$num"'[;:]'
 regx="$regx|(clr($scolor)=[$](fgc'|bkg'|([fb]dc)'$cdirect)${num}m'))" # m
 esprjtmp="$esprj"'tmp'
 esprjraw="$esprj"'raw'
 seqrx="$csi"'[^m]*m' # m is CSI final char
 if [ "$1" ]; then
  regfile="$1"
  absolute="$currentdir/${1%/*}"
 else
  regfile='.esprj'
  absolute="$currentdir"
  [ "$prloc" = 'parent' ] && absolute="${absolute%/*}"
 fi
 # strip blank and comment lines along with any preceeding whitespace
 sed -r -- 's/'"$seqrx"'//g;/^\s*(#.*)?$/d' "$regfile" |
  tr -cd '\12\15\40-\176' | # filter - pass lf, cr, printable
   tee -- "$esprjtmp" |
    # filter sequences with correct option=value, once per line
    # insert blank line if $regx does not match
    sed -rn -- 's/.*'"$regx"'.*/\1/p;te;i
:e' | tee -- "$esprjraw" | {
     # escape forward slashes in path
     # (instead of using up a filename char to delimit sed)
     absolute="${absolute//\//\\/}"'\/'
     # fix relative projectdir in session registration file
     fixrel="s/(projectdir=')([^/][^']*')/\1"
     sed -r -- "$fixrel$absolute"'\2/;Te;i# fixed relative projectdir
:e'; } > "$esprj"
 # send rejected lines to stderr
 diff -yt -- "$esprjraw" "$esprjtmp" |
  sed -nr -- 's/^\s+\|(.*)/'"$clrerr"'\1'"$reset"'/p' 1>&2
 # cleanup
 rm -f -- "$esprjtmp" "$esprjraw"
}


## preliminary arguments
printf '%s' "$reset" # start with 'clean slate'
case "$1" in
 '--help'|?'help'|'help') echo "$edhelp"; exit ;;
 'skip') shift ;; # skip or include resource configuration file
 *)
  if [ -f "$configfile" ]; then
   if [ 'unlocked' = "$mdsum" ]; then
    lock="$clrerr$mdsum$reset"
    sum="$mdsum"
   else
    sum="$( md5sum -- "$configfile" )"
    sum="${sum%% *}"
   fi
   if [ "$sum" = "$mdsum" ]; then
    printf 'using %s %s\n' "$configfile" "$lock"
    . "$configfile"
   else
    printf '%sconfigfile checksum unverified%s\n' "$clrerr" "$reset" 1>&2
   fi
  fi
 ;;
esac

instr(){ # return true if $1 is a substring of $2, 0=true, !0=false
 strin="${2/"$1"}"; [ "${#strin}" -ne "${#2}" ] && return 0 || return 1; }

fixup(){ [ "${1: -1}" = '/' ] && echo "$1" || echo "$1"'/'; }

# after resource configuration
tmpdir="$( fixup "$tmpdir" )"
sessiondir="$( fixup "$sessiondir" )"
esprj="$sessiondir"'.esprj' # session project file

# preliminary settings
readonly currentdir="$( pwd )"
colors='bg|brf|msf|tgt|src|smd|txt|ttl|new|tmd|rmv|err'

##  include project registration file
# explicit
if [ "$1" = 'register' ]; then
 [ -n "$2" ] && {
  [ -d "$2" ] && regp="$( fixup "$2" )"'.esprj' || regp="$2"
  if [ -f '.esprj' ] || [ -f '../.esprj' ]; then
   echo 'local project has priority'
  elif [ -f "$regp" ]; then
   if [ "$regp" -ef "$esprj" ]; then echo 'session previously registered'
   else
    printf 'register project %s\n' "$regp"
    sanitize "$regp"
    sed -n 's/^$//;te;p;:e' "$esprj"
   fi
  else
   printf 'no project file: %s\n' "$regp"
  fi
  exit
 }
 set 'make'
fi
#implicit
prloc='default'
if [ -f '.esprj' ]; then
 prloc='local'
else
 cd ..
 if [ -f '.esprj' ]; then
  prloc='parent'
 elif [ -f "$esprj" ]; then
  prloc='session'
  reginfo="$sessiondir"
 fi
fi
if [ "$prloc" != 'default' ]; then
 if [ "$prloc" != 'session' ]; then
  if [ '.esprj' -ef "$esprj" ]; then
   prloc='self' # sessiondir is same location as '.esprj file
  else
   sanitize
  fi
 fi
 echo "$prloc"' registration '"$reginfo"
 . "$esprj"
fi

padline(){ printf '%s\n' "$1$2${bgpoly:${#2}}$3"; } # pad to width

# effect potential 'columns' over-ride from config or reg file
bgpoly="$( printf "%-${columns}s" )"
bgline="$clrbg$bgpoly"

##  main arguments
mode='one' # display
state='default' # semaphore
# allow mode argument after file/dir arguments
[ -n "$3" ] && instr "$3" 'man make colors term page test keep' &&
 set "$3" "$1" "$2"
case "$1" in
 'man') edman ;;
 'make') project 'gen' ;;
 'colors') project 'show' ;;
 'term') mode='term' ;;
 'page') mode='page' ;;
 'test') mode='test' ;;
 'keep') mode='keep'; tmpdir='' ;;
 '--') shift ;; # end-of-options, default mode
esac
[ "$mode" = 'one' ] || shift # if $mode is not default, $1 was a mode argument
if [ -n "$2" ]; then # extra-project diff
 cd "$currentdir" || exit
 if [ -d "$1" ] && [ -d "$2" ]; then # compare two directories
  state='dir'; sourcedir="$( fixup "$1" )"; targetdir="$( fixup "$2" )";
  projectdir=''
 elif [ -f "$1" ] && [ -f "$2" ]; then # compare two files
  state='dual'; sourcedir=''; targetdir='';
  fname="${1##*/}"; sourcefile="$1"; targetfile="$2"
 else
  echo 'valid arguments are:  file1 file2  or:  dir1 dir2'
  exit
 fi
elif [ -n "$1" ]; then  # compare one project file
 state='single'
fi

# validate inputs
if [ -n "$sourcedir" ] && [ -n "$targetdir" ] && [ -n "$projectdir" ]; then
 projectdir="$( fixup "$projectdir" )"
 sourcedir="$( fixup "$sourcedir" )"
 targetdir="$( fixup "$targetdir" )"
 [ -d "$projectdir" ] ||
  { echo 'invalid projectdir: '"$projectdir"; exit; }
 cd "$projectdir" || exit
 [ -d "$projectdir$sourcedir" ] ||
  { echo 'invalid sourcedir '"$projectdir$sourcedir"; exit; }
 [ -d "$projectdir$targetdir" ] ||
  { echo 'invalid targetdir '"$projectdir$targetdir"; exit; }
 [ "$prloc" = 'default' ] &&
  echo "$prloc"' registration' # hard-coded
 if [ "$state" = 'single' ]; then
  sproj="$projectdir$sourcedir$1"
  if [ -d "$projectdir$1" ]; then # compare specified project folder
   targetdir="$( fixup "$1" )"
   state='default'
  elif [ -f "$sproj" ]; then # compare one project file
   sourcedir="$sourcedir$1"
   glob=''
  else
   [ '?' != "$1" ] && help="or 'help'" &&
    notfile='not a project file: '"$clrerr$sproj$reset"
   echo "$notfile" # blank line or 'not a project file'
   ls --color=always -- "$projectdir$sourcedir"
   echo "$help" # blank line or 'help'
   exit
  fi
 fi
elif ! instr "$state" 'dual dir'; then
 printf 'no project paths%s' "$edhelp"
 exit
fi


diffproc(){
 # diff   side-by-side  report-identical-files  expand-tabs  minimal
 result="$( diff -ystd --width="$dwidth" -- "$sourcefile" "$targetfile" 2>&1 )"
 dpret=$?
 case "$dpret" in
  0) padline "$clrtxt" " $fname" >> "$samefile" ;;
  1)
   padline "$clrsmd" " $fname" >> "$changefile"
   espr="$reportdir"'/report_'"$fname"'.espdif'
   if [ -d "$sourcefile" ]; then
    padline "$clrbrf" "${dspace:${#foldif}/2}$foldif" > "$espr"
    padline "$clrsmd" " $sourcefile" >> "$espr"
    padline "$clrtmd" " $targetfile" >> "$espr"
    #printf '%s' "$result" > tmpfoldif
   else
    # translate first byte of variable width utf-8 char to '?'
    # (positioning gfmt at dpos)
    # pass ascii lf, cr, printable chars
    # tab '\11' expansion to spaces by diff prior
    # include context lines, add line numbers
    printf '%s' "$result" |
     tr '\300-\367' '?' |
      tr -cd '\12\15\40-\176' |
       grep -nEC"$context" -- '^.{'"$dpos"'}[<>|].*' |
        tfixdif > "$espr" # parse filtered diff output
   fi
  ;;
  2) padline "$clrmsf$clrbg" "$result" >> "$errorfile"'_' ;;
  *)
   printf '\nunknown return code %s\n\n  %s\n' "$dpret" "$result" >> "$unknown"
  ;;
 esac
}


tfixdif(){
 # source-line number = diff numbering - removed lines
 # context-line and changed-line numbers - same as source-lines
 # removed-line number = diff numbering - added lines
 cmpoff=''
 srcoff=''
 modline=''
 while IFS='' read -r fline; do
  if [ "$fline" = '--' ]; then
   # separator (--) line, pad with spaces to position
   sep="${dplace:$newlen}${dseparator: -$newlen}"
   printf '%s\n' "$clrtxt$dspace$sep$sepspace"
  else
   # chop longest match from end, including colon or dash ('type')
   number="${fline%%[:-]*}"
   num=${#number}
   type="${fline:$num:1}"
   # split line in two
   left="${fline:$num+1:$dpos-1}"
   right="${fline:$num+1+$dpos}"
   if [ "$type" = ':' ]; then
   # added, deleted and changed lines
    gfmt="${right::1}";
    # format as appropriate to diff symbol $gfmt
    if [ "$gfmt" = '>' ]; then
    # removed lines reflect target file line number
     : $(( srcoff += 1 ))
     newnum=$(( number - cmpoff ))
     right="$clrtgt<$clrrmv${right:1}${dspace:${#right}}$clrtgt"
    elif [ "$gfmt" = '<' ]; then
    # new lines reflect source line number
     : $(( cmpoff += 1 ))
     newnum=$(( number - srcoff ))
     left="$clrnew$left"
     right="$clrsrc>${right:1}${dspace:${#right}}$clrsrc"
    else
    # altered lines reflect source line number
     newnum=$(( number - srcoff ))
     left="$clrsmd$left"
     right="$clrtmd$right${dspace:${#right}}$clrsrc"
     : $(( modline += 1 ))
    fi
   else
   # context lines, source line number
    newnum=$(( number - srcoff ))
    left="$clrtxt$left${dspace:${#left}+3}"
    right="$dspace$clrsrc"
   fi
   # re-assemble completed line for output
   newlen="${#newnum}"
   right="$right${dplace:$newlen}$newnum$clrtxt$type"
   printf '%s %s\n' "$right" "$left"
  fi
 done
 # summary
 # justification - left (align with target text), right \n center
 # ' 1 lines' pattern match requires a space after =" (next three lines)
 [ "$cmpoff" ] && cmpoff=" $cmpoff lines added  "
 [ "$modline" ] && modline=" $modline lines modified  "
 [ "$srcoff" ] && srcoff=" $srcoff lines removed"
 summary="$cmpoff$modline$srcoff"
 [ ${#targetfile} -gt "$dspclen" ] &&
  targetfile=${targetfile: -$dspclen+1}
 [ ${#sourcefile} -gt "$dspclen" ] &&
  sourcefile=${sourcefile: -$dspclen+1+$even}
 parta="$clrttl$bold$targetfile"
 partb="${dspace:${#summary}/2}${summary// 1 lines/ 1 line}"
 partb="$clrbrf$partb${bgpoly:${#partb}}"
 sfmt='%s\n %s%'$(( columns - ${#targetfile} - 2 ))'s%s \n%s\n%s\n'
 printf "$sfmt" "$bgpoly" "$parta" "$sourcefile" "$normal" "$partb" "$bgpoly"
}


supreport(){
 # supplemental report - find missing files for project
 export LC_ALL=C # sort order
 supsrc="$reportdir"'supsrc'
 ls "$1" > "$supsrc"
 suptgt="$reportdir"'suptgt'
 ls "$2" > "$suptgt"
 mdiff="$( diff -- "$supsrc" "$suptgt" | {
  while IFS='' read -r missing; do
   padline '' "$missing"
   done; } |
   sed -nr -- 's/^<(.*) /'"$clrsrc"'>'"$clrmsf"'\1 /p
    s/^>(.*) /'"$bell$clrtgt"' <'"$clrmsf"'\1/p' |
    sort -n --  )" # bell sorts first
 # write supplemental report data to stdout
 [ -n "$mdiff" ] &&
  padline "$bgpoly
$clrbrf" 'Missing' "
$mdiff"
 # cleanup
 rm -f -- "$supsrc" "$suptgt"
}

mainloop(){
 # queue files for diff comparison, govern spawn limit
 dpl=0
 foldif='sub-folder contents differ'
 for sourcefile in "$sourcedir"$glob; do
  # posix glob empty set yields literal match string
  if [ -e "$sourcefile" ]; then # ensure result exists
   # launch up to $dproclimit processes in the background
   if [ $(( dpl += 1 )) -ge "$dproclimit" ]; then # one at a time
    [ "$mode" = 'test' ] && printf '%s\n' "wait $sourcefile"
    wait -n  # wait for any job to complete
   fi
  else
   echo 'no source files '"$sourcefile" &&
   exit
  fi
  fname="${sourcefile##*/}"
  targetfile="$targetdir$fname"
  diffproc &  # process diff results
 done
}


##  change terminal window title, assume $PS1 resets this
printf '%s' "$titlepre$titletxt$st"

##  pre-formatting
even=$(( columns % 2 )) # adjust for odd number of columns
dseparator='----' # width of max line number (9999)
nmax=${#dseparator}
dplace='     ' # $dseparator plus one (spaces)
dplace="${dplace:$even}"
dwidth=$(( columns - nmax - 2 ))
dpos=$(( dwidth/2 - 1 + even )) # midpoint of diff -y
# left field ~ half the columns
dspclen=$(( dpos + 2 ))
dspace="${bgpoly::$dspclen}"
# spacing to fill separator lines
sepspace="${dspace:1}"

##  setup temp folder, exit trap handles removal
texit(){ [ -n "$reportdir" ] && [ "$mode" = 'keep' ] || rm -rf -- "$reportdir"; }
unset reportdir
trap texit EXIT
reportdir="$( mktemp -d "$tmpdir"'_espdiffXXXXXX' )" ||
 { printf '%serror creating temp file\n' "$clrerr" 1>&2; exit 1; }

##  assign brief names
unknown="$reportdir"'/_000_unknown_'
errorfile="$reportdir"'/_001_error_'
missfile="$reportdir"'/_002_missing_'
changefile="$reportdir"'/_003_changed'
samefile="$reportdir"'/_004_same'

##  initiate diff reports
if [ "$state" = 'dual' ]; then
 # directly dispatch extra-project 'file' runs
 diffproc;
else
 instr "$state" 'default dir' &&
  supreport "$sourcedir" "$targetdir" > "$missfile" &
  # supplemental report for default-project and extra-project 'dir'
 mainloop # queue for dispatch
 # single-project, default-project and extra-project 'dir' runs
fi

wait # for report sub-processes to finish

# core time test exits here
[ "$mode" = 'test' ] && exit


##  post-processing


finish(){
 # fill bottom of file given with lines of spaces, minus offset argument
 flines="$(wc -l -- "$1")"
 flines="${flines%% *}"
 # can be called with $2 offset omitted
 polylines=$(( lines - flines - ($2 + 1) ))
 while [ $(( polylines -= 1 )) -ge 0 ]; do
  printf '%s\n' "$bgpoly" >> "$1"
 done
}


# prepare brief section labels
# missing files section is prepped in 'initiate diff reports'
padline "$clrbg$bgline
$clrbrf" 'Errors' > "$errorfile"
padline "$bgpoly
$clrbrf" 'Different' > "$changefile"'_'
padline "$bgpoly
$clrbrf" 'Same' > "$samefile"'_'
# assemble preview page from meta files
[ -f "$changefile" ] &&
 sort -- "$changefile" > "$changefile"'__'
[ -f "$samefile" ] &&
 sort -- "$samefile" > "$samefile"'__'
cat -- "$reportdir"/_00*_ > "$reportdir"'/_0_brief'
printf '%s\n' "$bgpoly" >> "$reportdir"'/_0_brief'
# remove meta files
[ "$mode" = 'keep' ] ||
 rm -f -- "$reportdir"/_00* "$changefile" "$samefile"

# prepend statistics from bottom of each report to top
rcount=0
for final in "$reportdir"/*.espdif
do
 [ -f "$final" ] && { # skip loop if no reports
  tfx="$final"'_tfx'
  tail -n 3 -- "$final" | {
   IFS=''; read -r line; read -r swap
   instr "$foldif" "$line" ||
    printf '%s\n%s\n%s\n%s\n' "$bgline" "$swap" "$line" "$bgpoly" > "$tfx"
  }
  cat -- "$final" >> "$tfx"
  [ "$mode" = 'page' ] && finish "$tfx" # fill remaining lines with spaces
  rcount=$(( rcount + 1 ))
 }
done

# 'keep' exits here, or remove intermediate report files
[ "$mode" = 'keep' ] && exit || rm -f -- "$reportdir"/*.espdif

# paint empty bottom lines of initial page with background color
if [ $mode = 'page' ]; then
 finish "$reportdir"'/_0_brief'
elif [ "$mode" = 'one' ]; then
 if [ "$rcount" = 1 ]; then
  # combined brief and one report file
  alines="$( wc -l -- "$reportdir"'/_0_brief' )"
  finish "$final"'_tfx' "${alines%% *}"
 elif [ -z "$tfx" ]; then
  # no report file was generated
  finish "$reportdir"'/_0_brief'
 fi
fi

##  display
if [ "$mode" = 'page' ]; then
 # paged, less
 less -rc -- "$reportdir"/*
elif  [ "$mode" = 'one' ]; then
 # all reports in one, less
 cat -- "$reportdir"/* | less -rc --
elif  [ "$mode" = 'term' ]; then
 # no less
 cat -- "$reportdir"/*
 printf '%s\n\n' "$reset"
fi

exit


###  footnote

##  xterm
#    TERM='xterm-256color'
#    menus C-left/right mouse

##  tmux
#    TERM='screen-256color' or 'tmux-256color'
#    scrollback C-b [

##  screen
#    24bit direct-color in master branch (at least since 4.99)
#    TERM='screen-256color'
#    bce is not enabled by default
#    C-a : bce on, or insert 'bce on' line into screenrc file

##  less
#    fast - files do not have to load completely before display begins
#    caveat: no color buffer for hidden lines
#    (scroll-back coloring is reversed)

##  strategies for consistent background color
#    pad each line with spaces to edge of screen, or
#    print to each cell of window text area then over-writing, or
#    'yellow background\033[43m home\033[H erase\033[J' or
#    '\e[K' at start of each line, then erase to bottom of screen
#    not every terminal control-sequence code enjoys broad support
#    even so, actual rendering may not be equivalent

##  256color index
#    lookup tables shipped onboard a vga graphics card eprom
#    rgb levels were originally preconfigured to suit crt display hardware
#    variation today can result from algorithm discrepancy or preference
#   0-7 first 8 - ANSI color names, linux kernel system palette
#    color selection was limited to this range initially
#   8-15 next 8 - bright versions of first 8 colors, or may be bold font
#    terminal themes are implemented in the first sixteen colors
#   16-231 color cube - six intensity levels for  r, g, b  coordinates
#    decimal  0, 95, 135, 175, 215, 255  (00, 5f, 87, af, d7, ff hex)
#   232-255 greyscale - 24 shades,  8+(10*shade),  8;8;8m - 238;238;238m

##  busybox
#    if busybox is the default system shell:
#     change shebang to #!/bin/sh
#     install full versions of builtins diff, less
#    distribution binary does not pass unit tests A or B:
#     compile busybox-1.32.1 (latest stable)
#      make defconfig
#      make menuconfig - add or remove functionality/builtins*
#      make

##  unit tests - first line describes correct result
#
#    A) displays 'one' after 1 second duration
#    sleep 3 && echo three & sleep 1 & wait -n; echo one
#      fail: displays 'one' immediately
#
#    B) displays 'qwe'
#    a='asdfqwerty'; echo ${a:4:-3}
#      error:
#      sh: Illegal number: -3
#    ${ substring expansion variable : offset parameter : -length is negative }
#      in Bash since 4.2-alpha, busybox?

##  troubleshooting & theory of operation
#
#   $dpos is exact offset to the middle column in side-by-side diff output
#   this is expected to be standard for any implemented diff
#   using $dpos, grep provides line numbers, discarding unselected context
#   the line is then split in half, colorized and reassembled

# 'clairvoyance 6' and 'incursive engine' are trademarks of espdiff.sh

###EOF###
