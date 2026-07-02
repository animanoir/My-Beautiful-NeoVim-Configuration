--------------------------------------------------------------------------------
-- 1. General options
--------------------------------------------------------------------------------

-- This means that the magic key for every command will start with SPACE
vim.g.mapleader = " "
vim.g.maplocalleader = ","

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.wrap = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.clipboard = "unnamedplus"
opt.ignorecase = true
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.undofile = true
opt.updatetime = 250
opt.scrolloff = 8
vim.opt.guicursor = {
  "n-v-c:block-Cursor/lCursor-blinkwait30-blinkon30-blinkoff25",
  "i-ci-ve:ver25-Cursor/lCursor-blinkwait50-blinkon30-blinkoff25",
  "r-cr:hor20-Cursor/lCursor-blinkwait50-blinkon30-blinkoff25",
  "o:hor50-Cursor/lCursor",
}

-- Vim API
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.api.nvim_set_hl(0, "TermNormal", { bg = "#000000" })
    vim.opt_local.winhighlight = "Normal:TermNormal,NormalNC:TermNormal"
  end,
})
-- native spell-check
--[[
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.spell = false
    vim.opt_local.spelllang = "es,en_us"
  end,
})
--]]
--------------------------------------------------------------------------------
-- 2. BOOTSTRAP LAZY.NVIM (plugin management)
--------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------------------------------------
-- 3. PLUGINS
--------------------------------------------------------------------------------
require("lazy").setup({
  -- SuperCollider
  {
    "davidgranstrom/scnvim",
    ft = "supercollider",
    dependencies = { "L3MON4D3/LuaSnip" },
    config = function()
      local scnvim = require("scnvim")
      local map = scnvim.map
      local map_expr = scnvim.map_expr
      scnvim.setup({
        keymaps = {
          ["<M-e>"]      = map("editor.send_line", { "i", "n" }),
          --["<C-e>"]      = {
          --map("editor.send_block", { "i", "n" }),
          --map("editor.send_selection", "x"),
          --},
          ["<CR>"]       = map("postwin.toggle"),
          ["<M-CR>"]     = map("postwin.toggle", "i"),
          ["<M-L>"]      = map("postwin.clear", { "n", "i" }),
          ["<C-k>"]      = map("signature.show", { "n", "i" }),
          ["<F12>"]      = map("sclang.hard_stop", { "n", "x", "i" }),
          ["<leader>st"] = map("sclang.start"),
          ["<leader>sk"] = map("sclang.recompile"),
          ["<F1>"]       = map_expr("s.boot"),
          ["<F2>"]       = map_expr("s.meter"),
        },
        editor = {
          highlight = { color = "IncSearch" },
        },
        postwin = {
          float = { enable = false },
        },
      })
      local ok, luasnip = pcall(require, "luasnip")
      if ok then
        luasnip.add_snippets("supercollider", require("scnvim.utils").get_snippets())
      end
    end,
  },
  -- Neogit: plugin to see git graphs and stuff
  {
    "NeogitOrg/neogit",
    lazy = true,
    dependencies = {
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Show Neogit UI" }
    }
  },
  -- which.key: Shows me what key combinations I can do when I press SPACE.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")

      wk.setup({
        delay = 300,
      })
      wk.add({
        { "<leader>f", group = "Search" },
        { "<leader>h", group = "Git" },
        { "<leader>m", group = "Fun" },
        { "<leader>c", group = "Code (LSP)" },
        { "<leader>r", group = "Run / Rename" },
      })
    end,
  },
  -- cellular-automaton: fun.
  {
    "eandrju/cellular-automaton.nvim",
    cmd = "CellularAutomaton",
    keys = {
      { "<leader>mr", "<cmd>CellularAutomaton make_it_rain<cr>", desc = "Make it rain" },
      { "<leader>ml", "<cmd>CellularAutomaton game_of_life<cr>", desc = "Game of Life" },
    },
  },
  -- gitsigns: Tells me via Git about the changes in my code.
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = "│" },
        change       = { text = "│" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
        untracked    = { text = "┆" },
      },
      on_attach = function(bufnr)
        local gs = require("gitsigns")

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        -- Navigate through hunks.
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.next_hunk()
          end
        end, "Next hunk")

        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.prev_hunk()
          end
        end, "Prev hunk")

        -- Actions on hunks
        map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
        map("n", "<leader>hS", gs.stage_buffer, "Stage buffer completo")
        map("n", "<leader>hR", gs.reset_buffer, "Reset buffer completo")

        -- Visual: stage/reset only selected lines
        map("v", "<leader>hs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage hunk (visual)")
        map("v", "<leader>hr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset hunk (visual)")

        -- Inspection
        map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>hb", function()
          gs.blame_line({ full = true })
        end, "Complete blame line")
        map("n", "<leader>hd", gs.diffthis, "Diff this")
      end,
    },
  },
  -- trouble (🚦 A pretty diagnostics, references, telescope results, quickfix and location
  -- list to help you solve all the trouble your code is causing.)
  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
  -- Indent Blankline
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      scope = {
        enabled = true,
        show_start = true,
        show_end = false,
      },
    },
  },
  -- Neo-Tree: lateral file explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    keys = { { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorer" } },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
  },
  -- Color-themes
  {
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("moonfly")
    end,
  },
  -- Treesitter: syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        "racket", "lua",
        "markdown", "markdown_inline",
        "gdscript", "godot_resource", "gdshader",
        "javascript", "typescript", "tsx",
        "html", "css", "json", "clojure", "astro",
      })
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },

  -- mason.nvim: LSP
  {
    "mason-org/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "hls",
          "lua_ls",
          "ts_ls",
          "eslint",
          "html",
          "cssls",
          "emmet_ls",
          "jsonls",
          "clojure_lsp",
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "mason-org/mason-lspconfig.nvim" },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end
      -- HTML
      vim.lsp.config("html", {
        capabilities = capabilities,
      })

      -- CSS / SCSS / Less
      vim.lsp.config("cssls", {
        capabilities = capabilities,
      })

      -- Emmet (autocompletado de snippets HTML/CSS tipo div>ul>li*3)
      vim.lsp.config("emmet_ls", {
        capabilities = capabilities,
        filetypes = { "html", "css", "typescriptreact", "javascriptreact" },
      })

      -- JSON con soporte de esquemas
      vim.lsp.config("jsonls", {
        capabilities = capabilities,
      })
      -- Racket
      vim.lsp.config("racket_langserver", {
        cmd = {
          "racket",
          "--lib",
          "racket-langserver"
        },
        filetypes = { "racket" },
        capabilities = capabilities,
      })

      -- Clojure
      vim.lsp.config("clojure_lsp", {
        capabilities = capabilities,
      })
      -- Godot
      vim.lsp.config("gdscript", {
        cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),
        filetypes = { "gdscript" },
        root_markers = { "project.godot" },
        capabilities = capabilities,
      })
      -- Lua
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
          },
        },
      })
      -- TypeScript/JavaScript
      vim.lsp.config("ts_ls", {
        capabilities = capabilities,
      })

      vim.lsp.config("eslint", {
        capabilities = capabilities,
      })
      vim.lsp.enable({
        "hls",
        "lua_ls",
        "gdscript",
        "clojure_lsp",
        "racket_langserver",
        "ts_ls",
        "eslint",
        "html",
        "cssls",
        "emmet_ls",
        "jsonls",
      })

      -- Keymaps LSP
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gr", vim.lsp.buf.references, "See references")
          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>d", vim.diagnostic.open_float, "See diagnostics")
          map("[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Last diagnostic")
          map("]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
        end,
      })
    end,
  },
  -- Autocomplete
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      --"hrsh7th/cmp-omni",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },
  -- Telescope: fuzzy search
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make", -- compiles once
      },
    },
    config = function()
      local telescope = require("telescope")

      telescope.setup({
        defaults = {
          preview = { treesitter = false },
        },
      })
      telescope.load_extension("fzf")
    end,
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Search files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Grep in project" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Open buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "Search in Help" },
    },
  },
  -- Floating terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      open_mapping = [[<C-t>]],
      direction = "float",
      float_opts = {
        border = "curved",
        width = function() return math.floor(vim.o.columns * 0.9) end,
        height = function() return math.floor(vim.o.lines * 0.85) end,
      },
    },
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme                = "moonfly",
        globalstatus         = true,
        section_separators   = { left = "", right = "" },
        component_separators = { left = "│", right = "│" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = {
          { "branch", icon = "" },
          {
            "diff",
            symbols = { added = " ", modified = " ", removed = " " },
            source = function() -- uses gitsigns status dict
              local gs = vim.b.gitsigns_status_dict
              if gs then
                return { added = gs.added, modified = gs.changed, removed = gs.removed }
              end
            end,
          },
        },
        lualine_c = {
          {
            "filename",
            path = 1, -- shows relative route
            symbols = { modified = " ●", readonly = " ", unnamed = "[no name]" },
          },
        },
        lualine_x = {
          {
            "diagnostics",
            sources = { "nvim_lsp" },
            symbols = { error = " ", warn = " ", info = " ", hint = " " },
          },
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },
  -- --------------
  -- My own plugins:
  -- --------------
  {
    "windwp/nvim-ts-autotag",
    ft = { "html", "javascript", "typescript", "javascriptreact", "typescriptreact" },
    opts = {},
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "BufReadPost",
    opts = {},
    keys = {
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Search TODOs" },
    },
  },
  -- mini.comment: comments using gcc & gc
  { "echasnovski/mini.comment", event = "VeryLazy", opts = {} },
  {
    "Olical/conjure",
    ft = { "clojure", "fennel", "scheme", "racket" },
    init = function()
      -- Avoic conflict with localleader
      vim.g["conjure#mapping#prefix"] = "<localleader>c"
    end,
  },
  {
    "julienvincent/nvim-paredit",
    ft = {
      "clojure",
      "scheme",
      "lisp",
      "fennel",
      "racket"
    },
    config = function()
      require("nvim-paredit").setup()
    end,
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          gdscript = { "gdformat" },
          lua = { "stylua" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
          markdown = { "prettier" },
          markdown_jsx = { "prettier" },
        },
        format_on_save = {
          timeout_ms = 2000,
          lsp_format = "fallback",
        },
      })
    end,
  },
  {
    { "echasnovski/mini.pairs",    event = "InsertEnter", opts = {} },
    { "echasnovski/mini.surround", event = "VeryLazy",    opts = {} },
  }
})

vim.filetype.add({
  extension = {
    mdx = "markdown",
    gd = "gdscript",
    tscn = "gdresource",
    tres = "gdresource",
    gdshader = "gdshader",
  },
  pattern = {
    ["project%.godot"] = "confini",
  }
})

-- Let's me execute a Racket file
vim.keymap.set("n", "<leader>rr", function()
  local file = vim.fn.expand("%:p")
  vim.cmd("write")
  require("toggleterm").exec("racket " .. vim.fn.shellescape(file))
end, { desc = "Run current Racket file" })

-- Prevents childless Clojure/Racket processes
vim.api.nvim_create_autocmd("VimLeavePre", {
  pattern = "*.rkt",
  callback = function()
    pcall(vim.cmd, "ConjureClientRacketStdioStop")
  end,
})

-- Distinct background for Conjure log buffers
vim.api.nvim_create_autocmd({ "BufWinEnter", "BufNew" }, {
  pattern = "conjure-log-*",
  callback = function()
    vim.api.nvim_set_hl(0, "ConjureLogNormal", { bg = "#181825" })
    vim.opt_local.winhighlight =
    "Normal:ConjureLogNormal,NormalNC:ConjureLogNormal"
  end,
})
-- ----------------
-- My own Keymaps
-- ----------------

-- Opens a terminal horizontally
vim.keymap.set("n", "<leader>th",
  function()
    vim.cmd("split")
    vim.cmd("terminal")
    vim.cmd("resize 10")
  end, {
    desc = "Terminal horizontal split"
  })

-- multiline evaluation of SuperCollider:
-- multiline evaluation of SuperCollider:

-- Find the ( ... ) block enclosing the cursor via balanced paren counting.
-- Returns start/end line numbers, or nil if the cursor isn't inside a block.
local function sc_block_range()
  local cur  = vim.fn.line(".")
  local last = vim.fn.line("$")

  -- 1) Block start: nearest line at/above cursor that begins with "(" at column 0.
  local s
  for ln = cur, 1, -1 do
    if vim.fn.getline(ln):match("^%(") then
      s = ln; break
    end
  end
  if not s then return nil end

  -- 2) Walk forward counting balanced parens, skipping string/symbol literals,
  --    char literals ($x) and // line comments, until depth returns to zero.
  local depth, quote = 0, nil
  for ln = s, last do
    local line = vim.fn.getline(ln)
    local i, len = 1, #line
    while i <= len do
      local c = line:sub(i, i)
      if quote then -- inside "..." or '...'
        if c == "\\" then
          i = i + 1 -- skip escaped char
        elseif c == quote then
          quote = nil
        end
      elseif c == '"' or c == "'" then
        quote = c -- enter string/symbol literal
      elseif c == "$" then
        i = i + 1 -- char literal: next char is data
      elseif c == "/" and line:sub(i + 1, i + 1) == "/" then
        break     -- comment to end of line
      elseif c == "(" then
        depth = depth + 1
      elseif c == ")" then
        depth = depth - 1
        if depth == 0 then -- matched the block's closing paren
          if cur >= s and cur <= ln then return s, ln end
          return nil       -- cursor wasn't inside this block
        end
      end
      i = i + 1
    end
  end
  return nil -- unbalanced
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "supercollider",
  callback = function(args)
    local buf = args.buf

    -- Visual: eval exactly the selected lines
    vim.keymap.set("x", "<C-e>", function()
      local s = vim.fn.getpos("v")[2]
      local e = vim.fn.getpos(".")[2]
      local l1, l2 = math.min(s, e), math.max(s, e)
      local lines = vim.api.nvim_buf_get_lines(buf, l1 - 1, l2, false)
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
      require("scnvim").send(table.concat(lines, "\n"))
    end, { buffer = buf, desc = "SC: evaluar selección" })

    -- Normal: eval the ( ) block enclosing the cursor (no selection needed)
    vim.keymap.set("n", "<C-e>", function()
      local s, e = sc_block_range()
      if s then
        local lines = vim.api.nvim_buf_get_lines(buf, s - 1, e, false)
        require("scnvim").send(table.concat(lines, "\n"))
      else
        require("scnvim").send(vim.fn.getline(".")) -- fallback: current line
      end
    end, { buffer = buf, desc = "SC: evaluar bloque ()" })
  end,
})
