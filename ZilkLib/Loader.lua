--[[
	ZilkLib Loader — required entry point.
	Library and addons cannot be loaded from local files (readfile, etc).
]]

local DEFAULT_REPO = 'https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/main/ZilkLib/'

local Loader = {}
Loader.Repo = DEFAULT_REPO

function Loader.Load(repo)
	repo = repo or DEFAULT_REPO
	if type(repo) ~= 'string' or not repo:find('^https://raw%.githubusercontent%.com/.+/ZilkLib/', 1) then
		error('[ZilkLib] Invalid repo URL. Must be a raw GitHub ZilkLib path.')
	end
	if repo:sub(-1) ~= '/' then
		repo = repo .. '/'
	end

	local function loadModule(path)
		local url = repo .. path
		local body = game:HttpGet(url)
		if type(body) ~= 'string' or #body < 50 then
			error('[ZilkLib] Failed to fetch from GitHub: ' .. url)
		end

		getgenv().__ZILK_GITHUB_LOAD = {
			repo = repo,
			path = path,
			deadline = tick() + 3,
		}

		local fn, err = loadstring(body, '@' .. url)
		if not fn then
			getgenv().__ZILK_GITHUB_LOAD = nil
			error('[ZilkLib] Failed to compile ' .. path .. ': ' .. tostring(err))
		end

		local ok, result = pcall(fn)
		getgenv().__ZILK_GITHUB_LOAD = nil
		if not ok then
			error('[ZilkLib] Failed to run ' .. path .. ': ' .. tostring(result))
		end

		return result
	end

	local Library = loadModule('Library.lua')
	local ThemeManager = loadModule('addons/ThemeManager.lua')
	local SaveManager = loadModule('addons/SaveManager.lua')
	local BuiltInTabs = loadModule('addons/BuiltInTabs.lua')

	return Library, ThemeManager, SaveManager, BuiltInTabs
end

return Loader
