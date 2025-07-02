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
	wget $(DPDK_URL)
	tar xf $(DPDK_TAR)
	mv dpdk-$(DPDK_VERSION) $(DPDK_DIR)

build_dpdk:
	cd $(DPDK_DIR) && meson setup build
	cd $(DPDK_DIR) && ninja -C build

build_test:
	gcc -Wall -Wextra -Wstrict-prototypes -Wdeclaration-after-statement -Wmissing-declarations -Werror \
	-I$(DPDK_DIR)/build/include \
	test/main.c -o test/dpdk_cuckoo_test \
	-L$(DPDK_DIR)/build/lib -lrte_hash -lrte_eal -lrte_kvargs -lrte_ring -lrte_mempool -lrte_mbuf -lrte_net -lrte_ethdev -lrte_bus_pci \
	-lnuma -lpthread -ldl

run:
	./test/dpdk_cuckoo_test

clean:
	rm -rf $(DPDK_DIR)
	rm -f $(DPDK_TAR)
	rm -f test/dpdk_cuckoo_test
	rm -f log.txt
