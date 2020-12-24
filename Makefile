BLDDIR = ./build

app: clean
	./package.sh

clean:
	$(RM) -r $(BLDDIR)

.PHONY: app clean
