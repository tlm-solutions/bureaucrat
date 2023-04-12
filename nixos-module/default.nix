{ pkgs, config, lib, ... }:
let
  cfg = config.TLMS.bureaucrat;
in
{
  options.TLMS.bureaucrat = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''Wether to enable bureaucrat service'';
    };
    grpc = {
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = ''
          To which IP bureaucrat should bind its grpc server.
        '';
      };
      port = mkOption {
        type = types.port;
        default = 8080;
        description = ''
          To which port should bureaucrat bind its grpc server.
        '';
      };
    };
    redis = {
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = ''
          Database host
        '';
      };
      port = mkOption {
        type = types.port;
        default = 5354;
        description = ''
          Database port
        '';
      };
    };
    user = mkOption {
      type = types.str;
      default = "bureaucrat";
      description = ''systemd user'';
    };
    group = mkOption {
      type = types.str;
      default = "bureaucrat";
      description = ''group of systemd user'';
    };
    log_level = mkOption {
      type = types.str;
      default = "info";
      description = ''log level of the application'';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      services = {
        "bureaucrat" = {
          enable = true;
          wantedBy = [ "multi-user.target" "redis.service"];

          script = ''
            exec ${pkgs.bureaucrat}/bin/bureaucrat&
          '';

          environment = {
            "RUST_LOG" = "${cfg.log_level}";
            "RUST_BACKTRACE" = if (cfg.log_level == "info") then "0" else "1";
            "BUREAUCRAT_HOST" = "${cfg.host}:${toString cfg.port}";
            "REDIS_HOST" = "${cfg.redis.host}";
            "REDIS_PORT" = "${toString cfg.redis.port}"
          };

          serviceConfig = {
            Type = "forking";
            User = cfg.user;
            Restart = "always";
          };
        };
      };
    };

    # user accounts for systemd units
    users.users."${cfg.user}" = {
      name = "${cfg.user}";
      description = "This guy runs bureaucrat";
      isNormalUser = false;
      isSystemUser = true;
      group = cfg.group;
      extraGroups = [ ];
    };
  };
}
