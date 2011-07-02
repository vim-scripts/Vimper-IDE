include $(PROJECT_ROOT)/project.mk 

$(TEMP)/%.d: %.c
	@echo 'Compiler --> $(CC)...'
	@echo 'Compiler Flags --> [CFLAGS:$(CFLAGS)] [CXXFLAGS:$(CXXFLAGS)]...'
	@echo 'Include Paths --> $(INCLUDES)'
	@echo 'Generating dependency for $<'
	$(CC) -c $(CFLAGS) $(INCLUDES) -fmessage-length=0 -MMD -MP -MF"$@" -MT"$@" -o $(TEMP)/null.o  "$<"

$(TEMP)/%.d: %.cpp 
	@echo 'Compiler --> $(CXX)...'
	@echo 'Compiler Flags --> [CFLAGS:$(CFLAGS)] [CXXFLAGS:$(CXXFLAGS)]...'
	@echo 'Include Paths --> $(INCLUDES)'
	@echo 'Generating dependency for $<'
	$(CXX) -c $(CXXFLAGS) $(INCLUDES) -fmessage-length=0 -MMD -MP -MF"$@" -MT"$@" -o $(TEMP)/null.o  "$<"
