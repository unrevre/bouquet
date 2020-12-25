BLDDIR = ./build

app: clean
	./package.sh

deps:
	./prepare.sh

clean:
	$(RM) -r $(BLDDIR)

rmdeps:
	./prepare.sh --uninstall

.PHONY: app deps clean rmdeps
