# like lib.remove, but removing all elements of the list rather than only a
# single element.
{ }: elems: builtins.filter (x: !builtins.elem x elems)
