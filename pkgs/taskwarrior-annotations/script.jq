def csi: "\u001b[";
def sgr(attrs): csi + ([attrs] | join(";")) + "m";
def colour(c): sgr(c) + . + sgr(39);
def bwhite: colour(97);

if length == 1
then
  .[].annotations
  | if . == null
    then "no annotations\n" | halt_error(66)
    end
  | map(
    .entry |= (
      strptime("%Y%m%dT%H%M%SZ")
      | mktime
      | strflocaltime("%a %-e %b %R %Z")
    )
    | [(.entry | bwhite), .description]
    | join("\n")
  )
  | join("\n\n")
else
  "can't cope with multiple tasks just yet\n"
  | halt_error(69)
end
