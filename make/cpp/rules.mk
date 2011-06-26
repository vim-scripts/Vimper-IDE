.PHONY: clean
clean:
	-$(RM) *.o *~ core *.d

# Rule to make the subdirectories
# SUBDIRS must be set earlier.
#
.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -f subdir.mk $(MFLAGS) -C $@

# Rule to compile C++ files
#
.SUFFIXES: .cpp .cxx .d

# Set the vpath to include a <inc> directory if present
#
vpath %.h ./inc ./include

.o.cpp:
	$(CC) $(CFLAGS) $(INCLUDES) -c $*.cpp


.d.cpp:
	@set -e; rm -f $@; \
	$(CC) -M $(CPPFLAGS) $(INCLUDES) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

