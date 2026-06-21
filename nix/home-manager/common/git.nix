{ pkgs, forceLinks, ... }:

let
  ghCredentialHelper =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "!/opt/homebrew/bin/gh auth git-credential"
    else "!/usr/bin/gh auth git-credential";
in
{
  programs.git = {
    enable = true;
    package = null;

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6j5pkvHqP1YRODd00yh5FM7YGuozykifYWYYuQeMuu";
      format = "ssh";
      signByDefault = true;
      signer = "op-ssh-sign-wrapper";
    };

    ignores = [
      ".#*"
      ".dir-locals.el"
      ".DS_Store"
      "**/.claude/settings.local.json"
      ".pi/todos/"
    ];

    settings = [
      {
        user = {
          name = "Mark Tran";
          email = "mark.tran@gmail.com";
        };

        github.user = "marktran";

        core = {
          quotepath = false;
          pager = "less";
        };

        alias = {
          browse = "!gh repo view --web";
          w = "!gh repo view --web";
          compare = "!gh compare";

          a = "add";
          br = "branch";
          ci = "commit";
          co = "checkout";
          di = "diff";
          hist = "log --pretty=format:'%Cred%h%Creset%C(yellow)%d%Creset (%Cgreen%cr%Creset) %s [%Cblue%an%Creset]' --graph --abbrev-commit --date=relative";
          l = "log --name-status";
          st = "status --branch --short";
          sta = "stash";
        };

        color.ui = "auto";
        init.defaultBranch = "master";
        pull.rebase = true;
        difftool.prompt = false;
        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
        };
        commit.verbose = true;
        column.ui = "auto";
        branch.sort = "-committerdate";
        tag.sort = "-version:refname";
        rerere = {
          enabled = true;
          autoupdate = true;
        };
        fetch.prune = true;
        push = {
          autoSetupRemote = true;
          default = "current";
        };
        gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";
        hub.http-clone = true;
        magit.hideCampaign = true;
      }
      {
        credential."https://github.com".helper = "";
      }
      {
        credential."https://github.com".helper = ghCredentialHelper;
      }
      {
        credential."https://gist.github.com".helper = "";
      }
      {
        credential."https://gist.github.com".helper = ghCredentialHelper;
      }
    ];
  };

  xdg.configFile."git/config".force = forceLinks;
  xdg.configFile."git/ignore".force = forceLinks;
  xdg.configFile."git/allowed_signers" = {
    force = forceLinks;
    text = "mark.tran@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6j5pkvHqP1YRODd00yh5FM7YGuozykifYWYYuQeMuu\n";
  };
}
