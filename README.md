SciDB-lua
=========

Use SciDB from Lua

Tutorial on calling C functions from Lua <a href="http://www.troubleshooters.com/codecorn/lua/lua_lua_calls_c.htm" target="_blank">Here</a><br/>
Tutorial on libcurl <a href="http://curl.haxx.se/libcurl/c/libcurl-tutorial.html" target="_blank">Here</a> 

<h3>PRE-REQUISITES</h3>

<ul>
<li>Lua & lua development libraries <code>sudo apt-get install lua5.2 liblua5.2-dev</code></li>
<li>A symbolic link at /usr/include/lua pointing pointing to /usr/include/lua5.x. For example: <code>ln -s /usr/include/lua5.2 /usr/include/lua</code></li>
<li>The file <code>/usr/include/curl/types.h</code> must be present. Otherwise, create it with the following content: <code>/* not used */</code></li>
<li>A SciDB database running the <a href="https://github.com/Paradigm4/shim">shim</a> web service.</li>
</ul> 

<h3>COMPILE</h3>
<code>gcc -Wall -shared -fPIC -o shimclient.so -I/usr/include/lua  shimc.c -lcurl -I.</code>

<h3>USE</h3>

<ul>
<li>Create a text file called <code>conf.exe</code>. This text file must contain 4 lines:</li>
  <ul>
  <li>URL of the public shim interface</li>
  <li>URL of the dic shim interface</li>
  <li>Username</li>
  <li>Password</li>
  <ul>
  Such a file would look like this<br>
  <code>http://mySciDB:8080</code>
  <code>https://mySciDB:8083</code>
  <code>scidb</code>
  <code>mySecretPassword</code>

<li>Run the following command to run the tests: <code>lua shimc.lua</code></li>
</ul> 

