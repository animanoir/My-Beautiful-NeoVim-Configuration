--------------------------------------------------------------------------------
-- 1. General options
--------------------------------------------------------------------------------

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = false
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.wrap = false
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
opt.guicursor = {
  "n-v-c:block-Cursor/lCursor-blinkwait100-blinkon200-blinkoff150",
  "i-ci-ve:ver25-Cursor/lCursor-blinkwait300-blinkon200-blinkoff150",
  "r-cr:hor20-Cursor/lCursor-blinkwait300-blinkon200-blinkoff150",
  "o:hor50-Cursor/lCursor",
}

-- Vim API
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.api.nvim_set_hl(0, "TermNormal", { bg = "#000000" })
    vim.opt_local.winhighlight = "Normal:TermNormal,NormalNC:TermNormal"
  end,
})

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
  -- Neo-Tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, but recommended
      keys = { { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorador" } },
    },
    lazy = false, -- neo-tree will lazily load itself
  },
  -- Theme
  {
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("moonfly")
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000
    -- config = function()
    -- require("catppuccin").setup({ flavour = "mocha" })
    --vim.cmd.colorscheme("catppuccin")
    -- end,
  },

  -- Treesitter: syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        "racket", "haskell", "lua",
        "markdown", "markdown_inline",
        "gdscript", "godot_resource", "gdshader",
        "javascript", "typescript", "tsx",
        "html", "css", "json", "clojure",
      })
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },

  -- LSP
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
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
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end
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
      -- Haskell
      vim.lsp.config("hls", {
        capabilities = capabilities,
        settings = {
          haskell = {
            formattingProvider = "ormolu",
            checkProject = true,
          },
        },
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
      })

      -- Keymaps LSP
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Ir a definición")
          map("gr", vim.lsp.buf.references, "Ver referencias")
          map("K", vim.lsp.buf.hover, "Documentación hover")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>rn", vim.lsp.buf.rename, "Renombrar símbolo")
          map("<leader>d", vim.diagnostic.open_float, "Ver diagnóstico")
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
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { defaults = { preview = { treesitter = false } } },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Buscar archivos" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Grep en proyecto" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Buffers abiertos" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "Buscar en ayuda" },
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
        theme = "auto",
      },
    },
  },
  -- My own plugins:
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
          haskell = { "ormolu" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
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
