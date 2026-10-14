# NixOS module running the assistant as a systemd user service, so it
# reaches the user's gpg-agent (pass), gh login and Claude Code login.
self:
{ config, lib, pkgs, ... }:

let
  cfg = config.services.pimalaya-assistant;
in
{
  options.services.pimalaya-assistant = {
    enable = lib.mkEnableOption "the Pimalaya Assistant runner";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "The runner package.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "The user whose session runs the assistant.";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "When to run, as a systemd OnCalendar expression.";
    };

    dryRun = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Log proposals instead of posting them.";
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
      description = "Pimalaya Assistant runner";
      unitConfig.ConditionUser = cfg.user;
      environment = {
        DRY_RUN = if cfg.dryRun then "1" else "0";
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
      description = "Pimalaya Assistant runner timer";
      wantedBy = [ "timers.target" ];
      unitConfig.ConditionUser = cfg.user;
      timerConfig = {
        OnCalendar = cfg.interval;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
