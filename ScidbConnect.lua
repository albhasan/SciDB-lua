--[[

require("ScidbConnect")
sdbcon = ScidbConnect:new{
	host = "https://localhost", 
	port = "49902", 
	username = "scidb", 
	password = "xxxx.xxxx.xxxx"
}
sdbcon:getAuth()
sdbcon:getSession()
--afl = "list('functions')"
afl = "scan(winners)"
n = 0
res = sdbcon:query(afl, n)
str = res
print(res)
sdbcon:dropSession()
sdbcon:dropAuth()


t = sdb2table(str)
printTable(t)
DeepPrint(t)




	


]]


--Donde quedaron los indices de las dimensiones????????????????//


require("shimclient")
require("util")


ScidbConnect = {
	host = nil,
	port = nil,
	username = nil,
	password = nil,
	auth = nil,
	sid = nil, 
	release = nil,
	stream = nil,
	save = urlencode("csv+") -- csv+ includes dimensions as part of the CSV
}


function ScidbConnect:getAuth()
	sdburl = self.host .. ":" .. self.port
	if self.host ~= nil and self.port ~= nil and self.username ~= nil and self.password ~= nil then
		self.auth = login(sdburl, self.username, self.password)
	end
	print(self.auth)
end


function ScidbConnect:dropAuth()
	sdburl = self.host .. ":" .. self.port
	if self.auth ~= nil then
		logout(sdburl, auth)
	end
end


function ScidbConnect:getSession()
	sdburl = self.host .. ":" .. self.port
	if self.username ~= nil and self.password ~= nil then
		if self.auth == nil then
			self.getAuth()
		end
		self.sid = tonumber(newsession(sdburl, self.auth))
	else
		self.sid = tonumber(newsession(sdburl))
	end
	print(self.sid)
end


function ScidbConnect:dropSession()
	sdburl = self.host .. ":" .. self.port
	if self.auth ~= nil and self.sid ~= nil then
		releasesession(sdburl, self.sid, self.auth)
	elseif self.sid ~= nil then
		releasesession(sdburl, self.sid)	
	end
end


function ScidbConnect:query(afl, n)
	res = ""
	if self.sid ~= nil then 
		sdburl = self.host .. ":" .. self.port
		query = urlencode(afl)
		if self.auth ~= nil then
			executequery(sdburl, self.sid, query, self.save, self.release, self.stream, self.auth)
			res = readlines(sdburl, self.sid, n, self.auth)
		else
			executequery(sdburl, self.sid, query, self.save, self.release, self.stream)
			res = readlines(sdburl, self.sid, n)
		end
	end
	return res
end


function ScidbConnect:new (o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end


-- Takes a SciDB array (CSV) and returns a lua's table
-- TODO:  Make a difference between dimensions and attributes
function sdb2table(str)
	res = {}
	header = split(trim(str), "\n")[1]
	body = trim(string.sub(str, string.len(header) + 1))
	th = split(header, ",")
	tb = fromCSV(string.gsub(body, "\n", ","))
	row = {}
	for i = 1, #tb, 1 do
		index = (i % #th)
		if(index ~= 0) then
			row[th[index]] = tb[i]
		else
			row[th[#th]] = tb[i]
			table.insert(res, row)
			row = {}
		end
	end
	return res
end