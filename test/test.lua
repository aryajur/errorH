-- Test

require("errorH")

print("Going into test")
fr = require("fileReader")
preadNonExistantFile = _ERR.protect(fr.readNonExistantFile)
stat = {preadNonExistantFile()}
if not stat[1] then
	print("Error while doing:".._ERR.T,stat[2])
end
print("end program")