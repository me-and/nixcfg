{ writeCheckedShellScript }:
{ name, ... }@args:
writeCheckedShellScript ({ destination = "/bin/${name}"; } // args)
