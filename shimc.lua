#!/usr/bin/lua
require("shimclient")

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

--Read conf file
local file = 'conf.exe' --Text file containing the URL, SSL URL, user and password like this
--[[
http://www.myserver.org:00000
https://www.myserver.org:00001
myuser
mypassword
]]
local lines = lines_from(file)
local sdburl = lines[1]
local sdburls = lines[2]
local user = lines[3]
local password = lines[4]

--Query setup
local auth = ""
local sid = ""
local query = "list('functions')"
local save = "dcsv"
local release = nil
local stream = nil
local n = 10
local filepath = ""

print("\n", "-----------------------")
print("\n", "TEST NO AUTHENTICATION")
print("\n", "-----------------------")
print("\n", "Loggin in...")
sid = tonumber(newsession(sdburl))--TODO: Really weird casting, without casting it introduces a CR in the URL. Solve it using C
print("\n", sid)
print("\n", "Executing query...")
print(executequery(sdburl, sid, query, save, release, stream))
print("\n", "Reading lines...")
print(readlines(sdburl, sid, n))
print("\n", "Releasing session...")
print(releasesession(sdburl, sid))



print("\n", "-----------------------")
print("\n", "TEST USING AUTHENTICATION")
print("\n", "-----------------------")
print("\n", "Loggin in...")
auth = login(sdburls, user, password)
print("\n", auth)
print("\n", "Starting a new session...")
sid = tonumber(newsession(sdburls, auth))--TODO: Really weird casting, without casting it introduces a CR in the URL. Solve it using C
print("\n", sid)
print("\n", "Executing query...")
print(executequery(sdburls, sid, query, save, release, stream, auth))
print("\n", "Reading lines...")
print(readlines(sdburls, sid, n, auth))
print("\n", "Releasing session...")
print(releasesession(sdburls, sid,auth))
print("\n", "Loggin out...")
print(logout(sdburls, auth))

