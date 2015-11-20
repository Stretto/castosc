CC=gcc

default:
	echo "need implementation (epoll or select)"

epoll:
	make LIB=epoll oscbridge

select:
	make LIB=select oscbridge


oscbridge: oscbridge.c net_${LIB}.c
	gcc -o $@ $^

clean:
	rm -f *.o *~ oscbridge

