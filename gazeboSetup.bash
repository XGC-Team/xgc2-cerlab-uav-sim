#!/usr/bin/env bash

dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
worlds_dir="$(rospack find gazebo_sim_worlds 2>/dev/null || true)"
if [[ -n "${worlds_dir}" ]]; then
    export GAZEBO_MODEL_PATH="${GAZEBO_MODEL_PATH:-}:${worlds_dir}/models"
fi
export GAZEBO_RESOURCE_PATH="${GAZEBO_RESOURCE_PATH:-}:${dir}/urdf"
export GAZEBO_PLUGIN_PATH="${GAZEBO_PLUGIN_PATH:-}:${dir}/plugins"
