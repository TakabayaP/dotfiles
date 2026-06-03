{ pkgs, lib, ... }:
{
  programs.nixvim = {
    enable = true;

    version.enableNixpkgsReleaseCheck = false;
    nixpkgs.source = lib.mkForce pkgs.path;

    globals = {
      mapleader = " ";
    };

    opts = {
      clipboard = "unnamedplus";
      number = true;
      relativenumber = true;
      tabstop = 4;
      shiftwidth = 4;
      expandtab = true;
      softtabstop = 4;
      termguicolors = true;
    };

    # --------------------------------------------------------------------------
    # カラースキーム
    # --------------------------------------------------------------------------
    colorschemes.vscode = {
      enable = true;
      settings = {
        style = "dark";
      };
    };

    # --------------------------------------------------------------------------
    # プラグイン (NixVim 組み込みモジュール)
    # --------------------------------------------------------------------------

    plugins.web-devicons.enable = true;

    plugins.telescope = {
      enable = true;
      settings = {
        defaults = {
          find_command = [ "fd" "--type" "f" "--hidden" "--exclude" ".git" ];
        };
      };
      extensions.fzf-native.enable = true;
    };

    plugins.treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
      };
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        typescript tsx javascript
        json html css yaml markdown markdown_inline
        lua bash
        go gomod gosum
        nix
      ];
    };

    plugins.cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        snippet.expand = ''
          function(args)
            require("luasnip").lsp_expand(args.body)
          end
        '';
        mapping = {
          "__raw" = ''
            cmp.mapping.preset.insert({
              ['<C-b>'] = cmp.mapping.scroll_docs(-4),
              ['<C-f>'] = cmp.mapping.scroll_docs(4),
              ['<C-Space>'] = cmp.mapping.complete(),
              ['<C-e>'] = cmp.mapping.abort(),
              ['<CR>'] = cmp.mapping.confirm({ select = false }),
            })
          '';
        };
        sources = [
          { name = "nvim_lsp"; }
          { name = "luasnip"; }
          { name = "buffer"; }
          { name = "path"; }
        ];
      };
    };

    plugins.luasnip.enable = true;

    plugins.lsp = {
      enable = true;
      servers = {
        ts_ls.enable = true;
        gopls.enable = true;
        eslint.enable = false;
      };
      keymaps = {
        lspBuf = {
          "gd" = "definition";
          "K" = "hover";
          "<F2>" = "rename";
          "<leader>ca" = "code_action";
        };
        extra = [
          { key = "gr"; action.__raw = "require('telescope.builtin').lsp_references"; mode = "n"; }
        ];
      };
    };

    diagnostics = {
      underline = true;
      virtual_text = true;
      signs = true;
    };

    highlightOverride = {
      DiagnosticUnderlineError = { underline = true; sp = "#ff0000"; };
      DiagnosticUnderlineWarn = { underline = true; sp = "#ffcc00"; };
      DiagnosticUnderlineInfo = { underline = true; sp = "#00bfff"; };
      DiagnosticUnderlineHint = { underline = true; sp = "#888888"; };
    };

    plugins.conform-nvim = {
      enable = true;
      settings = {
        formatters_by_ft = {
          go = [ "gofmt" ];
          javascript = {
            __unkeyed-1 = "prettierd";
            __unkeyed-2 = "prettier";
            stop_after_first = true;
          };
          typescript = {
            __unkeyed-1 = "prettierd";
            __unkeyed-2 = "prettier";
            stop_after_first = true;
          };
          javascriptreact = {
            __unkeyed-1 = "prettierd";
            __unkeyed-2 = "prettier";
            stop_after_first = true;
          };
          typescriptreact = {
            __unkeyed-1 = "prettierd";
            __unkeyed-2 = "prettier";
            stop_after_first = true;
          };
          json = {
            __unkeyed-1 = "prettierd";
            __unkeyed-2 = "prettier";
            stop_after_first = true;
          };
          jsonc = {
            __unkeyed-1 = "prettierd";
            __unkeyed-2 = "prettier";
            stop_after_first = true;
          };
          css = {
            __unkeyed-1 = "prettierd";
            __unkeyed-2 = "prettier";
            stop_after_first = true;
          };
          html = {
            __unkeyed-1 = "prettierd";
            __unkeyed-2 = "prettier";
            stop_after_first = true;
          };
          yaml = {
            __unkeyed-1 = "prettierd";
            __unkeyed-2 = "prettier";
            stop_after_first = true;
          };
          markdown = {
            __unkeyed-1 = "prettierd";
            __unkeyed-2 = "prettier";
            stop_after_first = true;
          };
        };
        format_on_save = {
          timeout_ms = 3000;
          lsp_format = "never";
        };
      };
    };

    plugins.gitsigns = {
      enable = true;
      settings = {
        max_file_length = 5000;
        update_debounce = 1000;
      };
    };

    plugins.nvim-autopairs = {
      enable = true;
    };

    plugins.lualine = {
      enable = true;
      settings = {
        sections = {
          lualine_a = [ "mode" ];
          lualine_b = [ "branch" ];
          lualine_c = [
            {
              "__unkeyed-1" = {
                "__raw" = ''
                  function() return vim.fn.fnamemodify(vim.fn.getcwd(), ":~") end
                '';
              };
              icon = "";
            }
            {
              "__unkeyed-1" = "filename";
              path = 1;
            }
          ];
          lualine_x = [ "filetype" ];
          lualine_y = [ "progress" ];
          lualine_z = [ "location" ];
        };
      };
    };

    plugins.bufferline = {
      enable = true;
      settings = {
        options = {
          numbers.__raw = ''
            function(opts)
              return string.format('%s', opts.ordinal)
            end
          '';
        };
      };
    };

    plugins.render-markdown = {
      enable = true;
    };

    plugins.snacks = {
      enable = true;
      settings = {
        explorer = {
          enabled = true;
          replace_netrw = true;
        };
        indent = {
          enabled = true;
        };
        dashboard = {
          enabled = true;
          sections = [
            { section = "header"; }
            { section = "keys"; gap = 1; padding = 1; }
          ];
          preset = {
            keys = [
              { icon = " "; key = "f"; desc = "Find File"; action = ":lua Snacks.picker.files()"; }
              { icon = " "; key = "g"; desc = "Find Text"; action = ":lua Snacks.picker.grep()"; }
              { icon = " "; key = "r"; desc = "Recent Files"; action = ":lua Snacks.picker.recent()"; }
              { icon = " "; key = "s"; desc = "Restore Session"; action = ":lua require('persistence').load()"; }
              { icon = " "; key = "c"; desc = "Config"; action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })"; }
              { icon = " "; key = "q"; desc = "Quit"; action = ":qa"; }
            ];
          };
        };
        scroll = {
          enabled = true;
          animate = {
            duration = { step = 15; total = 150; };
          };
          filter.__raw = ''
            function(buf)
              return vim.g.snacks_scroll ~= false
                and vim.b[buf].snacks_scroll ~= false
                and vim.bo[buf].buftype ~= "terminal"
            end
          '';
        };
        picker = {
          enabled = true;
          sources = {
            explorer = {
              hidden = true;
              layout = {
                layout = {
                  position = "right";
                };
              };
            };
          };
        };
      };
    };

    # --------------------------------------------------------------------------
    # プラグイン (extraPlugins)
    # --------------------------------------------------------------------------

    extraPlugins = with pkgs.vimPlugins; [
      lazygit-nvim
      diffview-nvim
      git-worktree-nvim
      persistence-nvim
      neogen
      plenary-nvim
      nvim-web-devicons
    ];

    extraPackages = with pkgs; [
      fd
      ripgrep
      prettierd
      lazygit
    ];

    # --------------------------------------------------------------------------
    # キーバインド (宣言的)
    # --------------------------------------------------------------------------

    keymaps = [
      # 半ページスクロール
      { mode = "n"; key = "<C-d>"; action = "<C-d>"; options.desc = "Half-page down"; }
      { mode = "n"; key = "<C-u>"; action = "<C-u>"; options.desc = "Half-page up"; }

      # ジャンプ履歴
      { mode = "n"; key = "<leader>["; action = "<C-o>"; options.desc = "ジャンプ履歴: 戻る"; }
      { mode = "n"; key = "<leader>]"; action = "<C-i>"; options.desc = "ジャンプ履歴: 進む"; }
      { mode = "n"; key = "<F16>"; action = "<C-o>"; options.desc = "ジャンプ履歴: 戻る (Cmd+[)"; }
      { mode = "n"; key = "<F17>"; action = "<C-i>"; options.desc = "ジャンプ履歴: 進む (Cmd+])"; }

      # 保存 (Cmd+S)
      { mode = [ "n" "i" ]; key = "<F18>"; action = "<cmd>w<cr>"; options.desc = "保存 (Cmd+S)"; }

      # コメントアウト (Cmd+/)
      { mode = "n"; key = "<F20>"; action = "gcc"; options = { desc = "コメントアウト切替 (Cmd+/)"; remap = true; }; }
      { mode = "v"; key = "<F20>"; action = "gc"; options = { desc = "コメントアウト切替 (Cmd+/)"; remap = true; }; }
      { mode = "i"; key = "<F20>"; action = "<Esc>gcca"; options = { desc = "コメントアウト切替 (Cmd+/)"; remap = true; }; }

      # ターミナル操作
      { mode = "t"; key = "<C-w>"; action = "<C-\\><C-n><C-w>"; options.desc = "ターミナルからウィンドウ操作"; }
      { mode = "t"; key = "<Esc><Esc>"; action = "<C-\\><C-n>"; options.desc = "ターミナルでノーマルモードに切替"; }

      # ファイル検索 (Telescope)
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope live_grep<cr>"; options.desc = "Live Grep"; }
      { mode = "n"; key = "<F14>"; action = "<cmd>Telescope live_grep<cr>"; options.desc = "Live Grep (Ctrl+Shift+F)"; }

      # バッファ切り替え
      { mode = "n"; key = "gt"; action = "<cmd>BufferLineCycleNext<cr>"; options = { desc = "Next Buffer"; silent = true; }; }
      { mode = "n"; key = "gT"; action = "<cmd>BufferLineCyclePrev<cr>"; options = { desc = "Prev Buffer"; silent = true; }; }
      { mode = "n"; key = "<leader>bd"; action = "<cmd>bdelete<cr>"; options = { desc = "Close Buffer"; silent = true; }; }
      { mode = "n"; key = "<leader>bD"; action = "<cmd>%bdelete | enew<cr>"; options = { desc = "Close All Buffers"; silent = true; }; }

      # バッファ番号ジャンプ
      { mode = "n"; key = "<leader>1"; action = "<cmd>BufferLineGoToBuffer 1<cr>"; options = { desc = "Buffer 1"; silent = true; }; }
      { mode = "n"; key = "<leader>2"; action = "<cmd>BufferLineGoToBuffer 2<cr>"; options = { desc = "Buffer 2"; silent = true; }; }
      { mode = "n"; key = "<leader>3"; action = "<cmd>BufferLineGoToBuffer 3<cr>"; options = { desc = "Buffer 3"; silent = true; }; }
      { mode = "n"; key = "<leader>4"; action = "<cmd>BufferLineGoToBuffer 4<cr>"; options = { desc = "Buffer 4"; silent = true; }; }
      { mode = "n"; key = "<leader>5"; action = "<cmd>BufferLineGoToBuffer 5<cr>"; options = { desc = "Buffer 5"; silent = true; }; }
      { mode = "n"; key = "<leader>6"; action = "<cmd>BufferLineGoToBuffer 6<cr>"; options = { desc = "Buffer 6"; silent = true; }; }
      { mode = "n"; key = "<leader>7"; action = "<cmd>BufferLineGoToBuffer 7<cr>"; options = { desc = "Buffer 7"; silent = true; }; }
      { mode = "n"; key = "<leader>8"; action = "<cmd>BufferLineGoToBuffer 8<cr>"; options = { desc = "Buffer 8"; silent = true; }; }
      { mode = "n"; key = "<leader>9"; action = "<cmd>BufferLineGoToBuffer 9<cr>"; options = { desc = "Buffer 9"; silent = true; }; }

      # タブページ
      { mode = "n"; key = "<leader>tn"; action = "<cmd>tabnext<cr>"; options = { desc = "Next Tab Page"; silent = true; }; }
      { mode = "n"; key = "<leader>tp"; action = "<cmd>tabprev<cr>"; options = { desc = "Prev Tab Page"; silent = true; }; }

      # Snacks Explorer
      { mode = "n"; key = "<leader>e"; action.__raw = "function() Snacks.explorer.open() end"; options.desc = "Explorer (toggle)"; }
      { mode = "n"; key = "-"; action.__raw = "function() Snacks.explorer.open() end"; options.desc = "Explorer (toggle)"; }

      # Git差分・blame
      { mode = "n"; key = "<leader>gd"; action = "<cmd>Gitsigns diffthis<cr>"; options = { desc = "Git Diff"; silent = true; }; }
      { mode = "n"; key = "<leader>gb"; action = "<cmd>Gitsigns blame_line<cr>"; options = { desc = "Git Blame"; silent = true; }; }
      { mode = "n"; key = "<leader>gp"; action = "<cmd>Gitsigns preview_hunk<cr>"; options = { desc = "Git Hunk Preview"; silent = true; }; }
      { mode = "n"; key = "]c"; action = "<cmd>Gitsigns next_hunk<cr>"; options = { desc = "次の変更箇所"; silent = true; }; }
      { mode = "n"; key = "[c"; action = "<cmd>Gitsigns prev_hunk<cr>"; options = { desc = "前の変更箇所"; silent = true; }; }

      # Diffview
      { mode = "n"; key = "<leader>gh"; action = "<cmd>DiffviewFileHistory % --no-merges<cr>"; options = { desc = "現在ファイルのコミット履歴"; silent = true; }; }
      { mode = "n"; key = "<leader>gH"; action = "<cmd>DiffviewFileHistory --no-merges<cr>"; options = { desc = "リポジトリ全体のコミット履歴"; silent = true; }; }
      { mode = "n"; key = "<leader>gc"; action = "<cmd>DiffviewClose<cr>"; options = { desc = "Diffview を閉じる"; silent = true; }; }

      # LazyGit
      { mode = "n"; key = "<leader>gg"; action = "<cmd>LazyGit<cr>"; options = { desc = "LazyGit"; silent = true; }; }

      # 診断
      { mode = "n"; key = "<leader>d"; action.__raw = "vim.diagnostic.open_float"; options.desc = "エラー内容を表示"; }
      { mode = "n"; key = "]d"; action.__raw = "vim.diagnostic.goto_next"; options.desc = "次のエラーへ"; }
      { mode = "n"; key = "[d"; action.__raw = "vim.diagnostic.goto_prev"; options.desc = "前のエラーへ"; }

      # コードリンクコピー
      {
        mode = "n"; key = "<F15>"; options.desc = "Copy code link (Cmd+L)";
        action.__raw = ''
          function()
            local filepath = vim.fn.expand('%:.')
            local line = vim.fn.line('.')
            local link = filepath .. ':' .. line
            vim.fn.setreg('+', link)
            vim.notify('Copied: ' .. link, vim.log.levels.INFO)
          end
        '';
      }

      # セッション復元
      { mode = "n"; key = "<leader>sr"; action.__raw = "function() require('persistence').load() end"; options.desc = "セッション復元"; }
      { mode = "n"; key = "<leader>sl"; action.__raw = "function() require('persistence').load({ last = true }) end"; options.desc = "最後のセッションを復元"; }
      { mode = "n"; key = "<leader>sd"; action.__raw = "function() require('persistence').stop() end"; options.desc = "セッション自動保存を停止"; }

      # Neogen
      { mode = "n"; key = "<leader>jd"; action.__raw = "function() require('neogen').generate() end"; options.desc = "JSDoc アノテーション生成"; }
    ];

    # --------------------------------------------------------------------------
    # Lua ファイル (extraFiles で ~/.config/nvim/lua/custom/ に配置)
    # --------------------------------------------------------------------------

    extraFiles = {
      "lua/custom/worktree.lua".source = ./neovim/worktree.lua;
      "lua/custom/terminal.lua".source = ./neovim/terminal.lua;
      "lua/custom/find-files.lua".source = ./neovim/find-files.lua;
    };

    # --------------------------------------------------------------------------
    # extraConfigLua (宣言的に表現できない最小限の設定)
    # --------------------------------------------------------------------------

    extraConfigLua = ''
      vim.o.statuscolumn = '%s %{v:lnum} %{v:relnum ? v:relnum : ">"} '
      vim.opt.sessionoptions:remove('terminal')

      -- プラグインセットアップ
      require("persistence").setup({})
      require("neogen").setup({
        snippet_engine = "luasnip",
        languages = {
          javascript = { template = { annotation_convention = "jsdoc" } },
          typescript = { template = { annotation_convention = "tsdoc" } },
          typescriptreact = { template = { annotation_convention = "tsdoc" } },
          javascriptreact = { template = { annotation_convention = "jsdoc" } },
        },
      })

      -- カスタムモジュール読み込み
      require("custom.worktree")
      require("custom.terminal")
      require("custom.find-files")
    '';
  };
}
