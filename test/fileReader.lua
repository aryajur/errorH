local _ERR = _ERR
local io = io

local M = {}
package.loaded[...] = M
if setfenv and type(setfenv) == "function" then
	setfenv(1,M)	-- Lua 5.1
else
	_ENV = M		-- Lua 5.2
end


function readNonExistantFile()
	_ERR.T = "Reading file mrx.txt"
	local f
	local _ERR_TryWithFinal = function()	-- Finalizer FUnction
		print("running finalizer")
		if f then f:close() end
	end
	f = io.open("mrx.txt")
	f:read("*a")
	f:close()
end

