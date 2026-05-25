require("monitors")
require("autostart")
require("binds")
require("env")
require("permissions")
require("animations")
require("decorations")
require("layout")
require("misc")
require("input")
require("windowrule")

-- Obsidian sidebar scratchpad
hl.window_rule({
    match    = { class = "obsidian" },
    workspace = "special:obsidian silent",
    float    = true,
    size     = "600 1023",
    move     = "1307 43",
})

local mainMod = "SUPER"

-- Toggle Obsidian sidebar with Super+N
hl.bind(mainMod .. " + N", hl.dsp.workspace.toggle_special("obsidian"))

hl.config({
    animations = {
        { name = "specialWorkspace", 
	  enable = true, speed = 5, 
	  curve = "default", 
	  style = "slide" 
  	}
    }
})
