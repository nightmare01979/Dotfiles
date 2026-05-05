vim.opt.termguicolors = true
vim.opt.number = true            

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

    {
        "sphamba/smear-cursor.nvim",
        opts = {
            smear_between_buffers = true,
            smear_between_windows = true,
            min_horizontal_distance_smear = 1,
            min_vertical_distance_smear = 1,
            scroll_buffer_space = true,
            legacy_computing_symbols_support = false,
            smear_insert_mode = true,
        },
        config = function(_, opts)
            require("smear_cursor").setup(opts)
        end
    },
    {
    	"catgoose/nvim-colorizer.lua",
	event = "BufReadPre",
	 config = function()
    require("colorizer").setup()
    end,
    },
})

 vim.cmd.colorscheme("wal")
vim.api.nvim_set_hl(0, "Normal", {})  

