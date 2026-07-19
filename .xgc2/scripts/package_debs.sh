#!/usr/bin/env bash
set -euo pipefail

INSTALL_ROOT=""
OUTPUT_DIR=""
ROS_DISTRO="${ROS_DISTRO:-noetic}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

product_version() {
  awk -F': *' '/^version:[[:space:]]*/ {print $2; exit}' "${REPO_ROOT}/.xgc2/product.yml"
}

VERSION="${PACKAGE_VERSION:-$(product_version)}"
PACKAGE="ros-${ROS_DISTRO}-xgc2-gazebo-sim-cerlab-uav"
ROS_PACKAGE="xgc2_cerlab_uav_simulator"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-root)
      INSTALL_ROOT="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${INSTALL_ROOT}" || -z "${OUTPUT_DIR}" ]]; then
  echo "--install-root and --output-dir are required" >&2
  exit 1
fi

if [[ -z "${VERSION}" ]]; then
  echo "package version is missing" >&2
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
PREFIX="/opt/ros/${ROS_DISTRO}"
PREFIX_ROOT="${INSTALL_ROOT}${PREFIX}"
BUILD_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${BUILD_DIR}"
}
trap cleanup EXIT

mkdir -p "${OUTPUT_DIR}"
rm -f "${OUTPUT_DIR}"/*.deb

copy_path() {
  local src="$1"
  local dst_root="$2"
  if [[ -e "${src}" ]]; then
    mkdir -p "${dst_root}$(dirname "${src#${INSTALL_ROOT}}")"
    cp -a "${src}" "${dst_root}${src#${INSTALL_ROOT}}"
  fi
}

pkg_root="${BUILD_DIR}/${PACKAGE}"
mkdir -p "${pkg_root}"

copy_path "${PREFIX_ROOT}/share/${ROS_PACKAGE}" "${pkg_root}"
copy_path "${PREFIX_ROOT}/include/${ROS_PACKAGE}" "${pkg_root}"
copy_path "${PREFIX_ROOT}/lib/${ROS_PACKAGE}" "${pkg_root}"
copy_path "${PREFIX_ROOT}/share/gennodejs/ros/${ROS_PACKAGE}" "${pkg_root}"
copy_path "${PREFIX_ROOT}/share/common-lisp/ros/${ROS_PACKAGE}" "${pkg_root}"
copy_path "${PREFIX_ROOT}/share/roseus/ros/${ROS_PACKAGE}" "${pkg_root}"

mkdir -p "${pkg_root}/DEBIAN" "${pkg_root}/usr/share/doc/${PACKAGE}"
cat > "${pkg_root}/DEBIAN/control" <<EOF
Package: ${PACKAGE}
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: ${ARCH}
Maintainer: XGC2 <apt@example.com>
Depends: libgazebo11, libprotobuf17, libqt5widgets5, libpcl-common1.10, libpcl-io1.10, python3-numpy, python3-yaml, ros-${ROS_DISTRO}-gazebo-plugins, ros-${ROS_DISTRO}-gazebo-ros, ros-${ROS_DISTRO}-geometry-msgs, ros-${ROS_DISTRO}-mavros, ros-${ROS_DISTRO}-mavros-extras, ros-${ROS_DISTRO}-message-runtime, ros-${ROS_DISTRO}-pcl-conversions, ros-${ROS_DISTRO}-roscpp, ros-${ROS_DISTRO}-roslaunch, ros-${ROS_DISTRO}-roslib, ros-${ROS_DISTRO}-rospy, ros-${ROS_DISTRO}-sensor-msgs, ros-${ROS_DISTRO}-std-msgs, ros-${ROS_DISTRO}-tf2-geometry-msgs, ros-${ROS_DISTRO}-tf2-ros, ros-${ROS_DISTRO}-topic-tools, ros-${ROS_DISTRO}-xgc2-gazebo-sim-worlds (>= 1.1.0-11)
Description: CERLAB and Intent-MPC UAV Gazebo simulator for XGC2
EOF
printf 'xgc2-gazebo-sim-cerlab-uav package\n' > "${pkg_root}/usr/share/doc/${PACKAGE}/README"
chmod 0755 "${pkg_root}/DEBIAN"

fakeroot dpkg-deb --build "${pkg_root}" "${OUTPUT_DIR}/${PACKAGE}_${VERSION}_${ARCH}.deb" >/dev/null
find "${OUTPUT_DIR}" -maxdepth 1 -type f -name '*.deb' -print | sort
