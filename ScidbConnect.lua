--[[
require("ScidbConnect")
sdbcon = ScidbConnect:new{
	host = "https://localhost", 
	port = "49902", 
	username = "scidb", 
	password = "xxxx.xxxx.xxxx"
}

n = 0
afl = "list('instances')"
res = sdbcon:query(afl, n)
sdbcon:dropSession()
sdbcon:dropAuth()
DeepPrint(csv2table(res), "\t")
]]


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
	local sdburl = self.host .. ":" .. self.port
	if self.host ~= nil and self.port ~= nil and self.username ~= nil and self.password ~= nil then
		self.auth = login(sdburl, self.username, self.password)
	else
		print("ERROR: Unable to get authorized")
	end
end


function ScidbConnect:dropAuth()
	local sdburl = self.host .. ":" .. self.port
	if self.auth ~= nil then
		logout(sdburl, self.auth)
	end
	self:dropSession()
	self.auth = nil
end


function ScidbConnect:getSession()
	local sdburl = self.host .. ":" .. self.port
	-- check if authorization is required
	if self.username ~= nil and self.password ~= nil then
		if self.auth == nil then self:getAuth() end
		self.sid = tonumber(newsession(sdburl, self.auth))
	else
		self.sid = tonumber(newsession(sdburl))
	end
	if self.sid == nil then 
		print("ERROR: Unable to get session ID")
	end
end


function ScidbConnect:dropSession()
	local sdburl = self.host .. ":" .. self.port
	if self.auth ~= nil and self.sid ~= nil then
		releasesession(sdburl, self.sid, self.auth)
	elseif self.sid ~= nil then
		releasesession(sdburl, self.sid)	
	end
	self.sid = nil
end


function ScidbConnect:query(afl, n)
	local res = ""
	local sdburl = self.host .. ":" .. self.port
	if self.sid == nil then self:getSession() end
	local query = urlencode(afl)
	if self.auth ~= nil then
		executequery(sdburl, self.sid, query, self.save, self.release, self.stream, self.auth)
		res = readlines(sdburl, self.sid, n, self.auth)
	else
		executequery(sdburl, self.sid, query, self.save, self.release, self.stream)
		res = readlines(sdburl, self.sid, n)
	end
	return res
end


function ScidbConnect:new (o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end
