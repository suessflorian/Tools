local fn = vim.fn
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
	PACKER_BOOTSTRAP = fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
end

require("packer").startup(function(use)
	use({ "lervag/vimtex" })
	use({ "lewis6991/impatient.nvim" })
	use({ "wbthomason/packer.nvim" })
	use({ "RRethy/vim-illuminate" })
	use({ "navarasu/onedark.nvim" })
	use({ "akinsho/bufferline.nvim", requires = "kyazdani42/nvim-web-devicons" })
	use({ "lewis6991/gitsigns.nvim", requires = { "nvim-lua/plenary.nvim" } })
	use({ "tpope/vim-commentary" })
	use({ "tpope/vim-surround" })
	use({ "tpope/vim-sleuth" })
	use({ "williamboman/nvim-lsp-installer", requires = { "neovim/nvim-lspconfig" } })
	use({ "ruanyl/vim-gh-line" })
	use({ "kevinhwang91/nvim-ufo", requires = "kevinhwang91/promise-async" })
	use({ "kevinhwang91/nvim-bqf" })
	use({ "romainl/vim-cool" })
	use({ "jiangmiao/auto-pairs" })
	use({ "j-hui/fidget.nvim" })
	use({ "onsails/lspkind-nvim" })
	use({ "nvim-treesitter/nvim-treesitter", requires = { { "p00f/nvim-ts-rainbow" }, { "windwp/nvim-ts-autotag" } } })
	use({ "nvim-telescope/telescope.nvim", requires = { { "nvim-lua/plenary.nvim" }, { "kyazdani42/nvim-web-devicons" } } })
	use({ "L3MON4D3/LuaSnip", requires = { "rafamadriz/friendly-snippets" } })
	use({
		"hrsh7th/nvim-cmp",
		requires = {
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-path" },
			{ "hrsh7th/cmp-cmdline" },
			{ "saadparwaiz1/cmp_luasnip" },
		},
	})
	use({ "kyazdani42/nvim-tree.lua", requires = { "kyazdani42/nvim-web-devicons" } })

	if PACKER_BOOTSTRAP then
		require("packer").sync()
	end
end)
require("impatient") -- https://github.com/lewis6991/impatient.nvim#optimisations

---- TODO:
-- telescope: search through dotfiles
-- add better hover doc rendering, no real support out there atm
-- new window behaviour in Kitty weird

-----------------------------------CORE
local global = vim.g
global.mapleader = " " -- space

local options = vim.opt
-- TABBING
options.tabstop = 2 -- spaces per tab
-- BACKUP
options.backup = false -- disable backup files
options.swapfile = false -- no swap files
options.undofile = true -- persistant file undo"s
-- FOLDING
options.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
options.foldcolumn = "0" -- hide for now, waiting on https://github.com/neovim/neovim/pull/17446
options.foldlevel = 99 -- feel free to decrease the value
options.foldenable = true
-- APPEARANCE BEHAVIOUR
options.cursorline = true
options.completeopt = "menu,menuone,noselect" -- recommended by cmp
options.splitright = true -- vsplits by default to the right
options.wrap = false -- disable text wrapping by default
options.linebreak = true -- if wrapping, don"t break words up mid-wrap
-- MISC
options.clipboard = "unnamedplus" -- sync clipboard and default register
options.laststatus = 3 -- global status line
options.scrolloff = 3 -- always have lines bellow cursor line
options.ignorecase = true -- case insensitive searching UNLESS /C or capital in search
options.smartcase = true
options.jumpoptions = "stack"
options.mouse="a"

-- silent key binding, optionally pass additional options
local bind = function(key, func, opts)
	opts = opts or {}
	opts.noremap, opts.silent = true, true
	vim.keymap.set("n", key, func, opts)
end
-----------------------------------BLING

require("onedark").setup({ transparent = true })
require("onedark").load()
require("nvim-tree").setup({ git = { enable = false } })
require("bufferline").setup()
require("fidget").setup({ window = { blend = 0 } })

-------------------------------------GREPPING
local telescope = require("telescope.builtin")
bind("<leader>p", telescope.find_files)
bind("<leader>b", telescope.buffers)
bind("<leader>F", telescope.live_grep)
bind("<leader>f", telescope.grep_string)

-----------------------------------OTHER MAPPINGS
local bufferline = require("bufferline")
local tree = require("nvim-tree")
bind("<C-j>", function() bufferline.cycle(-1) end)
bind("<C-k>", function() bufferline.cycle(1) end)
bind("-", function() tree.toggle(true) end)

-----------------------------------SYNTAX
local ts = require("nvim-treesitter.configs")
ts.setup({
	ensure_installed = "all",
	ignore_install = { "phpdoc", "latex" },
	highlight = { enable = true },
	rainbow = { enable = true },
	autotag = { enable = true },
	indent = { enable = true },
})

-----------------------------------COMPLETION
local luasnip = require "luasnip"
local cmp = require "cmp"
cmp.setup {
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	mapping = {
		["<C-x><C-u>"] = cmp.mapping.complete(),
		["<C-p>"] = cmp.mapping.select_prev_item(),
		["<C-n>"] = cmp.mapping.select_next_item(),
		["<CR>"] = cmp.mapping.confirm { select = true },
		["<Tab>"] = cmp.mapping.confirm { select = true },
	},
	sources = {
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "path" },
	},
}

cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({ { name = "cmdline" } })
})

-----------------------------------LSC
local lsc = vim.lsp
local illuminate = require("illuminate")
local lsp_installer = require("nvim-lsp-installer")
local capabilities = require("cmp_nvim_lsp").update_capabilities(lsc.protocol.make_client_capabilities())
capabilities.textDocument.foldingRange = {
	dynamicRegistration = false,
	lineFoldingOnly = true
}

lsp_installer.on_server_ready(function(server)
	server:setup({
		on_attach = function(client, bufnr)
			illuminate.on_attach(client)
			local buffer_bind = function(key, func)
				bind(key, func, { buffer = bufnr })
			end
			buffer_bind("<C-n>", vim.diagnostic.goto_next)
			buffer_bind("<C-p>", vim.diagnostic.goto_prev)
			buffer_bind("K", lsc.buf.hover)
			buffer_bind("gf", lsc.buf.formatting)
			buffer_bind("gR", lsc.buf.rename)
			buffer_bind("gd", lsc.buf.declaration)
			buffer_bind("ga", lsc.buf.code_action)

			buffer_bind("<C-]>", telescope.lsp_definitions)
			buffer_bind("gt", telescope.lsp_type_definitions)
			buffer_bind("gi", telescope.lsp_implementations)
			buffer_bind("gr", telescope.lsp_references)
			buffer_bind("gs", telescope.lsp_document_symbols)
		end,
		capabilities = capabilities,
	})
end)
lsc.handlers["textDocument/publishDiagnostics"] = lsc.with(lsc.diagnostic.on_publish_diagnostics,
	{ virtual_text = false })
lsc.handlers["textDocument/hover"] = lsc.with(lsc.handlers.hover, { border = "rounded" })

bind("]n", function() illuminate.next_reference({ wrap = true }) end)
bind("[n", function() illuminate.next_reference({ reverse = true, wrap = true }) end)
require("ufo").setup() -- language server based code folding

-----------------------------------MISC
local gitsigns = require("gitsigns")
gitsigns.setup({
	current_line_blame = true,
	current_line_blame_formatter_opts = { relative_time = true },
	on_attach = function(bufnr)
		local buffer_bind = function(key, func)
			bind(key, func, { buffer = bufnr })
		end
		buffer_bind("]c", gitsigns.next_hunk)
		buffer_bind("[c", gitsigns.prev_hunk)
	end
})
