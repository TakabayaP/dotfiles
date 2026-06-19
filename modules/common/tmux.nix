{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 0;
    mouse = true;
    terminal = "tmux-256color";
    extraConfig = ''
      # pane分割 (vimの:vs/:spに対応)
      bind v split-window -h -c "#{pane_current_path}"
      bind s split-window -v -c "#{pane_current_path}"

      # pane移動
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # 新しいwindowを現在のパスで開く
      bind c new-window -c "#{pane_current_path}"

      # C-a C-a で配下のシェルにC-aを送る (行頭移動用)
      bind C-a send-prefix

      # copy-mode (prefix+[ で入る、vで選択開始、yでコピー)
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
    '';
  };
}
