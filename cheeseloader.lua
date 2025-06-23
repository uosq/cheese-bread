--- made by navet
--- this is a loader for Cheese Bread

local MAIN_FILE_LINK = "https://raw.githubusercontent.com/uosq/cheese-bread/refs/heads/main/src/main.lua"

local data = http.Get(MAIN_FILE_LINK)
local output = "Cheese Bread/temp/cheese-bread.lua"

if data then
	local file = io.open(output, "w")
	if file then
		file:write(data)
		file:flush()
		file:close()
		LoadScript(output)
	end
end

callbacks.Register("Unload", function()
	UnloadScript(output)
	os.remove("Cheese Bread/temp/cheese-bread.lua")
end)
