local _ERRORH = _ERRORH
local io = io

local M = {}
package.loaded[...] = M
if setfenv and type(setfenv) == "function" then
	setfenv(1,M)	-- Lua 5.1
else
	_ENV = M		-- Lua 5.2
end


function readNonExistantFile()
	_ERRORH.T = "Reading file mrx.txt"
	local f
	local function final()
		if f then f:close() end
	end
	_ERRORH.F = final
	f = io.open("mrx.txt")
	f:read("*a")
	f:close()
end

