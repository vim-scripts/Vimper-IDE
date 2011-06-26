SUBDIRPATH = <SUBDIRPATH>

DIROUTPUT = ./$(OUTPUTPATH)
DIROBJ = $(DIROUTPUT)/obj
DIRDEP = $(DIROUTPUT)/dep

CPPSRCS = $(wildcard $(SUBDIRPATH)/*.cpp)
CPPOBJS = $(addprefix $(DIROBJ)/, $(notdir $(CPPSRCS:.cpp=.o)))
CCCSRCS = $(wildcard $(SUBDIRPATH)/*.c)
CCCOBJS = $(addprefix $(DIROBJ)/, $(notdir $(CCCSRCS:.c=.o)))
DEPSRCS = $(addprefix $(DIRDEP)/, $(notdir $(CPPSRCS:.cpp=.d)))
DEPSRCS+= $(addprefix $(DIRDEP)/, $(notdir $(CCCSRCS:.c=.d)))

all: $(CPPOBJS) $(CCCOBJS)
	@echo 'Objects built $(CPPOBJS) $(CCCOBJS)...'

$(DIROBJ)/%.o: %.c $(DIROBJ) 
	@echo 'Building directory $(SUBDIRPATH)...'
	@echo 'Compile Targets --> $<'
	@echo 'Compiler --> $(CC)...'
	@echo 'Compiler Flags --> [CFLAGS:$(CFLAGS)] [CXXFLAGS:$(CXXFLAGS)]...'
	@echo 'Include Paths --> $(INCLUDES)'
	$(CC) -c $(CFLAGS) $(INCLUDES) -fmessage-length=0 -o"$@" "$<"
	@echo 'Done building directory $(SUBDIRPATH)...'

$(DIROBJ)/%.o: %.cpp $(DIROBJ) 
	@echo 'Building directory $(SUBDIRPATH)...'
	@echo 'Compile Targets --> $<'
	@echo 'Compiler --> $(CXX)...'
	@echo 'Compiler Flags --> [CFLAGS:$(CFLAGS)] [CXXFLAGS:$(CXXFLAGS)]...'
	@echo 'Include Paths --> $(INCLUDES)'
	$(CXX) -c $(CXXFLAGS) $(INCLUDES) -fmessage-length=0 -o"$@" "$<"
	@echo 'Done building directory $(SUBDIRPATH)...'

$(DIRDEP)/%.d: %.c $(DIRDEP)
	@echo 'Generating dependency for $<'
	$(CC) -c $(CFLAGS) $(INCLUDES) -fmessage-length=0 -MMD -MP -MF"$@" -MT"$@" -o $(TEMP)/null.o  "$<"

$(DIRDEP)/%.d: %.cpp $(DIRDEP) 
	@echo 'Generating dependency for $<'
	$(CXX) -c $(CXXFLAGS) $(INCLUDES) -fmessage-length=0 -MMD -MP -MF"$@" -MT"$@" -o $(TEMP)/null.o  "$<"

$(DIRDEP):
	@echo 'Creating directory $(DIRDEP)...'
	mkdir -p $(DIRDEP)

$(DIROBJ):
	@echo 'Creating directory $(DIROBJ)...'
	mkdir -p $(DIROBJ)

clean: $(DIROBJ) $(DIRDEP)
	@echo 'Removing build outputs from $(DIROBJ)...'
	$(RM) $(DIROBJ)/*
	$(RM) $(DIRDEP)/*

depend:
	@echo 'Generating dependencies...'

include $(DEPSRCS)

.PHONY: all clean depend
