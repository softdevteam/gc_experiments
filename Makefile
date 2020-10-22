# Copyright (c) 2020 King's College London
# Created by the Software Development Team <http://soft-dev.org/>
#
# Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# http://www.apache.org/licenses/LICENSE-2.0>, or the MIT license <LICENSE-MIT
# or http://opensource.org/licenses/MIT>, at your option. This file may not be
# copied, modified, or distributed except according to those terms.

YKSOM_DIR=yksom
RUSTC_BOEHM_DIR=rustc_boehm
SOMPP_DIR=SOMpp

YKSOM_BASELINE=yksom_baseline
YKSOM_CUSTOM_RUSTC=yksom_custom_rustc

TOP_DIR=`pwd`

KRUN_DIR=krun
KRUN=${KRUN_DIR}/krun.py
KRUN_VERSION=master
LIBKRUNTIME=${KRUN_DIR}/libkrun/libkruntime.so

PEXECS=10
INPROC_ITERS=2000

TEST_PEXECS=1
TEST_INPROC_ITERS=3

.PHONY: setup
setup: ${LIBKRUNTIME} ${YKSOM_DIR} ${RUSTC_BOEHM_DIR} ${YKSOM_BASELINE} \
	${YKSOM_CUSTOM_RUSTC} ${SOMPP_DIR}

${YKSOM_DIR}:
	git clone --recursive https://github.com/softdevteam/yksom

${RUSTC_BOEHM_DIR}:
	git clone https://github.com/softdevteam/rustc_boehm

${YKSOM_BASELINE}:
	cd ${YKSOM_DIR} && RUSTFLAGS="-l kruntime -L `realpath ../krun/libkrun`" cargo +nightly build --release --features "krun_harness" --target-dir=${YKSOM_BASELINE}

${YKSOM_CUSTOM_RUSTC}:
	cd rustc_boehm && ./x.py build --stage 1 && rustup toolchain link rustc_boehm build/x86_64-unknown-linux-gnu/stage1
	cd ${YKSOM_DIR} && RUSTFLAGS="-l kruntime -L `realpath ../krun/libkrun`" cargo +rustc_boehm build --release --features "rustc_boehm krun_harness" --target-dir=${YKSOM_CUSTOM_RUSTC}

${SOMPP_DIR}:
	git clone --recursive https://github.com/softdevteam/SOMpp && \
		cd ${SOMPP_DIR} && mkdir build && \
		cd build && cmake -DCMAKE_PREFIX_PATH=`realpath ../../krun/libkrun/` ../ && \
		LD_LIBRARY_PATH=$$LD_LIBRARY_PATH:`realpath ../../krun/libkrun/` make -j`nproc`

.PHONY: krun
krun: ${LIBKRUNTIME}

${KRUN}:
	git clone https://github.com/softdevteam/krun ${KRUN_DIR}
	cd ${KRUN_DIR} && git checkout ${KRUN_VERSION}

${LIBKRUNTIME}: ${KRUN}
	cd ${KRUN_DIR} && ${MAKE} NO_MSRS=1

.PHONY: clean
clean: clean-krun-results
	rm -rf ${YKSOM_DIR} ${RUSTC_BOEHM_DIR} ${SOMPP_DIR}

clean-krun-results:
	rm -rf experiment_results.json.bz2 experiment.log experiment.manifest \
		experiment_envlogs
