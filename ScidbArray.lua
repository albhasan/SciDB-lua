--[[
require("ScidbArray")
sdbcon = ScidbConnect:new{
	host = "https://localhost", 
	port = "49902", 
	username = "scidb", 
	password = "xxxx.xxxx.xxxx"
}
sdba = ScidbArray:new{
	name = "TEST_ARRAY",
	sdbcon = sdbcon
}
--sdba.name = "winners"
sdba:getData()
DeepPrint(sdba)
]]


require ("ScidbConnect")

ScidbArray = {
	name = nil,
	dimmensions = nil,
	attributes = nil,
	data = nil,
	sdbcon = nil
}

function ScidbArray:getSchema()
	if self.sdbcon ~= nil and self.name ~= nil then 
		local n = 0
		local afl = "show(" .. self.name .. ")"
		local strsc = csv2table(sdbcon:query(afl, n))[1]["schema"]

		self.name = string.sub(strsc, 1, string.find(strsc, "<") - 1)
		
		-- <person:string,time:double>
		local stratt = string.sub(strsc, string.find(strsc, "<") + 1, string.find(strsc, ">") - 1)
		self.attributes = {}
		for k1, v1 in ipairs(split(stratt, ",")) do
			local att = {}
			local tmp = split(v1, ":")
			att["name"] = tmp[1]
			att["type"] = tmp[2]
			table.insert(self.attributes, att)
		end
		
		-- [year=1996:2008,1000,0,event_id=0:3,1000,0]
		local tdim = split(string.sub(strsc, string.find(strsc, "[", nil, true) + 1, string.find(strsc, "]") - 1), ",")
		self.dimmensions = {}
		for i = 1, #tdim / 3, 1 do
			local dim = {}
			local th1 = split(tdim[i * 3 - 2], ":")
			local th2 = split(th1[1], "=")
			dim["name"] = th2[1]
			dim["min"] = th2[2]
			dim["max"] = th1[2]
			dim["chunksize"] = tdim[i * 3 - 1]
			dim["overlap"] = tdim[i * 3]
			table.insert(self.dimmensions, dim)
		end
	end
end


function ScidbArray:getData()
	if self.dimmensions == nil then
		self:getSchema()
	end
	local t = {}
	if self.sdbcon ~= nil and self.name ~= nil then 
		local n = 0
		local afl = "scan(" .. self.name .. ")"
		t = csv2table(sdbcon:query(afl, n))
	end
	self.data = table2sdbarray(t, self.dimmensions)
end


--===================================================================================

function table2sdbarray(t, dims)
	local res = {}
	local dimnames = {}
	for k, v in pairs(dims) do 
		dimnames[v["name"]] = true
	end
	for k1, v1 in pairs(t) do
		local row = {}
		local pos = {}
		local val = {}
		for k2, v2 in pairs(v1) do
			if dimnames[k2] then
				pos[k2] = v2
			else
				val[k2] = v2
			end
		end
		row["posicion"] = pos
		row["values"] = val
		table.insert(res, row)
	end
	return res
end


function ScidbArray:new (o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end
