RESOURCE_COMPILER = $(top_builddir)/tools/resource-compiler

backend_programs = $(NULL)
backend_libraries = $(NULL)
backend_sources = $(NULL)
backend_libadd = $(NULL)
backend_valaflags = $(NULL)
backend_cleanfiles = $(NULL)
glue_sources = $(NULL)

if OS_LINUX
if ARCH_64BIT
HELPER32 ?= $(srcdir)/null-resource.bin!frida-helper-32
HELPER64 ?= frida-helper!frida-helper-64
AGENT32 ?= $(srcdir)/null-resource.bin!frida-agent-32.so
AGENT64 ?= $(top_builddir)/lib/agent/.libs/libfrida-agent.so!frida-agent-64.so
else
HELPER32 ?= frida-helper!frida-helper-32
HELPER64 ?= $(srcdir)/null-resource.bin!frida-helper-64
AGENT32 ?= $(top_builddir)/lib/agent/.libs/libfrida-agent.so!frida-agent-32.so
AGENT64 ?= $(srcdir)/null-resource.bin!frida-agent-64.so
endif
HELPER = $(HELPER32) $(HELPER64)
AGENT = $(AGENT32) $(AGENT64)
HELPER_TARGETS = \
	$(shell echo $(HELPER32) | cut -f1 -d'!') \
	$(shell echo $(HELPER64) | cut -f1 -d'!')
AGENT_TARGETS = \
	$(shell echo $(AGENT32) | cut -f1 -d'!') \
	$(shell echo $(AGENT64) | cut -f1 -d'!')

backend_sources += \
	linux/linux-host-session.vala \
	linux/linjector.vala \
	linux/frida-helper-process.vala
glue_sources += \
	linux/system-linux.c \
	linux/linjector-glue.c
backend_libadd += \
	libfrida-helper-types.la \
	libfrida-data-helper-process.la
backend_valaflags += \
	--pkg=frida-helper-types \
	--pkg=frida-data-helper-process

backend_programs += \
	frida-helper
frida_helper_SOURCES = \
	$(NULL)
frida_helper_LDFLAGS = \
	$(FRIDA_LDFLAGS)
frida_helper_LDADD = \
	libfrida-helper-main.la \
	libfrida-helper-glue.la \
	$(FRIDA_LIBS)

backend_libraries += \
	libfrida-helper-types.la \
	libfrida-helper-main.la \
	libfrida-helper-glue.la

libfrida_helper_main_la_SOURCES = \
	linux/frida-helper.vala
libfrida_helper_main_la_CFLAGS = \
	-w
libfrida_helper_main_la_LIBADD = \
	libfrida-helper-types.la \
	$(FRIDA_LIBS)
libfrida_helper_main_la_VALAFLAGS = \
	--header=frida-helper.h \
	--vapidir=$(abs_top_srcdir)/lib/interfaces \
	--vapidir=$(abs_srcdir) \
	--pkg=frida-interfaces \
	--pkg=frida-helper-types \
	@FRIDA_PACKAGES@ \
	@FRIDA_VALAFLAGS@

libfrida_helper_glue_la_SOURCES = \
	linux/frida-helper-glue.c

libfrida_helper_types_la_SOURCES = \
	linux/frida-helper-types.vala
libfrida_helper_types_la_CFLAGS = \
	-w
libfrida_helper_types_la_LIBADD = \
	$(top_builddir)/lib/interfaces/libfrida-interfaces.la
libfrida_helper_types_la_VALAFLAGS = \
	--vapi=frida-helper-types.vapi \
	--library=frida-helper-types \
	--header=frida-helper-types.h \
	--vapidir=$(abs_top_srcdir)/lib/interfaces \
	--pkg=frida-interfaces \
	@FRIDA_PACKAGES@ \
	@FRIDA_VALAFLAGS@

backend_libraries += \
	libfrida-data-helper-process.la
libfrida_data_helper_process_la_SOURCES = \
	frida-data-helper-process.c \
	frida-data-helper-process-blob.S \
	$(NULL)
frida-data-helper-process.c frida-data-helper-process-blob.S: $(HELPER_TARGETS)
	$(AM_V_GEN) \
		$(RESOURCE_COMPILER) \
			-c "$(srcdir)/linux/frida-helper-process.resources" \
			-o "$(builddir)/frida-data-helper-process" \
			$(HELPER)
backend_cleanfiles += \
	frida-data-helper-process.vapi \
	frida-data-helper-process.h \
	frida-data-helper-process.c \
	frida-data-helper-process-blob.S
endif

if OS_DARWIN
HELPER = frida-helper
AGENT ?= $(top_builddir)/lib/agent/.libs/libfrida-agent.dylib!frida-agent.dylib
AGENT_TARGETS = $(shell echo $(AGENT) | cut -f1 -d'!')

backend_sources += \
	darwin/darwin-host-session.vala \
	darwin/fruitjector.vala \
	darwin/frida-helper-process.vala
glue_sources += \
	darwin/system-darwin.m \
	darwin/darwin-host-session-glue.c \
	darwin/fruitjector-glue.c \
	darwin/icon-helpers.h \
	darwin/icon-helpers.m
backend_libadd += \
	libfrida-helper-types.la \
	libfrida-data-helper-process.la
backend_valaflags += \
	--pkg=frida-helper-types \
	--pkg=frida-data-helper-process

backend_programs += \
	frida-helper
frida_helper_SOURCES = \
	$(NULL)
frida_helper_LDFLAGS = \
	$(FRIDA_LDFLAGS)
frida_helper_LDADD = \
	libfrida-helper-main.la \
	libfrida-helper-glue.la \
	$(FRIDA_LIBS)
if OS_MAC
frida_helper_LDFLAGS += \
	-sectcreate __TEXT __info_plist "$(srcdir)/darwin/frida-helper.plist"
endif

backend_libraries += \
	libfrida-helper-types.la \
	libfrida-helper-main.la \
	libfrida-helper-glue.la

libfrida_helper_main_la_SOURCES = \
	darwin/frida-helper.vala
libfrida_helper_main_la_CFLAGS = \
	-w
libfrida_helper_main_la_LIBADD = \
	libfrida-helper-types.la \
	$(FRIDA_LIBS)
libfrida_helper_main_la_VALAFLAGS = \
	--header=frida-helper.h \
	--vapidir=$(abs_top_srcdir)/lib/interfaces \
	--vapidir=$(abs_srcdir) \
	--pkg=frida-interfaces \
	--pkg=frida-helper-types \
	@FRIDA_PACKAGES@ \
	@FRIDA_VALAFLAGS@

libfrida_helper_glue_la_SOURCES = \
	darwin/frida-helper-glue.c \
	darwin/mapper.h \
	darwin/mapper.c

libfrida_helper_types_la_SOURCES = \
	darwin/frida-helper-types.vala
libfrida_helper_types_la_CFLAGS = \
	-w
libfrida_helper_types_la_LIBADD = \
	$(top_builddir)/lib/interfaces/libfrida-interfaces.la
libfrida_helper_types_la_VALAFLAGS = \
	--vapi=frida-helper-types.vapi \
	--library=frida-helper-types \
	--header=frida-helper-types.h \
	--vapidir=$(abs_top_srcdir)/lib/interfaces \
	--pkg=frida-interfaces \
	@FRIDA_PACKAGES@ \
	@FRIDA_VALAFLAGS@

frida-helper.stamp: frida-helper
if OS_MAC
	codesign -s "$$MAC_CERTID" -i "re.frida.Helper" "$(builddir)/frida-helper" || true
endif
if OS_IOS
	codesign -s "$$IOS_CERTID" --entitlements "$(srcdir)/darwin/frida-helper.xcent" "$<" || true
endif
	touch frida-helper.stamp

backend_libraries += \
	libfrida-data-helper-process.la
libfrida_data_helper_process_la_SOURCES = \
	frida-data-helper-process.c \
	frida-data-helper-process-blob.S \
	$(NULL)
frida-data-helper-process.c frida-data-helper-process-blob.S: frida-helper.stamp
	$(AM_V_GEN) \
		$(RESOURCE_COMPILER) \
			-c "$(srcdir)/darwin/frida-helper-process.resources" \
			-o "$(builddir)/frida-data-helper-process" \
			$(HELPER)
backend_cleanfiles += \
	frida-data-helper-process.vapi \
	frida-data-helper-process.h \
	frida-data-helper-process.c \
	frida-data-helper-process-blob.S

backend_sources += \
	fruity/fruity-client.vala \
	fruity/fruity-host-session.vala \
	fruity/fruity-property-list.vala
glue_sources += \
	fruity/fruity-host-session-darwin.m
endif

BUILT_SOURCES = frida-api-stamp

lib_LTLIBRARIES = \
	libfrida-core-1.0.la
noinst_PROGRAMS = \
	$(backend_programs)
noinst_LTLIBRARIES = \
	$(backend_libraries) \
	libfrida-data-agent.la \
	libfrida-core.la \
	libfrida-core-glue.la

fridacoreincludedir = $(includedir)/frida-1.0
fridacoreinclude_HEADERS = \
	$(builddir)/api/frida-core.h

vapidir = $(datadir)/vala/vapi
vapi_DATA = \
	$(builddir)/api/frida-core-1.0.deps \
	$(builddir)/api/frida-core-1.0.vapi

frida-api-stamp: libfrida-core-1.0.la $(srcdir)/generate-api.py
	mkdir -p $(builddir)/api
	python $(srcdir)/generate-api.py $(srcdir)/frida.vala $(srcdir)/frida-core.vapi $(srcdir)/frida-core.h $(top_srcdir)/lib/interfaces/frida-interfaces.vapi $(top_srcdir)/lib/interfaces/frida-interfaces.h $(builddir)/api
	touch $@

libfrida_core_1_0_la_SOURCES = \
	$(NULL)
libfrida_core_1_0_la_LIBADD = \
	$(top_builddir)/lib/interfaces/libfrida-interfaces.la \
	$(top_builddir)/lib/pipe/libfrida-pipe.la \
	libfrida-data-agent.la \
	$(backend_libadd) \
	libfrida-core.la \
	libfrida-core-glue.la
libfrida_core_1_0_la_LIBTOOLFLAGS = \
	--tag=disable-shared

libfrida_core_la_SOURCES = \
	frida.vala \
	host-session-service.vala \
	$(backend_sources) \
	tcp/tcp-host-session.vala \
	system.vala
libfrida_core_la_CFLAGS = \
	-w
libfrida_core_la_VALAFLAGS = \
	--vapi=frida-core.vapi \
	--library=frida-core \
	--header=frida-core.h \
	--vapidir=$(abs_top_srcdir)/vapi \
	--vapidir=$(abs_top_srcdir)/lib/interfaces \
	--vapidir=$(abs_top_srcdir)/lib/pipe \
	--vapidir=$(abs_srcdir) \
	--vapidir=$(abs_builddir) \
	--pkg=config \
	--pkg=frida-interfaces \
	--pkg=frida-pipe \
	--pkg=frida-data-agent \
	$(backend_valaflags) \
	@FRIDA_PACKAGES@ \
	@FRIDA_VALAFLAGS@

libfrida_core_glue_la_SOURCES = \
	frida-glue.c \
	$(glue_sources)
libfrida_core_glue_la_LIBTOOLFLAGS = \
	--tag=CC

AM_CPPFLAGS = \
	-include config.h \
	-I $(top_srcdir)/lib/interfaces \
	-I $(top_srcdir)/lib/pipe \
	$(FRIDA_CFLAGS) \
	-DPKGDATADIR=\""$(pkgdatadir)"\" \
	-DPKGLIBDIR=\""$(pkglibdir)"\"

libfrida_data_agent_la_SOURCES = \
	frida-data-agent.c \
	frida-data-agent-blob.S \
	$(NULL)
frida-data-agent.c frida-data-agent-blob.S: $(AGENT_TARGETS)
	$(AM_V_GEN) \
		$(RESOURCE_COMPILER) \
			-c "$(srcdir)/agent.resources" \
			-o "$(builddir)/frida-data-agent" \
			$(AGENT)

CLEANFILES = \
	frida-data-agent.vapi \
	frida-data-agent.h \
	frida-data-agent.c \
	frida-data-agent-blob.S \
	$(backend_cleanfiles) \
	$(NULL)
