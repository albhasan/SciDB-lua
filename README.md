SciDB-lua
=========

Use SciDB from Lua

Tutorial on calling C functions from Lua <a href="http://www.troubleshooters.com/codecorn/lua/lua_lua_calls_c.htm" target="_blank">Here</a><br/>
Tutorial on libcurl <a href="http://curl.haxx.se/libcurl/c/libcurl-tutorial.html" target="_blank">Here</a> 

<h3>PRE-REQUISITES</h3>

<ul>
	<li>A symbolic link at /usr/include/lua pointing to /usr/include/lua5.x</li>
	<li>The file <code>/usr/include/curl/types.h</code> must be present. Otherwise, create it with the following content: <code>/* not used */</code></li>
</ul> 

<h3>COMPILE</h3>
<code>gcc -Wall -shared -fPIC -o shimclient.so -I/usr/include/lua -llua  shimc.c -lcurl</code>

<h3>RUN</h3>
<code>lua shimc.lua</code>
