--[[
This file includes all the patches that allow MultiUI functionality to affect the DefaultUI.
This functionality is disabled at first, but can be enabled by editing config.ini or from the MultiUI settings menu.
]]--

lib.log_error("Patching DefaultUI")

--remove this once panels support is working!!!
lib.require({{name = "neomgr", version = "0"}}, function()
	lib.execute("neomgr", "0", "add_option", iup.button {
		title = "MultiUI",
		action = function()
			lib.execute("MultiUI", "0", "open")
		end,
	})
end)

local options_input = iup.vbox { }
local options_container = iup.vbox {}
local options_input_dialog = iup.dialog {
	topmost = "YES",
	fullscreen = "YES",
	show_cb = function(self)
		iup.Append(options_container, options_input)
		iup.Refresh(options_input)
	end,
	hide_cb = function(self)
		OptionsDialog:show()
	end,
	close_cb = function(self) --I can never remember which its supposed to be
		OptionsDialog:show()
	end,
	iup.vbox {
		iup.hbox {
			iup.label {
				title = "Custom Options",
			},
			iup.fill { },
			iup.stationbutton {
				title = "X",
				action = function(self)
					Iup.GetDialog(self):hide()
				end,
			},
		},
		iup.fill {
			size = "%2",
		},
		options_container
	},
}
options_input_dialog:map()

lib.execute("MultiUI", "0", "create_redirect", "options", options_input)

local access_button = iup.button {
	cx = 200,
	cy = 200,
	title = "Custom Options",
	action = function()
		options_input_dialog:show()
	end,
}
access_button:map()
local button_width = tonumber(access_button.size:match("(%d+)x"))
access_button.cx = (gkinterface.GetXResolution()/2) - (button_width/2)
access_button.cy = (gkinterface.GetYResolution()/2)
iup.Refresh(access_button)

iup.Append(OptionsDialog[1][1], access_button)