require("errorH")

upVal = "upVal"

function f1()
	local f1l = "f1l"
	local _ERR_TryWithFinal = function()
		print("Finalizer for f1",f1l,upVal)
	end
	print("Happily inside f1")
	error("ERROR INSIDE f1")
	_ERR.EndTryWithFinal()	
end

function f2()
	print("Starting f2")
	local f2l = "f2l"
	local _ERR_TryWithFinal = function()
		print("Finalizer for f2",f2l,upVal)
	end
	print("Happily inside f2")
	f1()	
	_ERR.EndTryWithFinal()
	
end

function f3()
	print("Happily inside f3")
	local stat,msg = pcall(f2)
	print("f2 call finished in f3")
	if not stat then
		print("ERROR in f2 call: "..msg)
	end
	error("ERROR in f3 call")
end

function f4()
	local f4l = "f4l"
	local _ERR_TryWithFinal = function()
		print("Finalizer for f4",f4l,upVal)
	end
		print("Happily Inside f4")
	_ERR.EndTryWithFinal()
	f3()	
end

function f5()
	local f5l = "f5l"
	local _ERR_TryWithFinal = function()
		print("Finalizer for f5",f5l,upVal)
	end
	print("Happily Inside f5")
	f4()	
	_ERR.EndTryWithFinal()
end

print(xpcall(f5,function(err) print("given error handler") return err end))

print("----------------------------------------------")
	
print(xpcall(f5,function(err) error("Error in given error handler") return err end))
