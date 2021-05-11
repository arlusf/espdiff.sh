#!/bin/bash
#!/bin/zsh
#!/home/busybox-1.32.1/busybox sh

name='  espdiff.sh  version 5.0'
# deploys clairvoyance(tm) 6 incursive engine to read diff intent
# tested with xterm, lxterminal, rxvt, screen, tmux
# 256color and 24bit direct-color support
# ECMA-48 conformance

# Copyright (c) 2021 arlusf@github, all rights reserved
# no warranty is expressed, provided or implied
# this version does not offer any license agreement
# this document has not received any sort of peer review
# information contained herein must not be taken as consumable
# security features or lack thereof have not been evaluated by any third party

##  help
#
#      >$  ./espdiff.sh help

##  install
#    shell:    move shebang to first line as required
#    project:  registration file or inline register
#    options:  review general options below

###    inline register
# uncomment to define default project paths
  # projectdir="$HOME"'/path/to/project/base'
  # sourcedir='current'
  # targetdir='previous'

###    general options

##  configfile location and md5sum
readonly configfile="$HOME"'/.espdiffrc'
  # readonly configfile='/root/.espdiffrc' # embedded devices
readonly mdsum='225755966757f794e55b00aae8e82d02'
  # readonly mdsum='unlocked' # disable configfile verification

##  session location for project registration
sessiondir="$HOME" #/.local/espdsh"
mdsessions='' # do not require session verification
  # mdsessions=" derived from resultant session register
  # 3c3d3c5249b3c5046f318a39084d672f .esprj from example.tar
  # 6f66685a3761f8eb60a580568e18456d  testdirect='true' >> .esprj
  # "

##  where to create report directory
tmpdir='/tmp'
  # tmpdir='/run/user/1000' # systemd tmpfs, user owned

##  sanitized folder and color names in project registration file
allowchars='a-zA-Z0-9/\_. -' # literal dash - last

###   format options
size="$(stty size)" # generally available
lines="${size% *}"
columns="${size#* }"
  # columns="$(tput cols)"; lines="$(tput lines)" # alternate method
  # columns=153; lines=40 # static over-ride


found(){ [ -f "$1" ] && echo 'exists' || echo 'not found'; }
shelp="
##  usage:
#    espdiff.sh ( man ) ( page | keep | term )
#               ( file ( file2 )  |  dir1 ( dir2 ) )
#    arguments are optional
"
sman(){
echo "
$name

##  small project diff - compare source files with target folder
#    side by side + line numbers + 256 & 24-bit color + multi-process
#    numbering up to 9999 is presented in the middle column
#    the line number of a removed line reflects that of the target file
#    additions and context lines are to the right
#    deletions are on the left hand side
#    sub-folder contents are briefly evaluated
$shelp
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


##  resource configuration file over-rides inline definitions
#   skip  - ignore resource file - given before any other arguments
#    md5sum verified
#
#      $configfile  $(found "$configfile")


##  project registration ( .esprj ) file properties have final priority
#    espdiff.sh looks in current dir, then in parent dir for a project
#    once found and registered as the session project, looking stops
#    if not found, prior registration will be used instead
#
#      .esprj  $(found '.esprj')
#      ../.esprj  $(found '../.esprj')
#      session $sessiondir.esprj  $(found "$esprj")
#
##  to view the session register, invoke espdiff.sh with  ' make '
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

##  utf-8
#    variable width characters are translated to '?'

##  mixed layout
#    experimental feature, show containing function/section
#    remove dependency on external diff for busybox

##  core tests
#    project reports are parsed but not displayed, no post-processing
#
#    show concurrent process limiting
#      >$  espdiff.sh test
#
#    wait delay sequence
#      >$  espdiff.sh seq
#
#    performance test
#      >$  espdiff.sh time

###   system options
umask 066 # user only permissions for new files
# maximum number of simultaneous diff processes (main loop)
dproclimit=3

###   project options
context=1 #  lines of leading and tailing context
glob='*' # default, process all files in source folder
##  show containing function names and section labels
# bash:  fxname(){  |  ##  |  ###
dfunc='\(^[[:alpha:]]\+(){$\)\|\(^[#]\{2,3\}\)'

##  enable 24bit depth direct-color test for 'colors' and 'make' options
  # testdirect='true'
testdirect='false'

# color palette may be redefined in project registration file
# 256color names are sourced from configuration file
# 24bit direct-color names are user-supplied
#
#    show color definitions:
#      >$  ./espdiff.sh make
#    show color swatch:
#      >$  ./espdiff.sh colors

##  terminal control sequences
# C0 code bytes (7bit, 0-127, control 0-31)
esc=$'\033' # 27 0x1b ascii escape key-code ^[
st=$esc'\' # ST (8bitC1=\233)
bell=$'\007' # BEL

osc=$esc']' # Operating System Command  OSC Ps ; Pt BEL  (xterm)
# Ps=0 change icon name and window title ; Pt=text  BEL or ST (\e\\)
titlepre=$osc'0;' # OSC + change window title
titletxt='espdiff.sh' # Pt

csi=$esc'[' # CSI - Control Sequence Introducer ^[[
bold=$csi'1m' # m is final character for CSI
reset=$csi'0m'
normal=$csi'22m' # not bold, not faint
reverse=$csi'7m'

bgc=$csi'48;5;' # background 256color
fgc=$csi'38;5;' # CSI + set foreground indexed-color
fdc=$csi'38;2;' # foreground direct-color sequence
bdc=$csi'48;2;' # background direct-color
# relict form: '\e[38:2::R:G:Bm'
# ( :: future use... color-space, tolerance, alpha?)
# (ITU-T Recommendation T.416, aka ISO/IEC 8613-6)

# default colors, 256color index
# 'gfmt' diff symbol  <|>
clrbg=$bgc'235m';   typ_clrbg='background color'
clrbrf=$fgc'103m';  typ_clrbrf='brief section header'
clrerr=$fgc'124m';  typ_clrerr='error'
clrmsf=$fgc'172m';  typ_clrmsf='missing file'
clrsmd=$fgc'185m';  typ_clrsmd='changed-to text'
clrtmd=$fgc'186m';  typ_clrtmd='changed-from text and gfmt'
clrnew=$fgc'159m';  typ_clrnew='added text'
clrrmv=$fgc'101m';  typ_clrrmv='removed text'
clrtxt=$fgc'188m';  typ_clrtxt='context line, separator and type'
clrsrc=$fgc'108m';  typ_clrsrc='source line-number and gfmt, new file'
clrtgt=$fgc'130m';  typ_clrtgt='target line-number and gfmt'
clrttl=$fgc'195m';  typ_clrttl="header ($bold bold $normal)"

clrdcs=$fdc'128;128;128m'
typ_clrdcs='24bit direct-color sample'
nam_clrdcs='darker gray' # 24bit color names are user specified
# 256color index to X11R4 name is sourced from configuration file



project(){
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
    ascii="${ascii:0:${#bgpoly}}" # truncate
    aspace="${bgpoly:${#ascii}}" # pad
    ascii="$ascii$aspace"
    sample="
$ascii
$reverse$bgpoly
$bgpoly$reset
$bgline"
  fi
  if [ -n "$xnam" ]; then # 256color names from configuration file
    xpush # implement array index, no eval
  fi
  IFS=\|
  zsplit "$colors" 'pcolor' "$1"
  [ "$1" = 'show' ] && {
    printf '%s\n' "$bgpoly"
    [ "$testdirect" = 'true' ] && ramps
  }
  printf '%s\n' "$reset$bgpoly"
  exit
}

xpush(){ # populate array index to $xnam (csv)
  local items=255
  local span='    '
  depth=${#span} # digits required to hold maximum index value
  local a="$xnam"',' # requires trailing delimiter to exit while loop
  local x=${#a}; xindex=${span:1}'0' # digits are one char wide
  while [ ${#a} -gt 0 ]; do
   a=${a#*,}; y=$((x-${#a}))
   xindex="$xindex${span:${#y}}$y"
  done
  return # comment to display array structure components
  local array='256color name index'
  z=-1; while [ $((z++)) -lt "$items" ]; do # 0-255
    xnames "$z"
    array="$array"$'\n'"$z  $cname  $xstruct"
  done
  echo "$array"
}

xnames(){
  [ -z "$xindex" ] && cname='unnamed' && return
  local c=$(($1*$depth))
  local b=$((($1+1)*$depth))
  local cc="${xindex:$c:4}"
  local bb="${xindex:$b:4}"
  cname="${xnam:$cc:$(($bb-$cc-1))}"
  xstruct="$c  $b  $bb-$cc"
}

pcolor(){
  color='clr'"$1"
  typ='typ_'"$color"
  nam='nam_'"$color"
  eval "colr=\$$color"
  cidx="${colr:7:-1}"
  cidx="${cidx#"${cidx%%[!0]*}"}" # strip leading zeros
  : "${cidx:=0}" # do not leave $cidx empty
  if [ "${colr:0:${#fgc}}" = "$fgc" ]; then # $colr begins with '$fgc'
    key='$fgc'
    xnames "$cidx" # $cname
  # $fgc and $bgc sequences use configured names
  elif [ "${colr:0:${#bgc}}" = "$bgc" ]; then
    key='$bgc'
    xnames "$cidx" # $cname
  else
    eval "nam=\"\$$nam\"" # user dc name
    cname="$nam" # for 'show'
    [ "${colr:0:${#fdc}}" = "$fdc" ] && key='$fdc' || key='$bdc'
  fi
  eval "typ=\$$typ"
  if [ "$2" = 'gen' ]; then
    [ "$color" = 'clrbg' ] && fcol='' || fcol=$colr
    if instr "$key" '$fdc $bdc'; then
      printf '%snam_%s\n' "$fcol" "$color='$nam'"
      cname="user custom"
      color="$color=$key'${colr#*[25];}'"
    else
      color="$color=$key'${cidx}m'"
    fi
    printf '%s%-27s# %-24s%s\n' "$fcol" "$color" "$cname" "$typ$clrbg"
  else # 'show'
    [ "$color" = 'clrbg' ] && return
    [ "$color" = 'clrttl' ] && tsamp="$bold" || tsamp=''
    padline "$clrbg$colr" "'$cname'   $typ" "$tsamp$sample"
  fi
}

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


diffproc(){
  if [ -n "$layout" ]; then # dual engines for now
    result="$(
      # -stdU   report-identical-files   expand-tabs   minimal   unified-context
      diff "$dopts" -F "$dfunc" -- "$sourcefile" "$targetfile" 2>&1 )"
  else
    result="$(
      # report-identical-files   expand-tabs   minimal   side-by-side
      diff -stdy --width="$dwidth" -- "$sourcefile" "$targetfile" 2>&1 )"
  fi
  dpret=$?
  case "$dpret" in
    0) padline "$clrtxt" " $fname" >> "$samefile" ;;
    1)
      padline "$clrsmd" " $fname" >> "$changefile"
      espr="$reportdir"'/report_'"$fname"'.espdif'
      [ "$mode" = 'keep' ] &&
        printf '%s' "$result" > "$reportdir"'/raw-ystd-'"$dwidth"'_'"$fname"
      if [ -d "$sourcefile" ]; then
        padline "$clrbg$clrbrf" "${dspace:${#foldif}/2}$foldif" > "$espr"
        padline "$clrsmd" " $sourcefile" >> "$espr"
        padline "$clrtmd" " $targetfile" "
$bgline" >> "$espr"
      elif [ -n "$layout" ]; then
        printf '%s' "$result" | newdif > "$espr"
      else printf '%s' "$result" |
        # translate first byte of variable width utf-8 char to '?'
        # (positioning gfmt at dpos)
        # pass ascii lf, cr, printable chars
        # (tab '\11' expansion to spaces by diff prior)
        # include context lines, add line numbers
        tr '\300-\375' '?' | # -\367 16bit BMP, Plane 0 (1-3 bytes follow)
          tr -dc '\12\15\40-\176' | # or '[:print:]\n'
            grep -nEC"$context" -- '^.{'"$dpos"'}[<>|].*' |
              tfixdif > "$espr" # parse filtered diff output
      fi
    ;;
    2) padline "$clrmsf$clrbg" "$result" >> "$errorfile"'_' ;;
    *)
      printf '\nunknown return code %s\n\n  %s
' "$dpret" "$result" >> "$unknown"
    ;;
  esac
  [ -n "$sequence" ] && sleep "$sequence"
  # notification that diffproc has completed
  [ "$mode" = 'test' ] && printf '\n\nping fifo %s' "$sourcefile"
  echo "$sourcefile" > "$dfifo"
}


newdif(){
  # implement 'mixed' output mode
  chg=0;add=0;del=0
  IFS=$'\n'
  read -r r; printf '%s\n' "$r"
  read -r r; printf '%s\n' "$r"
  while read -r r
  do case "${r:0:1}" in
    '@')
      a=${r:4};
      h=${a#*@}
      b=${a#*+};
      a=${a%%[, ]*};
      b=${b%%[, ]*};
      printf '\n%s\n' "$h"
      new=''
      continue
      ;;
    '-') # current
      new="$new$r
"
      continue
      ;;
    '+') # previous
        if [ -n "$new" ]; then
          n="${new#*
}" # chop off first line from $new buffer
          ln="$((${#new}-${#n}-1))" # offset to end of first line
          if [ "$ln" -le "$dpos" ]; then
            # echo pad
            z="${new:0:$ln}${bgpoly:0:$dpos-$ln}";
          else
            # echo truncate
            z="${new:0:$dpos}";
          fi
          printf '|%s%s  %s\n' "${dplace:${#a}}$((a++))" "$z" "${r:0:$dpos}"
          new="$n"; : $((chg++))
        else
          printf '<%s%s\n' "${dplace:${#b}}$b" "${r:0:$dwidth}"
          : $((del++))
        fi
      ;;
    ' ')
      # zsh produces extra line with '\n' at end of $new
      [ -n "$new" ] && zsplit "${new:0:-1}" 'nlines'
      printf ' %s%s\n' "${dplace:${#a}}$((a++))" "${r:0:$dwidth}"
      new=''
      ;;
    esac
    : $((b++))
  done
  echo "additions $add  changes $chg  deletions $del"
}

nlines(){
  printf '>%s%s\n' "${dplace:${#a}}$((a++))" "${1:0:$dwidth}"
  : $((add++))
}


tfixdif(){
#   $dpos is exact offset to the middle column in side-by-side diff output
#   $gfmt position is expected to be consistent for any implemented diff
#   using $dpos, grep provides line numbers, discarding unselected context
#   the line is then split in half, colorized and reassembled
  cmpoff=''
  srcoff=''
  modline=''
  while IFS='' read -r fline; do
    if [ "$fline" = '--' ]; then
      # separator, pad with spaces to position
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
        gfmt="${right:0:1}";
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


instr(){ # return true if $1 is a substring of $2, 0=true, !0=false
  strin="${2/"$1"}"; [ "${#strin}" -ne "${#2}" ] && return 0 || return 1; }

fixup(){ [ "${1: -1}" = '/' ] && echo "$1" || echo "$1"'/'; }

padline(){ printf '%s\n' "$1$2${bgpoly:${#2}}$3"; } # pad to width


zglob(){
# $~var
  if [ -n "$ZSH_VERSION" ]; then
    for c in "$1"$~2; do "$3" "$c"; done
  else
    for c in "$1"$2; do "$3" "$c"; done
  fi
}

zsplit(){
# setopt SH_WORD_SPLIT, zsh -y, $=var or use (s) flag instead of IFS
  if [ -n "$ZSH_VERSION" ]; then
    for c in "$=1"; do "$2" "$c" "$3"; done # or ${(s.,.)$1}
  else
    for c in $1; do "$2" "$c" "$3"; done
  fi
}


sanitize(){
  if [ "$1" ]; then
    regfile="$1"
    [ ${1:0:1} = '/' ] && abs="${1%/*}" || abs="$currentdir/${1%/*}"
  else
    regfile='.esprj'
    [ "$prloc" = 'parent' ] && abs="${currentdir%/*}" || abs="$currentdir"
  fi
  esprjtmp="$esprj"'tmp'
  # escape forward slashes in path
  abs="${abs//\//\\/}"'\/'
  # (not restricting use of any filename chars to delimit sed)
  fixrel="s/(projectdir=')([^/][^']*')/\1"
  # permit direct-color sample in project registration
  scolor="$colors"'|dcs'
  # pass correctly formatted keywords, allowed characters and numeric ranges
  regx="((context='[1-9]')"
  regx="$regx|(testdirect='(true|false)')"
  regx="$regx|((columns|lines)='[0-9]{1,4}')"
  regx="$regx|((targetdir|sourcedir|projectdir)='[$allowchars]{2,80}')"
  regx="$regx|((titletxt|nam_clr($scolor))='[$allowchars]{3,25}')"
  num='(25[0-5]|(([0-1])?[0-9]|2[0-4])?[0-9])' # 0-255 n, nn, nnn, 0n & 00n
  cdirect="$num"'[;:]'"$num"'[;:]'
  regx="$regx|(clr($scolor)=[$](fgc'|bgc'|([fb]dc)'$cdirect)${num}m'))" # m
  # strip blank and comment lines along with any preceding whitespace
  seqrx="$csi"'[^m]*m' # m is CSI final char
  sed -r -- 's/'"$seqrx"'//g;/^\s*(#.*)?$/d' "$regfile" |
    tr -cd '\12\15\40-\176' | # filter - pass lf, cr, printable
    # or '[:print:]' (POSIX character class)
      tee -- "$esprjtmp" |
        # filter sequences with correct option=value, once per line
        # insert blank line if $regx does not match
        sed -rn -- 's/.*'"$regx"'.*/\1/p;tz;i
:z' | # fix relative projectdir in session registration file
          sed -r -- "$fixrel$abs"'\2/;Tz;i# fixed relative projectdir
:z s /[^/]*/\.\.  ;tz' > "$esprj" # collapse /dir/.. parent indirection
  # send rejected lines to stderr
  grep -v '^#' "$esprj" | # ignore '# fixed relative...' line
    paste -d '\n' -- - "$esprjtmp" | # interleave
      sed -n -- '/^$/{n;s/\(.*\)/'"$clrerr"'  \1'"$reset"'/p}' >&2
  # cleanup
  rm -f -- "$esprjtmp"
}


supreport(){
  # supplemental report - find missing files for project
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
  [ -n "$mdiff" ] &&
    padline "$bgpoly
$clrbrf" 'Missing' "
$mdiff"
  # cleanup
  rm -f -- "$supsrc" "$suptgt"
}

mainloop(){
  sourcefile="$1"
  fdp=''
  # posix glob empty set yields literal match string
  if [ -e "$sourcefile" ]; then # ensure result exists
    # launch up to $dproclimit processes in the background
    waitmsg=$'\n'"dpl $dpl"
    [ "$((dpl++))" -gt "$dproclimit" ] && { # one at a time
      # pstree $$ | grep -v '\(grep\|pstree\)'
      # flush fifo, no hang if empty pipe
      dflush="$(dd if="$dfifo" iflag=nonblock of=/dev/null 2>&1)"
      [ -n "$sequence" ] && waitmsg="$waitmsg
flush fifo
$dflush"
      numdiffs="$(ps --ppid "$$" | grep -v 'defunct\|ps)')"
      waitmsg="$waitmsg
$numdiffs"
      numdiffs="$(($(echo "$numdiffs" | wc -l)-2))"
      waitmsg="$waitmsg
numdiff $numdiffs"
      if [ "$numdiffs" -lt "$dproclimit" ]; then
        dpl="$((numdiffs+2))"
        waitmsg="$waitmsg

dpl $((numdiffs+1))"
      else
        [ "$mode" = 'test' ] && printf '\n%s\n\nwait' "$waitmsg"
        waitmsg=''
        read fdp < "$dfifo" # wait for any diffproc to finish
        fdp="fifo $fdp"
      fi
    }
  else
    echo 'no source files '"$(pwd)/$sourcefile"
    exit
  fi
  # process diff results
  fname="${sourcefile##*/}"
  targetfile="$targetdir$fname"
  diffproc &
  dpid="$!"
  [ "$mode" = 'test' ] &&
    printf '\n%s\ndiffproc %s %s' "$waitmsg$fdp" "$sourcefile" "$dpid"
}


## zsh nomatch
# disable zsh error on glob match returning empty-set
# (result is tested in-script)
[ -n "$ZSH_VERSION" ] && setopt +o nomatch

##  precursory arguments
printf '%s' "$reset" # start with 'clean slate'
case "$1" in
  '--help'|?'help'|'help') echo "$shelp"; exit ;;
  'skip') shift ;; # or include resource configuration file
  *)
    if [ "$1" = 'mix' ]; then layout='mixed'; shift
    else layout='' # default
    fi
    # configuration
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
        printf '%sconfigfile checksum unverified%s\n' "$clrerr" "$reset" >&2
      fi
    fi
  ;;
esac

##  precursory settings
readonly currentdir="$( pwd )"
colors='bg|brf|msf|tgt|src|smd|txt|ttl|new|tmd|rmv|err'
# after resource configuration
tmpdir="$( fixup "$tmpdir" )"
sessiondir="$( fixup "$sessiondir" )"
esprj="$sessiondir"'.esprj' # session project file
[ -d "$sessiondir" ] ||
  { printf 'no sessiondir %s\n' "$clrerr$sessiondir$reset" >&2; exit; }

##  include project registration file
# explicit
if [ "$1" = 'register' ]; then
  [ -n "$2" ] && {
    [ -d "$2" ] &&
      regp="$( fixup "$2" )"'.esprj' ||
      regp="$2"
    # do not include the session register as local
    if { [ -f '.esprj' ] && [ ! "$esprj" -ef '.esprj' ]; } ||
      { [ -f '../.esprj' ] && [ ! "$esprj" -ef '../.esprj' ]; } then
      # presence of a local project would overwrite explicit registration
      echo 'local project has priority'
    elif [ -f "$regp" ]; then
      if [ "$regp" -ef "$esprj" ]; then
        echo 'session previously registered'
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
# implicit
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
  if instr "$prloc" 'local parent'; then
    if [ '.esprj' -ef "$esprj" ]; then
      prloc='session' # sessiondir is same location as '.esprj' file
      reginfo="$sessiondir"
    else
      sanitize
    fi
  fi
  # verify md5sum for session
  if [ "$prloc" = 'session' ] && [ -n "$mdsessions" ]; then
    sum="$( md5sum -- "$esprj" )"
    sum="${sum%% *}"
    if instr "$sum" "$mdsessions"; then
      prloc='verified'
    else
      reginfo='- session failed to verify md5sum'
      prloc='failed'
    fi
  fi
  echo "$prloc"' registration '"$reginfo"
  [ "$prloc" != 'failed' ] && . "$esprj"
fi

##  secondary settings
# effect potential 'columns' over-ride from registration file
bgpoly=''; x=$((columns/50))
bgp='                                                  ';
while [ $((x--)) -gt 0 ]; do bgpoly="$bgpoly$bgp"; done
bgpoly="$bgpoly${bgp:0:$columns%50}"
bgline="$clrbg$bgpoly"



switch(){
  [ -z "$1" ] && return 1
  case "$1" in
    'man') sman ;;
    'make') project 'gen' ;;
    'colors') project 'show' ;;
    'term') mode='term' ;;
    'page') mode='page' ;;
    'test') mode='test' ;;
    'time') tite="$(date +%s%N)" ;;
    'seq') mode='test'; sequence=1 ;;
    'keep') mode='keep'; tmpdir='' ;;
    *) return 1
  esac
  return 0
}


### main

##  main arguments
mode='default' # display
state='default' # semaphore
sequence='' # extended test mode
switch "$1" && shift # $1 was a mode argument
# option bridge
[ "$1" = '--' ] && shift  # filename can be same as options
# third argument is considered
[ -n "$4" ] && echo 'more than one extra argument'
[ -n "$3" ] && { switch "$3" || echo 'extra argument unrecognized: '"$3 $#"; }
if [ -n "$2" ]; then # extra-project diff
  cd "$currentdir" || exit
  if [ -d "$1" ] && [ -d "$2" ]; then # compare two directories
    state='dir'; sourcedir="$( fixup "$1" )"; targetdir="$( fixup "$2" )";
    projectdir=''
  elif [ -f "$1" ] && [ -f "$2" ]; then # compare two files
    state='dual'; sourcedir=''; targetdir='';
    fname="${1##*/}"; sourcefile="$1"; targetfile="$2"
  elif [ -n "$1" ] && switch "$2"; then
    state='single'
  else
    echo 'valid arguments are:  file1 file2  or:  dir1 dir2'
    exit
  fi
elif [ -n "$1" ]; then  # compare one project file
  state='single'
fi

##  validate inputs
if [ -n "$sourcedir" ] && [ -n "$targetdir" ] && [ -n "$projectdir" ]; then
  # check directories
  projectdir="$( fixup "$projectdir" )"
  sourcedir="$( fixup "$sourcedir" )"
  targetdir="$( fixup "$targetdir" )"
  [ -d "$projectdir" ] ||
    { echo 'invalid projectdir: '"$projectdir"; exit; }
  cd "$projectdir" || exit
  [ -d "$sourcedir" ] ||
    { echo 'invalid sourcedir '"$projectdir$sourcedir"; exit; }
  [ -d "$targetdir" ] ||
    { echo 'invalid targetdir '"$projectdir$targetdir"; exit; }
  # 'inline' project register location
  [ "$prloc" = 'default' ] &&
    echo 'inline registration'
  # single sub-states
  if [ "$state" = 'single' ]; then
    sproj="$projectdir$sourcedir$1"
    if [ -d "$projectdir$1" ]; then # compare specified project folder
      targetdir="$( fixup "$1" )"
      state='default'
    elif [ -f "$sproj" ]; then # compare one project file
      sourcedir="$sourcedir$1"
      glob=''
    else
      notf=''; clue=''
      [ '?' != "$1" ] && clue="or 'help'" &&
        notf='not a project file: '"$clrerr$sproj$reset"
      echo "$notf" # blank line or 'not a project file'
      ls --color=always -- "$projectdir$sourcedir"
      echo "$clue" # blank line or 'help'
      exit
    fi
  fi
elif ! instr "$state" 'dual dir'; then
  printf 'no project paths%s' "$shelp"
  exit
fi

##  change terminal window title
printf '%s' "$titlepre$titletxt$st" # assume $PS1 will reset title

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
dspace="${bgpoly:0:$dspclen}"
# spacing to fill separator lines
sepspace="${dspace:1}"

##  temp folder
# exit trap handles removal
texit(){  [ "$mode" = 'keep' ] || {
    [ -n "$reportdir" ] && rm -rf -- "$reportdir"
    [ -n "$reportnew" ] && rm -rf -- "$reportnew"; } }
unset reportdir
trap texit EXIT
reportdir="$( mktemp -d "$tmpdir"'_espdiffXXXXXX' )" ||
  { printf '%serror creating temp file\n' "$clrerr" >&2; exit 1; }

##  fifo heartbeat
dfifo=$reportdir'/FIFO'
mkfifo "$dfifo"

# compare engine outputs
#reportnew="$( mktemp -d "$tmpdir"'_espdiffXXXXXX' )" ||
# { printf '%serror creating temp file\n' "$clrerr" >&2; exit 1; }

##  assign brief names
unknown="$reportdir"'/_000_unknown_'
errorfile="$reportdir"'/_001_error_'
missfile="$reportdir"'/_002_missing_'
changefile="$reportdir"'/_003_changed'
samefile="$reportdir"'/_004_same'

##  sort order
export LC_ALL=C

##  process diff reports
dopts='-stdU'"$context"
foldif='sub-folder contents differ'
if [ "$state" = 'dual' ]; then
# directly dispatch extra-project 'file' runs
  diffproc &
else
# single-project, default-project and extra-project 'dir' runs
  # supplemental report for default-project and extra-project 'dir'
  instr "$state" 'default dir' &&
    supreport "$sourcedir" "$targetdir" > "$missfile" &
  # queue files for diff comparison
  dpl=1
  zglob "$sourcedir" "$glob" 'mainloop'
fi

# wait for reporting sub-processes to finish
[ "$mode" = 'test' ] && finis=$'\n'"$(ps --ppid "$$"; jobs -l)" || finis=''
while IFS=$'\n'
  [ "$(($(ps --ppid "$$" | grep -v 'defunct\|ps\|grep' | wc -l)-2))" -gt 0 ]
    do
      read line < "$dfifo" # or implement signals
      [ "$mode" = 'test' ] && finis="$finis
completed $line"
    done

# tests exit here
[ -n "$tite" ] && echo "elapsed core time: $(($(date +%s%N)-tite))ns" && exit
[ "$mode" = 'test' ] && echo "$finis"$'\n' && exit
rm "$dfifo"



finish(){
  # fill bottom of file given with lines of spaces, minus offset argument
  flines="$(wc -l -- "$1")"
  flines="${flines%% *}"
  # can be called with $2 offset omitted ($2+0 if last term)
  polylines=$(( lines - flines - $2 - 1 ))
  while [ $(( polylines -= 1 )) -ge 0 ]; do
    printf '%s\n' "$bgpoly" >> "$1"
  done
}


statistics(){
  final="$1"
  [ -f "$final" ] && { # skip loop if no reports
    tfx="$final"'_tfx'
    [ -n "$layout" ] && mv "$final" "$tfx" && return # pass-through 'mixed'
    tail -n 4 -- "$final" | {
      IFS=''; read -r fif; read -r line; read -r swap
      instr "$foldif" "$fif" || # temp bypass subfolder content reports
        printf '%s\n%s\n%s\n%s\n' "$bgline" "$swap" "$line" "$bgpoly" > "$tfx"
    }
    cat -- "$final" >> "$tfx"
    [ "$mode" = 'page' ] && finish "$tfx" # fill remaining lines with spaces
    rcount=$(( rcount + 1 ))
  }
}


###   post-processing

# prepare brief section labels
brf="$reportdir"'/_0_brief'
padline "$bgline
$clrbrf" 'Errors' > "$errorfile"
# missing-files section is prepped in 'initiate diff reports'
padline "$bgline
$clrbrf" 'Different' > "$changefile"'_'
padline "$bgline
$clrbrf" 'Same' > "$samefile"'_'
# assemble preview page from meta files
[ -f "$changefile" ] &&
  printf '%s' "$clrbg" > "$changefile"'__' &&
    sort -- "$changefile" >> "$changefile"'__'
[ -f "$samefile" ] &&
  printf '%s' "$clrbg" > "$samefile"'__' &&
    sort -- "$samefile" >> "$samefile"'__'
cat -- "$reportdir"/_00*_ > "$brf"
printf '%s\n' "$bgline" >> "$brf"
# remove meta files
[ "$mode" = 'keep' ] ||
  rm -f -- "$reportdir"/_00* "$changefile" "$samefile"

# prepend statistics from bottom of each report to top
rcount=0
zglob "$reportdir" "/*.espdif" 'statistics'

# 'keep' exits here
[ "$mode" = 'keep' ] && exit

# remove intermediate report files
[ -z "$layout" ] && rm -f -- "$reportdir"/*.espdif

# paint empty bottom lines of initial page with background color
if [ $mode = 'page' ]; then
  finish "$brf"
elif [ "$mode" = 'default' ]; then
  if [ "$rcount" = 1 ]; then
    # combined brief and one report file
    alines="$( wc -l -- "$brf" )"
    finish "$tfx" "${alines%% *}"
  elif [ -z "$tfx" ]; then
    # no report file was generated
    finish "$brf"
  fi
# final lines to standard out
elif [ "$mode" = 'term' ]; then
  if [ "$rcount" -ge 1 ]; then
    printf '%s\n\n' "$bgline$reset" >> "$tfx"
  else
    printf '%s\n\n' "$bgline$reset" >> "$brf"
  fi
fi

##  display
if [ "$mode" = 'page' ]; then
  # paged, less
  less -rc -- "$reportdir"/*
elif  [ "$mode" = 'default' ]; then
  # all reports in one, less
  cat -- "$reportdir"/* | less -rc --
elif  [ "$mode" = 'term' ]; then
  # no less
  cat -- "$reportdir"/*
fi

exit


###   footnote

##  xterm
#    TERM='xterm-256color'
#    menus C-left/right mouse

##  tmux
#    TERM='screen-256color' or 'tmux-256color'
#    scroll-back C-b [

##  screen
#    24bit direct-color in master branch (at least since 4.99)
#    TERM='screen-256color'
#    bce is not enabled by default
#    C-a : bce on, or insert 'bce on' line into screenrc file

##  less
#    fast - files do not have to load completely before display begins
#    color is not buffered for hidden lines (scroll-back coloring is reversed)

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
# wget security patch did not apply to busybox-1.32.1:
#  https://git.busybox.net/busybox/commit/
#  ?id=fc2ce04a38ebfb03f9aeff205979786839cd5a7c
# if this is of concern, compile the most recent commit of busybox-1.33_stable
#
#    if busybox is the default system shell:
#     change shebang to #!/bin/sh
#     install full version of diff - builtin does not have -y option
#    distribution binary does not pass unit test B:
#     compile busybox-1.32.1 (latest stable release)
#      make defconfig
#      or make menuconfig - add and remove functionality/builtins*
#      make

##  unit test - first line describes correct result
#
#    B) displays 'qwe'
#    a='asdfqwerty'; echo ${a:4:-3}
#      error:
#      sh: Illegal number: -3
#    ${ substring expansion parameter : offset : -length is negative }
#      in Bash since 4.2-alpha, busybox?

# 'clairvoyance 6' and 'incursive engine' are trademarks of espdiff.sh

###EOF###
