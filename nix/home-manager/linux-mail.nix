{ config, lib, pkgs, ... }:

let
  mailRepository = "${config.accounts.email.maildirBasePath}/gmail";
  notmuchConfig = "${config.xdg.configHome}/notmuch/default/config";
  credentialFile = "${mailRepository}/.credentials.gmailieer.json";

  mailRuntimeInputs = [
    config.programs.lieer.package
    config.programs.notmuch.package
  ];

  gmailAuth = pkgs.writeShellApplication {
    name = "notmuch-gmail-auth";
    runtimeInputs = mailRuntimeInputs;
    text = ''
      umask 077
      repository=${lib.escapeShellArg mailRepository}

      if [[ ! -e "$repository/.gmailieer.json" ]]; then
        echo "notmuch-gmail-auth: Lieer is not configured; run 'make switch' first" >&2
        exit 1
      fi

      mkdir -p "$repository/mail"/{cur,new,tmp}
      export NOTMUCH_CONFIG=${lib.escapeShellArg notmuchConfig}

      # Lieer requires an initialized Notmuch database before OAuth setup.
      notmuch new
      exec gmi auth -C "$repository" "$@"
    '';
  };

  mailSync = pkgs.writeShellApplication {
    name = "notmuch-sync";
    runtimeInputs = mailRuntimeInputs;
    text = ''
      repository=${lib.escapeShellArg mailRepository}
      credential_file=${lib.escapeShellArg credentialFile}
      export NOTMUCH_CONFIG=${lib.escapeShellArg notmuchConfig}

      if [[ ! -f "$credential_file" ]]; then
        if [[ "''${1:-}" == "--if-authorized" ]]; then
          exit 0
        fi
        echo "notmuch-sync: Gmail is not authorized; run 'notmuch-gmail-auth' first" >&2
        exit 1
      fi

      if [[ "''${1:-}" == "--if-authorized" ]]; then
        shift
      fi
      exec gmi sync -C "$repository" "$@"
    '';
  };

  gmailSendmail = pkgs.writeShellApplication {
    name = "notmuch-sendmail";
    runtimeInputs = mailRuntimeInputs;
    text = ''
      repository=${lib.escapeShellArg mailRepository}
      credential_file=${lib.escapeShellArg credentialFile}
      export NOTMUCH_CONFIG=${lib.escapeShellArg notmuchConfig}

      if [[ ! -f "$credential_file" ]]; then
        echo "notmuch-sendmail: Gmail is not authorized; run 'notmuch-gmail-auth' first" >&2
        exit 1
      fi

      # Emacs may pass these sendmail delivery-mode flags for asynchronous
      # sends. The Gmail API sends immediately, so Lieer does not need them.
      args=()
      for arg in "$@"; do
        case "$arg" in
          -oem|-odb) ;;
          *) args+=("$arg") ;;
        esac
      done

      exec gmi send -t -C "$repository" "''${args[@]}"
    '';
  };
in
{
  accounts.email = {
    maildirBasePath = "Maildir";

    accounts.gmail = {
      primary = true;
      address = "mark.tran@gmail.com";
      realName = "Mark Tran";
      flavor = "gmail.com";
      maildir.path = "gmail";

      notmuch.enable = true;
      lieer = {
        enable = true;
        sync = {
          enable = true;
          frequency = "*:0/5";
        };
      };
    };
  };

  programs = {
    lieer.enable = true;

    notmuch = {
      enable = true;
      # Lieer applies Gmail's actual INBOX and UNREAD labels while importing.
      # Adding Notmuch's defaults here would incorrectly mark archived/read
      # messages as inbox/unread during the first pull.
      new.tags = [ ];
      search.excludeTags = [
        "deleted"
        "spam"
        "trash"
      ];
    };
  };

  home.packages = [
    gmailAuth
    mailSync
    gmailSendmail
  ];

  # Home Manager writes Lieer's declarative configuration, while these Maildir
  # directories and OAuth/state files remain mutable user data.
  home.activation.createLieerMaildir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg mailRepository}/mail/{cur,new,tmp}
    run chmod 700 ${lib.escapeShellArg config.accounts.email.maildirBasePath} \
      ${lib.escapeShellArg mailRepository} ${lib.escapeShellArg mailRepository}/mail \
      ${lib.escapeShellArg mailRepository}/mail/{cur,new,tmp}
  '';
}
