{ substCheckedShellScript }:
{ name, ... }@args:
substCheckedShellScript ({ destination = "/bin/${name}"; } // args)
