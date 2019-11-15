CC := gcc -std=c++11
CFLAGS := -Wall -pedantic -Wextra -g
INC := -lstdc++ -Iinclude/ -lm

BUILDDIR := build
TARGETFILE := Run

SRCEXT := cpp
SOURCES := $(wildcard ./*.$(SRCEXT))
OBJECTS := $(SOURCES: .$(SRCEXT)=.o)

$(TARGETFILE): $(OBJECTS)
	$(CC) $^ -o $@ $(CFLAGS) $(INC)

$(BUILDDIR)/%.o: ./%.$(SRCEXT)
	mkdir -p $(BUILDDIR)
	$(CC) -c $< -o $@ $(CFLAGS) $(INC)

.PHONY: clean
clean:
	rm -f -r $(BUILDDIR) $(TARGETDIR) $(TARGETFILE)
