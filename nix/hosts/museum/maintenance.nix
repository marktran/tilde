{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;
  logrotateConfig = pkgs.writeText "museum-logrotate.conf" ''
    /tmp/process-compose-${config.home.username}.log
    ${home}/src/vhm/museum/.devbox/compose.log
    ${home}/.herdr/worktrees/museum/*/.devbox/compose.log {
      size 20M
      rotate 2
      compress
      copytruncate
      missingok
      notifempty
    }
  '';
in
{
  systemd.user.services.museum-maintenance = {
    Unit.Description = "Reap deleted Museum worktree services and rotate Devbox logs";
    Service = {
      Type = "oneshot";
      StateDirectory = "museum-maintenance";
      UMask = "0077";
      Nice = 10;
      TimeoutStartSec = "60s";
      ExecStart = [
        "${lib.getExe pkgs.ruby} ${./reap-stale-services.rb}"
        "${lib.getExe pkgs.logrotate} --state %S/museum-maintenance/logrotate.status ${logrotateConfig}"
      ];
    };
  };

  systemd.user.timers.museum-maintenance = {
    Unit.Description = "Bound Museum development-service disk usage";
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
      AccuracySec = "30s";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
