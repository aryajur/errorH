-- Error Handler mechanism for Lua
-- Other mechanisms are:
-- http://lua-users.org/wiki/FinalizedExceptions - Here a protect factory wraps the function call in a pcall. 
--				* So protect wraps functions that throw errors to return nil and error message. 
--				* After that the newtry function generates a try function to run the protected function (or a function with respects the nil,message convention). If there is an error (returned nil) then it runs the finalizer function that was sent initially to newtry.

-- Need to know which ones throw error and which ones follow nil,message practice. Also for the ones that return nil,message try function converts them to throw errors. While for the ones that throw error protect function converts them to return nil,message

-- Main motivation is to let Lua itself handle Errors and not add layers. But still have the capacity to run finalizers


-- MECHANISM
-- Provide a global table _ERRORH
-- The key "T" contains a message which says what is going on in the code. So before every new task just like writing comments you write the comment about the task of the next section of the code in this key
-- The key "F" should be initialized to a finalizer function. If T is modified "F" is automatically set to nil
-- Just go about writing code the normal way. For code that follows the nil,message convention there will be some error when the nil returned is used somewhere. For the code that throws errors there is an exception generated. So we endup throwing exceptions the Lua way.
-- You also have the option of converting functions following the nil,message convention to the ones that throw errors using the unprotect function
-- Now at whatever level you want to catch the exceptions that level should protect the function. And now if it generates teh error it should refer to _ERRORH to report which task generated the error and also run its finalizer.

-- ADVANTAGES
-- * Do not have to worry about unknown functions throwing errors without protection. Otherwise adding protections would make the code messy again
-- * Helps merge code documentation with Error Messages
-- * _ERRORH table usage can be expanded easily to log the T messages and hence provide a good logging of the program running as well.

local setmetatable = setmetatable
local up
if not table.unpack then
	up = unpack
else
	up = table.unpack
end
local unpack = up
local type = type
local print = print


_ERR = {}	-- Make a new _ERRORH table
local _ERR = _ERR



local data = {T=""}
local DEBUG

local errorHMeta = {
	__newindex = function(t,k,v)
		if k == "T" then
			data.T = v or ""
			data.F = nil
			if DEBUG then
				DEBUG("DEBUG Message:"..data.T)
			end
		elseif k == "F" then
			data.F = v
		elseif k == "DEBUG" then
			if v and type(v) == "function" then
				DEBUG = v
			elseif v then
				DEBUG = print
			else
				DEBUG = nil
			end
		end
	end,
	
	__index = function(t,k)
		if k == "T" then
			return data.T
		elseif k == "F" then
			return data.F
		else
			return nil
		end
	end	
}

function _ERR.unprotect(f)
    return function(...)
        local stat = {f(...)}
		if stat[1] == nil then
			error(stat[2],0)
		end
		return unpack(stat)
    end
end

function _ERR.protect(f)
	return function(...)
		local stat = {pcall(f, ...)}
		if stat[1] == false then
			return unpack(stat)
		end
		return unpack(stat,2)
	end
end

setmetatable(_ERR,errorHMeta)

