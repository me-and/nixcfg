{ personalCfg, ... }:
{
  specialisation = {
    pd.configuration = {
      imports = [ personalCfg.nixosModules.pd ];
    };
    steeplechase.configuration = {
      imports = [ personalCfg.nixosModules.steeplechase ];
    };
  };
}
