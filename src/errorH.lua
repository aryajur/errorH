-- Error Handler mechanism for Lua
-- Other mechanisms are:
-- http://lua-users.org/wiki/FinalizedExceptions - Here a protect factory wraps the function call in a pcall. 
--				* So protect wraps functions that throw errors to return nil and error message. 
--				* After that the newtry function generates a try function to run the protected function (or a function with respects the nil,message convention). If there is an error (returned nil) then it runs the finalizer function that was sent initially to newtry.

-- Need to know which ones throw error and which ones follow nil,message practice. Also for the ones that return nil,message try function converts them to throw errors. While for the ones that throw error protect function converts them to return nil,message

-- Main motivation is to let Lua itself handle Errors and not add layers. But still have the capacity to run finalizers

--[[
WHAT ARE ERRORS?
	- Errors are situations where the program is not able to handle the response and would throw the message all the way above it.
]]


-- MECHANISM
-- Provide a global table _ERRORH
-- The key "T" contains a message which says what is going on in the code. So before every new task just like writing comments you write the comment about the task of the next section of the code in this key
-- Just go about writing code the normal way. For code that follows the nil,message convention there will be some error when the nil returned is used somewhere. This does not mean however that for situations where nil is returned and can be handled by the local code should not check for and handle the nil. Because if the code can handle the nil it is not an error. SEE: What are Errors above. errorH module is for handling errors. For the code that throws errors there is an exception generated. So we end up throwing exceptions the Lua way.
-- You also have the option of converting functions following the nil,message convention to the ones that throw errors using the unprotect function
-- Now at whatever level you want to catch the exceptions that level should protect the function. And now if it generates teh error it should refer to _ERR.T to report which task generated the error and also run its finalizer.
-- FINALIZERS
-- errorH gives a mechanism to create finalizers. These finalizers will be run if the error is caught anywhere using pcall or xpcall. Whenever there is an error the error handler defined below will check the code level where the error happenned and if a finalizer is defined there will run it before the stack is unwound. It will do that for all levels in the stack till where the pcall or xpcall was initiated.
-- To define a finalizer just set: _ERR_TryWithFinal = f where f is the finalizer function.
-- To end the scope of the code where the finalizer needs to run either do _ERR_TryWithFinal = nil or do _ERR.EndTryWithFinal()

-- ADVANTAGES
-- * Do not have to worry about unknown functions throwing errors without protection. Otherwise adding protections would make the code messy again
-- * errorH module helps detect those errors without needing to write return with custom message all the way up the hierarchy. It allows adding custom messages when the error source is unknown or can happen anywhere in a code block
-- * Helps merge code documentation with Error Messages
-- * It does not require the code to try out to be in a separate function. It can encompass a few lines of code and create a finalizer for that


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
local oldpcall = pcall
local oldxpcall = xpcall


_ERR = {}	-- Make a new _ERR table as a global table which can be referred anywhere in the code.
local _ERR = _ERR



local data = {T=""}	-- data table to hold the message of what is being done currently in the code.
local DEBUG

local errorHMeta = {
	__newindex = function(t,k,v)
		if k == "T" then
			data.T = v or ""
			if DEBUG then
				DEBUG("DEBUG Message:"..data.T)
			end
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
		elseif k == "DEBUG" then
			return DEBUG
		else
			return nil
		end
	end	
}

-- Error Handler to run all finalizers if any
local function errorHand(err,stLvl)
	--print("In Custom Error handler: ",err,stLvl)
	-- Start from given level or level 2 which is the level one level above this function, which would be the function where the error happened
	local level = stLvl or 2	
	local f = debug.getinfo(level,"f")
	local done,index
	while not done and f do
		--print("FUNCTION: ",debug.getinfo(level,"n").name,f.func)
		-- Check all upvalues to see whether we are at the pcall or xpcall functions defined below since for them data table above is a upvalue
		index = 1
		local n,v = debug.getupvalue(f.func,index)
		--print("Upvalue: ",n)
		while n do
			if n =="data" and v == data then
				--print("Done=true now")
				done = true
				break
			end
			index = index + 1
			n,v = debug.getupvalue(f.func,index)
			--print("Upvalue: ",n)
		end
		if not done then
			-- Check if any finalizer at this level
			index = 1
			n,v = debug.getlocal(level,index)
			--print("Local: ",n)
			while n do
				if n =="_ERR_TryWithFinal" then
					oldpcall(v)	-- Execute the finalizer
					break
				end
				index = index + 1
				n,v = debug.getlocal(level,index)
				--print("Local: ",n)
			end
		end
		level = level + 1
		f = debug.getinfo(level,"f")
	end
	--print("Leaving Custom Error Handler")
	return err
end

-- Redefine pcall to use my error handler
function pcall(f,...)
	local x = data
	return oldxpcall(f,errorHand,...)
end

--print(pcall)

-- Redefine xpcall to also call my error Hander function
function xpcall(f,eH,...)
	local function errHand(err)
		local ret = {oldpcall(eH,err)}
		errorHand(err,3)	-- My Error handler to run all finalizers
		return unpack(ret,2)
	end
	return oldxpcall(f,errHand,...)
end

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

-- Function to remove the finalizer from the local variable so that on any error now the finalizer is not defined
function _ERR.EndTryWithFinal()
	index = 1
	local n,v = debug.getlocal(2,index)
	--print("Local: ",n)
	while n do
		if n =="_ERR_TryWithFinal" then
			debug.setlocal(2,index,nil)
			break
		end
		index = index + 1
		n,v = debug.getlocal(2,index)
		--print("Local: ",n)
	end
end

setmetatable(_ERR,errorHMeta)

