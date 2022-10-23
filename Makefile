# SPDX-License-Identifier: (GPL-2.0-only)
#
# Copyright (C) 2020-21 Intel Corporation.
#

VERSION					:= 1.0.0
TARGET					:= $(shell uname -r)
DKMS_ROOT_PATH			:= /usr/src/iosm-rpc-$(VERSION)

KERNEL_MODULES			:= /lib/modules/$(TARGET)

ifneq ("","$(wildcard /usr/src/linux-headers-$(TARGET)/*)")
	KERNEL_BUILD		:= /usr/src/linux-headers-$(TARGET)
else
ifneq ("","$(wildcard /usr/src/kernels/$(TARGET)/*)")
	KERNEL_BUILD		:= /usr/src/kernels/$(TARGET)
else
	KERNEL_BUILD		:= $(KERNEL_MODULES)/build
endif
endif

.PHONY: all modules clean dkms-install dkms-uninstall

all: modules

debug:
	@$(MAKE) -C $(KERNEL_BUILD) M=$(CURDIR) ccflags-y+=-DDEBUG modules

modules:
	@$(MAKE) -C $(KERNEL_BUILD) M=$(CURDIR) modules

clean:
	@$(MAKE) -C $(KERNEL_BUILD) M=$(CURDIR) clean
	rm -rf *.o

dkms-install:
	mkdir $(DKMS_ROOT_PATH)
	cp $(CURDIR)/dkms.conf $(DKMS_ROOT_PATH)
	cp $(CURDIR)/Makefile $(DKMS_ROOT_PATH)
	cp $(CURDIR)/*.c $(DKMS_ROOT_PATH)
	cp $(CURDIR)/*.h $(DKMS_ROOT_PATH)

	sed -e "s/@CFLGS@/${MCFLAGS}/" \
		-e "s/@VERSION@/$(VERSION)/" \
		-i $(DKMS_ROOT_PATH)/dkms.conf

	dkms add iosm-rpc/$(VERSION)
	dkms build iosm-rpc/$(VERSION)
	dkms install iosm-rpc/$(VERSION)

dkms-uninstall:
	dkms remove iosm-rpc/$(VERSION) --all
	rm -rf $(DKMS_ROOT_PATH)

CONFIG_IOSM := m
CONFIG_WWAN_DEBUGFS := y

iosm-rpc-y = \
	iosm_ipc_task_queue.o	\
	iosm_ipc_imem.o			\
	iosm_ipc_imem_ops.o		\
	iosm_ipc_mmio.o			\
	iosm_ipc_port.o			\
	iosm_ipc_wwan.o			\
	iosm_ipc_uevent.o		\
	iosm_ipc_pm.o			\
	iosm_ipc_pcie.o			\
	iosm_ipc_irq.o			\
	iosm_ipc_chnl_cfg.o		\
	iosm_ipc_protocol.o		\
	iosm_ipc_protocol_ops.o	\
	iosm_ipc_mux.o			\
	iosm_ipc_mux_codec.o		\
	iosm_ipc_devlink.o		\
	iosm_ipc_flash.o		\
	iosm_ipc_coredump.o

iosm-rpc-$(CONFIG_WWAN_DEBUGFS) += \
	iosm_ipc_debugfs.o		\
	iosm_ipc_trace.o

obj-$(CONFIG_IOSM) := iosm-rpc.o
