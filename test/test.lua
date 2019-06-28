-- Test

require("errorH")

print("Going into test")
fr = require("fileReader")
stat = {pcall(fr.readNonExistantFile)}
if not stat[1] then
	print("Error while ".._ERRORH.T,stat[2])
	print("running finalizer")
	_ERRORH.F()
end
print("end program")