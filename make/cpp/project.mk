##
# 	This file contains the project specific settings.
# 	To change the compile options and include any project specific libraries and headers
# 	please edit the appropriate variables below. It is not required to edit any of the other 
# 	settings.
# #

## Template set Platform Architecture
ARCH := <ARCH>
export ARCH

## Template set Project Name
PROJECT_NAME := <PROJECT_NAME>
export PROJECT_NAME

##Template set Project Root Directory
PROJECT_ROOT := <PROJECT_ROOT>
export PROJECT_ROOT

## Template set Project Output Directory
PROJECT_OUTPUT_DIR := <PROJECT_OUTPUT_DIR>
export PROJECT_OUTPUT_DIR

## Template set Prject Type
PROJECT_TYPE := <PROJECT_TYPE>
export PROJECT_TYPE

## Template set Project Build Output
PROJECT_BUILD_OUTPUT := <PROJECT_BUILD_OUTPUT>
export PROJECT_BUILD_OUTPUT

## Template set Target Extension
EXTN := <EXTN>

## Sub-directory output path
OUTPUTPATH=/output/$(MODE)/$(ARCH)
export OUTPUTPATH

## Template set Dependency
PROJ_DEPEND_LIBS := \

export PROJ_DEPEND_LIBS

## Template set Include Paths
PROJ_INCLUDES := \

export PROJ_INCLUDES

## Tempalte set Included Libraries 
#  Format -L<dir> -llib1 -llib2 -L<dir1> ...
#
PROJ_LIBS := \

export PROJ_LIBS

## Template set additional CPP flags
PROJ_CPPFLAGS :=

export PROJ_CPPFLAGS

## Template set additional C flags
PROJ_CFLAGS :=

export PROJ_CGLAGS
## Template set additional CXX flags
PROJ_CXXFLAGS :=

export PROJ_CXXFLAGS

## Template set additional LD flags
PROJ_LDFLAGS :=

export PROJ_LDFLAGS

## Template set additional AS flags
PROJ_ASFLAGS :=

export PROJ_ASFLAGS

## Set Compile Mode (_DEBUG, _GDB_DEBUG, _DEFAULT)
MODE := _DEFAULT
export MODE

## Set Strict Compile Mode - All warnigns will be treated as errors
STRICT := OFF

## Set profiling ON
GPROF := OFF

## Set Code Coverage ON
CODE_COVERAGE := OFF
