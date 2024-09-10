all: mstatic mshare

mstatic:
	cc -I ./ -c mod.c
	cc -I ./ -o mstatic main.c mod.o
	rm mod.o

mshare:
	cc -I ./ -shared -fPIC -o libmod.so mod.c
	cc -I ./ -L ./ -lmod -o mshare main.c

runmshare:
	-LD_LIBRARY_PATH=./ ./mshare

clean:
	-rm -f libmod.so mshare mstatic mod.o
