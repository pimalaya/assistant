# Home Manager module running the drafter as a systemd user service, so
# it reaches the user's gh login and Claude Code login. It never posts:
# plans wait in the queue until the user applies them.
self:
{ config, lib, pkgs, ... }:

let
  cfg = config.services.pimalaya-assistant;
in
{
  options.services.pimalaya-assistant = {
    enable = lib.mkEnableOption "the Pimalaya triage drafter";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "The drafter package.";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "*:0/5";
      description = "When to run, as a systemd OnCalendar expression.";
    };

    repos = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "pimalaya/himalaya" ];
      description = "The repositories to watch, as owner/name.";
    };

    workdir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/code/pimalaya";
      description = "Where Claude Code runs: the folder holding the repositories.";
    };

    maxBudgetUsd = lib.mkOption {
      type = lib.types.str;
      default = "1";
      description = "Maximum spend per item, in US dollars.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services.pimalaya-assistant = {
      Unit.Description = "Pimalaya triage drafter";
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe cfg.package;
        Environment = [
          "REPOS=${lib.concatStringsSep " " cfg.repos}"
          "WORKDIR=${cfg.workdir}"
          "MAX_BUDGET_USD=${cfg.maxBudgetUsd}"
        ];
      };
    };

    systemd.user.timers.pimalaya-assistant = {
      Unit.Description = "Pimalaya triage drafter timer";
      Timer = {
        OnCalendar = cfg.interval;
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
