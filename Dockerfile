# AMRS in a container: build with CMake + gfortran, run a model from a mounted folder.
# The image holds two builds of the program: a fast Release build (default) and a Debug build
# (array-bounds checks, about 3x slower) that is used when the container is started with -e DEBUG=1.
#
#   docker build -t amrs --build-arg VERSION=$(git describe --tags --always) .
#   docker run --rm amrs --version
#   docker run --rm -v /path/to/model:/model amrs                  # runs the model in /path/to/model
#   docker run --rm -e DEBUG=1 -v /path/to/model:/model amrs       # same, with the debug build
#

# ---- stage 1: build both versions ----
FROM ubuntu:24.04 AS build
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      gfortran cmake ninja-build \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY CMakeLists.txt .
COPY src ./src
# the git tag is not available inside the image (.git is not copied): pass it in
ARG VERSION=unknown
RUN cmake -S . -B /build-release -G Ninja -D CMAKE_BUILD_TYPE=Release -D TAG="${VERSION}" \
 && cmake --build /build-release \
 && cp "$(find /build-release -maxdepth 1 -type f -name 'amrs-*')" /amrs-release
# debug: bounds checking, but no floating-point traps (they stop on harmless errors)
RUN cmake -S . -B /build-debug -G Ninja -D CMAKE_BUILD_TYPE=Debug -D AMRS_FPE_TRAP=OFF -D TAG="${VERSION}" \
 && cmake --build /build-debug \
 && cp "$(find /build-debug -maxdepth 1 -type f -name 'amrs-*')" /amrs-debug

# ---- stage 2: small runtime image ----
FROM ubuntu:24.04
LABEL org.opencontainers.image.source="https://github.com/spark-hydro/AMRS"
LABEL org.opencontainers.image.description="AMRS: APEX coupled with MODFLOW-NWT, RT3D and salinity"
COPY --from=build /amrs-release /usr/local/bin/amrs-release
COPY --from=build /amrs-debug /usr/local/bin/amrs-debug
COPY docker/entrypoint.sh /usr/local/bin/amrs
# the model folder (with APEXRUN.DAT and the other APEX inputs) is mounted here
WORKDIR /model
ENTRYPOINT ["amrs"]
