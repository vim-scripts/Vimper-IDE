SUBDIRPATH = <SUBDIRPATH>

DEPLOY_SUBPATH := <DIR_NAME>

build: $(PROJECT_OUTPUT_DIR)/$(DEPLOY_SUBPATH) copy cleanoutput deploy

deploy:
	@echo 'Deploying files to $(VIM_DEPLOYMENT_DIR)/$(DEPLOY_SUBPATH)...' 
	cd $(PROJECT_OUTPUT_DIR)/$(DEPLOY_SUBPATH); \
	cp -R *  $(VIM_DEPLOYMENT_DIR)/$(DEPLOY_SUBPATH)/ ; \
	cd $(SUBDIRPATH)

copy:
	@echo 'Building directory $(SUBDIRPATH)...'
	cp -R * $(PROJECT_OUTPUT_DIR)/$(DEPLOY_SUBPATH)/
	@echo 'Done building directory $(SUBDIRPATH)...'

cleanoutput:
	cd $(PROJECT_OUTPUT_DIR)/$(DEPLOY_SUBPATH); \
	for extn in $(IGNORE_LIST); \
	do \
		echo "Removing $$extn..."; \
		find . -name $$extn -exec rm -f {} \; ; \
	done; \
	cd $(SUBDIRPATH)

$(PROJECT_OUTPUT_DIR)/$(DEPLOY_SUBPATH):
	@echo "Creating directory $(PROJECT_OUTPUT_DIR)/$(DEPLOY_SUBPATH)..."
	mkdir --parent $(PROJECT_OUTPUT_DIR)/$(DEPLOY_SUBPATH)/


.PHONY : build cleanoutput
