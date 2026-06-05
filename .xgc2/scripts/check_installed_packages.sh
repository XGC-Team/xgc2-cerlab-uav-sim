#!/usr/bin/env bash
set -euo pipefail

ROS_DISTRO="${ROS_DISTRO:-noetic}"
source "/opt/ros/${ROS_DISTRO}/setup.bash"

dpkg -s ros-noetic-xgc2-gazebo-sim-cerlab-uav >/dev/null
test "$(rospack find xgc2_cerlab_uav_simulator)" = "/opt/ros/${ROS_DISTRO}/share/xgc2_cerlab_uav_simulator"
test -x "/opt/ros/${ROS_DISTRO}/lib/xgc2_cerlab_uav_simulator/keyboard_control"
test -x "/opt/ros/${ROS_DISTRO}/lib/xgc2_cerlab_uav_simulator/quadcopterTFBroadcaster"
test -x "/opt/ros/${ROS_DISTRO}/lib/xgc2_cerlab_uav_simulator/world_generator.py"
test -f "/opt/ros/${ROS_DISTRO}/share/xgc2_cerlab_uav_simulator/plugins/libquadcopterPlugin.so"
test -f "/opt/ros/${ROS_DISTRO}/share/xgc2_cerlab_uav_simulator/plugins/libobstaclePathPlugin.so"
test -f "/opt/ros/${ROS_DISTRO}/share/xgc2_cerlab_uav_simulator/plugins/liblivox_laser.so"
test -f "/opt/ros/${ROS_DISTRO}/share/xgc2_cerlab_uav_simulator/worlds/generated_env/generated_env.world"
test -f "/opt/ros/${ROS_DISTRO}/share/xgc2_cerlab_uav_simulator/models/corridor/model.sdf"
test -f "/opt/ros/${ROS_DISTRO}/share/xgc2_cerlab_uav_simulator/urdf/quadcopter_lidar.urdf"
test -f "/opt/ros/${ROS_DISTRO}/share/xgc2_cerlab_uav_simulator/launch/px4_start.launch"
test -f "/opt/ros/${ROS_DISTRO}/share/xgc2_cerlab_uav_simulator/src/livox_lidar/scan_mode/mid360-real-centr.csv"
test -f "/opt/ros/${ROS_DISTRO}/include/xgc2_cerlab_uav_simulator/quadcopterPlugin.h"
test -f "/opt/ros/${ROS_DISTRO}/share/xgc2_cerlab_uav_simulator/msg/LivoxCustomMsg.msg"

roslaunch --files xgc2_cerlab_uav_simulator start.launch >/dev/null

while IFS= read -r file; do
  if ! file -b "${file}" | grep -q '^ELF'; then
    continue
  fi
  if ! ldd "${file}" | awk '/not found/ {missing=1} END {exit missing ? 1 : 0}'; then
    echo "missing shared library dependency in ${file}" >&2
    ldd "${file}" >&2 || true
    exit 1
  fi
done < <(
  {
    find "/opt/ros/${ROS_DISTRO}/lib/xgc2_cerlab_uav_simulator" -type f 2>/dev/null
    find "/opt/ros/${ROS_DISTRO}/share/xgc2_cerlab_uav_simulator/plugins" -type f 2>/dev/null
  } | sort -u
)

echo "Installed CERLAB UAV simulator package check passed"
