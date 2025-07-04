#include <rte_eal.h>
#include <rte_hash.h>
#include <rte_jhash.h>
#include <rte_random.h>
#include <rte_cycles.h>
#include <rte_errno.h> 
#include <stdio.h>
#include <inttypes.h>


#define HASH_ENTRIES (1 << 20)  // 1 млн элементов
#define TOTAL_KEYS (16 * 1000 * 1000)  // 16 млн ключей

static struct rte_hash *handle = NULL;

int main(int argc, char **argv) {
    (void)argc;
    (void)argv; 

    int ret;
    uint64_t start_time, current_time;
    struct rte_hash_parameters params = {
        .name = "cuckoo_test",
        .entries = HASH_ENTRIES,
        .key_len = sizeof(uint64_t),
        .hash_func = rte_jhash,
        .hash_func_init_val = 0,
    };

    setenv("RTE_MALLOC_DEBUG", "0", 1);
    setenv("RTE_EAL_ALLOW_NO_HUGE", "1", 1);

    // Создаем новые аргументы для DPDK EAL
    const char *dpdk_args[] = {
        argv[0],        // имя программы
        "--no-huge",    // отключаем hugepages
        "--no-pci",     // отключаем PCI (недоступно в WSL)
        "--log-level=0" // уменьшаем логирование
    };
    int new_argc = sizeof(dpdk_args) / sizeof(dpdk_args[0]);

    // Инициализация DPDK Environment Abstraction Layer (EAL)
    ret = rte_eal_init(new_argc, (char **)dpdk_args);
    if (ret < 0) {
        fprintf(stderr, "EAL initialization failed: %s\n", rte_strerror(rte_errno));
        return -1;
    }
    rte_srand(rte_rdtsc());  // Инициализация ГСЧ

    handle = rte_hash_create(&params);
    if (handle == NULL) {
        fprintf(stderr, "Hash table creation failed\n");
        return -1;
    }

    printf("cuckoo test\n");
    start_time = rte_get_tsc_cycles();
    uint64_t key, value;
    const uint64_t special_key = 42;

    for (int i = 0; i < TOTAL_KEYS; i++) {
        key = rte_rand();
        value = rte_rand();

        if (i == 123455) {  // 123456-я итерация (0-based)
            key = special_key;
            value = 123456;
        }

        rte_hash_add_key_data(handle, (const void*)&key, (void*)(uintptr_t)value);

        if (i % (1000 * 1000) == 0) {
            current_time = rte_get_tsc_cycles() - start_time;
            uint64_t hz = rte_get_tsc_hz();
            uint64_t ns = (current_time * 1000000000ULL) / hz;
            printf("%d k / %d k, time: %"PRIu64" ns\n", i/1000, TOTAL_KEYS/1000, ns);
        }
    }

    // Поиск ключа 42
    void *data;
    uint64_t lookup_start = rte_get_tsc_cycles();
    int key_idx = rte_hash_lookup_data(handle, (const void*)&special_key, &data);
    uint64_t lookup_time = (rte_get_tsc_cycles() - lookup_start) * 1000000000ULL / rte_get_tsc_hz();

    if (key_idx < 0) {
        printf("Key 42 not found\n");
    } else {
        printf("Hash size: %d, key: %"PRIu64", hash idx: %d, data: %"PRIu64", lookup time: %"PRIu64" ns\n",
               HASH_ENTRIES, special_key, key_idx, (uint64_t)(uintptr_t)data, lookup_time);
    }

    rte_hash_free(handle);
    return 0;
}