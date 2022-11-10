local MultiUI = {
	version = "Alpha 6.0",
	IF = true,
	current_interface = {
		--replace with overridable
		name = gkini.ReadString("MultiUI", "current_if", "DefaultUI"),
		path = gkini.ReadString("MultiUI", "current_path", "vo/if.lua"),
	},
	patch = gkini.ReadString("MultiUI", "patch_default", "NO"),
}

local dump_table
function dump_table(tab)
	for k, v in pairs(tab) do
		lib.log_error(tostring(k) .. ": ")
		if type(v) == "table" then
			lib.log_error("{")
			dump_table(v)
			lib.log_error("}")
		else
			lib.log_error(tostring(v))
		end
	end
end

lib.log_error("MultiUI " .. MultiUI.version .. " is starting...")

local if_registry = {} --list of IFs to load
local append_tags = {} --list of reference tags for append-redirects

local function IsIUP(e) return pcall(iup.GetType, e) end

function MultiUI.create_redirect(new_tag, iup_parent)
	if type(new_tag) ~= "string" then
		new_tag = "ORPHANED"
	end
	if type(iup_parent) ~= "string" or IsIUP(iup_parent) then
		return false
	end
	
	lib.log_error("MultiUI: Creating new redirect from " .. "<>" .. " to " .. new_tag)
	
	if not append_tags[new_tag] then
		append_tags[new_tag] = {}
	end
	table.insert(append_tags[new_tag], iup_parent)
end

function MultiUI.append(obj, tag)
	if type(tag) ~= "string" then
		tag = "ORPHANED"
	end
	if type(obj) == "function" then
		--this is a constructor
		for k, v in ipairs(append_tags[tag]) do
			iup.Append(v, obj())
		end
	elseif type(obj) == "userdata" and IsIUP(obj) then
		--this is a singular element; since we cannot clone iup elements, it is only added to the first entry (usually the UI?)
		if append_tags[tag][1] then
			iup.Append(append_tags[tag][1])
		end
	end
end

function MultiUI.register_interface (iftable)
	--[[ Adds a new interface that can be selected from
	{
		name = name of interface
		path = path to interface execution
	}
	]]--
	local error = false
	if type(iftable) ~= "table" then
		error = true
		lib.log_error("MultiUI:interface registration:invalid type, recieved a " .. type(iftable))
	end
	if type(iftable.name) ~= "string" then
		error = true
	end
	if type(iftable.path) ~= "string" then
		iftable.path = "vo/if.lua"
	end
	
	table.insert(if_registry, iftable)
	lib.log_error("MultiUI: registered " .. iftable.name .. " as a new interface!")
end

MultiUI.register_interface {
	name = "DefaultUI",
	path = "vo/if.lua",
}

function MultiUI.get_interface()
	return MultiUI.current_interface.name
end



function MultiUI.open()
	
	local function create_settings_editor()
		
		local patch_default_ui = iup.stationtoggle {
			title = " :Apply Patch",
			value = MultiUI.patch,
			action = function(self)
				if self.value == "ON" then
					MultiUI.patch = "YES"
				else
					MultiUI.patch = "NO"
				end
			end,
		}
		if MultiUI.patch == "YES" then
			patch_default_ui.value = "ON"
		else
			patch_default_ui.value = "OFF"
		end
		
		local ui_list = iup.stationsublist {
			expand = "HORIZONTAL",
			size = HUDSize(0.2, 0.3),
			action = function(self, text, index, click)
				if click == 1 then
					MultiUI.current_interface = if_registry[index]
					if text == "DefaultUI" then
						patch_default_ui.active = "YES"
					else
						patch_default_ui.active = "NO"
					end
				end
			end,
		}
		
		for k, v in ipairs(if_registry) do
			ui_list[k] = v.name
		end
		
		local save_changes_button = iup.button {
			title = "Save changes",
			action = function(self)
				gkini.WriteString("MultiUI", "current_if", MultiUI.current_interface.name)
				gkini.WriteString("MultiUI", "current_path", MultiUI.current_interface.path)
				gkini.WriteString("MultiUI", "patch_default", MultiUI.patch)
				iup.Destroy(iup.GetDialog(self))
				ReloadInterface()
			end,
		}
		
		local settings_root_panel = iup.vbox {
			iup.hbox {
				iup.label {
					title = "Select the interface you would like to use:  ",
				},
				iup.fill { },
				ui_list,
			},
			iup.fill {
				size = "%2",
			},
			iup.hbox {
				iup.label {
					title = "(For DefaultUI only) patch the defaultUI to include spaces for MultiUI Panels?",
				},
				iup.fill { },
				patch_default_ui,
			},
			iup.fill {
				size = "%10",
			},
			save_changes_button,
		}
		
		return settings_root_panel
	end
	
	local bg_panel = iup.vbox {
		iup.label {
			title = "",
			size = HUDSize(1, 1),
			image = gkini.ReadString("MultiUI", "bgimage", "plugins/MultiUI/bg_panel.png"),
		},
	}
	
	local diag_view = iup.zbox {
		expand = "YES",
		all = "YES",
		[1] = bg_panel,
		[2] = create_settings_editor(),
	}
	
	local diag = iup.dialog {
		fullscreen = "YES",
		topmost = "YES",
		iup.vbox {
			iup.hbox {
				iup.label {
					title = MultiUI.version,
				},
				iup.fill { },
				iup.button {
					title = "X",
					action = function(self)
						iup.Destroy(iup.GetDialog(self))
					end,
				},
			},
			iup.hbox {
				iup.stationsubframe {
					iup.hbox {
						iup.fill { },
						iup.label {
							title = " ",
						},
						iup.fill { },
					},
				},
			},
			diag_view,
		},
	}
	
	diag:map()
	diag:show()
	
end

--[[
MultiUI's init phase:

lib.resolve_file the path of the current IF

if it fails, change to defaultUI and launch that instead
]]--

if lib.get_gstate().ifmgr == "MultiUI" then
	lib.log_error("Attempting to load your current interface: " .. MultiUI.current_interface.name)

	local status, etc = lib.resolve_file(MultiUI.current_interface.path)
	if status then
		lib.log_error("Interface launched successfully")
		if MultiUI.current_interface.name == "DefaultUI" then
			if gkini.ReadString("MultiUI", "patch_default", "NO") == "YES" then
				lib.log_error("patching the default interface...")
				lib.resolve_file("plugins/MultiUI/DefaultUI patch.lua")
			end
		end
	else
		--fail
		lib.log_error("MultiUI failed to launch your custom interface; the DefaultUI has been selected")
		MultiUI.current_interface.name = "DefaultUI"
		MultiUI.current_interface.path = "vo/if.lua"
		dofile("vo/if.lua")
	end
else
	lib.log_error("MultiUI is not set as the current interface management system by Neoloader; not launching interface...")
	lib.log_error("Current setting is: " .. lib.get_gstate().ifmgr)
end

RegisterUserCommand("MultiUI", MultiUI.open)

lib.set_class("MultiUI", 6, MultiUI)