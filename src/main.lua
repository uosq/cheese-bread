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
---@field credits string? All of the package's creators

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

local json_link = "https://raw.githubusercontent.com/rxi/json.lua/dbf4b2dd2eb7c23be2773c89eb059dadd6436f94/json.lua"

---@type JSON?
local json = load(http.Get(json_link))()

if not json then
	return
end

--[[
structure of the directory

Cheese Bread:
	packages:
		snowflake.json
		paimbot.json
		...
--]]

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
printc(255, 224, 140, 255, "[Cheese Bread] Getting repo packages...")

local repo_link_rest = "https://api.github.com/repos/uosq/cheese-bread-pkgs/contents/"

---@type RepoPkg[]?
local repo_pkgs = {}
local finished_fetching = false
local repo_count = 0

filesystem.EnumerateDirectory(REPOS_PATH .. "*.json", function(filename, attributes)
	repo_count = repo_count + 1

	local path = REPOS_PATH .. filename

	local file = io.open(path)

	if file then
		local contents = json.decode(file:read("a"))

		local name = filename:gsub(".json", "")

		printc(255, 255, 0, 255, "[Cheese Bread] Loading '" .. name .. "' repo")

		for _, v in ipairs(contents) do
			---@diagnostic disable-next-line: param-type-mismatch
			table.insert(repo_pkgs, v)
		end

		file:close()
	end
end)

if repo_count > 0 then
	finished_fetching = true
end

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

		printc(255, 224, 140, 255, "[Cheese Bread] Success!")
		finished_fetching = true
	else
		printc(255, 0, 0, 255, "[Cheese Bread] Error while fetching the repo!")
	end
end

if finished_fetching then
	printc(100, 255, 100, 255, "[Cheese Bread] Finished loading", "Use command 'cb'")
end

---

--- Returns the raw pkg from the local repo
---@param name string
---@return Package?
local function GetPkgFromRepo(name)
	if not repo_pkgs then
		printc(255, 0, 0, 255, "[Cheese Bread] The repo packages are empty! WTF")
		return
	end

	if not installed_packages then
		printc(255, 0, 0, 255, "[Cheese Bread] installed_packages table is nil! WTF??")
		return
	end

	local selected_pkg = nil

	--- this probably wont scale well if we have hundreds or thousands of packages
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
		printc(255, 224, 140, 255, "[Cheese Bread] Package '" .. pkg.name .. "' is already installed!")
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

					local script = io.open(SCRIPT_PATH .. pkg.name .. ".lua", "w")
					if script then
						local script_raw = http.Get(pkg.url)
						script:write(script_raw)
						script:flush()
						script:close()
					end

					printc(
						255,
						219,
						140,
						255,
						string.format("[Cheese Bread] Package '%s' finished intalling", pkg.name)
					)
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
		os.remove(SCRIPT_PATH .. pkg.name .. ".lua")

		--- unload it in case its loaded
		if running_packages[pkg.name] then
			--- cant assume its SCRIPT_PATH .. pkg.name .. ".lua" as it could be in the temp dir!
			UnloadScript(running_packages[pkg.name])
		end

		installed_packages[pkg.name] = nil
		printc(140, 255, 167, 255, "[Cheese Bread] Package '" .. pkg.name .. "' was removed")
	else
		installed_packages[pkg.name] = nil --- just in case its still in memory
		printc(255, 0, 0, 255, "[Cheese Bread] Package '" .. pkg.name .. "' not found or already removed")
	end
end

---@param pkg Package
local function RunPkg(pkg)
	if not installed_packages then
		return
	end

	if running_packages[pkg.name] then
		return
	end

	local path = SCRIPT_PATH .. pkg.name .. ".lua"
	local script = io.open(path)
	if script then
		running_packages[pkg.name] = path
		LoadScript(path)
		script:close()
	else --- script not found
		printc(255, 0, 0, 255, "Package '" .. pkg.name .. "' not found! Try reinstalling it")
	end
end

---@param pkg Package
local function StopPkg(pkg)
	if running_packages[pkg.name] then
		UnloadScript(running_packages[pkg.name])
		running_packages[pkg.name] = nil
	end
end

local function SyncRepo()
	printc(140, 255, 251, 255, "[Cheese Bread] Fetching repo...")
	repo_pkgs = {}

	filesystem.EnumerateDirectory(REPOS_PATH .. "*.json", function(filename, attributes)
		local path = REPOS_PATH .. filename

		local file = io.open(path)

		if file then
			local contents = json.decode(file:read("a"))

			local name = filename:gsub(".json", "")

			printc(255, 255, 0, 255, "[Cheese Bread] Loading '" .. name .. "' repo")

			for _, v in ipairs(contents) do
				repo_pkgs[#repo_pkgs + 1] = v
			end

			file:close()
		end
	end)

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
end

local function ListInstalledPkgs()
	if not installed_packages then
		return
	end

	local text = "--> %s | %s"

	printc(190, 140, 255, 255, "Installed packages:")

	for _, pkg in pairs(installed_packages) do
		printc(
			175,
			255,
			140,
			255,
			string.format(text, pkg.name, pkg.description),
			"   credits: " .. (pkg.credits or "?")
		)
	end
end

local function ListRepoPkgs()
	if not repo_pkgs then
		error()
	end

	if not installed_packages then
		return
	end

	printc(190, 140, 255, 255, "Available packages:")

	for i = 1, #repo_pkgs do
		local pkg = repo_pkgs[i]
		if pkg then
			local name = string.gsub(pkg.name, ".json", "")
			local installed = false

			local file = io.open(PACKAGE_PATH .. pkg.name, "r")
			if file then
				installed = true
				file:close()
			end

			printc(255, 255, 255, 255, "--> " .. name .. (installed and " (installed)" or ""))
		end
	end
end

local function ListRunningPkgs()
	printc(190, 140, 255, 255, "Currently running packages:")
	for name in pairs(running_packages) do
		printc(255, 255, 255, 255, "--> " .. name)
	end
end

local function Help()
	printc(161, 255, 186, 255, "Cheese Bread")
	printc(148, 148, 148, 255, "-------------------")
	printc(255, 255, 255, 255, "Available commands:")
	printc(255, 255, 255, 255, "--> cb install pkg")
	printc(255, 255, 255, 255, "--> cb remove pkg")
	printc(255, 255, 255, 255, "--> cb run pkg")
	printc(255, 255, 255, 255, "--> cb stop pkg")
	printc(255, 255, 255, 255, "--> cb list repopkgs/localpkgs/runpkgs")
	printc(255, 255, 255, 255, "--> cb / cb help (both are the same thing)")
	printc(255, 255, 255, 255, "--> cb sync")
	printc(148, 148, 148, 255, "-------------------")
	printc(
		161,
		255,
		186,
		255,
		"'cb sync' updates the packages and the local repo(s), so use it when a script has updated"
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
	if not (words[1] == "cb") then
		return
	end

	--- make console not give a error
	str:Set("")

	--- its only "cb", which means cb help
	if words[2] == nil or words[2] == "" or words[2] == "help" then
		Help()
	elseif words[2] == "list" then
		if words[3] == "repopkgs" then
			ListRepoPkgs()
		elseif words[3] == "localpkgs" then
			ListInstalledPkgs()
		elseif words[3] == "runpkgs" then
			ListRunningPkgs()
		else
			printc(255, 0, 0, 255, "[Cheese Bread] Wrong list! Options: repopkgs, localpkgs or runpkgs")
			return
		end
	else
		if words[2] == "sync" then
			SyncRepo()
		else
			local pkg = GetPkgFromRepo(table.concat(words, " ", 3))
			if not pkg then
				printc(255, 0, 0, 255, string.format("[Cheese Bread] The package '%s' was not found!", words[3]))
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
			end
		end
	end
end

local function Unload()
	json = nil
	---@diagnostic disable-next-line: cast-local-type
	installed_packages = nil
	repo_pkgs = nil

	collectgarbage("collect")
end

callbacks.Register("SendStringCmd", "Cheese Bread Shell", RunShell)
callbacks.Register("Unload", Unload)
