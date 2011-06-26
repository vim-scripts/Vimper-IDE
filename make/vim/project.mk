##
# 	This file contains the project specific settings.
# 	To change the compile options and include any project specific libraries and headers
# 	please edit the appropriate variables below. It is not required to edit any of the other 
# 	settings.
# #

## Template set Project Name
PROJECT_NAME := <PROJECT_NAME>
export PROJECT_NAME

## Template set Project Root Directory
PROJECT_ROOT := <PROJECT_ROOT>
export PROJECT_ROOT

## Template set Vim Install Folder
VIM_INSTALL_DIR := <VIM_HOME>
export VIM_INSTALL_DIR

## Template set Vim Deployment Root
VIM_DEPLOYMENT_DIR := <VIM_DEPLOYMENT>
export VIM_DEPLOYMENT_DIR

## Template set Prject Type
PROJECT_TYPE := <PROJECT_TYPE>
export PROJECT_TYPE


## Template set Prject Output Directory
PROJECT_OUTPUT_DIR := <PROJECT_OUTPUT_DIR>
export PROJECT_OUTPUT_DIR

## Template set Ignore List
# This is the list of file types and directories which
# are removed from the output directory if copied during the 
# build process
IGNORE_LIST = .vim .svn *.mk *.swp Makefile
export IGNORE_LIST
