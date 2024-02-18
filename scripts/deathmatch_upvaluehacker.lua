local function GetUpValue(func, varname)
	local i = 1
	local n, v = debug.getupvalue(func, 1)
	while n ~= nil do
		--print("UPVAL GET", varname ,n, v)
		if n == varname then
			return v
		end
		i = i + 1
		n, v = debug.getupvalue(func, i)
	end
end
local function ReplaceUpValue(func, varname, newvalue)
	local i = 1
	local n, v = debug.getupvalue(func, 1)
	while n ~= nil do
		--print("UPVAL REPLACE",varname,n, v)
		if n == varname then
			debug.setupvalue(func, i, newvalue)
			return
		end
		i = i + 1
		n, v = debug.getupvalue(func, i)
	end
end
local function PrintUpValues(func) --debug
	local i = 1
	local n, v = debug.getupvalue(func, 1)
	while n ~= nil do
		print("UPVAL", n, v)
		i = i + 1
		n, v = debug.getupvalue(func, i)
	end
end

return {
	Get = GetUpValue,
	Replace = ReplaceUpValue,
	Print = PrintUpValues
}