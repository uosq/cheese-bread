--- made by navet
--- this is a loader for Cheese Bread

local MAIN_FILE_LINK = "https://raw.githubusercontent.com/uosq/cheese-bread/refs/heads/main/src/main.lua"

local data = http.Get(MAIN_FILE_LINK)

if data then
	local script = load(data)
	if script then
		script()
	end
end
