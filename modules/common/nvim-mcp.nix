{ config, lib, pkgs, nvim-mcp, ... }:

let
  nvimMcp = nvim-mcp.packages.${pkgs.system}.default;
  nvimMcpPlugin = pkgs.vimUtils.buildVimPlugin {
    pname = "nvim-mcp";
    version = nvim-mcp.shortRev or "unstable";
    src = nvim-mcp;
  };

  syncNvimMcpClients = pkgs.writeShellScriptBin "sync-nvim-mcp-clients" ''
    set -euo pipefail

    home_dir=${lib.escapeShellArg config.home.homeDirectory}
    nvim_mcp_bin=${lib.escapeShellArg (lib.getExe nvimMcp)}
    expected_args='["--connect","auto"]'

    codex_bin=""
    for candidate in \
      "$home_dir/.local/bin/codex" \
      "/Applications/Codex.app/Contents/Resources/codex"
    do
      if [ -x "$candidate" ]; then
        codex_bin="$candidate"
        break
      fi
    done
    if [ -z "$codex_bin" ] && command -v codex >/dev/null 2>&1; then
      codex_bin="$(command -v codex)"
    fi

    if [ -n "$codex_bin" ]; then
      if ! current="$("$codex_bin" mcp get nvim --json 2>/dev/null)" \
        || ! printf '%s' "$current" | ${pkgs.jq}/bin/jq -e \
          --arg command "$nvim_mcp_bin" \
          --argjson args "$expected_args" \
          '.transport.type == "stdio"
           and .transport.command == $command
           and .transport.args == $args' >/dev/null
      then
        "$codex_bin" mcp remove nvim >/dev/null 2>&1 || true
        "$codex_bin" mcp add nvim -- "$nvim_mcp_bin" --connect auto
      fi
    else
      echo "sync-nvim-mcp-clients: Codex CLI is not installed; skipping Codex config" >&2
    fi

    cursor_dir="$home_dir/.cursor"
    cursor_config="$cursor_dir/mcp.json"
    mkdir -p "$cursor_dir"

    if [ -f "$cursor_config" ]; then
      if ! ${pkgs.jq}/bin/jq -e \
        'type == "object" and ((.mcpServers // {}) | type == "object")' \
        "$cursor_config" >/dev/null
      then
        echo "sync-nvim-mcp-clients: $cursor_config is not a valid MCP config; skipping Cursor config" >&2
        exit 0
      fi
      cursor_source="$cursor_config"
    else
      cursor_source=${pkgs.writeText "empty-cursor-mcp.json" "{}"}
    fi

    if ! ${pkgs.jq}/bin/jq -e \
      --arg command "$nvim_mcp_bin" \
      --argjson args "$expected_args" \
      '.mcpServers.nvim.command == $command
       and .mcpServers.nvim.args == $args' \
      "$cursor_source" >/dev/null
    then
      umask 077
      cursor_tmp="$(mktemp "$cursor_dir/.mcp.json.XXXXXX")"
      trap 'rm -f "$cursor_tmp"' EXIT
      ${pkgs.jq}/bin/jq \
        --arg command "$nvim_mcp_bin" \
        --argjson args "$expected_args" \
        '.mcpServers = (.mcpServers // {})
         | .mcpServers.nvim = { command: $command, args: $args }' \
        "$cursor_source" > "$cursor_tmp"
      mv "$cursor_tmp" "$cursor_config"
      trap - EXIT
    fi

    cursor_bin=""
    for candidate in \
      "$home_dir/.local/bin/cursor-agent" \
      "$home_dir/.local/bin/agent"
    do
      if [ -x "$candidate" ]; then
        cursor_bin="$candidate"
        break
      fi
    done
    if [ -z "$cursor_bin" ] && command -v cursor-agent >/dev/null 2>&1; then
      cursor_bin="$(command -v cursor-agent)"
    fi

    if [ -n "$cursor_bin" ]; then
      if ! "$cursor_bin" mcp enable nvim >/dev/null 2>&1; then
        echo "sync-nvim-mcp-clients: Cursor MCP config was written, but nvim could not be enabled" >&2
      fi
    else
      echo "sync-nvim-mcp-clients: Cursor CLI is not installed; config was written for later use" >&2
    fi
  '';
in
{
  programs.nixvim = {
    extraPlugins = [ nvimMcpPlugin ];
    extraFiles."lua/custom/nvim-mcp.lua".source = ./neovim/nvim-mcp.lua;
    extraConfigLua = ''
      require("custom.nvim-mcp").setup()
    '';
  };

  home.packages = [
    nvimMcp
    syncNvimMcpClients
  ];

  home.activation.syncNvimMcpClients =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      PATH="${pkgs.nodejs}/bin:$PATH" \
        $DRY_RUN_CMD ${syncNvimMcpClients}/bin/sync-nvim-mcp-clients
    '';
}
