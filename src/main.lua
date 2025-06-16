--- made by navet

--[[

cb install pkg
cb remove pkg
cb run pkg
cb stop pkg
cb list
cb | cb help

--]]

--- this is the structure of how we package stuff in the repo (after decode)
---@class Package
---@field name string Name of the package
---@field description string Description of the package
---@field url string Url of the package's file
---@field authors string? All of the package's creators
---@field deps {name: string, url: string}[] Array with dependencies (urls)

---@class JSON
---@field encode fun(tab: table): string
---@field decode fun(str: string): table

--- This is how github returns the each package in the repo
---@class RepoPkg
---@field name string
---@field path string
---@field sha string
---@field size integer
---@field url string
---@field html_url string
---@field git_url string
---@field download_url string
---@field type string
---@field _links {self: string, git: string, html: string}

printc(120, 217, 255, 255, "Cheese bread is starting")
printc(255, 171, 226, 255, "This may freeze your game for a few seconds")

local json_link = "https://raw.githubusercontent.com/LuaDist/dkjson/refs/heads/master/dkjson.lua"

---@type JSON?
local json = load(http.Get(json_link))()

if not json then
	return
end

---@type table<string, Package>
local installed_packages = {}

---@type table<string, string>
local running_packages = {}

local ROOT = "Cheese Bread/"
local PACKAGE_PATH = ROOT .. "packages/"
local SCRIPT_PATH = ROOT .. "scripts/"
local REPOS_PATH = ROOT .. "repos/"

--- create dir if we didnt have it already
filesystem.CreateDirectory("Cheese Bread")
filesystem.CreateDirectory("Cheese Bread/packages")
filesystem.CreateDirectory("Cheese Bread/scripts")
filesystem.CreateDirectory("Cheese Bread/repos")

--- these names are hilarious lol

---@param r integer
---@param g integer
---@param b integer
local function CheeseGeneric(r, g, b, ...)
	local msgs = { ... }

	for _, msg in ipairs(msgs) do
		local output = string.format("[Cheese Bread]: %s", tostring(msg))
		printc(r, g, b, 255, output)
	end
end

local function CheeseWarn(...)
	CheeseGeneric(255, 255, 0, ...)
end

local function CheeseError(...)
	CheeseGeneric(255, 0, 0, ...)
end

local function CheesePrint(...)
	CheeseGeneric(255, 255, 255, ...)
end

local function CheeseSuccess(...)
	CheeseGeneric(122, 240, 255, ...)
end

filesystem.EnumerateDirectory(PACKAGE_PATH .. "*.json", function(filename, attributes)
	local name = filename:gsub(".json", "")
	local path = string.format(PACKAGE_PATH .. "%s.json", name)
	local file = io.open(path)
	if file then
		local contents = file:read("a")
		installed_packages[name] = json.decode(contents)
		file:close()
	end
end)

---
--printc(255, 224, 140, 255, "[Cheese Bread] Getting repo packages...")
CheesePrint("Getting repo packages")

local repo_link_rest = "https://api.github.com/repos/uosq/cheese-bread-pkgs/contents/packages"

---@type RepoPkg[]?
local repo_pkgs = {}
local repo_count = 0

local function EnumerateRepoDir()
	repo_count = 0
	filesystem.EnumerateDirectory(REPOS_PATH .. "*.json", function(filename, attributes)
		repo_count = repo_count + 1

		local path = REPOS_PATH .. filename
		local file = io.open(path)

		if file then
			local contents = file:read("a")
			local decoded = json.decode(contents)

			local repo_name = filename:gsub(".json", "")

			--printc(255, 255, 0, 255, "[Cheese Bread] Loading '" .. repo_name .. "' repo")
			CheeseWarn(string.format("Loading repository '%s'", repo_name))

			for _, pkg in ipairs(decoded) do
				-- Sanity check for JSON file name matching the inner name
				local file_name_no_ext = pkg.name:gsub("%.json$", "")

				local pkg_content_raw = http.Get(pkg.download_url)
				local pkg_content = json.decode(pkg_content_raw)
				if pkg_content and pkg_content.name ~= file_name_no_ext then
					CheeseError(
						string.format(
							"Name mismatch: file '%s' has 'name' field '%s'. Skipping this package",
							pkg.name,
							pkg_content and pkg_content.name or "?"
						)
					)
				else
					repo_pkgs[#repo_pkgs + 1] = pkg
				end
			end

			file:close()
		end
	end)
end

EnumerateRepoDir()

if repo_count == 0 then
	local repo_response = http.Get(repo_link_rest)

	if repo_response then
		---@type RepoPkg[]?
		repo_pkgs = json.decode(repo_response)

		local file = io.open("Cheese Bread/repos/standard.json", "w")

		if file then
			file:write(repo_response)
			file:flush()
			file:close()
		end
	else
		CheeseError("Error while fetching 'standard' repo!")
	end
end

CheeseSuccess("Finished loading", "Use command 'cheese' or 'cheese help' to start")
---

--- Returns the raw pkg from the local repo
---@param name string
---@return Package?
local function GetPkgFromRepo(name)
	if not repo_pkgs then
		--printc(255, 0, 0, 255, "[Cheese Bread] The repo packages are empty! WTF")
		CheeseError("The repo packages are empty! WTF??")
		return
	end

	if not installed_packages then
		--printc(255, 0, 0, 255, "[Cheese Bread] installed_packages table is nil! WTF??")
		CheeseError("installed_packages table is nil! WTF??????!?!?!")
		return
	end

	local selected_pkg = nil

	--- this probably wont scale well if we have hundreds or thousands of packages
	--- i wanted this to be async, but http.GetAsync doesn't return the full data
	for i = 1, #repo_pkgs do
		local pkg = repo_pkgs[i]
		if pkg and pkg.name == (name .. ".json") then
			---@type Package?
			local pkg_content = json.decode(http.Get(pkg.download_url))

			if pkg_content then
				selected_pkg = pkg_content
			end

			break
		end
	end

	return selected_pkg
end

---@param pkg Package
local function InstallPkg(pkg)
	if not installed_packages or not repo_pkgs then
		return
	end

	if installed_packages[pkg.name] then
		CheeseWarn(string.format("The package '%s' is already installed!", pkg.name))
		return
	end

	--- package is not installed
	--- so we can install it know
	for i = 1, #repo_pkgs do
		local this = repo_pkgs[i]

		local name = this.name:gsub(".json", "")

		if
			this and pkg.name == name --[[string.find(pkg.name, this.name:gsub(".json", ""))]]
		then
			local path = string.format(PACKAGE_PATH .. "%s.json", this.name:gsub(".json", ""))

			installed_packages[pkg.name] = pkg

			local file = io.open(path, "w")

			if file then
				local pkg_encoded = json.encode(pkg)
				if pkg_encoded then
					file:write(pkg_encoded)
					file:flush()
					file:close()

					filesystem.CreateDirectory(SCRIPT_PATH .. pkg.name)

					local formattedtext = string.format("%s/%s/%s.lua", SCRIPT_PATH, pkg.name, pkg.name)
					local script = io.open(formattedtext, "w")
					if script then
						local script_raw = http.Get(pkg.url)

						script:write(script_raw)
						script:flush()
						script:close()
					end

					--- install dependencies
					if pkg.deps and #pkg.deps > 0 then
						for _, dep in ipairs(pkg.deps) do
							local path = string.format("%s/%s/%s.lua", SCRIPT_PATH, pkg.name, dep.name)
							local file = io.open(path, "w")
							if file then
								file:write(http.Get(dep.url))
								file:flush()
								file:close()
							end
						end
					end

					CheeseSuccess(string.format("The package '%s' has finished installing", pkg.name))
				end
			end

			break
		end
	end
end

---@param pkg Package
local function RemovePkg(pkg)
	local path = PACKAGE_PATH .. pkg.name .. ".json"
	local file = io.open(path)
	if file then
		file:close()

		os.remove(path)

		filesystem.EnumerateDirectory(SCRIPT_PATH .. pkg.name .. "/" .. "*.lua", function(filename, attributes)
			local path = SCRIPT_PATH .. pkg.name .. "/" .. filename
			os.remove(path)
		end)

		os.remove(SCRIPT_PATH .. pkg.name--[[ .. ".lua"]])

		--- unload it in case its loaded
		if running_packages[pkg.name] then
			--- cant assume its SCRIPT_PATH .. pkg.name .. ".lua" as it could be in another folder!
			UnloadScript(running_packages[pkg.name])
		end

		installed_packages[pkg.name] = nil
		CheeseSuccess(string.format("Package '%s' removed", pkg.name))
	else
		installed_packages[pkg.name] = nil --- just in case its still in memory
		CheeseWarn(string.format("Package '%s' not found or already removed", pkg.name))
	end
end

---@param pkg Package
local function RunPkg(pkg)
	if not installed_packages then
		return
	end

	if running_packages[pkg.name] then
		CheeseWarn(string.format("The package '%s' is already running!"))
		return
	end

	local path = SCRIPT_PATH .. pkg.name .. "/" .. pkg.name .. ".lua"
	local script = io.open(path)
	if script then
		running_packages[pkg.name] = path
		LoadScript(path)
		script:close()
		CheeseSuccess(string.format("The package '%s' started", pkg.name))
	else --- script not found
		CheeseWarn(string.format("Package '%s' not found! Try reinstalling it"))
	end
end

---@param pkg Package
local function StopPkg(pkg)
	if running_packages[pkg.name] then
		UnloadScript(running_packages[pkg.name])
		running_packages[pkg.name] = nil
	else
		CheeseWarn(string.format("The package '%s' is already stopped", pkg.name))
	end
end

local function SyncRepo()
	local repo_response = http.Get(repo_link_rest)

	CheesePrint("Fetching repo")
	repo_pkgs = {}

	EnumerateRepoDir()

	filesystem.EnumerateDirectory(SCRIPT_PATH .. "*.lua", function(filename, attributes)
		local pkg = GetPkgFromRepo(filename:gsub(".json", ""))

		if pkg then
			local file = io.open(SCRIPT_PATH .. pkg.name, "w")
			if file then
				file:write(http.Get(pkg.url))
				file:flush()
				file:close()
			end
		end
	end)

	if repo_response then
		---@type RepoPkg[]?
		repo_pkgs = json.decode(repo_response)

		local file = io.open("Cheese Bread/repos/standard.json", "w")

		if file then
			file:write(repo_response)
			file:flush()
			file:close()
			CheeseSuccess("Repo fetched successfully")
		end
	end
end

local function ListInstalledPkgs()
	if not installed_packages then
		return
	end

	local text = "--> %s | %s"

	CheeseGeneric(190, 140, 255, "Installed packages:")

	for _, pkg in pairs(installed_packages) do
		printc(
			175,
			255,
			140,
			255,
			string.format(text, pkg.name, pkg.description),
			"   author(s): " .. (pkg.authors or "?")
		)
	end
end

local function ListRepoPkgs()
	if not repo_pkgs then
		--error()
		CheeseError("repo_pkgs is nil! wtf??")
		return
	end

	if not installed_packages then
		CheeseError("installed_packages is nil! WTF???")
		return
	end

	CheeseGeneric(190, 140, 255, "Available packages:")

	for _, pkg in ipairs(repo_pkgs) do
		local name = string.gsub(pkg.name, ".json", "")
		local installed = false

		local file = io.open(PACKAGE_PATH .. pkg.name, "r")
		if file then
			installed = true
			file:close()
		end

		printc(255, 255, 255, 255, string.format("--> %s %s", name, (installed and "(installed)" or "")))
	end
end

local function ListRunningPkgs()
	CheeseGeneric(190, 140, 255, "Currently running packages:")
	for name in pairs(running_packages) do
		printc(255, 255, 255, 255, string.format("--> %s", name))
	end
end

local function Help()
	printc(161, 255, 186, 255, "Cheese Bread")
	printc(148, 148, 148, 255, "-------------------")
	printc(255, 255, 255, 255, "Available commands:")
	printc(255, 255, 255, 255, "--> cheese install pkg")
	printc(255, 255, 255, 255, "--> cheese remove pkg")
	printc(255, 255, 255, 255, "--> cheese run pkg")
	printc(255, 255, 255, 255, "--> cheese stop pkg")
	printc(255, 255, 255, 255, "--> cheese list repopkgs/localpkgs/runpkgs")
	printc(255, 255, 255, 255, "--> cheese / cheese help (both do the same thing)")
	printc(255, 255, 255, 255, "--> cheese sync")
	printc(255, 255, 255, 255, "--> cheese unload")
	printc(148, 148, 148, 255, "-------------------")
	printc(
		161,
		255,
		186,
		255,
		"'cheese sync' updates the packages and the local repo(s), so use it when a script has updated"
	)
end

---@param str StringCmd
local function RunShell(str)
	local full_text = str:Get()

	--- separate all words
	local words = {}

	for word in string.gmatch(full_text, "%S+") do
		words[#words + 1] = word
	end

	--- check if first word is ours
	if not (words[1] == "cheese") then
		return
	end

	--- make console not give a error
	str:Set("")

	--- its only "cb", which means cb help
	if words[2] == nil or words[2] == "" or words[2] == "help" then
		Help()
	elseif words[2] == "unload" then
		callbacks.Unregister("SendStringCmd", "Cheese Bread Shell")
		return
	elseif words[2] == "list" then
		if words[3] == "repopkgs" then
			ListRepoPkgs()
		elseif words[3] == "localpkgs" then
			ListInstalledPkgs()
		elseif words[3] == "runpkgs" then
			ListRunningPkgs()
		else
			CheeseError("Wrong list! Options available: repopkgs, localpkgs or runpkgs")
			return
		end
	else
		if words[2] == "sync" then
			SyncRepo()
		else
			local pkg_name = table.concat(words, " ", 3)
			local pkg = GetPkgFromRepo(pkg_name)
			if not pkg then
				CheeseError(string.format("The package '%s' was not found!", pkg_name))
				return
			end

			if words[2] == "install" then
				InstallPkg(pkg)
			elseif words[2] == "remove" then
				RemovePkg(pkg)
			elseif words[2] == "run" then
				RunPkg(pkg)
			elseif words[2] == "stop" then
				StopPkg(pkg)
			else
				CheeseWarn("Invalid command!")
			end
		end
	end
end

local function Unload()
	json = nil
	---@diagnostic disable-next-line: cast-local-type
	installed_packages = nil
	repo_pkgs = nil

	for i, pkg in ipairs(running_packages) do
		UnloadScript(pkg)
	end

	---@diagnostic disable-next-line: cast-local-type
	running_packages = nil

	CheeseSuccess("Cheese Bread unloaded successfully")

	collectgarbage("collect")
end

callbacks.Unregister("SendStringCmd", "Cheese Bread Shell")
callbacks.Register("SendStringCmd", "Cheese Bread Shell", RunShell)
callbacks.Register("Unload", Unload)
