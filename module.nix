# NixOS module running the drafter as a systemd user service, so it
# reaches the user's gh login and Claude Code login. It never posts:
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

    user = lib.mkOption {
      type = lib.types.str;
      description = "The user whose session runs the drafter.";
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
      default = "%h/code/pimalaya";
      description = "Where Claude Code runs: the folder holding the repositories.";
    };

    maxBudgetUsd = lib.mkOption {
      type = lib.types.str;
      default = "1";
      description = "Maximum spend per item, in US dollars.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.pimalaya-assistant = {
      description = "Pimalaya triage drafter";
      unitConfig.ConditionUser = cfg.user;
      environment = {
        REPOS = lib.concatStringsSep " " cfg.repos;
        WORKDIR = cfg.workdir;
        MAX_BUDGET_USD = cfg.maxBudgetUsd;
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe cfg.package;
      };
    };

    systemd.user.timers.pimalaya-assistant = {
      description = "Pimalaya triage drafter timer";
      wantedBy = [ "timers.target" ];
      unitConfig.ConditionUser = cfg.user;
      timerConfig = {
        OnCalendar = cfg.interval;
        Persistent = true;
      };
    };
  };
}
