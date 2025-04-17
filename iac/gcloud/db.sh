#!/bin/sh
function delete_cloud_sql_instance() {
  local FUNC_NAME="${FUNCNAME[0]}"

  # Display usage information if '--help' is passed or no parameter is provided
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} INSTANCE_NAME"
    return 0
  fi

  local INSTANCE_NAME="$1"

  echo "[INFO] ${FUNC_NAME}: Attempting to delete instance '${INSTANCE_NAME}'..."

  # Execute the command and handle errors
  if ! start_cloud_sql_instance "${INSTANCE_NAME}"; then
    echo "[ERROR] ${FUNC_NAME}: Failed to start instance '${INSTANCE_NAME}'."
    return 1
  fi

  # Execute the command and handle errors
  if ! patch_deletion_protection_of_cloud_sql_instance "${INSTANCE_NAME}" disable; then
    echo "[ERROR] ${FUNC_NAME}: Failed to patch deletion protection of instance '${INSTANCE_NAME}'."
    return 1
  fi

  # Execute the command and handle errors
  if ! gcloud sql instances delete "${INSTANCE_NAME}"; then
    echo "[ERROR] ${FUNC_NAME}: Failed to delete instance '${INSTANCE_NAME}'."
    return 1
  fi

  echo "[INFO] ${FUNC_NAME}: Successfully deleted instance '${INSTANCE_NAME}'."
  return 0
}

function patch_deletion_protection_of_cloud_sql_instance() {
  local FUNC_NAME="${FUNCNAME[0]}"

  # Display usage if '--help' is passed or if parameters are missing
  if [[ "$1" == "--help" || -z "$1" || -z "$2" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} INSTANCE_NAME [enable|disable]"
    echo "[INFO] ${FUNC_NAME}:   enable  - Enable deletion protection"
    echo "[INFO] ${FUNC_NAME}:   disable - Disable deletion protection"
    return 0
  fi

  local INSTANCE_NAME="$1"
  local ACTION="$2"

  case "${ACTION}" in
    enable)
      echo "[INFO] ${FUNC_NAME}: Attempting to patch instance '${INSTANCE_NAME}' to enable deletion protection..."
      if ! gcloud sql instances patch "${INSTANCE_NAME}" --deletion-protection; then
        echo "[ERROR] ${FUNC_NAME}: Failed to enable deletion protection on instance '${INSTANCE_NAME}'."
        return 1
      fi
      echo "[INFO] ${FUNC_NAME}: Successfully enabled deletion protection on instance '${INSTANCE_NAME}'."
      ;;
    disable)
      echo "[INFO] ${FUNC_NAME}: Attempting to patch instance '${INSTANCE_NAME}' to disable deletion protection..."
      if ! gcloud sql instances patch "${INSTANCE_NAME}" --no-deletion-protection; then
        echo "[ERROR] ${FUNC_NAME}: Failed to disable deletion protection on instance '${INSTANCE_NAME}'."
        return 1
      fi
      echo "[INFO] ${FUNC_NAME}: Successfully disabled deletion protection on instance '${INSTANCE_NAME}'."
      ;;
    *)
      echo "[ERROR] ${FUNC_NAME}: Invalid option '${ACTION}'. Valid options are 'enable' or 'disable'."
      return 1
      ;;
  esac

  return 0
}

function patch_activation_policy() {
  local FUNC_NAME="${FUNCNAME[0]}"

  # Display usage information if '--help' is passed or if parameters are missing
  if [[ "$1" == "--help" || -z "$1" || -z "$2" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} INSTANCE_NAME [always|never]"
    echo "[INFO] ${FUNC_NAME}:   INSTANCE_NAME - The name of the SQL instance to patch"
    echo "[INFO] ${FUNC_NAME}:   always       - Set activation policy to ALWAYS"
    echo "[INFO] ${FUNC_NAME}:   never        - Set activation policy to NEVER"
    return 0
  fi

  local INSTANCE_NAME="$1"
  local POLICY_PARAM="$2"

  case "${POLICY_PARAM}" in
    always)
      echo "[INFO] ${FUNC_NAME}: Patching instance '${INSTANCE_NAME}' to set activation policy to ALWAYS..."
      if ! gcloud sql instances patch "${INSTANCE_NAME}" --activation-policy=ALWAYS; then
        echo "[ERROR] ${FUNC_NAME}: Failed to patch instance '${INSTANCE_NAME}' with activation policy ALWAYS."
        return 1
      fi
      echo "[INFO] ${FUNC_NAME}: Successfully patched instance '${INSTANCE_NAME}' with activation policy ALWAYS."
      ;;
    never)
      echo "[INFO] ${FUNC_NAME}: Patching instance '${INSTANCE_NAME}' to set activation policy to NEVER..."
      if ! gcloud sql instances patch "${INSTANCE_NAME}" --activation-policy=never; then
        echo "[ERROR] ${FUNC_NAME}: Failed to patch instance '${INSTANCE_NAME}' with activation policy NEVER."
        return 1
      fi
      echo "[INFO] ${FUNC_NAME}: Successfully patched instance '${INSTANCE_NAME}' with activation policy NEVER."
      ;;
    *)
      echo "[ERROR] ${FUNC_NAME}: Invalid policy option '${POLICY_PARAM}'. Valid options are 'always' or 'never'."
      return 1
      ;;
  esac

  return 0
}

function start_cloud_sql_instance() {
  local FUNC_NAME="${FUNCNAME[0]}"
  local INSTANCE_NAME="$1"

  # Display usage information if '--help' is passed or if parameters are missing
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} INSTANCE_NAME"
    return 0
  fi

  patch_activation_policy "${INSTANCE_NAME}" "always"

  echo "[INFO] ${FUNC_NAME}: Successfully started instance '${INSTANCE_NAME}'."
  return 0
}

function stop_cloud_sql_instance() {
  local FUNC_NAME="${FUNCNAME[0]}"
  local INSTANCE_NAME="$1"

  # Display usage information if '--help' is passed or if parameters are missing
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} INSTANCE_NAME"
    return 0
  fi

  patch_activation_policy "${INSTANCE_NAME}" "never"

  echo "[INFO] ${FUNC_NAME}: Successfully stopped instance '${INSTANCE_NAME}'."
  return 0
}
