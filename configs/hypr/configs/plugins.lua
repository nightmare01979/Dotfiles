-- .config/hypr/hyprland.lua
hl.config({
    plugin = {
        scrolloverview = {
            gesture_distance = 300, -- how far is the "max" for the gesture
            scale = 0.5, -- preferred overview scale
            workspace_gap = 100,
            layout = "vertical", -- vertical or horizontal
            wallpaper = 2, -- 0: global only, 1: per-workspace only, 2: both
            -- blur = true, -- blur only the main overview wallpaper

            shadow = {
                enabled = true,
                range = 50,
            },
        },
    },
})

-- Toggle ScrollOverview with SUPER+g
hl.bind("SUPER + TAB", function()
    hl.plugin.scrolloverview.overview("toggle all")
end)
hl.bind("SUPER + ALT + F", hl.dsp.layout("fit active"))
