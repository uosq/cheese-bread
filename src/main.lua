--- made by navet

--[[

cb install pkg
cb remove pkg
cb run pkg
cb stop pkg
cb list
cb | cb help


printc(255, 255, 255, 255, "cb install pkg")
printc(255, 255, 255, 255, "cb remove pkg")
printc(255, 255, 255, 255, "cb run pkg")
printc(255, 255, 255, 255, "cb stop pkg")
printc(255, 255, 255, 255, "cb list")
printc(255, 255, 255, 255, "cb | cb help")
--]]

---@class Package
---@field name string Name of the package
---@field description string Description of the package
---@field url string Url of the package's file
---@field continuous boolean If the package has callbacks

---@class JSON
---@field encode fun(tab: table): string
---@field decode fun(str: string): table

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

---@type Package[]?
local installed_packages = {}

local json_link = "https://raw.githubusercontent.com/rxi/json.lua/dbf4b2dd2eb7c23be2773c89eb059dadd6436f94/json.lua"

---@type JSON?
local json = load(http.Get(json_link))()

if not json then
	return
end

---
printc(255, 224, 140, 255, "[Cheese Bread] Getting repo packages...")
local repo_link_rest = "https://api.github.com/repos/uosq/cheese-bread-pkgs/contents/"

---@type RepoPkg[]?
local repo_pkgs = {}

local repo_response = http.Get(repo_link_rest)

if repo_response then
	---@type RepoPkg[]?
	repo_pkgs = json.decode(repo_response)
end
---

---@param name string
---@return Package?
local function GetPkgFromRepo(name)
	if not repo_pkgs then
		printc(255, 0, 0, 255, "The repo packages are empty!")
		return
	end

	local selected_pkg = nil

	for i = 1, #repo_pkgs do
		local pkg = repo_pkgs[i]
		if not pkg then
			return
		end

		if pkg.name == name then
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
local function InstallPkg(pkg) end

---@param pkg Package
local function RemovePkg(pkg) end

---@param pkg Package
local function RunPkg(pkg) end

---@param pkg Package
local function StopPkg(pkg) end

local function ListInstalledPkgs() end

local function Help()
	printc(161, 255, 186, 255, "Cheese Bread")
	printc(148, 148, 148, 255, "------------")
	printc(255, 255, 255, 255, "cb install pkg")
	printc(255, 255, 255, 255, "cb remove pkg")
	printc(255, 255, 255, 255, "cb run pkg")
	printc(255, 255, 255, 255, "cb stop pkg")
	printc(255, 255, 255, 255, "cb list")
	printc(255, 255, 255, 255, "cb")
	printc(255, 255, 255, 255, "cb help")
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
		ListInstalledPkgs()
	else
		local pkg = GetPkgFromRepo(words[3])
		if not pkg then
			printc(255, 0, 0, 255, string.format("The package %s was not found!", words[3]))
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

local function Unload()
	json = nil
	installed_packages = nil
	repo_pkgs = nil
end

callbacks.Register("SendStringCmd", "Cheese Bread Shell", RunShell)
