#!/usr/bin/env bash
set -euo pipefail

if (($# != 1)) || [[ ! -f "$1/telemetry.csv" ]]; then
    echo "Usage: $0 RUN_DIRECTORY" >&2
    exit 2
fi

run_dir=$1
echo "Run: $run_dir"
if [[ -f "$run_dir/metadata.txt" ]]; then
    sed -n -e '/^timestamp_start=/p' -e '/^duration_requested=/p' \
        -e '/^proton_version=/p' -e '/^vkd3d_config=/p' \
        -e '/^steam_launch_options=/p' "$run_dir/metadata.txt"
fi

awk -F, '
    NR == 1 { next }
    NR == 2 {
        min_cpu=max_cpu=$5; min_power=max_power=$8; min_clock=max_clock=$9;
        min_gpu=max_gpu=$11; min_vram=max_vram=$13
    }
    {
        n++
        sum_cpu += $5; sum_power += $8; sum_clock += $9; sum_gpu += $11; sum_vram += $13
        if ($5 < min_cpu) min_cpu=$5; if ($5 > max_cpu) max_cpu=$5
        if ($8 < min_power) min_power=$8; if ($8 > max_power) max_power=$8
        if ($9 < min_clock) min_clock=$9; if ($9 > max_clock) max_clock=$9
        if ($11 < min_gpu) min_gpu=$11; if ($11 > max_gpu) max_gpu=$11
        if ($13 < min_vram) min_vram=$13; if ($13 > max_vram) max_vram=$13
    }
    END {
        if (!n) { print "No telemetry samples"; exit 1 }
        printf "samples=%d\n", n
        printf "cpu_percent avg=%.1f min=%.1f max=%.1f\n", sum_cpu/n, min_cpu, max_cpu
        printf "gpu_percent avg=%.1f min=%.1f max=%.1f\n", sum_gpu/n, min_gpu, max_gpu
        printf "power_w avg=%.2f min=%.2f max=%.2f\n", sum_power/n, min_power, max_power
        printf "graphics_mhz avg=%.0f min=%.0f max=%.0f\n", sum_clock/n, min_clock, max_clock
        printf "vram_mib avg=%.0f min=%.0f max=%.0f\n", sum_vram/n, min_vram, max_vram
    }
' "$run_dir/telemetry.csv"

if [[ -s "$run_dir/kernel-gpu-errors.log" ]]; then
    echo 'Kernel/GPU messages were captured; inspect kernel-gpu-errors.log.'
else
    echo 'No matching kernel/GPU errors captured.'
fi
