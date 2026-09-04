hl.monitor({
    output   = "DP-1",
    mode     = "1920x1080@60",
    position = "1280x1",
    scale    = "auto",
})
hl.monitor({
    output   = "DVI-I-1",
    mode     = "1280x1024@60",
    position = "0x1",
    scale    = "1",
})

-- Persistent Workspaces
hl.workspace_rule({ workspace = "1", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-1", persistent = true })
