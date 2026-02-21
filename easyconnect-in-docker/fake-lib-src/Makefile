.PHONY: all clean

all: fake-getlogin.so fake-hwaddr.so

fake-getlogin.so: fake-getlogin.c
	${CC} --shared -o fake-getlogin.so fake-getlogin.c -ldl -fPIC

fake-hwaddr.so: fake-hwaddr.c
	${CC} --shared -o fake-hwaddr.so fake-hwaddr.c -ldl -fPIC

clean:
	-rm -f fake-getlogin.so fake-hwaddr.so
