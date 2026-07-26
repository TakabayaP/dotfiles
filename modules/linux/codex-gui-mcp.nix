{ config, lib, pkgs, ... }:

let
  knownHostsPath = "${config.home.homeDirectory}/.ssh/codex-gui-known-hosts";
  identityPath = "${config.home.homeDirectory}/.ssh/homecloud";
  sshCommand = "${pkgs.openssh}/bin/ssh";
  commonArgs = [
    "-T"
    "-i"
    identityPath
    "-o"
    "IdentitiesOnly=yes"
    "-o"
    "BatchMode=yes"
    "-o"
    "StrictHostKeyChecking=yes"
    "-o"
    "UserKnownHostsFile=${knownHostsPath}"
    "-o"
    "RequestTTY=no"
    "codex-gui@192.168.11.205"
  ];

  syncCodexGuiMcp = pkgs.writeShellScriptBin "sync-codex-gui-mcp" ''
    set -euo pipefail

    codex_bin=${config.home.homeDirectory}/.local/bin/codex
    if [ ! -x "$codex_bin" ]; then
      echo "sync-codex-gui-mcp: Codex CLI is not installed; skipping" >&2
      exit 0
    fi

    sync_server() {
      name="$1"
      remote_command="$2"
      expected_args="$(${pkgs.jq}/bin/jq -cn \
        --arg remote_command "$remote_command" \
        '${builtins.toJSON commonArgs} + [$remote_command]')"

      if current="$("$codex_bin" mcp get "$name" --json 2>/dev/null)" \
        && printf '%s' "$current" | ${pkgs.jq}/bin/jq -e \
          --arg command ${lib.escapeShellArg sshCommand} \
          --argjson args "$expected_args" \
          '.transport.type == "stdio"
           and .transport.command == $command
           and .transport.args == $args' >/dev/null
      then
        return
      fi

      "$codex_bin" mcp remove "$name" >/dev/null 2>&1 || true
      "$codex_bin" mcp add "$name" -- \
        ${sshCommand} \
        ${lib.concatMapStringsSep " " lib.escapeShellArg commonArgs} \
        "$remote_command"
    }

    sync_server gui-computer computer
    sync_server gui-browser browser
  '';
in
{
  home.file.".ssh/codex-gui-known-hosts" = {
    text = ''
      codex-gui,192.168.11.205 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBgxiOsRdZ/DljwPAoFAk0dW8oPLvrOQV5qShfMKAX/X
    '';
  };

  home.packages = [
    pkgs.jq
    pkgs.openssh
    syncCodexGuiMcp
  ];

  home.activation.syncCodexGuiMcp =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${syncCodexGuiMcp}/bin/sync-codex-gui-mcp
    '';
}
