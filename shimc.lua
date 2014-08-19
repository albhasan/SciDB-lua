#!/usr/bin/lua
require("shimclient")


local sdburl = "http://www.myserver.org:00000"
local sdburls = "https://www.myserver.org:00000"
local user = "myuser"
local password = "mypassword"
local auth = ""
local sid = ""
local query = "list('functions')"
local save = "dcsv"
local release = nil
local stream = nil
local n = 10

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
