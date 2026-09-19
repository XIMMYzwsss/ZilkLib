--[[
	ZilkLib Loader — copy loadZilkModule into your script, or load this file once via HttpGet.

	Place ZilkLib/ next to your script in the executor workspace, e.g.:
	  ZilkLib/Library.lua
	  ZilkLib/addons/ThemeManager.lua
	  ZilkLib/addons/SaveManager.lua
	  ZilkLib/addons/BuiltInTabs.lua
]]

local DEFAULT_REPO = 'https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/main/ZilkLib/'

local function normalizeRel(path)
	return (path:gsub('^ZilkLib/', ''))
end

local function loadZilkModule(path, repo)
	repo = repo or DEFAULT_REPO
	if repo:sub(-1) ~= '/' then
		repo = repo .. '/'
	end

	local rel = normalizeRel(path)
	local body

	if typeof(readfile) == 'function' and typeof(isfile) == 'function' then
		for _, candidate in ipairs({ path, 'ZilkLib/' .. rel, rel }) do
			if isfile(candidate) then
				body = readfile(candidate)
				break
			end
		end
	end

	if not body then
		local url = repo .. rel
		body = game:HttpGet(url)
		if type(body) ~= 'string' or #body < 50 then
			error('[ZilkLib] Failed to fetch: ' .. url)
		end
	end

	local chunkName = '@ZilkLib/' .. rel
	local fn, err = loadstring(body, chunkName)
	if not fn then
		error('[ZilkLib] Failed to compile ' .. rel .. ': ' .. tostring(err))
	end

	local ok, result = pcall(fn)
	if not ok then
		error('[ZilkLib] Failed to run ' .. rel .. ': ' .. tostring(result))
	end

	return result
end

local Loader = {
	Repo = DEFAULT_REPO,
	loadZilkModule = loadZilkModule,
}

function Loader.Load(repo)
	repo = repo or DEFAULT_REPO
	return
		loadZilkModule('Library.lua', repo),
		loadZilkModule('addons/ThemeManager.lua', repo),
		loadZilkModule('addons/SaveManager.lua', repo),
		loadZilkModule('addons/BuiltInTabs.lua', repo)
end

return Loader
