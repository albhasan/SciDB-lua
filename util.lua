function urlencode(str)
	if (str) then
		str = string.gsub (str, "\n", "\r\n")
		str = string.gsub (str, "([^%w ])",
		function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string.gsub (str, " ", "+")
	end
	return str
end

function file_exists(file)
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

function lines_from(file)
	if not file_exists(file) then return {} end
	lines = {}
	for line in io.lines(file) do 
		lines[#lines + 1] = line
	end
	return lines
end


-- remove trailing and leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(8programming)
function trim(s)
  -- from PiL2 20.4
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end


--Print table values
function printTable(t)
	for i, v in ipairs(t) do print(i, v) end
end


-- Taken from http://stackoverflow.com/questions/11886277/lua-iterating-nested-table
function DeepPrint (e)
    -- if e is a table, we should iterate over its elements
    if type(e) == "table" then
        for k,v in pairs(e) do -- for every element in the table
            print(k, "=")
            DeepPrint(v)       -- recursively repeat the same procedure
        end
    else -- if not, we can just print it
        print(e)
    end
end

--#########################################################################
-- CSV parsing
--#########################################################################


-- Taken from http://lua-users.org/wiki/SplitJoin
function split(str, pat)
	local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(t,cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end
	return t
end


-- Taken from http://www.lua.org/pil/20.3.html
function toCSV (t)
	local s = ""
	for _,p in pairs(t) do
		s = s .. "," .. escapeCSV(p)
	end
	return string.sub(s, 2)      -- remove first comma
end


-- Taken from http://www.lua.org/pil/20.3.html
function escapeCSV (s)
	if string.find(s, '[,"]') then
		s = '"' .. string.gsub(s, '"', '""') .. '"'
	end
	return s
end

	
-- Adapted from http://www.lua.org/pil/20.3.html
function fromCSV (s)
	s = s .. ','        -- ending comma
	local t = {}        -- table to collect fields
	local fieldstart = 1
	repeat
		-- next field is quoted? (start with `"'?)
		if string.find(s, "^'", fieldstart) then
			local a, c
			local i  = fieldstart
			repeat
				-- find closing quote
				a, i, c = string.find(s, "'('?)", i+1)
			until c ~= "'"    -- quote not followed by quote?
			if not i then error("unmatched '") end
			local f = string.sub(s, fieldstart+1, i-1)
			table.insert(t, (string.gsub(f, "''", "'")))
			fieldstart = string.find(s, ',', i) + 1
		else                -- unquoted; find next comma
			local nexti = string.find(s, ',', fieldstart)
			table.insert(t, string.sub(s, fieldstart, nexti-1))
			fieldstart = nexti + 1
		end
	until fieldstart > string.len(s)
	return t
end
