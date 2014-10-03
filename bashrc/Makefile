RCFILE = \
		 rc-arch \
		 rc-ifts
ArchLinux = ifts-client.in arch.in systemd.in
IFTS = ifts-server.in


all: $(RCFILE)

rc-arch:
	cat common $(ArchLinux) >arch.bashrc

rc-ifts:
	cat common $(IFTS) >ifts.bashrc

install-arch:
	install -m644 arch.bashrc $(HOME)/.bashrc

install-ifts:
	install -m644 ifts.bashrc $(HOME)/.bashrc

clean:
	$(RM) arch.bashrc ifts.bashrc

.PHONY: install clean
