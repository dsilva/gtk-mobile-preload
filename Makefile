
all: libmobilegtk.so

clean:
	rm *.o *.so *.hi || true
	rm *_stub.* || true

run: libmobilegtk.so
	LD_PRELOAD=./libmobilegtk.so gjiten

libmobilegtk.so: init.c MobileGtk.hs libgtktypes.so
	ghc --make -dynamic -shared -fPIC MobileGtk.hs -o libmobilegtk.so  /usr/lib/ghc-6.12.1/libHSrts-ghc6.12.1.so -optl-Wl,-rpath,/usr/lib/ghc-6.12.1/ -optc '-DMODULE=MobileGtk' init.c libgtktypes.so `pkg-config --libs-only-l gtk+-2.0 hildon-1`

libgtktypes.so: gtktypes.o
	gcc -Wall -shared -fPIC -o libgtktypes.so gtktypes.o  `pkg-config --libs gobject-2.0`

gtktypes.o: gtktypes.c
	gcc -Wall -c -fPIC `pkg-config --cflags gobject-2.0` gtktypes.c

