DPDK_VERSION=23.11
DPDK_DIR=dpdk
DPDK_TAR=dpdk-$(DPDK_VERSION).tar.xz
DPDK_URL=https://fast.dpdk.org/rel/$(DPDK_TAR)

.PHONY: all info download_dpdk build_dpdk build_test run clean

all: info download_dpdk build_dpdk build_test run

info:
	@echo "===== /etc/os-release ====="
	@cat /etc/os-release
	@echo "===== gcc version ====="
	@gcc --version
	@echo "===== python version ====="
	@python3 --version

download_dpdk:
	rm -rf $(DPDK_DIR)
	rm -f dpdk-*.tar.xz
	wget $(DPDK_URL)
	tar xf $(DPDK_TAR)
	mv dpdk-$(DPDK_VERSION) $(DPDK_DIR)

build_dpdk:
	cd $(DPDK_DIR) && meson setup build
	cd $(DPDK_DIR) && ninja -C build

build_test:
	gcc -std=gnu11 \
	-Wall -Wextra -Wstrict-prototypes -Wdeclaration-after-statement \
	-Wmissing-declarations -Werror -Wno-error=declaration-after-statement \
	-I$(DPDK_DIR)/config \
	-I$(DPDK_DIR)/lib/eal/linux/include \
	-I$(DPDK_DIR)/lib/eal/x86/include \
	-I$(DPDK_DIR)/lib/eal/include \
	-I$(DPDK_DIR)/lib/rcu \
	-I$(DPDK_DIR)/lib/hash \
	-I$(DPDK_DIR)/lib/log \
	-I$(DPDK_DIR)/lib/ring \
	-I$(DPDK_DIR)/build/ \
	-I$(DPDK_DIR)/build/lib/ \
	-I$(DPDK_DIR)/build/lib/eal/x86/include \
	-I$(DPDK_DIR)/build/lib/eal/linux/include \
	-I$(DPDK_DIR)/build/lib/eal/include \
	test/main.c -o test/dpdk_cuckoo_test \
	-L$(DPDK_DIR)/build/lib \
	-Wl,--whole-archive \
	-lrte_eal -lrte_hash -lrte_kvargs -lrte_ring -lrte_mempool \
	-lrte_mbuf -lrte_net -lrte_ethdev -lrte_pci -lrte_timer -lrte_telemetry \
	-lrte_log -lrte_rcu \
	-Wl,--no-whole-archive \
	-lnuma -lpthread -ldl -lm
run:
	LD_LIBRARY_PATH=dpdk/build/lib ./test/dpdk_cuckoo_test

clean:
	rm -rf $(DPDK_DIR)
	rm -f $(DPDK_TAR)