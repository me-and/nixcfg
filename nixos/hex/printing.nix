{ mylib, pkgs, ... }:
{
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    cups-kyocera-3500-4500
    hplip # PD GOD HP printers
    cnijfilter2 # Colour printer in Preston
  ];

  nixpkgs.config.allowUnfreePackages = [
    "cups-kyocera-3500-4500"
    "cnijfilter2"
  ];

  # TODO replace pypdf3 in cups-kyocera-3500-4500 with pypdf3.  See
  # https://github.com/NixOS/nixpkgs/pull/506381 for similar work for a
  # different Kyocera driver set.
  #
  # In the meantime, I've reviewed these vulnerabilities and, while they're far
  # from ideal, I'm not desperately worried about them.
  nixpkgs.config.allowInsecurePredicate =
    pkg:
    pkg.pname == "pypdf3"
    &&
      (mylib.removeAll [
        "CVE-2026-27024"
        "CVE-2026-27025"
        "CVE-2026-27628"
        "CVE-2026-27888"
        "CVE-2026-28351"
        "CVE-2026-33699"
      ] pkg.meta.knownVulnerabilities) == [ ];

}
