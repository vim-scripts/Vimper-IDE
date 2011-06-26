override CC=gcc
override CXX=g++
override CPP=$(CC) -E
override LD=ld
override RM=rm -f

# Always use unsigned char rather the machine default.
CFLAGS+= -funsigned-char 

## WARNING OPTIONS ##
# C wanring flags
CFLAGS+= -Wall -Wswitch-enum -Wunused-parameter -Winit-self 
CFLAGS+= -Wsign-compare -Wcast-align -Wunknown-pragmas -Wpacked -Wpadded -Wunreachable-code 

# C++ additional warning flags
CXXFLAGS+= -Wold-style-cast -Woverloaded-virtual

# If compiling in Strict Mode make all warnings to errors
ifdef $(STRICT)
	CFLAGS+= -Werror
endif

## WARNING OPTIONS ##

## DEBUG OPTIONS ##
# If compiling in Normal Debug Mode
ifeq "$(strip $(MODE))" "_DEBUG"
	CFLAGS+= -g
endif

# If compiling in GDB Debug Mode
ifeq "$(strip $(MODE))" "_GDB_DEBUG"
	CFLAGS+= -ggdb3
endif

# Turn profiling information ON
ifeq "$(strip $(GPROF))" "ON"
	CFLAGS+= -pg
endif

# Turn Test code converage ON
ifeq "$(strip $(CODE_COVERAGE))" "ON"
	CFLAGS+= -fprofile-arcs -ftest-coverage
endif

## DEBUG OPTIONS ##

## PROJECT OPTIONS ##
CFLAGS+=$(PROJ_CFLAGS)
CPPFLAGS+=$(PROJ_CPPFLAGS)
CXXFLAGS+=$(PROJ_CXXFLAGS)
ASFLAGS+=$(PROJ_ASFLAGS)
LDFLAGS+=$(PROJ_LDFLAGS)
INCLUDES+=$(PROJ_INCLUDES)
LIBINCLUDES+=$(PROJ_LIBS)
LIBINCLUDES+=$(PROJ_DEPEND_LIBS)
## PROJECT OPTIONS ##


# Export the FLAGS for use by sub-makes
export CFLAGS CXXFLAGS CC CXX CPP LDFLAGS ASFLAGS RM INCLUDES LIBINCLUDES

