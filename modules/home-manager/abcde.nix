# TODO The following options haven't yet been wrangled here.  This is copied
# from the upstream abcde.conf file.
#
# If NOCDDBQUERY is set to y, then abcde will never even try to access
# the CDDB server; running abcde will automatically drop you into a
# blank cddb file to edit at your leisure.  This is the same as the
# -n option.  NOCDDBQUERY=y implies NOSUBMIT=y.
#NOCDDBQUERY=n

# Specify the style of encoder to use here -
# oggenc, vorbize - for OGGENCODERSYNTAX
# lame, gogo, bladeenc, l3enc, xingmp3enc, mp3enc - for MP3ENCODERSYNTAX
# flac - the only supported for FLACENCODERSYNTAX at the moment
# speexenc - the only encoder for SPEEXENCODERSYNTAX
# mpcenc - encoder for MPCENCODERSYNTAX
# wavpack, ffmpeg - encoder for WVENCODERSYNTAX
# mac - for APENCODERSYNTAX
# fdkaac, ffmpeg, neroAacEnc, faac, qaac, fhgaacenc - for AACENCODERSYNTAX
# opusenc - for OPUSENCODERSYNTAX
# twolame, ffmpeg - for MP2ENCODERSYNTAX
# tta, ttaenc - for TTAENCODERSYNTAX
# ffmpeg - for AIFFENCODERSYNTAX
# default is a valid option for oggenc, lame, flac, speexenc, mpcenc, wavpack,
# fdkaac, opus, twolame and tta. Currently this affects the default location of the
# binary, the variable to pick encoder command-line options from, and where
# the options are given.
#MP3ENCODERSYNTAX=default
#OGGENCODERSYNTAX=default
#FLACENCODERSYNTAX=default
#SPEEXENCODERSYNTAX=default
#MKAENCODERSYNTAX=default
#MPCENCODERSYNTAX=default
#WVENCODERSYNTAX=default
#APENCODERSYNTAX=default
#AACENCODERSYNTAX=default
#OPUSENCODERSYNTAX=default
#MP2ENCODERSYNTAX=default
#TTAENCODERSYNTAX=default
#AIFFENCODERSYNTAX=default

# Specify the syntax of the normalize binary here - so far only 'normalize'
# is supported.
#NORMALIZERSYNTAX=default

# CD reader program to use - currently recognized options are 'cdparanoia',
# 'libcdio' (cd-paranoia),'icedax', 'cdda2wav', 'dagrab', 'pird',
# 'cddafs' (Mac OS X only) and 'flac'.
#CDROMREADERSYNTAX=cdparanoia

# CUE reader syntax for the CUE reader program to use.
# abcde supports 2 CUE modes: 'mkcue' and 'abcde.mkcue' so you can set the
# MKCUE variable accordingly. The 'abcde.mkcue' uses an internal
# implementation, without the need of an external program.
#CUEREADERSYNTAX=default

# Specify the program to convert a CUE sheet back to a CD disc ID for CDDB queries.
# Select between '/path/to/cue2discid' (provided as an example) or
# 'abcde.cue2discid', implemented internaly.
#CUE2DISCID=abcde.cue2discid

# Define if you want abcde to be non-interactive.
# Keep in mind that there is no way to deactivate it right now in the command
# line, so setting this option makes abcde to be always non-interactive.
#INTERACTIVE=n

# Specify 'nice'ness of the encoder, the CD reader and the distmp3 proc.
# This is a relative 'nice'ness (that is, if the parent process is at a
# nice level of 12, and the ENCNICE is set to 3, then the encoder will
# run with an absolute nice value of 15. Note also, that setting these
# to be empty will result in some default niceness increase (4 in tcsh
# and 10 using the bsdutils' nice).
#ENCNICE=10
#READNICE=10
#DISTMP3NICE=10

# Paths of programs to use

# Encoders:
#LAME=lame
#GOGO=gogo
#BLADEENC=bladeenc
#L3ENC=l3enc
#XINGMP3ENC=xingmp3enc
#MP3ENC=mp3enc
#VORBIZE=vorbize
#OGGENC=oggenc
#FLAC=flac
#SPEEXENC=speexenc
#MPCENC=mpcenc
#WVENC=wavpack
#APENC=mac
#FAAC=faac
#NEROAACENC=neroAacEnc
#FDKAAC=fdkaac
#TWOLAME=twolame
# Note that if you use avconv rather than FFmpeg give the
# path to avconv here (e.g. FFMPEG=/usr/bin/avconv):
# FFMPEG=ffmpeg
#TTA=tta
#TTAENC=ttaenc

# The path for qaac, refalac and fhgaacenc  can be problematic as abcde
# cannot cope with the 'standard' Wine location with spaces. For example:
# "$HOME/.wine/drive_c/Program\ Files/qaac/qaac.exe" is problematic. Try instead:
# "$HOME/.wine/drive_c/qaac/qaac.exe"
# Installation instructions for qaac, refalac and fhgaacenc here:
#    http://www.andrews-corner.org/linux/qaac.html
#    http://www.andrews-corner.org/linux/fhgaacenc.html
# (Hint: Use QAAC=refalac to use the Open Source alac encoder...)
#QAAC=qaac
#FHGAACENC=fhgaacenc

# Taggers, rippers, replaygain etc:
#ID3=id3
#ID3V2=id3v2
#MID3V2=mid3v2
#EYED3=eyeD3
#CDPARANOIA=cdparanoia
#CD_PARANOIA=cd-paranoia
#CDDA2WAV=icedax
#PIRD=pird
#CDDAFS=cp
#CDDISCID=cd-discid
#CDDBTOOL=cddb-tool
#EJECT=eject
#MD5SUM=md5sum
#DISTMP3=distmp3
#VORBISCOMMENT=vorbiscomment
#METAFLAC=metaflac
#NORMALIZE=normalize-audio
#CDSPEED=eject
#VORBISGAIN=vorbisgain
#MKCUE=mkcue
#MKTOC=cdrdao
#DIFF=diff
#WVGAIN=wvgain
#WVTAG=wvtag
#APETAG=apetag
#GLYRC=glyrc
#IDENTIFY=identify
#CONVERT=convert
#DISPLAYCMD=display
#WINE=wine

# Options to call programs with:

# If HTTPGET is modified, the HTTPGETOPTS options should also be defined
# accordingly. If HTTPGET is changed, the default options will be set,
# if HTTPGETOPTS is empty or not defined.
#HTTPGET=wget
# for fetch (FreeBSD): HTTPGETOPTS="-q -o -"
# for wget: HTTPGETOPTS="-q -nv -O -"
# for curl (MacOSX): HTTPGETOPTS="-f -s"
#HTTPGETOPTS="-q -O -"

# MP3:
# For the best LAME encoder options have a look at:
# <http://wiki.hydrogenaudio.org/index.php?title=LAME#Recommended_encoder_settings>
# A good option is '-V 0' which gives Variable Bitrate Rate (VBR) recording
# with a target bitrate of ~245 Kbps and a bitrate range of 220...260 Kbps.
#LAMEOPTS=
#GOGOOPTS=
# Bladeenc still works with abcde in 2015, and the last release of bladeenc
# was in 2001! Settings that will produce a great encode are: '-br 192' 
#BLADEENCOPTS=
# L3enc still works with abcde in 2015, pretty amazing when you realise 
# that the last release of l3enc was in 1997! Settings that will produce 
# a great encode are: '-br 256000 -hq -crc'
#L3ENCOPTS=
#XINGMP3ENCOPTS=
# And mp3enc also still works with abcde in 2015 with the last release
# of mp3enc in 1998! Settings that will produce a great encode, albeit
# a slow one, are: '-v -br 256000 -qual 9 -no-is -bw 16500'
#MP3ENCOPTS=

# Ogg:
#VORBIZEOPTS=
#OGGENCOPTS=

# FLAC:
# The flac option is a workaround for an error where flac fails
# to encode with error 'floating point exception'. This is flac 
# error in get_console_width(), corrected in flac 1.3.1
#FLACOPTS="--silent"
# Options passed to MetaFlac for ReplayGain tags:
#FLACGAINOPTS="--add-replay-gain"
# Speex:
#SPEEXENCOPTS=

# MPP/MP+ (Musepack):
# For the encoder options look at 'mpcenc --longhelp', consider
# setting '--extreme' for a good quality encode.
#MPCENCOPTS=

# WavPack:
# Look at 'wavpack --help' for detailed options, consider using '-hx3' 
# for a good quality encode
#WAVENCOPTS=
# For Wavpack replay gain we set both the default of 'track gain' 
# as well as this option for 'album gain'. Better media players
# such as vlc can select either or neither.    
#WVGAINOPTS='-a'

# Monkey's Audio (ape)
# Without this set mac chokes unfortunately. Choices
# are from 1000 to 5000.
#APENCOPTS='-c4000'

#AIFF
# These options needed by FFmpeg for tagging and selection of id3v2 version:
#  1. '-write_id3v2 1' allows id3v2 tagging while '-write_id3v2 0' disables tagging
#  2. '-id3v2_version 4' gives version id3v2.4 while '3' gives id3v2.3 
#AIFFENCOPTS="-write_id3v2 1 -id3v2_version 4"

# M4A/AAC
# There are now 6 AAC encoders available to abcde, the default being
# fdkaacenc. Note that the old AACENCOPTS has been rendered obsolete by
# the following options, new to abcde 2.7:
#  1. fdkaac: see 'fdkaac --help' and consider using 
#     '--profile 2 --bitrate-mode 5 --afterburner 1'
#     for a good quality encode. 
#FDKAACENCOPTS='--bitrate 192k'
#  2. FFmpeg: Use the following to use the FFmpeg native encoder, adding
#     -strict -2 if you have an older FFmpeg:
#     FFMPEGENCOPTS="-c:a aac -b:a 192k"
#  3. neroAacEnc: see 'neroAacEnc -help' and
#     consider using '-q 0.65' for a good quality encode.
#NEROAACENCOPTS=
#  4. faac: see 'faac --long-help' and consider
#     using '-q 250' for a good quality encode.
#FAACENCOPTS=
#  5. qaac: simply run 'wine qaac.exe' to see all options and
#     consider using '--tvbr 100' for a good quality
#     encode or '--alac' for Apple Lossless Audio Codec
#QAACENCOPTS=
#  6. fhgaacenc: simply run 'wine fhgaacenc.exe' to see all options.
#     consider using '--vbr 4' for a decent quality encode.
#FHGAACENCOPTS=

# True Audio
# This is a lossless format so no options of any note available:
#TTAENCOPTS=

# MP2
# Currently uses either twolame or ffmpeg, for twolame options look at:
# 'twolame --help',a highly recommended setting is "--bitrate 320".
#TWOLAMENCOPTS=

# FFmpeg or avconv can be used for several audio codecs, as well as being
# the default encoder for the Matroska container mka::
# 1. Encoding to WavPack (FFmpeg only: avconv does not have a native encoder).
#    Consider setting the following with a compression_level between 0-8:
#    FFMPEGENCOPTS="-c:a wavpack -compression_level 6"
# 2. Encoding to ALAC (both FFmpeg and avconv have a native encoder).
#    Consider using the following for either FFmpeg and avconv:
#    FFMPEGENCOPTS="-c:a alac"
# 3. Encoding to mp2
#    Consider using the following for either FFmpeg and avconv:
#    FFMPEGENCOPTS="-c:a mp2 -b:a 320k"
#FFMPEGENCOPTS=

# mp3 tagging:
# There are three ways to tag MP3 files:
#   1. id3v1 (with id3)
#   2. id3v2.3 (with id3v2)
#   3. id3v2.4 (with eyeD3) This is the default
# Use ID3TAGV to select one of the older formats:
#ID3TAGV=id3v2.4
#ID3OPTS=
#ID3V2OPTS=
#EYED3OPTS="--set-encoding=utf16-LE"

# Other options:
# The variable CDPARANOIOPTS is also used by GNU's cd-paranoia,
# so use this when setting CDROMREADERSYNTX=libcdio.
#CDPARANOIAOPTS=
#CDDA2WAVOPTS=
#PIRDOPTS="-p"
# Options for the CD ripper dagrab can be seen by running 'dagrab -h'.
# A good option to experiment with is the 'sectors per request' setting
# which by default is '-n 8'.
#DAGRABOPTS=
#CDDAFSOPTS="-f"
#CDDBTOOLOPTS=
#EJECTOPTS=
#DISTMP3OPTS=
#NORMALIZEOPTS=
#CDSPEEDOPTS="-x"
#CDSPEEDVALUE=""
#MKCUEOPTS=""
#MKTOCOPTS=""
#DIFFOPTS=""
#VORBISCOMMENTOPTS="-R"
#METAFLACOPTS="--no-utf8-convert"
# Bear in mind that the AtomicParsley option '--overWrite' is already
# used in abcde...
#ATOMICPARSLEYOPTS=

# CD device you want to read from
# It can be defined as a singletrack flac file, but since it might change from
# file to file it makes little sense to define it here.
#CDROM=/dev/cdrom
# If we are using the IDE bus, we need CDPARANOIACDROMBUS defined as "d"
# If we are using the ide-scsi emulation layer, we need to define a "g"
#CDPARANOIACDROMBUS="d"

# If you'd like to make a default location that overrides the current
# directory for putting mp3's, uncomment this.
#OUTPUTDIR=`pwd`

# Or if you'd just like to put the temporary .wav files somewhere else
# you can specify that here
#WAVOUTPUTDIR=`pwd`

# Output filename format - change this to reflect your inner desire to
# organize things differently than everyone else :)
# You have the following variables at your disposal:
# OUTPUT, GENRE, ALBUMFILE, ARTISTFILE, TRACKFILE, TRACKNUM and YEAR.
# Make sure to single-quote this variable. abcde will automatically create
# the directory portion of this filename.
# NOTICE: OUTPUTTYPE has been deprecated in the OUTPUTFORMAT string.
# Since multiple-output was integrated we always append the file type
# to the files. Remove it from your user defined string if you are getting
# files like ".ogg.ogg".
#OUTPUTFORMAT='${ARTISTFILE}-${ALBUMFILE}/${TRACKNUM}.${TRACKFILE}'

# Like OUTPUTFORMAT but for Various Artists discs.
#VAOUTPUTFORMAT='Various-${ALBUMFILE}/${TRACKNUM}.${ARTISTFILE}-${TRACKFILE}'

# Like OUTPUTFORMAT and VAOUTPUTFORMAT but for the ONEFILE rips.
#ONETRACKOUTPUTFORMAT=$OUTPUTFORMAT
#VAONETRACKOUTPUTFORMAT=$VAOUTPUTFORMAT

# Define how many encoders to run at once. This makes for huge speedups
# on SMP systems. Defaults to 1. Equivalent to -j.
#MAXPROCS=2

# Support for systems with low disk space:
# n:	Default parallelization (read entire CD in while encoding)
# y:	No parallelization (rip, encode, rip, encode...)
#LOWDISK=n

# If set to y, enables batch mode normalization, which preserves relative
# volume differences between tracks of an album.
#BATCHNORM=n

# Enables nogap encoding when using the 'lame' encoder.
#NOGAP=y

# Set the playlist file location format. Uses the same variables and format
# as OUTPUTFORMAT. If the playlist is specified to be in a subdirectory, it
# will be created for you and the playlist will reference files from that
# subdirectory.
#PLAYLISTFORMAT='${ARTISTFILE}-${ALBUMFILE}.${OUTPUT}.m3u'
# If you want to prefix every filename in a playlist with an arbitrary
# string (such as 'http://you/yourstuff/'), use this option
#PLAYLISTDATAPREFIX=''

#Like PLAYLIST{FORMAT,DATAPREFIX} but for Various Artists discs:
#VAPLAYLISTFORMAT='${ARTISTFILE}-${ALBUMFILE}.${OUTPUT}.m3u'
#VAPLAYLISTDATAPREFIX=''

#This will give the playlist CR-LF line-endings, if set to "y".
#(some hardware players insist on CR-LF line-endings)
#DOSPLAYLIST=n

# album art download options (see glyrc's help for details with more detailed 
# examples here: https://github.com/sahib/glyr/wiki/Commandline-arguments).
# For example use '--formats jpg;jpeg' to only search for JPEG images
# These options: '--from <provider>' and '--lang <langcode>' might also be useful
#GLYRCOPTS=
#ALBUMARTFILE="cover.jpg"
#ALBUMARTTYPE="JPEG"

# Options for ImageMagick commands used by album art processing when available
# For example: CONVERTOPTS="-colorspace RGB -resize 600x600>"
# to make the image RGB and fit inside 600x600 while keeping the aspect ratio
#IDENTIFYOPTS=
#CONVERTOPTS=
#DISPLAYCMDOPTS="-resize 512x512 -title abcde_album_art"
# By default convert is only called when the image type is different from
# ALBUMARTTYPE, use ALBUMARTALWAYSCONVERT="y" to always call convert
#ALBUMARTALWAYSCONVERT="n"

# To encode on the remote machines foo, bar, baz, quux, and qiix, as well as
# on the local machine (requires distmp3 to be installed on local machine and
# distmp3host to be installed and running on all remote machines - see README)
#REMOTEHOSTS=foo,bar,baz,quux,qiix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.abcde;

  mkDisableOption = d: (lib.mkEnableOption d) // {default = true;};
in {
  options.programs.abcde = {
    enable = lib.mkEnableOption "abcde, A Better CD Extractor";
    package = lib.mkPackageOption pkgs "abcde" {};

    cddb = {
      method = lib.mkOption {
        description = ''
          Choose whether you want to use "cddb", "musicbrainz" and/or "cdtext".
          Default is "musicbrainz", but all can be specified to be tried
          sequentially. All the results will be displayed ready for user
          choice.
        '';
        type = lib.types.listOf (lib.types.enum [
          "cddb"
          "musicbrainz"
          "cdtext"
        ]);
        default = ["musicbrainz"];
      };

      url = lib.mkOption {
        description = "URL for the CDDB server to use.";
        type = lib.types.str;
        default = "http://freedb.freedb.org/~cddb/cddb.cgi";
      };

      protocolLevel = lib.mkOption {
        description = ''
          The CDDB protocol level.  Right now, 5 is latin1 output and 6 is UTF8
          encoding.
        '';
        type = lib.types.int;
        default = 6;
      };

      helloInfo = lib.mkOption {
        description = ''
          The CDDB protocol requires hello information, including a valid
          username and hostname. If you feel paranoid about giving away such
          info, set a value here - the format is username@hostname.
        '';
        type = lib.types.nullOr lib.types.str;
        default = null;
      };

      submissionEmail = lib.mkOption {
        description = ''
          This controls the email address CDDB changes are submitted to.
        '';
        type = lib.types.str;
        default = "freedb-submit@freedb.org";
      };

      cache = {
        enable = lib.mkEnableOption "local caching of CDDB entries";
        path = lib.mkOption {
          description = ''
            Directory for any local CDDB cache.
          '';
          type = lib.types.path;
          default = config.home.homeDirectory + "/.cddb";
        };
        checkRecursive = mkDisableOption "recursive checking of the local cache";
      };

      offerSubmit = mkDisableOption "prompting to submit edited cddb files";

      useLocal = lib.mkEnableOption "using the locally stored CDDB entries.  This is useful if you do a lot of editing to those CDDB entries.  Also, other tools like Grip store CDDB entries under $HOME/.cddb, so they can be reused when ripping CDs.";

      fields = lib.mkOption {
        description = ''
          List the fields we want the parsing function to output.  The fields
          are not case sensitive.
        '';
        type = lib.types.listOf lib.types.str;
        default = ["year" "genre"];
      };
    };

    encoders = {
      opus = {
        enable = lib.mkEnableOption "using the Opus encoder";
        options = lib.mkOption {
          description = "Encoder options to use.  Look at `opusenc -h` for options.";
          type = lib.types.str;
          default = "";
        };
      };
    };

    keepWavs = lib.mkEnableOption "keeping the wav files after encoding";

    outputTypes = lib.mkOption {
      description = "Audio formats to output.";
      type = lib.types.listOf (lib.types.enum [
        "flac"
        "m4a"
        "mp3"
        "mpc"
        "ogg"
        "opus"
        "mka"
        "spx"
        "vorbis"
        "wav"
        "wv"
        "ape"
        "aiff"
      ]);
      default = ["ogg"];
    };

    actions = lib.mkOption {
      description = ''
        Actions to take.

        -   encode implies read
        -   normalize implies read
        -   tag implies cddb,read,encode
        -   move implies cddb,read,encode,tag
        -   replaygain implies cddb,read,encode,tag,move
        -   playlist implies cddb
        -   embedalbumart implies getalbumart
        -   default implies cddb,read,encode,tag,move,clean

        An action can be added to the "default" action by specifying it along with
        "default", without having to repeat the default ones: `["default"
        "playlist"]`.
      '';
      type = lib.types.listOf (lib.types.enum [
        "cddb"
        "cue"
        "read"
        "normalize"
        "encode"
        "tag"
        "move"
        "replaygain"
        "playlist"
        "getalbumart"
        "embedalbumart"
        "clean"
        "default"
      ]);
      default = ["default"];
    };

    hooks = {
      mungeFilename = lib.mkOption {
        description = ''
          Bash code to run to perform custom filename munging.

          By default, abcde will do the following to CDDB data to get a useful filename:

          1.   Delete any dots preceding the title (first sed command)
          2.   Replace all spaces with an underscore (second sed command).
               Simply remove this if you prefer spaces.
          3.   Delete a grab bag of characters which variously Windows and
               Linux do not permit (tr command). Remove any of these from the
               list if you wish to actually use them.

          Variant 1 (works anywhere): Translate everything to lowercase.
          Replace ALL chars that may cause trouble for Linux, Windows and DOS
          with '_' (underscore); remove double underscores; remove leading and
          trailing underscores; recode to flat ASCII:

          ```
          echo "$@" | tr [A-Z] [a-z] | \
              sed "s/[- ,.:\'\/!@#\?\$%\^&()]/_/g" | \
              sed 's/_[_]*/_/g' | \
              sed 's/^_*//' | \
              sed 's/_*$//' | \
              ''${pkgs.recode}/bin/recode -f iso8859-1..flat
          ```

          Variant 2 (legible):

          Accept all chars, EXCEPT '/' (obvious) or ":" (because eyeD3 cannot
          cope with ":" in pathnames): replace them with " " (space).
          Additionally, replace contiguous spaces with one space; strip leading
          spaces; strip trailing spaces and recode to flat filenames.

          ```
          echo "$@" | sed "s/[:\/]/ /g" | \
              sed 's/ [ ]*/ /g' | \
              sed 's/^ *//' | \
              sed 's/ *$//' | \
              ''${pkgs.recode}/bin/recode -f iso8859-1..flat
          ```
        '';
        type = lib.types.str;
        default = ''
          echo "$@" | sed -e 's/^\.*//' -e 's/ /_/g' | tr -d ":><|*/\"'?[:cntrl:]"
        '';
      };
      mungeTrackName = lib.mkOption {
        description = ''
          Bash code to run to perform filename munging specific to track names.
        '';
        type = lib.types.str;
        default = "mungefilename \"$@\"";
      };
      mungeArtistName = lib.mkOption {
        description = ''
          Bash code to run to perform filename munging specific to artist names.
        '';
        type = lib.types.str;
        default = "mungefilename \"$@\"";
      };
      mungeAlbumName = lib.mkOption {
        description = ''
          Bash code to run to perform filename munging specific to album names.
        '';
        type = lib.types.str;
        default = "mungefilename \"$@\"";
      };
      mungeGenre = lib.mkOption {
        description = ''
          Bash code to run to perform genre munging.

          By default we just transform uppercase to lowercase.  Not much of a
          fancy function, with not much use, but one can disable it or just
          turn the first Uppercase.
        '';
        type = lib.types.str;
        default = "echo \"$CDGENRE\" | tr \"[:upper:]\" \"[:lower:]\"";
      };
      pre_read = lib.mkOption {
        description = ''
          Bash code to perform custom actions before reading.

          You can set some things to get abcde function in better ways:

          -   Close the CD tray using eject -t (if available in eject and
              supported by your CD device.
          -   Set the CD speed. You can also use the built-in options, but you
              can also set it here. In Debian, eject -x and cdset -x do the
              job.
        '';
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      post_read = lib.mkOption {
        description = ''
          Bash code to perform custom actions after reading.

          You can set some things to get abcde function in better ways:

          -   Store a copy of the CD TOC.
        '';
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      post_encode = lib.mkOption {
        description = ''
          Bash code to perform custom actions after encoding.

          You can set some things to get abcde function in better ways:

          -   Move the resulting directory over the network
          -   Compare results with a previously made run, for tests
        '';
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };

    autoEject = lib.mkEnableOption "automatically ejecting the cdrom after all the tracks have been read";

    padTracks = lib.mkEnableOption "forcing abcde to pad tracks using 0, so every song uses a two digit entry.  If set, even a single song encoding outputs a file like 01.my_song.ext";

    verbosity = lib.mkOption {
      description = ''
        Verbosity level.  Set to 1 or 2 to obtain some information about
        actions happening in the background.  Useful if you have a slow network
        or CDDB servers seem unresponsive.
      '';
      type = lib.types.int;
      default = 0;
    };

    extraConfig = lib.mkOption {
      description = "Extra configuration to append to the .abcde.conf file.";
      type = lib.types.lines;
      default = "";
    };

    configuration = let
      yn = v:
        if v
        then "y"
        else "n";

      definitions =
        {
          CDDBMETHOD = lib.strings.concatStringsSep "," cfg.cddb.method;
          CDDBURL = cfg.cddb.url;
          CDDBPROTO = cfg.cddb.protocolLevel;
          CDDBSUBMIT = cfg.cddb.submissionEmail;
          CDDBCOPYLOCAL = yn cfg.cddb.cache.enable;
          CDDBLOCALDIR = cfg.cddb.cache.path;
          CDDBLOCALRECURSIVE = yn cfg.cddb.cache.checkRecursive;
          NOSUBMIT = yn (!cfg.cddb.offerSubmit);
          CDDBUSELOCAL = yn cfg.cddb.useLocal;
          SHOWCDDBFIELDS = lib.strings.concatStringsSep "," cfg.cddb.fields;
          KEEPWAVS = yn cfg.keepWavs;
          ACTIONS = lib.strings.concatStringsSep "," cfg.actions;
          OUTPUTTYPE = lib.strings.concatStringsSep "," cfg.outputTypes;
          EJECTCD = yn cfg.autoEject;
          PADTRACKS = yn cfg.padTracks;
          EXTRAVERBOSE= cfg.verbosity;
        }
        // lib.optionalAttrs (cfg.cddb.helloInfo != null) {
          HELLOINFO = cfg.cddb.helloInfo;
        }
        // lib.optionalAttrs cfg.encoders.opus.enable {
          OPUSENC = "${pkgs.opusTools}/bin/opusenc";
          OPUSENCOPTS = cfg.encoders.opus.options;
        };

        functionText = lib.concatStrings (lib.attrsets.mapAttrsToList (n: v:
      lib.optionalString (v != null) ''
          ${lib.strings.toLower n} () {
              ${v}
          }
        '')
        cfg.hooks);
    in
      lib.mkOption {
        description = ''
          Literal contents of the .abcde.conf file.  Defining this value will
          override any other abcde configuration; generally you should use
          extraConfig to add more configuration that isn't directly supported
          by this module.
        '';
        type = lib.types.lines;
        default = ''
          ${lib.strings.toShellVars definitions}
          ${functionText}
          ${cfg.extraConfig}
        '';
      };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.cddb.useLocal -> cfg.cddb.cache.checkRecursive;
        message = ''
          programs.abcde.cddb.useLocal requires
          programs.abcde.cddb.cache.checkRecursive.
        '';
      }
    ];
    home.file.".abcde.conf".text = cfg.configuration;
    home.packages = [cfg.package];
  };
}
