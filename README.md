# Lua Error Handling
Lua provides basic error handling and catching mechanisms using pcall, xpcall and error functions.   
There is no try-catch-finally mechanism directly but there have been proposed methods to do the same things:  
 
 
http://lua-users.org/wiki/FinalizedExceptions - Here a protect factory wraps the function call in a pcall. 
* So protect wraps functions that throw errors to return nil and error message. 
* After that the newtry function generates a try function to run the protected function (or a function with respects the nil,message convention). If there is an error (returned nil) then it runs the finalizer function that was sent initially to newtry.

Here however we need to know which ones throw error and which ones follow nil,message practice. Also for the ones that return nil,message try function converts them to throw errors. While for the ones that throw error protect function converts them to return nil,message

# Motivation
The main motivation is to let Lua itself handle Errors and not add layers of function calls and also still have the capacity to run finalizers.   
With this implementation there are some other perks that come with it like code commenting mechanism that also helps produce more meaningful customized error messages.


# What are errors
Errors are situations where the program is not able to handle the response and would throw the message all the way above it.



# Mechanism and usage
The module provides a global table ***_ERR***
The key ***T*** in this table contains a message which says what is going on in the code. So before every new task just like writing comments you write the comment about the task of the next section of the code in this key.   

For example:

	require("errorH")
	_ERR.T = "Run loop to count from 1 to 10"
	for i = 1,10 do
		print(i)
	end

Just go about writing code the normal way. For code that follows the nil,message convention there will be some error when the nil returned is used somewhere.  
This does not mean however that for situations where nil is returned and can be handled by the local code should not check for and handle the nil.   
Because if the code can handle the nil it is not an error. SEE: [What are errors](#what-are-errors) above. errorH module is for handling errors.   
For the code that throws errors there is an exception generated. So we end up throwing exceptions the Lua way.

## Unprotect functions
You also have the option of converting functions following the nil,message convention to the ones that throw errors using the ***unprotect*** function:

	require("errorH")
	function trimString(arg1)
		if type(arg1) ~= "string" then
			return nil,"Argument not a string"
		end
		return arg1:gsub("^%s*","")
	end
	utrimString = _ERR.unprotect(trimString)


## Protect functions
Functions that throw an error can be protected to return nil on error using the ***protect*** function:

	require("errorH")
	function trimString(arg1)
		if type(arg1) ~= "string" then
			error("Argument not a string")
		end
		return arg1:gsub("^%s*","")
	end
	utrimString = _ERR.protect(trimString)

	
## Example
Now at whatever level you want to catch the exceptions that level should protect the function. And now if it generates the error it should refer to ***_ERR.T*** to report which task generated the error and also run its finalizer.

	require("errorH")

	function readNonExistantFile()
		_ERR.T = "Reading file mrx.txt"
		local f
		f = io.open("mrx.txt")
		f:read("*a")
		f:close()
	end
	preadNonExistantFile = _ERR.protect(preadNonExistantFile)
	print("Start test")
	stat = {preadNonExistantFile()}
	if not stat[1] then
		print("Error while doing:".._ERR.T,stat[2])
	end
	print("end program")

# FINALIZERS
***errorH*** gives a mechanism to create finalizers. These finalizers will be run if the error is caught anywhere using pcall or xpcall. Whenever there is an error the error handler will check the code level where the error happenned and if a finalizer is defined there will run it before the stack is unwound. It will do that for all levels in the stack till where the pcall or xpcall was initiated.
 To define a finalizer just set: ***_ERR_TryWithFinal*** = f where f is the finalizer function.
 To end the scope of the code where the finalizer needs to run either do ***_ERR_TryWithFinal*** = nil or do ***_ERR.EndTryWithFinal()***
 
 ## Example
 
 	require("errorH")

	function readNonExistantFile()
		_ERR.T = "Reading file mrx.txt"
		local f
		local _ERR_TryWithFinal = function()	-- Finalizer Function
			print("running finalizer")
			if f then f:close() end
		end
		f = io.open("mrx.txt")
		f:read("*a")
		f:close()
	end
	preadNonExistantFile = _ERR.protect(preadNonExistantFile)
	print("Start test")
	stat = {preadNonExistantFile()}
	if not stat[1] then
		print("Error while doing:".._ERR.T,stat[2])
	end
	print("end program")

# Extensions
If ***_ERR.DEBUG*** is set to a function then that function is called whenever ***_ERR.T*** is set to a new value. The argument given to the function is the value assigned to ***_ERR.T***.
This allows ways to extend the functionality by adding a function. So the messages may be stacked, logged or parsed for creating certain actions.

# Advantages
* Do not have to worry about unknown functions throwing errors without protection. Otherwise adding protections would make the code messy again
* errorH module helps detect those errors without needing to write return with custom message all the way up the hierarchy. It allows adding custom messages when the error source is unknown or can happen anywhere in a code block
* Helps relate the error message with the code documentation
* It does not require the code to try out to be in a separate function. It can encompass a few lines of code and create a finalizer for that
