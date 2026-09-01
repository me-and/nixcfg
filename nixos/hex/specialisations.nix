{ personalCfg, ... }:
{
  specialisation = {
    pd.configuration = {
      imports = [ personalCfg.nixosModules.pd ];
    };
    tether.configuration = {
      imports = [ personalCfg.nixosModules.tether ];
    };
  };
}
