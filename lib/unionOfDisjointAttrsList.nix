# Like lib.mergeAttrsList, but using lib.attrsets.unionOfDisjoint, so accessing
# any attributes present in multiple sets will throw an error.
{ lib }:
list:
let
  # `binaryMerge start end` merges the elements at indices `index` of `list`
  # such that `start <= index < end`.
  binaryMerge =
    start: end:
    # assert start < end; # Invariant
    if end - start >= 2 then
      # If there's at least two elements, split the range in two, recurse on
      # each part and merge the result.  The invariant is satisfied because
      # each half will have at least one element.
      let
        left = binaryMerge start (start + (end - start) / 2);
        right = binaryMerge (start + (end - start) / 2) end;
      in
      lib.attrsets.unionOfDisjoint left right
    else
      # Otherwise there will be exactly one element due to the invariant, in
      # which case we just return it directly.
      builtins.elemAt list start;
in
if list == [ ] then
  # Calling binaryMerge as below wouldn't satisfy the invariant.
  { }
else
  binaryMerge 0 (builtins.length list)
