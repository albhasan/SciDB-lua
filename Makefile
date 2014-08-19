CC = gcc
#gcc -Wall -shared -fPIC -o shimclient.so -I/usr/include/lua -llua shimc.c -lcurl -I.
CFLAGS1 = -Wall -shared -fPIC
CFLAGS2 = -I/usr/include/lua -llua
CFLAGS3 = -lcurl -I.

shimc: shimc.c
	$(CC) $(CFLAGS1) -o shimclient.so $(CFLAGS2) shimc.c $(CFLAGS3)

clean:
	-rm -f shimclient.so

rebuild: clean shimc

