{ pkgs, lib, ... }:
{
  programs.nixvim = {
    enable = true;

    version.enableNixpkgsReleaseCheck = false;
    nixpkgs.source = lib.mkForce pkgs.path;

    globals = {
      mapleader = " ";
      VM_maps = {
        "Add Cursor Down" = "<C-j>";
        "Add Cursor Up" = "<C-k>";
      };
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
      mouse = "a";
      autowriteall = true;
      shell =
        if pkgs.stdenv.isDarwin
        then "/opt/homebrew/bin/fish"
        else "${pkgs.fish}/bin/fish";
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
        preselect.__raw = "cmp.PreselectMode.None";
        completion.completeopt = "menu,menuone,noselect";
        snippet.expand = ''
          function(args)
            require("luasnip").lsp_expand(args.body)
          end
        '';
        mapping = {
          "__raw" = ''
            (function()
              local luasnip = require("luasnip")
              return cmp.mapping.preset.insert({
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<C-e>'] = cmp.mapping.abort(),
                ['<CR>'] = cmp.mapping.confirm({ select = false }),
                ['<Tab>'] = cmp.mapping(function(fallback)
                  if cmp.visible() then
                    cmp.select_next_item()
                  elseif luasnip.expandable() then
                    luasnip.expand()
                  elseif luasnip.jumpable(1) then
                    luasnip.jump(1)
                  else
                    fallback()
                  end
                end, { 'i', 's' }),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                  if cmp.visible() then
                    cmp.select_prev_item()
                  elseif luasnip.jumpable(-1) then
                    luasnip.jump(-1)
                  else
                    fallback()
                  end
                end, { 'i', 's' }),
              })
            end)()
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
          "gi" = "implementation";
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
      Normal = { bg = "none"; };
      NormalNC = { bg = "none"; };
      NormalFloat = { bg = "none"; };
      SignColumn = { bg = "none"; };
      LineNr = { bg = "none"; };
      FoldColumn = { bg = "none"; };
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

    plugins.gitlinker = {
      enable = true;
      settings.mappings = null;
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
      settings = {
        # Keep source visible while editing, as in the referenced setup.
        render_modes = [ "n" "c" ];
        heading.enabled = false;
        link.enabled = false;
        pipe_table.enabled = true;
        # Snacks owns Mermaid rendering. render-markdown's code-block conceal
        # hides its Kitty unicode placeholders in Normal mode.
        code.disable = [ "mermaid" ];
      };
    };

    plugins.image = {
      enable = true;
      settings = {
        backend = "kitty";
        processor = "magick_cli";
        integrations = {
          markdown = {
            enabled = true;
            clear_in_insert_mode = true;
            only_render_image_at_cursor = false;
            floating_windows = false;
            filetypes = [ "markdown" ];
          };
          asciidoc.enabled = false;
          css.enabled = false;
          html.enabled = false;
          neorg.enabled = false;
          org.enabled = false;
          rst.enabled = false;
          syslang.enabled = false;
          typst.enabled = false;
        };
        max_height_window_percentage = 50;
        # This setup is for images embedded in Markdown, not opening image files
        # as Neovim buffers.
        hijack_file_patterns.__raw = "{}";
      };
    };

    plugins.snacks = {
      enable = true;
      settings = {
        image = {
          enabled = true;
          # Keep high-resolution conversions separate from the old cache,
          # since Snacks cache keys do not include converter arguments.
          cache.__raw = "vim.fn.stdpath('cache') .. '/snacks/image-1200x2'";
          # Mermaid rendering is attached explicitly only to Markdown files in
          # Git repositories. Do not hijack standalone image buffers.
          formats.__raw = "{}";
          convert = {
            notify = true;
            mermaid.__raw = ''
              function()
                local theme = vim.o.background == "light" and "neutral" or "dark"
                return {
                  "-i", "{src}",
                  "-o", "{file}",
                  "-b", "transparent",
                  "-t", theme,
                  "-w", "1200",
                  "-s", "2",
                }
              end
            '';
          };
          doc = {
            # Keep Mermaid diagrams visible through Kitty unicode placeholders
            # instead of showing them only while the cursor is on the block.
            enabled = false;
            inline = true;
            float = false;
            # Snacks defaults to 80x40 cells. Use twice that area so inline
            # Markdown previews are visibly larger on wide terminal windows.
            max_width = 160;
            max_height = 80;
          };
          math.enabled = false;
        };
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
        terminal = {
          enabled = true;
          win = {
            position = "bottom";
            height = 15;
          };
        };
        picker = {
          enabled = true;
          sources = {
            explorer = {
              hidden = true;
              ignored = true;
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
      nvim-treesitter-textobjects
      vim-visual-multi
    ];

    extraPackages =
      (with pkgs; [
        fd
        git
        imagemagick
        mermaid-cli
        ripgrep
        prettierd
        lazygit
      ])
      ++ lib.optionals pkgs.stdenv.isLinux [
        pkgs.chromium
        pkgs.wl-clipboard
        pkgs.xclip
      ];

    # --------------------------------------------------------------------------
    # キーバインド (宣言的)
    # --------------------------------------------------------------------------

    keymaps = [
      # 半ページスクロール
      { mode = "n"; key = "<C-d>"; action = "<C-d>"; options.desc = "Half-page down"; }
      { mode = "n"; key = "<C-u>"; action = "<C-u>"; options.desc = "Half-page up"; }

      # 現在のwindowをzoom表示
      { mode = "n"; key = "<C-w>f"; action.__raw = "function() Snacks.zen.zoom() end"; options.desc = "Toggle window zoom"; }

      # Markdown画像・Mermaidを画像専用bufferで拡大表示
      { mode = "n"; key = "<leader>ip"; action.__raw = "function() require('custom.mermaid').preview_at_cursor() end"; options.desc = "Preview image in buffer"; }
      { mode = "n"; key = "<leader>ic"; action.__raw = "function() require('custom.mermaid').copy_at_cursor() end"; options.desc = "Copy image to clipboard"; }

      # ジャンプ履歴
      { mode = "n"; key = "<leader>["; action = "<C-o>"; options.desc = "ジャンプ履歴: 戻る"; }
      { mode = "n"; key = "<leader>]"; action = "<C-i>"; options.desc = "ジャンプ履歴: 進む"; }
      { mode = "n"; key = "<F16>"; action = "<C-o>"; options.desc = "ジャンプ履歴: 戻る (Ctrl+[)"; }
      { mode = "n"; key = "<F17>"; action = "<C-i>"; options.desc = "ジャンプ履歴: 進む (Ctrl+])"; }

      # 保存 (Ctrl+S)
      { mode = [ "n" "i" ]; key = "<F18>"; action = "<cmd>w<cr>"; options.desc = "保存 (Ctrl+S)"; }

      # コメントアウト (Ctrl+/)
      { mode = "n"; key = "<F20>"; action = "gcc"; options = { desc = "コメントアウト切替 (Ctrl+/)"; remap = true; }; }
      { mode = "v"; key = "<F20>"; action = "gc"; options = { desc = "コメントアウト切替 (Ctrl+/)"; remap = true; }; }
      { mode = "i"; key = "<F20>"; action = "<Esc>gcca"; options = { desc = "コメントアウト切替 (Ctrl+/)"; remap = true; }; }

      # ターミナル
      { mode = [ "n" "t" "i" ]; key = "<F19>"; action.__raw = "function() Snacks.terminal.toggle() end"; options.desc = "Toggle terminal (Ctrl+J)"; }
      { mode = "t"; key = "<C-w>"; action = "<C-\\><C-n><C-w>"; options.desc = "Window nav from terminal"; }

      # ファイル検索 (Telescope)
      { mode = "n"; key = "<leader>fg"; action.__raw = "function() require('custom.find-files').live_grep() end"; options.desc = "Live Grep"; }
      { mode = "n"; key = "<F14>"; action.__raw = "function() require('custom.find-files').live_grep() end"; options.desc = "Live Grep (Ctrl+Shift+F)"; }

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
      { mode = "n"; key = "<leader>gd"; options = { desc = "Git Diff (toggle)"; silent = true; };
        action.__raw = ''
          function()
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              local buf = vim.api.nvim_win_get_buf(win)
              local name = vim.api.nvim_buf_get_name(buf)
              if name:match("^gitsigns://") then
                vim.api.nvim_buf_delete(buf, { force = true })
                vim.cmd("diffoff")
                return
              end
            end
            require("gitsigns").diffthis()
          end
        '';
      }
      { mode = "n"; key = "<leader>gb"; action = "<cmd>Gitsigns blame_line<cr>"; options = { desc = "Git Blame"; silent = true; }; }
      { mode = "n"; key = "<leader>gp"; action = "<cmd>Gitsigns preview_hunk<cr>"; options = { desc = "Git Hunk Preview"; silent = true; }; }
      { mode = "n"; key = "]c"; action = "<cmd>Gitsigns next_hunk<cr>"; options = { desc = "次の変更箇所"; silent = true; }; }
      { mode = "n"; key = "[c"; action = "<cmd>Gitsigns prev_hunk<cr>"; options = { desc = "前の変更箇所"; silent = true; }; }

      # Diffview
      { mode = "n"; key = "<leader>gh"; action = "<cmd>DiffviewFileHistory % --no-merges<cr>"; options = { desc = "現在ファイルのコミット履歴"; silent = true; }; }
      { mode = "n"; key = "<leader>gH"; action = "<cmd>DiffviewFileHistory --no-merges<cr>"; options = { desc = "リポジトリ全体のコミット履歴"; silent = true; }; }
      { mode = "n"; key = "<leader>gc"; action = "<cmd>DiffviewClose<cr>"; options = { desc = "Diffview を閉じる"; silent = true; }; }

      # GitHub permalink
      {
        mode = ["n" "v"]; key = "<leader>gy"; options = { desc = "GitHub permalink"; silent = true; };
        action.__raw = ''
          function()
            local bufname = vim.api.nvim_buf_get_name(0)
            if bufname:match("^%w+://") then
              vim.notify("permalink: real file buffer で実行してね", vim.log.levels.WARN)
              return
            end
            require("gitlinker").get_buf_range_url(vim.fn.mode())
          end
        '';
      }

      # LazyGit
      { mode = "n"; key = "<leader>gg"; action = "<cmd>LazyGit<cr>"; options = { desc = "LazyGit"; silent = true; }; }

      # 診断
      { mode = "n"; key = "<leader>d"; action.__raw = "vim.diagnostic.open_float"; options.desc = "エラー内容を表示"; }
      { mode = "n"; key = "]d"; action.__raw = "vim.diagnostic.goto_next"; options.desc = "次のエラーへ"; }
      { mode = "n"; key = "[d"; action.__raw = "vim.diagnostic.goto_prev"; options.desc = "前のエラーへ"; }

      # コードリンクコピー
      {
        mode = "n"; key = "<F15>"; options.desc = "Copy code link (Ctrl+L)";
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
      "lua/custom/find-files.lua".source = ./neovim/find-files.lua;
      "lua/custom/mermaid.lua".source = ./neovim/mermaid.lua;
    };

    # --------------------------------------------------------------------------
    # extraConfigLua (宣言的に表現できない最小限の設定)
    # --------------------------------------------------------------------------

    # Terminal capability overrides must run before plugin setup. Otherwise
    # snacks.image can cache Herdr as a terminal without unicode placeholders.
    extraConfigLuaPre = ''
      if vim.env.HERDR_ENV == "1" then
        vim.env.SNACKS_KITTY = "true"
      end

      -- Mermaid CLI uses Chromium headlessly to turn diagram source into PNG.
      vim.env.PUPPETEER_EXECUTABLE_PATH = ${
        if pkgs.stdenv.isDarwin
        then ''"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"''
        else ''"${pkgs.chromium}/bin/chromium"''
      }
    '';

    extraConfigLua = ''
      vim.o.statuscolumn = '%s %{v:lnum} %{v:relnum ? v:relnum : ">"} '
      vim.opt.sessionoptions:remove('terminal')

      -- The terminal sends Ctrl shortcuts as F13-F20. Herdr preserves the underlying
      -- Shift-F1..F8 identity when Neovim enables the Kitty keyboard protocol.
      -- Remap both representations to the existing F13-F20 actions.
      if vim.env.HERDR_ENV == "1" then
        vim.api.nvim_create_autocmd("VimEnter", {
          once = true,
          callback = function()
            vim.schedule(function()
              local herdr_key_aliases = {
                ["<S-F1>"] = "<F13>",
                ["<S-F2>"] = "<F14>",
                ["<S-F3>"] = "<F15>",
                ["<S-F4>"] = "<F16>",
                ["<S-F5>"] = "<F17>",
                ["<S-F6>"] = "<F18>",
                ["<S-F7>"] = "<F19>",
                ["<S-F8>"] = "<F20>",
              }
              for source, target in pairs(herdr_key_aliases) do
                vim.keymap.set({ "n", "i", "v", "t" }, source, target, {
                  remap = true,
                  silent = true,
                })
              end
            end)
          end,
        })
      end

      -- treesitter-textobjects
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local select_textobject = require("nvim-treesitter-textobjects.select").select_textobject
      local move = require("nvim-treesitter-textobjects.move")

      -- select keymaps
      local select_maps = {
        af = "@function.outer",
        ["if"] = "@function.inner",
        ac = "@class.outer",
        ic = "@class.inner",
        aa = "@parameter.outer",
        ia = "@parameter.inner",
        ai = "@conditional.outer",
        ii = "@conditional.inner",
        al = "@loop.outer",
        il = "@loop.inner",
      }
      for key, query in pairs(select_maps) do
        vim.keymap.set({ "x", "o" }, key, function()
          select_textobject(query, "textobjects")
        end, { desc = "TS: " .. query })
      end

      -- move keymaps
      vim.keymap.set({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next function start" })
      vim.keymap.set({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Prev function start" })
      vim.keymap.set({ "n", "x", "o" }, "]a", function() move.goto_next_start("@parameter.outer", "textobjects") end, { desc = "Next parameter" })
      vim.keymap.set({ "n", "x", "o" }, "[a", function() move.goto_previous_start("@parameter.outer", "textobjects") end, { desc = "Prev parameter" })

      -- swap keymaps
      local swap = require("nvim-treesitter-textobjects.swap")
      vim.keymap.set("n", "<leader>a", function() swap.swap_next("@parameter.inner", "textobjects") end, { desc = "Swap param next" })
      vim.keymap.set("n", "<leader>A", function() swap.swap_previous("@parameter.inner", "textobjects") end, { desc = "Swap param prev" })

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
      require("custom.find-files")
      require("custom.mermaid")
    '';
  };
}
