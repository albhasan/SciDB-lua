#!/usr/bin/lua
require("shimclient")


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

--Read conf file
local file = 'conf.exe' --Text file containing the URL, SSL URL, user and password like this (without the comment marks):
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
local query = ""
local save = ""
local release = nil
local stream = nil
local n = 0
local filepath = "/media/data/gProjects/SciDB-lua/olympic_data.scidb"
local filepathSciDB = "" -- File path on SciDB's server
local bfilepath = "/tmp/fileDownloadedFromSciDB.txt"


--[[
]]
print("\n", "-----------------------")
print("\n", "TEST - NO AUTHENTICATION")
print("\n", "-----------------------")
save = "dcsv"
query = urlencode("list('functions')")
print("\n", "Starting a new session...")
sid = tonumber(newsession(sdburl))--TODO: Really weird casting, without casting it introduces a CR in the URL. Solve it using C
print("\n", sid)
print("\n", "Executing query...")
print(executequery(sdburl, sid, query, save, release, stream))
print("\n", "Reading lines...")
n = 10
print(readlines(sdburl, sid, n))
print("\n", "Releasing session...")
print(releasesession(sdburl, sid))



print("\n", "-----------------------")
print("\n", "TEST - USE AUTHENTICATION")
print("\n", "-----------------------")
save = "dcsv"
query = urlencode("list('functions')")
print("\n", "Loggin in...")
auth = login(sdburls, user, password)
print("\n", auth)
print("\n", "Starting a new session...")
sid = tonumber(newsession(sdburls, auth))--TODO: Really weird casting
print("\n", sid)
print("\n", "Executing query...")
print(executequery(sdburls, sid, query, save, release, stream, auth))
print("\n", "Reading lines...")
n = 10
print(readlines(sdburls, sid, n, auth))
print("\n", "Releasing session...")
print(releasesession(sdburls, sid,auth))
print("\n", "Loggin out...")
print(logout(sdburls, auth))



print("\n", "-----------------------")
print("\n", "TEST - CREATE ARRAY AND LOAD DATA TO IT")
print("\n", "-----------------------")
save = "dcsv"
print("\n", "Loggin in...")
auth = login(sdburls, user, password)
print("\n", auth)
print("\n", "Starting a new session...")
sid = tonumber(newsession(sdburls, auth))--TODO: Really weird casting
print("\n", sid)
print("\n", "Creating destination array...")
--****** COMMENT WHEN RUNNING FOR THE FIRST TIME
query = urlencode("remove(winnersFlat)")
print(executequery(sdburls, sid, query, nil, nil, nil, auth))
--******
query = urlencode("CREATE ARRAY winnersFlat<event:string,year:int64,person:string,time:double>[i=0:*,1000000,0]")
print(executequery(sdburls, sid, query, nil, nil, nil, auth))
print("\n", "Loading file...")
filepathSciDB = uploadfile(sdburls, sid, filepath, auth)
print(filepathSciDB)
print("\n", "Loading data to array...")
query = urlencode("load(winnersFlat, '" .. filepathSciDB:sub(1, filepathSciDB:len() -2) .. "')")
print(executequery(sdburls, sid, query, nil, nil, nil, auth))
print("\n", "Creating redimensioned array...")
--****** COMMENT WHEN RUNNING FOR THE FIRST TIME
query = urlencode("remove(winners)")
print(executequery(sdburls, sid, query, nil, nil, nil, auth))
--******
query = urlencode("CREATE ARRAY winners <person:string, time:double>[year=1996:2008,1000,0, event_id=0:3,1000,0]")
print(executequery(sdburls, sid, query, nil, nil, nil, auth))
print("\n", "Creating index array...")
--****** COMMENT WHEN RUNNING FOR THE FIRST TIME
query = urlencode("remove(event_index)")
print(executequery(sdburls, sid, query, nil, nil, nil, auth))
--******
query = urlencode("CREATE ARRAY event_index <event:string>[event_id=0:*,10,0]")
print(executequery(sdburls, sid, query, nil, nil, nil, auth))
print("\n", "Redimensioning...")
query = urlencode("store(uniq(sort(project(winnersFlat,event)),'chunk_size=10'),event_index)")
print(executequery(sdburls, sid, query, nil, nil, nil, auth))
query = urlencode("store(redimension(project(index_lookup(winnersFlat, event_index, winnersFlat.event, event_id), year, person, time, event_id), winners),winners)")
print(executequery(sdburls, sid, query, nil, nil, nil, auth))
print("\n", "Retrieve loaded data...")
query = "scan(winners)" -- query = "scan(event_index)" -- query = "scan(winnersFlat)"
print(executequery(sdburls, sid, query, save, release, stream, auth))
print("\n", "Reading lines...")
n = 0
print(readlines(sdburls, sid, n, auth))
print("\n", "Releasing session...")
print(releasesession(sdburls, sid,auth))
print("\n", "Loggin out...")
print(logout(sdburls, auth))



print("\n", "-----------------------")
print("\n", "TEST - READ BYTES")
print("\n", "-----------------------")
print("\n", "Loggin in...")
auth = login(sdburls, user, password)
print("\n", auth)
print("\n", "Starting a new session...")
sid = tonumber(newsession(sdburls, auth))--TODO: Really weird casting
print("\n", sid)
print("\n", "Executing query...")
save = "(double)"
query = urlencode("build(<x:double>[i=1:10,10,0],random())")
print(executequery(sdburls, sid, query, save, release, stream, auth))
print("\n", "Reading bytes...")
n = 20
print(readbytes(sdburls, sid, n, bfilepath, auth))

print("\n", "Releasing session...")
print(releasesession(sdburls, sid,auth))
print("\n", "Loggin out...")
print(logout(sdburls, auth))
--[[
]]


--TODO: Test cancel 
--TODO: Write uploadfile for binaries