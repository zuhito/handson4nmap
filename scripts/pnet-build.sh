#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# The default branch of p-net ships sources only. Tag v0.2.0 still contains the
# CMake project and the sample application that answers DCP Identify All.
rm -rf external/p-net
git clone -q --branch v0.2.0 --depth 1 https://github.com/rtlabs-com/p-net.git external/p-net
git -C external/p-net submodule update --init --recursive --depth 1
cmake -S external/p-net -B external/p-net/build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
cmake --build external/p-net/build -j "$(nproc)" --target pn_dev
