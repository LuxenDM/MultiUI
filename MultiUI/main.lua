if type(lib) == "table" and type(lib[1]) == "string" then --makes sure a Neoloader-like environment is set up.
	--if your plugin expects a certain API of neoloader, check that here!
	if not lib.is_exist("MultiUI") then --check if your plugin already exists in the registry
		lib.register("plugins/MultiUI/registration.ini") --register the missing plugin
	end
	
	if lib.is_ready("MultiUI") then
		--do any post-setup work here
	end
else
	print("\127FF7777MultiUI requires the Neoloader or compatible environment to run.\127FFFFFF")
end