# Deterministic pseudorandom numbers.  For when that's something you want.
# Feed, for example, the system name and the systemd unit name to get a
# randomized time to run OnCalendar systemd timers.  Works by getting a
# pseudorandom number by hashing an input string, then using modulo operations
# to extract integers in given ranges.
#
# Doesn't aim to be cryptographically secure; I can't immediately see why it
# wouldn't be provided you don't use up all the entropy and stick to picking
# from ranges that are powers of two, but I haven't tried to think about
# security here.
let
  inherit (builtins) foldl' genList getAttr hashString stringLength substring;

  foldlAttrs = f: init: set:
    foldl'
    (acc: name: f acc name set."${name}")
    init
    (builtins.attrNames set);

  hexToInt = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    "a" = 10;
    "b" = 11;
    "c" = 12;
    "d" = 13;
    "e" = 14;
    "f" = 15;
  };

  days = [
    "Mon"
    "Tue"
    "Wed"
    "Thu"
    "Fri"
    "Sat"
    "Sun"
  ];

  divmod = x: y: rec {
    quot = builtins.div x y;
    rem = x - y * quot;
  };

  zeroPad = len: n: let
    s = builtins.toString n;
    oldLen = stringLength s;
  in
    if oldLen >= len
    then s
    else builtins.concatStringsSep "" ((genList (_: "0") (len - oldLen)) ++ [s]);
in rec {
  calculateSeed = seedStr: let
    # Only use the first 15 characters: Nix integers are 64-bit signed, and I
    # want to make sure I'm only dealing with unsigned integers.
    #
    # Generate a hash of the string, take the first 15 characters, convert the
    # hex characters into integers, then add them all up.
    stringToChars = s: genList (p: substring p 1 s) 15;
    hexHash = hashString "sha1" seedStr;
    intList = map (c: getAttr c hexToInt) (stringToChars hexHash);
  in foldl' (x: y: (x*16) + y) 0 intList;

  # Pick a number between 0 and (n-1).  Return that number, and the rest of the
  # entropy in the seed.
  randInt' = seed: n: let
    result' = divmod seed n;
  in {
    result = result'.rem;
    seed = result'.quot;
  };

  randInt = seedStr: n: (randInt' (calculateSeed seedStr) n).result;

  # Take a seed string and a list of integers, and produce a list of random
  # numbers between 0 and each integer.
  randInts = seedStr: ns: let
    step = intermediate: n: let
      thisResult = randInt' intermediate.seed n;
    in {
      seed = thisResult.seed;
      results = intermediate.results ++ [thisResult.result];
    };
    start = {
      seed = calculateSeed seedStr;
      results = [];
    };
  in (builtins.foldl' step start ns).results;

  randInts = seedStr: ns: let


  systemdCalendar = {
    randMinutely = seedStr: "*:*:${randInt seedStr 60}";
    randHourly = seedStr: let


  };
}
