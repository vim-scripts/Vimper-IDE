
include project.mk

# ----------------------Include Sub directories to be build-------------------#
# Auto Generated setion please do not edit. If incorrectly edited can cause the
# project configurations to be corrputed. Use Add/Delete Sub-directories functions
# to change the project build configurations.
# _START_SUBDIR_MAKES
# _END_SUBDIR_MAKES
# ----------------------Include Sub directories to be build-------------------#



all: subdirs 

subdirs:
	for subdir in $(SUBDIRS); \
	do \
		$(MAKE) -C $$subdir -f subdir.mk build; \
	done

clean:
	-@echo "Removing build outputs..."
	cd $(PROJECT_OUTPUT_DIR); \
	rm -Rf *; \
	cd $(PROJECT_ROOT);

.PHONY: all subdirs deploy 

.SECONDARY:

