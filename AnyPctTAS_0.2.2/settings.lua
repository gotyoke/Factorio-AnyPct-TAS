data:extend({{
        type = "bool-setting",
        name = "tas-console-debug",
        setting_type = "runtime-global",
        default_value = false
    }, {
        type = "string-setting",
        name = "tas-gui-debug",
        setting_type = "runtime-global",
        default_value = "disabled",
        allowed_values = {"open", "close", "disabled"}
    }, {
        type = "int-setting",
        name = "tas-target-task",
        setting_type = "runtime-global",
        default_value = 0
    }, {
        type = "double-setting",
        name = "tas-max-speed",
        setting_type = "runtime-global",
        default_value = 1000.0
    }, {
        type = "double-setting",
        name = "tas-default-speed",
        setting_type = "runtime-global",
        default_value = 1.0
    }
})
