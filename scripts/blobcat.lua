#!/usr/bin/env lua

if #arg < 2 then
	print("\n" .. arg[0] .. " size blob(s)...\n")
	print("", "size:", "", "The total size of the output blob in bytes. Any space not taken by the input blobs will become zeros.")
	print("", "blob:", "", "All the binary blobs to be concatinated directly after one another.")
	print("\nThe output binary blob will be sent to stdout and can be piped into other programs.\n")

	os.exit(1)
end

C=tonumber(arg[1])

if C == 0 then C = nil end

for i=2, #arg do
	local f, e = io.open(arg[i], "rb")
	if e then print("", e) os.exit(-1) end
	repeat d = f:read() if d then io.write(d) if C then C=C-#d end end until not d
	f:close()
end

if C then
	if C < 0 then
		print("", "Warning: concatinated blobs are greater than expected output by " .. -C .. " bytes.") os.exit(-2)
	else
		io.write(string.rep("\0", C))
	end
end




