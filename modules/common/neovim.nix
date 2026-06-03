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
    ];

    # --------------------------------------------------------------------------
    # extraConfigLua (ロジックを含む設定)
    # --------------------------------------------------------------------------

    extraConfigLua = ''
      -- statuscolumn
      vim.o.statuscolumn = '%s %{v:lnum} %{v:relnum ? v:relnum : ">"} '

      -- sessionoptions から terminal を除外
      vim.opt.sessionoptions:remove('terminal')

      -- :q でバッファを閉じる (最後の1つなら Neovim を終了)
      vim.api.nvim_create_user_command('Q', function()
        local wins = vim.tbl_filter(function(w)
          return vim.api.nvim_win_get_config(w).relative == ""
        end, vim.api.nvim_tabpage_list_wins(0))
        if #wins > 1 then
          vim.cmd('quit')
        else
          local bufs = vim.tbl_filter(function(b) return vim.bo[b].buflisted end, vim.api.nvim_list_bufs())
          if #bufs > 1 then
            vim.cmd('bdelete')
          else
            vim.cmd('quit')
          end
        end
      end, {})
      vim.cmd([[cnoreabbrev <expr> q getcmdtype() == ':' && getcmdline() == 'q' ? 'Q' : 'q']])
      vim.cmd([[cnoreabbrev <expr> hs getcmdtype() == ':' && getcmdline() == 'hs' ? 'sp' : 'hs']])

      -- persistence.nvim セットアップ
      require("persistence").setup({})

      -- neogen セットアップ
      require("neogen").setup({
        snippet_engine = "luasnip",
        languages = {
          javascript = { template = { annotation_convention = "jsdoc" } },
          typescript = { template = { annotation_convention = "tsdoc" } },
          typescriptreact = { template = { annotation_convention = "tsdoc" } },
          javascriptreact = { template = { annotation_convention = "jsdoc" } },
        },
      })
      vim.keymap.set('n', '<leader>jd', function() require("neogen").generate() end, { desc = "JSDoc アノテーション生成" })

      -- git-worktree セットアップ (v2.x API)
      require("telescope").load_extension("git_worktree")
      local hooks = require("git-worktree.hooks")
      hooks.register(hooks.type.SWITCH, function(path, prev_path)
        vim.schedule(function()
          vim.cmd('%bdelete!')
          local ok, persistence = pcall(require, "persistence")
          if ok then persistence.load() end
          vim.cmd("doautoall FileType")
        end)
      end)
      hooks.register(hooks.type.DELETE, function(path)
        vim.schedule(function()
          if path then
            _G._wt_diff_cache[path] = nil
          end
          if _G._wt_update_cache then _G._wt_update_cache() end
        end)
      end)

      -- ファイル一覧キャッシュ
      _G._file_cache = nil
      local function refresh_file_cache()
        vim.fn.jobstart({ 'fd', '--type', 'f', '--hidden', '--exclude', '.git' }, {
          stdout_buffered = true,
          on_stdout = function(_, data)
            _G._file_cache = vim.tbl_filter(function(line) return line ~= "" end, data)
          end,
        })
      end
      vim.api.nvim_create_autocmd("VimEnter", { callback = refresh_file_cache })
      vim.api.nvim_create_autocmd("DirChanged", { callback = refresh_file_cache })
      vim.api.nvim_create_autocmd("BufWritePost", {
        callback = function(ev)
          local path = ev.file
          if _G._file_cache and not vim.tbl_contains(_G._file_cache, path) then
            refresh_file_cache()
          end
        end,
      })

      local function cached_find_files()
        if _G._file_cache then
          require('telescope.pickers').new({}, {
            prompt_title = 'Find Files',
            finder = require('telescope.finders').new_table({ results = _G._file_cache }),
            sorter = require('telescope.config').values.file_sorter({}),
            previewer = require('telescope.config').values.file_previewer({}),
          }):find()
        else
          require('telescope.builtin').find_files()
        end
      end
      vim.keymap.set('n', '<leader>ff', cached_find_files, { desc = "Find Files" })
      vim.keymap.set('n', '<F13>', cached_find_files, { desc = "Find Files (Cmd+P)" })

      -- ターミナル切替
      local _term_buf = nil
      local function toggle_terminal()
        if _term_buf and vim.api.nvim_buf_is_valid(_term_buf) then
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == _term_buf then
              local wins = vim.tbl_filter(function(w)
                return vim.api.nvim_win_get_config(w).relative == ""
              end, vim.api.nvim_tabpage_list_wins(0))
              if #wins <= 1 then vim.cmd('enew') end
              vim.api.nvim_win_hide(win)
              return
            end
          end
          vim.cmd('botright 15split')
          vim.api.nvim_set_current_buf(_term_buf)
          vim.cmd('startinsert')
        else
          vim.cmd('botright 15split | terminal')
          _term_buf = vim.api.nvim_get_current_buf()
          vim.cmd('startinsert')
        end
      end
      vim.keymap.set({'n', 't', 'i'}, '<F19>', toggle_terminal, { desc = "ターミナル切替 (Cmd+J)" })

      -- コードリンクコピー
      vim.keymap.set('n', '<F15>', function()
        local filepath = vim.fn.expand('%:.')
        local line = vim.fn.line('.')
        local link = filepath .. ':' .. line
        vim.fn.setreg('+', link)
        vim.notify('Copied: ' .. link, vim.log.levels.INFO)
      end, { desc = "Copy code link (Cmd+L)" })

      -- セッション復元
      vim.keymap.set('n', '<leader>sr', function() require("persistence").load() end, { desc = "セッション復元 (このディレクトリ)" })
      vim.keymap.set('n', '<leader>sl', function() require("persistence").load({ last = true }) end, { desc = "最後のセッションを復元" })
      vim.keymap.set('n', '<leader>sd', function() require("persistence").stop() end, { desc = "セッション自動保存を停止" })

      -- 診断表示
      vim.diagnostic.config({
        underline = true,
        virtual_text = true,
        signs = true,
      })
      vim.api.nvim_set_hl(0, 'DiagnosticUnderlineError', { underline = true, sp = '#ff0000' })
      vim.api.nvim_set_hl(0, 'DiagnosticUnderlineWarn', { underline = true, sp = '#ffcc00' })
      vim.api.nvim_set_hl(0, 'DiagnosticUnderlineInfo', { underline = true, sp = '#00bfff' })
      vim.api.nvim_set_hl(0, 'DiagnosticUnderlineHint', { underline = true, sp = '#888888' })

      -- LSP キーバインド
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        end,
      })

      -- Git ワークツリー: 差分キャッシュ
      _G._wt_diff_cache = _G._wt_diff_cache or {}

      local function wt_parse_list()
        local output = vim.fn.systemlist('git worktree list --porcelain')
        local worktrees = {}
        local w = {}
        for _, line in ipairs(output) do
          if line:match('^worktree ') then
            w = { path = line:match('^worktree (.+)') }
          elseif line:match('^branch ') then
            w.branch = line:match('^branch refs/heads/(.+)')
          elseif line == "" and w.path then
            table.insert(worktrees, w)
            w = {}
          end
        end
        if w.path then table.insert(worktrees, w) end
        return worktrees
      end

      local function wt_update_cache()
        local ok, worktrees = pcall(wt_parse_list)
        if not ok or #worktrees == 0 then
          _G._wt_diff_cache = {}
          return
        end
        local active_paths = {}
        for _, w in ipairs(worktrees) do active_paths[w.path] = true end
        for path in pairs(_G._wt_diff_cache) do
          if not active_paths[path] then _G._wt_diff_cache[path] = nil end
        end
        for _, w in ipairs(worktrees) do
          vim.fn.jobstart({ 'git', '-C', w.path, 'diff', '--numstat' }, {
            stdout_buffered = true,
            on_stdout = function(_, data)
              local add, del = 0, 0
              for _, line in ipairs(data) do
                local a, d = line:match('^(%d+)%s+(%d+)')
                if a then add = add + tonumber(a); del = del + tonumber(d) end
              end
              _G._wt_diff_cache[w.path] = { add = add, del = del }
            end,
          })
        end
      end

      _G._wt_update_cache = wt_update_cache

      vim.keymap.set('n', '<leader>wt', function()
        wt_update_cache()
        local pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local conf = require('telescope.config').values
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')

        local worktrees = wt_parse_list()

        local max_branch = 0
        for _, w in ipairs(worktrees) do
          local b = w.branch or '(detached)'
          if #b > max_branch then max_branch = #b end
        end

        pickers.new({}, {
          prompt_title = 'Git Worktrees',
          finder = finders.new_table({
            results = worktrees,
            entry_maker = function(entry)
              local branch = entry.branch or '(detached)'
              local cache = _G._wt_diff_cache[entry.path] or { add = 0, del = 0 }
              local add_str = cache.add > 0 and string.format("+%d", cache.add) or ""
              local del_str = cache.del > 0 and string.format("-%d", cache.del) or ""

              local pad = string.rep(" ", max_branch - #branch)
              local diff_part = string.format("%6s %6s", add_str, del_str)
              local line = branch .. pad .. "  " .. diff_part

              local highlights = {}
              local diff_start = max_branch + 2
              if add_str ~= "" then
                local add_offset = diff_start + (6 - #add_str)
                table.insert(highlights, { { add_offset, add_offset + #add_str }, "GitSignsAdd" })
              end
              if del_str ~= "" then
                local del_offset = diff_start + 7 + (6 - #del_str)
                table.insert(highlights, { { del_offset, del_offset + #del_str }, "GitSignsDelete" })
              end

              return {
                value = entry,
                display = function()
                  return line, highlights
                end,
                ordinal = branch,
              }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              local sel = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if sel then
                require("persistence").save()
                require('git-worktree').switch_worktree(sel.value.path)
              end
            end)
            map('i', '<C-d>', function()
              local sel = action_state.get_selected_entry()
              if sel then
                actions.close(prompt_bufnr)
                require('git-worktree').delete_worktree(sel.value.path)
              end
            end)
            return true
          end,
        }):find()
      end, { desc = "Git Worktree 一覧・切替" })
      vim.keymap.set('n', '<leader>wc', function() require('telescope').extensions.git_worktree.create_git_worktree() end, { desc = "Git Worktree 作成" })
    '';
  };
}
