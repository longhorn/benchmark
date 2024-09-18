# KBench

Various benchmark for storage and Kubernetes.

## FIO

### Example Result of Single Volume Benchmark
```
=====================
FIO Benchmark Summary
For: test_device
SIZE: 50G
QUICK MODE: DISABLED
=====================
IOPS (Read/Write)
        Random:            98368 / 89200
  CPU Idleness:                      68%

Bandwidth in KiB/sec (Read/Write)
    Sequential:          552052 / 521330
  CPU Idleness:                      99%

Latency in ns (Read/Write)
        Random:            97222 / 44548
  CPU Idleness:                      72%
```

### Example Result of Comparison Benchmark
```
================================
FIO Benchmark Comparsion Summary
For: 850-pro-raw vs 850-pro-ext4
SIZE: 50G
QUICK MODE: DISABLED
================================
                             850-pro-raw   vs             850-pro-ext4    :              Change
IOPS (Read/Write)
        Random:          96,735 / 89,565   vs          98,135 / 88,990    :      1.45% / -0.64%
  CPU Idleness:                      68%   vs                      66%    :                 -2%

Bandwidth in KiB/sec (Read/Write)
    Sequential:        551,825 / 522,936   vs        552,337 / 520,364    :      0.09% / -0.49%
  CPU Idleness:                      98%   vs                      98%    :                  0%

Latency in ns (Read/Write)
        Random:          82,899 / 44,437   vs         114,331 / 45,104    :      37.92% / 1.50%
  CPU Idleness:                      72%   vs                      73%    :                  1%
```

### Tweak the options

For official benchmarking:
1. `SIZE` environmental variable: the size should be **at least 25 times the read/write bandwidth** to avoid the caching impacting the result.
1. If you're testing a distributed storage solution like Longhorn, always **test against the local storage first** to know what's the baseline.
    * You can install a storage provider for local storage like [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) for this test if you're testing with Kubernetes.
1. `CPU_IDLE_PROF` environmental variable: the CPU idleness profiling measures the CPU idleness, but it introduces extra overhead and reduces the storage performance. By default, the flag is disabled.

### Understanding the result
* **IOPS**: IO operations per second. *Higher is better.*
    * It's a measurement of how many IO operations can the device handle in a second, mainly concerning the smaller IO chunks, e.g. 4k.
* **Bandwidth**: Also called **Throughput**. *Higher is better.*
    * It's a measurement of how many data can the device read/write in a second. It's mainly concering the bigger IO chunks, e.g. 128k.
* **Latency**: The total time each request spent in the IO path. *Lower is better.*
    * It's a measurement of how efficient is the storage system to handle each request.
    * The data path overhead of a storage system can be expressed as the latency it added on top of the native storage system (SSD/NVMe).
* **CPU Idleness**: How idle is the CPU on the node that's running the test. *Higher is better.*
    * It's a measurement of the CPU load/overhead that the storage device has generated.
    * Notice this is idleness, so if the value is higher, it means the CPUs on that node have more free cycles.
    * Unforunately at this moment, this measurement cannot reflect the load on the whole cluster for distributed storage systems. But it's still a worthy reference regarding the storage client's CPU load when benchmarking (depends on how distributed storage was architected).
* For *comparison benchmark*, the `Change` column indicates what's the percentage differences when comparing the second volume to the first volume.
    * For **IOPS, Bandwidth, CPU Idleness**, positive percentage is better.
    * For **Latency**, negative percentage is better.
    * For **CPU Idleness**, instead of showing the percentage of the change, we are showing the difference.

### Understanding the result of a distributed storage system

For a distributed storage system, you always need to test the local storage first as a baseline.

Something is *wrong* when:
1. You're getting *lower read latency than local storage*.
	* You might get higher read IOPS/bandwidth than local storage due to the storage engines can aggregate performance from different nodes/disks. But you shouldn't be able to get lower latency on reading compare to the local storage.
	* If that happens, it's most likely due to there is a cache. Increase the `SIZE` to avoid that.
1. You're getting *better write IOPS/bandwidth/latency than local storage*.
	* It's almost impossible to get better write performance compare to the local storage for a distributed storage solution, unless you have a persistent caching device in front of the local storage.
	* If you are getting this result, it's likely the storage solution is not crash-consistent, so it doesn't commit the data into the disk before respond, which means in the case of an incident, you might lose data.
1. You're getting low *CPU Idleness for Latency benchmark* , e.g. <40%.
	* For **Latency**, the **CPU Idleness** should be at least 40% to guarantee the test won't be impacted by CPU starving.
	* If this happens, adding more CPUs to the node, or move to a beefer machine.

### Deploy the FIO benchmark

#### Deploy Single Volume Benchmark in Kubernetes cluster

By default:
1. The benchmark will use the **default storage class**.
    * You can specify the storage class with the YAML locally.
2. **Filesystem mode** will be used.
    * You can switch to the block mode with the YAML locally.
3. The test requires a **33G** PVC temporarily.
    * You can change the test size with the YAML locally.
    * As mentioned above, for formal benchmark, the size should be **at least 25 times the read/write bandwidth** to avoid the caching impacting the result.

Step to deploy:
1. One line to start benchmarking your default storage class:
    ```
    kubectl apply -f https://raw.githubusercontent.com/longhorn/kbench/main/deploy/fio.yaml
    ```
1. Observe the Result:
    ```
    kubectl logs -l kbench=fio -f
    ```
1. Cleanup:
    ```
    kubectl delete -f https://raw.githubusercontent.com/longhorn/kbench/main/deploy/fio.yaml
    ```

Note: a single benchmark for FIO will take about 6 minutes to finish.

See [./deploy/fio.yaml](https://github.com/longhorn/kbench/blob/main/deploy/fio.yaml) for available options.

#### Deploy Comparison Benchmark in Kubernetes cluster

1. Get a local copy of `fio-cmp.yaml`
    ```
    wget https://raw.githubusercontent.com/longhorn/kbench/main/deploy/fio-cmp.yaml
    ```
1. Set the storage class for each volume you want to compare.
    * By default, it's `local-path` vs `longhorn`.
    * You can install a storage provider for local storage like [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) for this test if you're testing with Kubernetes.
1. Update the `FIRST_VOL_NAME` and `SECOND_VOL_NAME` fields in the yaml to the name you want to call them
    * By default, it's also `Local-Path` vs `Longhorn`.
1. Update the `SIZE` of PVCs and the benchmark configuration.
    * By default, the size for comparison benchmark is **`30G`**.
    * As mentioned above, for formal benchmark, the size should be **at least 25 times the read/write bandwidth** to avoid the caching impacting the result.
1. Deploy using
    ```
    kubectl apply -f fio-cmp.yaml
    ```
1. Observe the result:
    ```
    kubectl logs -l kbench=fio -f
    ```
1. Cleanup:
    ```
    kubectl delete -f fio-cmp.yaml
    ```

Note: a comparison benchmark for FIO will take about 12 minutes to finish.

See [./deploy/fio-cmp.yaml](https://github.com/longhorn/kbench/blob/main/deploy/fio-cmp.yaml) for available options.

#### Run Single Volume Benchmark as Container Locally

```
docker run -v /volume longhornio/kbench:latest /volume/test.img
```
e.g.
```
docker run -e "SIZE=100M" -v /volume longhornio/kbench:latest /volume/test.img
```

#### Run Single Volume Benchmark as a Binary Locally

Notice in this case, `fio` is required locally.

```
./fio/run.sh <test_file> <output_prefix>
```
e.g.
```
./fio/run.sh /dev/sdaxxx ~/fio-results/Samsung_850_PRO_512GB/raw-bloc
```

Intermediate result will be saved into `<output_prefix>-iops.json`, `<output_prefix>-bandwidth.json` and `<output_prefix>-latency.json`.
The output will be printed out as well as saved into `<output_prefix>.summary`.

## License

Copyright (c) 2021 Sheng Yang

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
