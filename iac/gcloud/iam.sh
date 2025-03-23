#!/bin/sh
function create_gcloud_service_account() {
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "サービスアカウントを作成するよ！"

  # Check for help parameter
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: create_gcloud_service_account <SERVICE_ACCOUNT_ID> <PROJECT_ID> <ROLE>"
    echo "[INFO] ${func_name}: Example: create_gcloud_service_account my-service-account my-project-id roles/storage.admin"
    echo "[INFO] ${func_name}: [INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/create"
    echo "[INFO] ${func_name}: [INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/add-iam-policy-binding"
    return 0
  fi

  # Validate number of parameters
  if [[ "$#" -ne 3 ]]; then
    echo "[ERROR] ${func_name}: Invalid number of arguments. Use --help for usage."
    return 1
  fi

  local SERVICE_ACCOUNT_ID="$1"
  local PROJECT_ID="$2"
  local ROLE="$3"

  # Create the service account
  echo "[INFO] ${func_name}: Creating service account '${SERVICE_ACCOUNT_ID}'..."
  gcloud iam service-accounts create "${SERVICE_ACCOUNT_ID}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gciam "失敗…" "サービスアカウントを作成できなかったよ…" "red"
    echo "[ERROR] ${func_name}: Failed to create service account '${SERVICE_ACCOUNT_ID}'."
    return 1
  fi

  # Bind the IAM policy with the provided role
  echo "[INFO] ${func_name}: Adding IAM policy binding for project '${PROJECT_ID}' with role '${ROLE}'..."
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="${ROLE}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gciam "失敗…" "IAMポリシーをバインドできなかったよ…" "red"
    echo "[ERROR] ${func_name}: Failed to add IAM policy binding for project '${PROJECT_ID}'."
    return 1
  fi

  send_discord_notification_about_gciam "バインドしたよ！" "IAMポリシーをバインドしたよ！" "green"
  echo "[INFO] ${func_name}: Service account '${SERVICE_ACCOUNT_ID}' created and policy binding added successfully."
}

function add_iam_policy_binding_on_gcloud() {
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "サービスアカウントにIAMポリシーをバインドするよ！"

  # --help オプションのチェック
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <PROJECT_ID> <SERVICE_ACCOUNT_ID> <ROLE>"
    echo "[INFO] ${func_name}: Example: ${func_name} my-project my-service-account roles/storage.admin"
    echo "[INFO] ${func_name}: [INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/add-iam-policy-binding"
    return 0
  fi

  # 引数チェック: PROJECT_ID, SERVICE_ACCOUNT_ID, ROLE の3つは必須
  if [[ "$#" -ne 3 ]]; then
    echo "[ERROR] ${func_name}: Invalid number of arguments. Use --help for usage." >&2
    return 1
  fi

  local PROJECT_ID="$1"
  local SERVICE_ACCOUNT_ID="$2"
  local ROLE="$3"

  echo "[INFO] ${func_name}: Adding IAM policy binding for project '${PROJECT_ID}' with service account '${SERVICE_ACCOUNT_ID}' and role '${ROLE}'..."
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="${ROLE}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gciam "失敗…" "IAMポリシーをバインドできなかったよ…" "red"
    echo "[ERROR] ${func_name}: Failed to add IAM policy binding for project '${PROJECT_ID}'." >&2
    return 1
  fi

  send_discord_notification_about_gciam "バインドしたよ！" "IAMポリシーをバインドしたよ！" "green"
  echo "[INFO] ${func_name}: IAM policy binding added successfully."
}

function list_gcloud_service_accounts() {
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "サービスアカウントを列挙するよ！"

  # Check if the help parameter is provided
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: list_gcloud_service_accounts [FILTER_EXPRESSION] [SORT_BY]"
    echo "[INFO] ${func_name}: Example: list_gcloud_service_accounts 'email:example.com' 'name'"
    echo "[INFO] ${func_name}: [INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/list"
    return 0
  fi

  # Ensure no more than 2 arguments are provided
  if [[ "$#" -gt 2 ]]; then
    echo "[ERROR] ${func_name}: Too many arguments. Use --help for usage."
    return 1
  fi

  # Set parameters if provided
  local filter=""
  local sortby=""
  if [[ "$#" -ge 1 ]]; then
    filter="$1"
  fi
  if [[ "$#" -ge 2 ]]; then
    sortby="$2"
  fi

  # Build the command using an array for safety
  local cmd=( "gcloud" "iam" "service-accounts" "list" )
  if [[ -n "$filter" ]]; then
    cmd+=( "--filter=${filter}" )
  fi
  if [[ -n "$sortby" ]]; then
    cmd+=( "--sort-by=${sortby}" )
  fi

  echo "[INFO] ${func_name}: Running command: ${cmd[*]}"
  "${cmd[@]}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gciam "失敗…" "サービスアカウントを列挙できなかったよ…" "red"
    echo "[ERROR] ${func_name}: Failed to list service accounts."
    return 1
  fi
  send_discord_notification_about_gciam "列挙したよ！" "サービスアカウントを列挙したよ！" "green"
}

function disable_gcloud_service_account() {
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "サービスアカウントを無効化するよ！"

  # Check for help parameter
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: disable_gcloud_service_account <SERVICE_ACCOUNT>"
    echo "[INFO] ${func_name}: Example: disable_gcloud_service_account my-service-account@my-project.iam.gserviceaccount.com"
    echo "[INFO] ${func_name}: [INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/disable"
    return 0
  fi

  # Validate the parameter count
  if [[ "$#" -ne 1 ]]; then
    echo "[ERROR] ${func_name}: Invalid number of arguments. Use --help for usage."
    return 1
  fi

  local SERVICE_ACCOUNT="$1"

  # Disable the service account
  echo "[INFO] ${func_name}: Disabling service account '${SERVICE_ACCOUNT}'..."
  gcloud iam service-accounts disable "${SERVICE_ACCOUNT}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gciam "失敗…" "サービスアカウントを無効化できなかったよ…" "red"
    echo "[ERROR] ${func_name}: Failed to disable service account '${SERVICE_ACCOUNT}'."
    return 1
  fi

  send_discord_notification_about_gciam "無効化したよ！" "サービスアカウントを無効化したよ！" "green"
  echo "[INFO] ${func_name}: Service account '${SERVICE_ACCOUNT}' disabled successfully."
}

function enable_gcloud_service_account() {
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "サービスアカウントを有効化するよ！"

  # Check for help parameter
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: enable_gcloud_service_account <SERVICE_ACCOUNT>"
    echo "[INFO] ${func_name}: Example: enable_gcloud_service_account my-service-account@my-project.iam.gserviceaccount.com"
    echo "[INFO] ${func_name}: [INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/enable"
    return 0
  fi

  # Validate the parameter count
  if [[ "$#" -ne 1 ]]; then
    echo "[ERROR] ${func_name}: Invalid number of arguments. Use --help for usage."
    return 1
  fi

  local SERVICE_ACCOUNT="$1"

  # Enable the service account
  echo "[INFO] ${func_name}: Enabling service account '${SERVICE_ACCOUNT}'..."
  gcloud iam service-accounts enable "${SERVICE_ACCOUNT}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gciam "失敗…" "サービスアカウントを有効化できなかったよ…" "red"
    echo "[ERROR] ${func_name}: Failed to enable service account '${SERVICE_ACCOUNT}'."
    return 1
  fi

  send_discord_notification_about_gciam "有効化したよ！" "サービスアカウントを有効化したよ！" "green"
  echo "[INFO] ${func_name}: Service account '${SERVICE_ACCOUNT}' enabled successfully."
}

function delete_gcloud_service_account() {
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "サービスアカウントを削除するよ！"

  # Check for help parameter
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: delete_gcloud_service_account <SERVICE_ACCOUNT>"
    echo "[INFO] ${func_name}: Example: delete_gcloud_service_account my-service-account@my-project.iam.gserviceaccount.com"
    echo "[INFO] ${func_name}: [INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/delete"
    return 0
  fi

  # Validate the parameter count
  if [[ "$#" -ne 1 ]]; then
    echo "[ERROR] ${func_name}: Invalid number of arguments. Use --help for usage."
    return 1
  fi

  local SERVICE_ACCOUNT="$1"

  # Delete the service account
  echo "[INFO] ${func_name}: Deleting service account '${SERVICE_ACCOUNT}'..."
  gcloud iam service-accounts delete "${SERVICE_ACCOUNT}" --quiet
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gciam "失敗…" "サービスアカウントを削除できなかったよ…" "red"
    echo "[ERROR] ${func_name}: Failed to delete service account '${SERVICE_ACCOUNT}'."
    return 1
  fi

  send_discord_notification_about_gciam "削除したよ！" "サービスアカウントを削除したよ！" "green"
  echo "[INFO] ${func_name}: Service account '${SERVICE_ACCOUNT}' deleted successfully."
}

function update_gcloud_service_account() {
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "サービスアカウントを削除するよ！"

  # Check for help parameter
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: update_gcloud_service_account <SERVICE_ACCOUNT> [--description=DESCRIPTION] [--display-name=DISPLAY_NAME]"
    echo "[INFO] ${func_name}: Example: update_gcloud_service_account my-service-account@my-project.iam.gserviceaccount.com --description='My updated description' --display-name='My Service Account'"
    return 0
  fi

  # Ensure at least one parameter (SERVICE_ACCOUNT) is provided
  if [[ "$#" -lt 1 ]]; then
    echo "[ERROR] ${func_name}: SERVICE_ACCOUNT parameter is required. Use --help for usage."
    return 1
  fi

  local SERVICE_ACCOUNT="$1"
  shift

  # Prepare an array for optional parameters
  local options=()
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --description=*)
        options+=( "$1" )
        ;;
      --display-name=*)
        options+=( "$1" )
        ;;
      *)
        echo "[ERROR] ${func_name}: Unknown option '$1'. Use --help for usage."
        return 1
        ;;
    esac
    shift
  done

  echo "[INFO] ${func_name}: Updating service account '${SERVICE_ACCOUNT}' with options: ${options[*]}"
  gcloud iam service-accounts update "${SERVICE_ACCOUNT}" "${options[@]}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gciam "失敗…" "サービスアカウントを更新できなかったよ…" "red"
    echo "[ERROR] ${func_name}: Failed to update service account '${SERVICE_ACCOUNT}'."
    return 1
  fi

  send_discord_notification_about_gciam "更新したよ！" "サービスアカウントを更新したよ！" "green"
  echo "[INFO] ${func_name}: Service account '${SERVICE_ACCOUNT}' updated successfully."
}
