#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>
#include <curl/types.h>
#include <curl/easy.h>
#include <sys/stat.h>
#include <fcntl.h>


/*
*	******************************************
*	WORKER
*	******************************************
*/



void buildUrl(const char *url, const char *operation, const char *parameters[], int paramsize, char *result){
	const char *query = "?";
	const char *equal = "=";
	const char *amp = "&";
	//char result[10000];
	char aOperation[100];
	strcpy(result, url);
	strcpy(aOperation, operation);
	strncat(result, aOperation, sizeof(aOperation) / sizeof(aOperation[0]));

	int i = 0;
	for (i = 0; i < paramsize; i++)
	{
		if(i == 0)
			strncat(result, query, sizeof(query) / sizeof(query[0]));
		char aParameter[10000];
		strcpy(aParameter, parameters[i]);
		strncat(result, aParameter, sizeof(aParameter) / sizeof(aParameter[0]));
		if(i % 2 == 0)
		{
			strncat(result, equal, sizeof(equal) / sizeof(equal[0]));
		}
		else
		{
			if(i != paramsize - 1)
				strncat(result, amp, sizeof(amp) / sizeof(amp[0]));
		}
	}
	//return result;
}



struct BufferStruct
{
	char * buffer;
	size_t size;
};



static size_t WriteMemoryCallback(void *ptr, size_t size, size_t nmemb, void *data)
{
	size_t realsize = size * nmemb;
	struct BufferStruct * mem = (struct BufferStruct *) data;
	mem->buffer = realloc(mem->buffer, mem->size + realsize + 1);
	if(mem->buffer){
		memcpy( &( mem->buffer[ mem->size ] ), ptr, realsize );
		mem->size += realsize;
		mem->buffer[ mem->size ] = 0;
	}
	return realsize;
}



void callOperation(lua_State *L, const char *url, const char *operation, const char *parameters[], int paramsize)
{
	curl_global_init(CURL_GLOBAL_ALL);
	CURL * curl;
	CURLcode result;
	struct BufferStruct output;
	output.buffer = NULL;
	output.size = 0;

	char aUrl[10000];
	buildUrl(url, operation, parameters, paramsize, aUrl);

	curl = curl_easy_init();
	if(curl){
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&output);
		//curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);
		curl_easy_setopt(curl, CURLOPT_URL, aUrl);
		curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0);
		curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0);
		
		result = curl_easy_perform(curl);
		if(result == CURLE_OK)
		{
			if( output.buffer )
			{
				lua_pushstring(L, output.buffer);
			}
		}
		else
		{
			lua_pushstring(L, curl_easy_strerror(result));
		}
		curl_easy_cleanup(curl);
		if(output.buffer)
		{
			free ( output.buffer );
			output.buffer = 0;
			output.size = 0;
		}
	}
	else
	{
		lua_pushstring(L, "ERROR: CURL initialization failed");
		return;
	}
}



void callOperationUpload(lua_State *L, const char *url, const char *filepath, const char *parameters[], int paramsize)
{
	struct stat file_info;
	struct curl_httppost *formpost = NULL;
	struct curl_httppost *lastptr = NULL;
	struct BufferStruct output;
	output.buffer = NULL;
	output.size = 0;
	
	curl_global_init(CURL_GLOBAL_ALL);
	CURL *curl;
	CURLcode result;

	char aUrl[10000];	
	const char *operation = "/upload_file";
	buildUrl(url, operation, parameters, paramsize, aUrl);

	FILE *fd;
	fd = fopen(filepath, "rb");
	if(!fd)
	{
		lua_pushstring(L, "ERROR: File not found");
		return;
	}
	if(fstat(fileno(fd), &file_info) != 0)
	{
		lua_pushstring(L, "ERROR: File information unavailable");
		return;
	}
	fclose(fd);

	curl_formadd(&formpost, &lastptr, 
					CURLFORM_COPYNAME, "file",
					CURLFORM_FILE , filepath, 
					CURLFORM_END);

	curl = curl_easy_init();
	if(curl) {
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&output);
		//curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);
		curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
		curl_easy_setopt(curl, CURLOPT_URL, aUrl);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost);
		curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0);
		curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0);
		
		result = curl_easy_perform(curl);
		
		if(result == CURLE_OK)
		{
			if( output.buffer )
			{
				lua_pushstring(L, output.buffer);
			}
		}
		else
		{
			lua_pushstring(L, curl_easy_strerror(result));
		}
		
		curl_easy_cleanup(curl);
		curl_formfree(formpost);
		if(output.buffer)
		{
			free ( output.buffer );
			output.buffer = 0;
			output.size = 0;
		}
	}
	else
	{
		lua_pushstring(L, "ERROR: CURL initialization failed");
		return;
	}
}


/*
*	******************************************
*	FUNCTION REGISTERING
*	******************************************
*/

static int version(lua_State *L){
	int res = 0;
	const char *url = lua_tostring(L, 1);

	if(url != NULL)
	{
		const char *parameters[1] = {NULL};
		callOperation(L, url, "/version", parameters, 0);
		res = 1;
	}
	return res;
}

static int login(lua_State *L){ 
	int res = 0;
	int paramCount = 4;
	const char *url = lua_tostring(L, 1);
	const char *username = lua_tostring(L, 2);
	const char *password = lua_tostring(L, 3);
	
	if(url != NULL && username != NULL && password != NULL)
	{
		if(strstr(url, "https") != NULL)
		{
			const char *parameters[4];
			parameters[0] = "username";
			parameters[1] = username;
			parameters[2] = "password";
			parameters[3] = password;
			callOperation(L, url, "/login", parameters, paramCount);
			res = 1;
		}
		else
		{
			lua_pushstring(L, "ERROR: A secure connection requires HTTPS.");
			res = 1;
		}
	}
	return res;
}

static int logout(lua_State *L){ 
	int res = 0;
	int paramCount = 2;
	const char *url = lua_tostring(L, 1);
	const char *auth = lua_tostring(L, 2);
	if(url != NULL && auth != NULL)
	{
		const char *parameters[2];
		parameters[0] = "auth";
		parameters[1] = auth;
		callOperation(L, url, "/logout", parameters, paramCount);
		res = 1;
	}
	return res;
}

static int newsession(lua_State *L){
	int res = 0;
	int paramCount = 0;
	const char *url = lua_tostring(L, 1);
	const char *auth = lua_tostring(L, 2);
	if(url != NULL)
	{
		const char *parameters[2];
		parameters[0] = NULL;
		parameters[1] = NULL;
		if(auth != NULL)
		{
			parameters[0] = "auth";
			parameters[1] = auth;
			paramCount = 2;
		}
		callOperation(L, url, "/new_session", parameters, paramCount);
		res = 1;
	}
	return res;
}


static int releasesession(lua_State *L){ 
	int res = 0;
	int paramCount = 2;
	const char *url = lua_tostring(L, 1);
	const char *id = lua_tostring(L, 2);
	const char *auth = lua_tostring(L, 3);

	if(url != NULL && id != NULL)
	{
		const char *parameters[4];
		parameters[0] = "id";
		parameters[1] = id;
		parameters[2] = NULL;
		parameters[3] = NULL;
		if(auth != NULL)
		{
			parameters[2] = "auth";
			parameters[3] = auth;
			paramCount = 4;
		}
		callOperation(L, url, "/release_session", parameters, paramCount);
		res = 1;
	}
	return res;
}

static int executequery(lua_State *L){ 
	
	int res = 0;
	int paramCount = 4;
	const char *url = lua_tostring(L, 1);
	const char *id = lua_tostring(L, 2);
	const char *query = lua_tostring(L, 3);
	const char *save = lua_tostring(L, 4);//If the save parameter is not specified, don't save the query output. 
	const char *release = lua_tostring(L, 5);
	const char *stream = lua_tostring(L, 6);
	const char *auth = lua_tostring(L, 7);

	if(url != NULL && id != NULL && query != NULL)
	{
		const char *parameters[12];
		parameters[0] = "id";
		parameters[1] = id;
		parameters[2] = "query";
		parameters[3] = query;
		parameters[4] = NULL;
		parameters[5] = NULL;
		parameters[6] = NULL;
		parameters[7] = NULL;
		parameters[8] = NULL;
		parameters[9] = NULL;
		parameters[10] = NULL;
		parameters[11] = NULL;
		if(save != NULL)
		{
			parameters[paramCount] = "save";
			parameters[paramCount + 1] = save;
			paramCount += 2;
		}
		if(release != NULL)
		{
			parameters[paramCount] = "release";
			parameters[paramCount + 1] = release;
			paramCount += 2;
		}
		if(stream != NULL)
		{
			parameters[paramCount] = "stream";
			parameters[paramCount + 1] = stream;
			paramCount += 2;
		}
		if(auth != NULL)
		{
			parameters[paramCount] = "auth";
			parameters[paramCount + 1] = auth;
			paramCount += 2;

		}
		callOperation(L, url, "/execute_query", parameters, paramCount);
		res = 1;
	}
	return res;
}

static int readlines(lua_State *L){ 
	int res = 0;
	int paramCount = 4;
	const char *url = lua_tostring(L, 1);
	const char *id = lua_tostring(L, 2);
	const char *n = lua_tostring(L, 3);//maximum number of lines to read and return between 0 and 2147483647
	const char *auth = lua_tostring(L, 4);

	if(url != NULL && id != NULL && n != NULL)
	{
		const char *parameters[6];
		parameters[0] = "id";
		parameters[1] = id;
		parameters[2] = "n";
		parameters[3] = n;
		parameters[4] = NULL;
		parameters[5] = NULL;
		if(auth != NULL)
		{
			parameters[4] = "auth";
			parameters[5] = auth;
			paramCount = 6;

		}
		callOperation(L, url, "/read_lines", parameters, paramCount);
		res = 1;
	}
	return res;
}

static int readbytes(lua_State *L){ 
	int res = 0;
	int paramCount = 4;
	const char *url = lua_tostring(L, 1);
	const char *id = lua_tostring(L, 2);
	const char *n = lua_tostring(L, 3);//maximum number of bytes to read and return between 0 and 2147483647
	const char *auth = lua_tostring(L, 4);

	if(url != NULL && id != NULL && n != NULL)
	{
		const char *parameters[6];
		parameters[0] = "id";
		parameters[1] = id;
		parameters[2] = "n";
		parameters[3] = n;
		parameters[4] = NULL;
		parameters[5] = NULL;
		if(auth != NULL)
		{
			parameters[4] = "auth";
			parameters[5] = auth;
			paramCount = 6;

		}
		callOperation(L, url, "/read_bytes", parameters, paramCount);
		res = 1;
	}
	return res;
}

static int cancel(lua_State *L){ 
	int res = 0;
	int paramCount = 2;
	const char *url = lua_tostring(L, 1);
	const char *id = lua_tostring(L, 2);
	const char *auth = lua_tostring(L, 3);

	if(url != NULL && id != NULL)
	{
		const char *parameters[4];
		parameters[0] = "id";
		parameters[1] = id;
		parameters[2] = NULL;
		parameters[3] = NULL;
		if(auth != NULL)
		{
			parameters[2] = "auth";
			parameters[3] = auth;
			paramCount = 4;
		}
		callOperation(L, url, "/cancel", parameters, paramCount);
		res = 1;
	}
	return res;
}

static int uploadfile(lua_State *L){ 
	int res = 0;
	int paramCount = 2;
	const char *url = lua_tostring(L, 1);
	const char *id = lua_tostring(L, 2);
	const char *filepath = lua_tostring(L, 3);
	const char *auth = lua_tostring(L, 4);

	if(url != NULL && id != NULL && filepath != NULL)
	{
		const char *parameters[4];
		parameters[0] = "id";
		parameters[1] = id;
		parameters[2] = NULL;
		parameters[3] = NULL;
		if(auth != NULL)
		{
			parameters[2] = "auth";
			parameters[3] = auth;
			paramCount = 4;
		}
		callOperationUpload(L, url, filepath, parameters, paramCount);
		res = 1;
	}
	return res;
}


int luaopen_shimclient(lua_State *L){
	lua_register(L, "version", version);
	lua_register(L,"newsession", newsession);
	lua_register(L,"releasesession", releasesession);
	lua_register(L,"executequery", executequery);
	lua_register(L,"cancel", cancel);
	lua_register(L,"readlines", readlines);
	lua_register(L,"readbytes", readbytes);
	lua_register(L,"uploadfile", uploadfile);
	lua_register(L,"login", login);
	lua_register(L,"logout", logout);
	return 0;
}
