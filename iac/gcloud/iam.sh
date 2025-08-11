#!/bin/sh

#==============================================================#
##          IAM policy Functions                              ##
#==============================================================#
function add_iam_policy_binding_to_project_on_gcloud() {
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
  echo ""
  echo "======= IAM Policy Binding ================================================================================="
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="${ROLE}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gciam "失敗…" "IAMポリシーをバインドできなかったよ…" "red"
    echo "[ERROR] ${func_name}: Failed to add IAM policy binding for project '${PROJECT_ID}'." >&2
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  send_discord_notification_about_gciam "バインドしたよ！" "IAMポリシーをバインドしたよ！" "green"
  echo "[INFO] ${func_name}: IAM policy binding added successfully."
}

function add_iam_policy_binding_to_service_account_on_gcloud() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "サービスアカウントにIAMポリシーバインディングを追加するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <SERVICE_ACCOUNT_EMAIL> <MEMBER> <ROLE> [--condition=KEY=VALUE,...] [--condition-from-file=PATH_TO_FILE]"
    echo ""
    echo "引数:"
    echo "  SERVICE_ACCOUNT_EMAIL  IAMポリシーバインディングを追加するサービスアカウントのメールアドレス"
    echo "  MEMBER                 追加するプリンシパル (形式: user|group|serviceAccount|domain:email)"
    echo "  ROLE                   追加するロール (例: roles/iam.serviceAccountUser)"
    echo "  --condition            省略可能: IAMの条件 (形式: KEY=VALUE,...)"
    echo "  --condition-from-file  省略可能: 条件を含むファイルへのパス"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-sa@my-project.iam.gserviceaccount.com user:user@example.com roles/iam.serviceAccountUser"
    echo "  ${func_name} my-sa@my-project.iam.gserviceaccount.com group:admin@example.com roles/iam.serviceAccountAdmin"
    echo "  ${func_name} my-sa@my-project.iam.gserviceaccount.com user:user@example.com roles/iam.serviceAccountUser --condition=\"title=test,expression=request.time < timestamp('2023-01-01T00:00:00Z')\""
    echo "[INFO] ${func_name}: [INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/add-iam-policy-binding"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: SERVICE_ACCOUNT_EMAIL が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: MEMBER が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$3" ]]; then
    echo "[ERROR] ${func_name}: ROLE が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local service_account_email="$1"
  local member="$2"
  local role="$3"
  local condition=""
  local condition_from_file=""

  # オプションの解析
  shift 3
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --condition=*)
        condition="--condition=${1#*=}"
        shift
        ;;
      --condition-from-file=*)
        condition_from_file="--condition-from-file=${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # condition と condition-from-file の両方が指定されていないか確認
  if [[ -n "${condition}" && -n "${condition_from_file}" ]]; then
    echo "[ERROR] ${func_name}: --condition と --condition-from-file は同時に指定できません。" >&2
    return 1
  fi

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam service-accounts add-iam-policy-binding ${service_account_email} --member=${member} --role=${role} ${condition} ${condition_from_file}"

  # コマンド実行
  echo ""
  echo "======= IAM Policy Binding ================================================================================="
  if ! gcloud iam service-accounts add-iam-policy-binding "${service_account_email}" \
       --member="${member}" \
       --role="${role}" \
       ${condition} \
       ${condition_from_file}; then
    echo "[ERROR] ${func_name}: サービスアカウント '${service_account_email}' へのIAMポリシーバインディング追加に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "サービスアカウントにIAMポリシーバインディングを追加できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: サービスアカウント '${service_account_email}' に ${member} を ${role} ロールで正常に追加しました。"
  send_discord_notification_about_gciam "IAMポリシーバインディングを追加したよ！" "サービスアカウントにIAMポリシーバインディングを追加したよ！" "green"
  return 0
}

function add_workload_identity_binding_to_service_account_on_gcloud() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "サービスアカウントにWorkload Identityバインディングを追加するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <SERVICE_ACCOUNT_EMAIL> <PROJECT_NUMBER> <POOL_ID> <REPOSITORY_OWNER> <REPOSITORY_NAME> [--provider-id=PROVIDER_ID] [--condition=KEY=VALUE,...] [--condition-from-file=PATH_TO_FILE]"
    echo ""
    echo "引数:"
    echo "  SERVICE_ACCOUNT_EMAIL  IAMポリシーバインディングを追加するサービスアカウントのメールアドレス"
    echo "  PROJECT_NUMBER         プロジェクト番号"
    echo "  POOL_ID                ワークロードアイデンティティプールのID"
    echo "  REPOSITORY_OWNER       リポジトリのオーナー"
    echo "  REPOSITORY_NAME        リポジトリの名前"
    echo "  --provider-id          省略可能: プロバイダーID (GitHub Actions用YAMLの生成に使用)"
    echo "  --condition            省略可能: IAMの条件 (形式: KEY=VALUE,...)"
    echo "  --condition-from-file  省略可能: 条件を含むファイルへのパス"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-sa@my-project.iam.gserviceaccount.com 123456789012 my-pool my-org my-repo"
    echo "  ${func_name} my-sa@my-project.iam.gserviceaccount.com 123456789012 my-pool my-org my-repo --provider-id=github"
    echo "  ${func_name} my-sa@my-project.iam.gserviceaccount.com 123456789012 my-pool my-org my-repo --condition=\"title=test,expression=request.time < timestamp('2023-01-01T00:00:00Z')\""
    echo "[INFO] ${func_name}: [INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/add-iam-policy-binding"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: SERVICE_ACCOUNT_EMAIL が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_NUMBER が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$3" ]]; then
    echo "[ERROR] ${func_name}: POOL_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$4" ]]; then
    echo "[ERROR] ${func_name}: REPOSITORY_OWNER が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$5" ]]; then
    echo "[ERROR] ${func_name}: REPOSITORY_NAME が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local service_account_email="$1"
  local project_number="$2"
  local pool_id="$3"
  local repo_owner="$4"
  local repo_name="$5"
  local provider_id=""
  local condition=""
  local condition_from_file=""

  # principalSet の生成
  local principal_set="principalSet://iam.googleapis.com/projects/${project_number}/locations/global/workloadIdentityPools/${pool_id}/attribute.repository/${repo_owner}/${repo_name}"

  # オプションの解析
  shift 5
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --provider-id=*)
        provider_id="${1#*=}"
        shift
        ;;
      --condition=*)
        condition="--condition=${1#*=}"
        shift
        ;;
      --condition-from-file=*)
        condition_from_file="--condition-from-file=${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # condition と condition-from-file の両方が指定されていないか確認
  if [[ -n "${condition}" && -n "${condition_from_file}" ]]; then
    echo "[ERROR] ${func_name}: --condition と --condition-from-file は同時に指定できません。" >&2
    return 1
  fi

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam service-accounts add-iam-policy-binding ${service_account_email} --member='${principal_set}' --role=roles/iam.workloadIdentityUser ${condition} ${condition_from_file}"

  # コマンド実行
  echo ""
  echo "======= IAM Policy Binding ================================================================================="
  if ! gcloud iam service-accounts add-iam-policy-binding "${service_account_email}" \
       --member="${principal_set}" \
       --role="roles/iam.workloadIdentityUser" \
       ${condition} \
       ${condition_from_file}; then
    echo "[ERROR] ${func_name}: サービスアカウント '${service_account_email}' へのワークロードアイデンティティバインディング追加に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "サービスアカウントにWorkload Identityバインディングを追加できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: サービスアカウント '${service_account_email}' に ${repo_owner}/${repo_name} リポジトリからのアクセスを正常に設定しました。"
  send_discord_notification_about_gciam "IAMポリシーバインディングを追加したよ！" "サービスアカウントにWorkload Identityバインディングを追加したよ！" "green"

  # GitHub Actions用のYAML情報を表示
  echo ""
  echo "[INFO] ${func_name}: 以下はGitHub Actions用のYAMLファイルに記述するための設定例です:"
  echo "----------------------------------------------------------------"
  echo "env:"
  echo "  GCLOUD_PROJECT_NUMBER: \${{ secrets.GCLOUD_PROJECT_NUMBER }}"
  echo "  GCLOUD_POOL_ID: \${{ secrets.GCLOUD_POOL_ID }}"
  if [[ -n "${provider_id}" ]]; then
    echo "  GCLOUD_PROVIDER_ID: \${{ secrets.GCLOUD_PROVIDER_ID }}"
  else
    echo "  GCLOUD_PROVIDER_ID: \${{ secrets.GCLOUD_PROVIDER_ID }} # プロバイダーIDを設定してください"
  fi
  echo "  GCLOUD_SERVICE_ACCOUNT_EMAIL: \${{ secrets.GCLOUD_SERVICE_ACCOUNT_EMAIL }}"
  echo "jobs:"
  echo "  test:"
  echo "    runs-on: ubuntu-latest"
  echo "    steps:"
  echo "      - id: 'gcloud_auth'"
  echo "        name: 'Authenticate to Google Cloud'"
  echo "        uses: 'google-github-actions/auth@v2'"
  echo "        with:"
  echo "          create_credentials_file: true"
  echo "          workload_identity_provider: 'projects/\${{ env.GCLOUD_PROJECT_NUMBER }}/locations/global/workloadIdentityPools/\${{ env.GCLOUD_POOL_ID }}/providers/\${{ env.GCLOUD_PROVIDER_ID }}'"
  echo "          service_account: '\${{ env.GCLOUD_SERVICE_ACCOUNT_EMAIL }}'"
  echo "----------------------------------------------------------------"
  echo ""
  echo "[INFO] ${func_name}: GitHub SecretsにプロジェクトID、プールID、プロバイダーID、サービスアカウントのメールアドレスを設定してください。"

  return 0
}

#==============================================================#
##          Service Account Functions                         ##
#==============================================================#
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
  echo ""
  echo "======= Service Accounts on Google Cloud ==================================================================="
  "${cmd[@]}"
  echo "============================================================================================================"
  echo ""

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
  echo ""
  echo "======= Service Accounts on Google Cloud ==================================================================="
  gcloud iam service-accounts disable "${SERVICE_ACCOUNT}"
  echo "============================================================================================================"
  echo ""

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
  echo ""
  echo "======= Service Accounts on Google Cloud ==================================================================="
  gcloud iam service-accounts enable "${SERVICE_ACCOUNT}"
  echo "============================================================================================================"
  echo ""

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
  echo ""
  echo "======= Service Accounts on Google Cloud ==================================================================="
  gcloud iam service-accounts delete "${SERVICE_ACCOUNT}" --quiet
  echo "============================================================================================================"
  echo ""

  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gciam "失敗…" "サービスアカウントを削除できなかったよ…" "red"
    echo "[ERROR] ${func_name}: Failed to delete service account '${SERVICE_ACCOUNT}'."
    return 1
  fi

  send_discord_notification_about_gciam "削除したよ！" "サービスアカウントを削除したよ！" "green"
  echo "[INFO] ${func_name}: Service account '${SERVICE_ACCOUNT}' deleted successfully."
}

function undelete_gcloud_service_account() {
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "サービスアカウントを復元するよ！"
  local account_id=""

  # ヘルプが要求された場合
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法:"
    echo "  ${func_name} <ACCOUNT_ID>"
    echo ""
    echo "説明:"
    echo "  削除されたサービスアカウントを復元します"
    echo ""
    echo "例:"
    echo "  ${func_name} my-service-account@my-project.iam.gserviceaccount.com"
    echo "[INFO] ${func_name}: [INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/undelete"
    return 0
  fi

  # パラメータの検証
  if [[ $# -eq 0 ]]; then
    echo "[ERROR] ${func_name}: アカウントIDが指定されていません"
    echo "[INFO] ${func_name}: 使用方法を表示するには --help を指定してください"
    return 1
  fi

  account_id="$1"

  # コマンド実行前の情報表示
  echo "[INFO] ${func_name}: 以下のコマンドを実行します:"
  echo "gcloud iam service-accounts undelete ${account_id}"

  # コマンド実行
  local result
  echo "[INFO] ${func_name}: Deleting service account '${SERVICE_ACCOUNT}'..."
  echo ""
  echo "======= Service Accounts on Google Cloud ==================================================================="
  if ! result=$(gcloud iam service-accounts undelete "${account_id}" 2>&1); then
    echo "[ERROR] ${func_name}: サービスアカウントの復元に失敗しました: ${result}"
    send_discord_notification_about_gciam "失敗…" "サービスアカウントを復元できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  # 成功した場合の結果表示
  echo "[INFO] ${func_name}: サービスアカウントの復元に成功しました"
  send_discord_notification_about_gciam "復元したよ！" "サービスアカウントを復元したよ！" "green"
  echo "${result}"

  return 0
}

function update_gcloud_service_account() {
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "サービスアカウントを更新するよ！"

  # Check for help parameter
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: update_gcloud_service_account <SERVICE_ACCOUNT> [--description=DESCRIPTION] [--display-name=DISPLAY_NAME]"
    echo "[INFO] ${func_name}: Example: update_gcloud_service_account my-service-account@my-project.iam.gserviceaccount.com --description='My updated description' --display-name='My Service Account'"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/update"
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
  echo ""
  echo "======= Service Accounts on Google Cloud ==================================================================="
  gcloud iam service-accounts update "${SERVICE_ACCOUNT}" "${options[@]}"
  echo "============================================================================================================"
  echo ""

  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gciam "失敗…" "サービスアカウントを更新できなかったよ…" "red"
    echo "[ERROR] ${func_name}: Failed to update service account '${SERVICE_ACCOUNT}'."
    return 1
  fi

  send_discord_notification_about_gciam "更新したよ！" "サービスアカウントを更新したよ！" "green"
  echo "[INFO] ${func_name}: Service account '${SERVICE_ACCOUNT}' updated successfully."
}

function describe_gcloud_service_account() {
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "サービスアカウントの詳細を取得するよ！"
  local service_account=""

  # ヘルプが要求された場合
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法:"
    echo "  ${func_name} <SERVICE_ACCOUNT>"
    echo ""
    echo "説明:"
    echo "  指定されたサービスアカウントの詳細情報を表示します"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-service-account@my-project.iam.gserviceaccount.com"
    return 0
  fi

  # パラメータの検証
  if [[ $# -eq 0 ]]; then
    echo "[ERROR] ${func_name}: サービスアカウント名が指定されていません"
    echo "[INFO] ${func_name}: 使用方法を表示するには --help を指定してください"
    return 1
  fi

  service_account="$1"

  # コマンド実行前の情報表示
  echo "[INFO] ${func_name}: 以下のコマンドを実行します:"
  echo "gcloud iam service-accounts describe ${service_account}"

  # コマンド実行
  echo ""
  echo "======= Service Accounts on Google Cloud ==================================================================="
  local result
  if ! result=$(gcloud iam service-accounts describe "${service_account}" 2>&1); then
    echo "[ERROR] ${func_name}: サービスアカウントの情報の取得に失敗しました: ${result}"
    send_discord_notification_about_gciam "失敗…" "サービスアカウントの詳細を取得できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  # 成功した場合の結果表示
  echo "[INFO] ${func_name}: サービスアカウント情報の取得に成功しました"
  echo "${result}"
  send_discord_notification_about_gciam "詳細を取得したよ！" "サービスアカウントの詳細を取得したよ！" "green"

  return 0
}

#==============================================================#
##        Workload Identity Pool Functions                    ##
#==============================================================#
function create_workload_identity_pool() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "Workload Identity Poolを作成するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <WORKLOAD_IDENTITY_POOL> <PROJECT_ID> [--location=LOCATION] [--description=DESCRIPTION]"
    echo ""
    echo "引数:"
    echo "  WORKLOAD_IDENTITY_POOL  作成するワークロードアイデンティティプールの名前"
    echo "  PROJECT_ID              Google CloudプロジェクトのプロジェクトID"
    echo "  --location              省略可能: ロケーション (デフォルト: global)"
    echo "  --description           省略可能: プールの説明"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-pool my-project-id"
    echo "  ${func_name} my-pool my-project-id --location=global"
    echo "  ${func_name} my-pool my-project-id --description=\"My workload identity pool\""
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/create"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: WORKLOAD_IDENTITY_POOL が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local pool_id="$1"
  local project_id="$2"
  local location="global"
  local description=""

  # オプションの解析
  shift 2
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --location=*)
        location="${1#*=}"
        shift
        ;;
      --description=*)
        description="--description=${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam workload-identity-pools create ${pool_id} --project=${project_id} --location=${location} ${description}"

  # コマンド実行
  echo ""
  echo "======= Workload Identity Pools ============================================================================"
  if ! gcloud iam workload-identity-pools create "${pool_id}" --project="${project_id}" --location="${location}" ${description}; then
    echo "[ERROR] ${func_name}: ワークロードアイデンティティプールの作成に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "Workload Identity Poolを作成できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: ワークロードアイデンティティプール '${pool_id}' をプロジェクト '${project_id}' のロケーション '${location}' に正常に作成しました。"
  send_discord_notification_about_gciam "作成したよ！" "Workload Identity Poolを作成したよ！" "green"
  return 0
}

# ワークロードアイデンティティプールの一覧を表示する関数
function list_workload_identity_pools() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "Workload Identity Poolsの一覧を取得するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <PROJECT_ID> [--location=LOCATION] [--show-deleted] [--filter=EXPRESSION]"
    echo ""
    echo "引数:"
    echo "  PROJECT_ID      Google CloudプロジェクトのプロジェクトID"
    echo "  --location      省略可能: ロケーション (デフォルト: global)"
    echo "  --show-deleted  省略可能: 削除されたプールも表示する"
    echo "  --filter        省略可能: 結果をフィルタリングする式"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-project-id"
    echo "  ${func_name} my-project-id --location=us-central1"
    echo "  ${func_name} my-project-id --show-deleted"
    echo "  ${func_name} my-project-id --filter=\"display_name=my-pool*\""
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/list"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local project_id="$1"
  local location="global"
  local show_deleted=""
  local filter=""

  # オプションの解析
  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --location=*)
        location="${1#*=}"
        shift
        ;;
      --show-deleted)
        show_deleted="--show-deleted"
        shift
        ;;
      --filter=*)
        filter="$1"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam workload-identity-pools list --project=${project_id} --location=${location} ${show_deleted} ${filter}"

  # コマンド実行
  echo ""
  echo "======= Workload Identity Pools ============================================================================"
  if ! gcloud iam workload-identity-pools list --project="${project_id}" --location="${location}" ${show_deleted} ${filter}; then
    echo "[ERROR] ${func_name}: ワークロードアイデンティティプールの一覧取得に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "Workload Identity Poolの一覧を取得できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: ワークロードアイデンティティプールの一覧をプロジェクト '${project_id}' のロケーション '${location}' から正常に取得しました。"
  send_discord_notification_about_gciam "一覧を取得したよ！" "Workload Identity Poolsを一覧を取得したよ！" "green"
  return 0
}

# ワークロードアイデンティティプールの詳細を表示する関数
function describe_workload_identity_pool() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "Workload Identity Poolの詳細を取得するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <WORKLOAD_IDENTITY_POOL> <PROJECT_ID> [--location=LOCATION]"
    echo ""
    echo "引数:"
    echo "  WORKLOAD_IDENTITY_POOL  詳細を表示するワークロードアイデンティティプールの名前"
    echo "  PROJECT_ID              Google CloudプロジェクトのプロジェクトID"
    echo "  --location              省略可能: ロケーション (デフォルト: global)"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-pool my-project-id"
    echo "  ${func_name} my-pool my-project-id --location=us-central1"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/describe"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: WORKLOAD_IDENTITY_POOL が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local pool_id="$1"
  local project_id="$2"
  local location="global"

  # オプションの解析
  shift 2
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --location=*)
        location="${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam workload-identity-pools describe ${pool_id} --project=${project_id} --location=${location}"

  # コマンド実行
  echo ""
  echo "======= Workload Identity Pools ============================================================================"
  if ! gcloud iam workload-identity-pools describe "${pool_id}" --project="${project_id}" --location="${location}"; then
    echo "[ERROR] ${func_name}: ワークロードアイデンティティプール '${pool_id}' の詳細取得に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "Workload Identity Poolの詳細を取得できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: ワークロードアイデンティティプール '${pool_id}' の詳細を正常に取得しました。"
  send_discord_notification_about_gciam "詳細を取得したよ！" "Workload Identity Poolsの詳細を取得したよ！" "green"
  return 0
}

# ワークロードアイデンティティプールを削除する関数
function delete_workload_identity_pool() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "Workload Identity Poolを削除するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <WORKLOAD_IDENTITY_POOL> <PROJECT_ID> [--location=LOCATION]"
    echo ""
    echo "引数:"
    echo "  WORKLOAD_IDENTITY_POOL  削除するワークロードアイデンティティプールの名前"
    echo "  PROJECT_ID              Google CloudプロジェクトのプロジェクトID"
    echo "  --location              省略可能: ロケーション (デフォルト: global)"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-pool my-project-id"
    echo "  ${func_name} my-pool my-project-id --location=us-central1"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/delete"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: WORKLOAD_IDENTITY_POOL が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local pool_id="$1"
  local project_id="$2"
  local location="global"

  # オプションの解析
  shift 2
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --location=*)
        location="${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # 削除の確認
  # read -p "[INFO] ${func_name}: ワークロードアイデンティティプール '${pool_id}' を削除しますか？ (y/n): " confirm
  # if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
  #   echo "[INFO] ${func_name}: 削除をキャンセルしました。"
  #   return 0
  # fi

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam workload-identity-pools delete ${pool_id} --project=${project_id} --location=${location} --quiet"

  # コマンド実行
  echo ""
  echo "======= Workload Identity Pools ============================================================================"
  if ! gcloud iam workload-identity-pools delete "${pool_id}" --project="${project_id}" --location="${location}" --quiet; then
    echo "[ERROR] ${func_name}: ワークロードアイデンティティプール '${pool_id}' の削除に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "Workload Identity Poolを削除できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: ワークロードアイデンティティプール '${pool_id}' を正常に削除しました。"
  send_discord_notification_about_gciam "削除したよ！" "Workload Identity Poolを削除したよ！（復元したかったらundeleteしてね。）" "green"
  return 0
}

function undelete_workload_identity_pool() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "Workload Identity Poolを復元するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <WORKLOAD_IDENTITY_POOL> <PROJECT_ID> [--location=LOCATION]"
    echo ""
    echo "引数:"
    echo "  WORKLOAD_IDENTITY_POOL  復元するワークロードアイデンティティプールの名前"
    echo "  PROJECT_ID              Google CloudプロジェクトのプロジェクトID"
    echo "  --location              省略可能: ロケーション (デフォルト: global)"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-pool my-project-id"
    echo "  ${func_name} my-pool my-project-id --location=us-central1"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/undelete"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: WORKLOAD_IDENTITY_POOL が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local pool_id="$1"
  local project_id="$2"
  local location="global"

  # オプションの解析
  shift 2
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --location=*)
        location="${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam workload-identity-pools undelete ${pool_id} --project=${project_id} --location=${location}"

  # コマンド実行
  echo ""
  echo "======= Workload Identity Pools ============================================================================"
  if ! gcloud iam workload-identity-pools undelete "${pool_id}" --project="${project_id}" --location="${location}"; then
    echo "[ERROR] ${func_name}: ワークロードアイデンティティプール '${pool_id}' の復元に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "Workload Identity Poolを復元できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: ワークロードアイデンティティプール '${pool_id}' を正常に復元しました。"
  send_discord_notification_about_gciam "復元したよ！" "Workload Identity Poolを復元したよ！" "green"
  return 0
}

function update_workload_identity_pool() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "Workload Identity Poolを更新するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <WORKLOAD_IDENTITY_POOL> <PROJECT_ID> [--location=LOCATION] [--description=DESCRIPTION] [--disabled] [--display-name=DISPLAY_NAME]"
    echo ""
    echo "引数:"
    echo "  WORKLOAD_IDENTITY_POOL  更新するワークロードアイデンティティプールの名前"
    echo "  PROJECT_ID              Google CloudプロジェクトのプロジェクトID"
    echo "  --location              省略可能: ロケーション (デフォルト: global)"
    echo "  --description           省略可能: プールの説明"
    echo "  --disabled              省略可能: プールを無効にする"
    echo "  --display-name          省略可能: 表示名"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-pool my-project-id"
    echo "  ${func_name} my-pool my-project-id --description=\"Updated pool description\""
    echo "  ${func_name} my-pool my-project-id --disabled"
    echo "  ${func_name} my-pool my-project-id --display-name=\"My Updated Pool\""
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/update"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: WORKLOAD_IDENTITY_POOL が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local pool_id="$1"
  local project_id="$2"
  local location="global"
  local description=""
  local disabled=""
  local display_name=""

  # オプションの解析
  shift 2
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --location=*)
        location="${1#*=}"
        shift
        ;;
      --description=*)
        description="--description=${1#*=}"
        shift
        ;;
      --disabled)
        disabled="--disabled"
        shift
        ;;
      --display-name=*)
        display_name="--display-name=${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam workload-identity-pools update ${pool_id} --project=${project_id} --location=${location} ${description} ${disabled} ${display_name}"

  # コマンド実行
  echo ""
  echo "======= Workload Identity Pools ============================================================================"
  if ! gcloud iam workload-identity-pools update "${pool_id}" --project="${project_id}" --location="${location}" ${description} ${disabled} ${display_name}; then
    echo "[ERROR] ${func_name}: ワークロードアイデンティティプール '${pool_id}' の更新に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "Workload Identity Poolを更新できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: ワークロードアイデンティティプール '${pool_id}' を正常に更新しました。"
  send_discord_notification_about_gciam "更新したよ！" "Workload Identity Poolを更新したよ！" "green"
  return 0
}

#==============================================================#
##     Workload Identity Pool Provider Functions              ##
#==============================================================#
# OIDC プロバイダーを作成する関数
function create_oidc_workload_identity_pool_provider() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "OIDC Workload Identity Pool Providerを作成するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <PROVIDER> <PROJECT_ID> <WORKLOAD_IDENTITY_POOL> <ISSUER_URI> <ATTRIBUTE_MAPPING> <ATTRIBUTE_CONDITION> [--location=LOCATION]"
    echo ""
    echo "引数:"
    echo "  PROVIDER                作成するプロバイダーの名前"
    echo "  PROJECT_ID              Google CloudプロジェクトのプロジェクトID"
    echo "  WORKLOAD_IDENTITY_POOL  プロバイダーを作成するワークロードアイデンティティプールの名前"
    echo "  ISSUER_URI              OIDCプロバイダーの発行者URI"
    echo "  ATTRIBUTE_MAPPING       属性マッピング (形式: KEY=VALUE,...)"
    echo "  ATTRIBUTE_CONDITION     属性条件"
    echo "  --location              省略可能: ロケーション (デフォルト: global)"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-provider my-project-id my-pool https://accounts.google.com \"google.subject=assertion.sub\" \"assertion.sub.startsWith('abc')\""
    echo "  ${func_name} my-provider my-project-id my-pool https://accounts.google.com \"google.subject=assertion.sub,google.groups=assertion.groups\" \"assertion.aud == 'my-audience'\""
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/providers/create-oidc"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: PROVIDER が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$3" ]]; then
    echo "[ERROR] ${func_name}: WORKLOAD_IDENTITY_POOL が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$4" ]]; then
    echo "[ERROR] ${func_name}: ISSUER_URI が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$5" ]]; then
    echo "[ERROR] ${func_name}: ATTRIBUTE_MAPPING が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$6" ]]; then
    echo "[ERROR] ${func_name}: ATTRIBUTE_CONDITION が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local provider="$1"
  local project_id="$2"
  local pool_id="$3"
  local issuer_uri="$4"
  local attribute_mapping="$5"
  local attribute_condition="$6"
  local location="global"

  # オプションの解析
  shift 6
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --location=*)
        location="${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam workload-identity-pools providers create-oidc ${provider} --project=${project_id} --location=${location} --workload-identity-pool=${pool_id} --issuer-uri=${issuer_uri} --attribute-mapping=\"${attribute_mapping}\" --attribute-condition=\"${attribute_condition}\""

  # コマンド実行
  echo ""
  echo "======= Workload Identity Pool Providers =================================================================="
  if ! gcloud iam workload-identity-pools providers create-oidc "${provider}" \
       --project="${project_id}" \
       --location="${location}" \
       --workload-identity-pool="${pool_id}" \
       --issuer-uri="${issuer_uri}" \
       --attribute-mapping="${attribute_mapping}" \
       --attribute-condition="${attribute_condition}"; then
    echo "[ERROR] ${func_name}: OIDCプロバイダー '${provider}' の作成に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "OIDC Workload Identity Pool Providerを作成できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: OIDCプロバイダー '${provider}' をワークロードアイデンティティプール '${pool_id}' に正常に作成しました。"
  send_discord_notification_about_gciam "作成したよ！" "OIDC Workload Identity Pool Providerを作成したよ！" "green"
  return 0
}

function create_oidc_workload_identity_pool_provider_for_github_actions() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "GitHub Actions用のOIDC Workload Identity Pool Providerを作成するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <PROVIDER_ID> <PROJECT_ID> <POOL_ID> <REPOSITORY_OWNER> [--location=LOCATION]"
    echo ""
    echo "引数:"
    echo "  PROVIDER_ID       作成するプロバイダーのID"
    echo "  PROJECT_ID        Google CloudプロジェクトのプロジェクトID"
    echo "  POOL_ID           プロバイダーを作成するワークロードアイデンティティプールのID"
    echo "  REPOSITORY_OWNER  GitHubリポジトリのオーナー名（組織名またはユーザー名）"
    echo "  --location        省略可能: ロケーション (デフォルト: global)"
    echo ""
    echo "使用例:"
    echo "  ${func_name} github-provider my-project-id my-pool my-org"
    echo "  ${func_name} github-provider my-project-id my-pool my-org --location=global"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/providers/create-oidc"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: PROVIDER_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$3" ]]; then
    echo "[ERROR] ${func_name}: POOL_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$4" ]]; then
    echo "[ERROR] ${func_name}: REPOSITORY_OWNER が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local provider_id="$1"
  local project_id="$2"
  local pool_id="$3"
  local repo_owner="$4"
  local location="global"

  # オプションの解析
  shift 4
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --location=*)
        location="${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # 属性マッピングと条件の設定
  local attribute_mapping="google.subject=assertion.sub,attribute.repository=assertion.repository"
  local attribute_condition="assertion.repository_owner=='${repo_owner}'"

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam workload-identity-pools providers create-oidc ${provider_id} --project=${project_id} --location=${location} --workload-identity-pool=${pool_id} --issuer-uri=https://token.actions.githubusercontent.com/ --attribute-mapping=\"${attribute_mapping}\" --attribute-condition=\"${attribute_condition}\""

  # コマンド実行
  echo ""
  echo "======= Workload Identity Pool Providers =================================================================="
  if ! gcloud iam workload-identity-pools providers create-oidc "${provider_id}" \
       --project="${project_id}" \
       --location="${location}" \
       --workload-identity-pool="${pool_id}" \
       --issuer-uri="https://token.actions.githubusercontent.com/" \
       --attribute-mapping="${attribute_mapping}" \
       --attribute-condition="${attribute_condition}"; then
    echo "[ERROR] ${func_name}: GitHub Actions用のOIDCプロバイダー '${provider_id}' の作成に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "GitHub Actions用のOIDC Workload Identity Pool Providerを作成できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  # プロバイダー名を取得
  local provider_name="projects/${project_id}/locations/${location}/workloadIdentityPools/${pool_id}/providers/${provider_id}"

  echo "[INFO] ${func_name}: GitHub Actions用のOIDCプロバイダー '${provider_id}' を正常に作成しました。"
  send_discord_notification_about_gciam "作成したよ！" "GitHub Actions用のOIDC Workload Identity Pool Providerを作成したよ！" "green"

  # GitHub Actions用のYAML情報を表示
  echo ""
  echo "[INFO] ${func_name}: 以下はGitHub Actions用のYAMLファイルに記述するための設定例です:"
  echo "----------------------------------------------------------------"
  echo "env:"
  echo "  GCLOUD_PROJECT_NUMBER: \${{ secrets.GCLOUD_PROJECT_NUMBER }} # プロジェクト番号を設定してください"
  echo "  GCLOUD_POOL_ID: ${pool_id}"
  echo "  GCLOUD_PROVIDER_ID: ${provider_id}"
  echo "  GCLOUD_SERVICE_ACCOUNT_EMAIL: \${{ secrets.GCLOUD_SERVICE_ACCOUNT_EMAIL }} # サービスアカウントのメールアドレスを設定してください"
  echo "jobs:"
  echo "  test:"
  echo "    runs-on: ubuntu-latest"
  echo "    steps:"
  echo "      - id: 'gcloud_auth'"
  echo "        name: 'Authenticate to Google Cloud'"
  echo "        uses: 'google-github-actions/auth@v2'"
  echo "        with:"
  echo "          create_credentials_file: true"
  echo "          workload_identity_provider: 'projects/\${{ env.GCLOUD_PROJECT_NUMBER }}/locations/${location}/workloadIdentityPools/${pool_id}/providers/${provider_id}'"
  echo "          service_account: '\${{ env.GCLOUD_SERVICE_ACCOUNT_EMAIL }}'"
  echo "----------------------------------------------------------------"
  echo ""
  echo "[INFO] ${func_name}: GitHub Secretsにプロジェクト番号とサービスアカウントのメールアドレスを設定してください。"
  echo "[INFO] ${func_name}: 次に、サービスアカウントにリポジトリからのアクセスを許可するためにIAMポリシーバインディングを追加する必要があります。"

  return 0
}

function list_workload_identity_pool_providers() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "Workload Identity Pool Providerの一覧を取得するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <PROJECT_ID> <WORKLOAD_IDENTITY_POOL> [--location=LOCATION] [--show-deleted] [--filter=EXPRESSION]"
    echo ""
    echo "引数:"
    echo "  PROJECT_ID              Google CloudプロジェクトのプロジェクトID"
    echo "  WORKLOAD_IDENTITY_POOL  プロバイダーを表示するワークロードアイデンティティプールの名前"
    echo "  --location              省略可能: ロケーション (デフォルト: global)"
    echo "  --show-deleted          省略可能: 削除されたプロバイダーも表示する"
    echo "  --filter                省略可能: 結果をフィルタリングする式"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-project-id my-pool"
    echo "  ${func_name} my-project-id my-pool --location=us-central1"
    echo "  ${func_name} my-project-id my-pool --show-deleted"
    echo "  ${func_name} my-project-id my-pool --filter=\"displayName=my-provider*\""
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/providers/list"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: WORKLOAD_IDENTITY_POOL が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local project_id="$1"
  local pool_id="$2"
  local location="global"
  local show_deleted=""
  local filter=""

  # オプションの解析
  shift 2
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --location=*)
        location="${1#*=}"
        shift
        ;;
      --show-deleted)
        show_deleted="--show-deleted"
        shift
        ;;
      --filter=*)
        filter="$1"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam workload-identity-pools providers list --project=${project_id} --workload-identity-pool=${pool_id} --location=${location} ${show_deleted} ${filter}"

  # コマンド実行
  echo ""
  echo "======= Workload Identity Pool Providers ==================================================================="
  if ! gcloud iam workload-identity-pools providers list \
       --project="${project_id}" \
       --workload-identity-pool="${pool_id}" \
       --location="${location}" \
       ${show_deleted} \
       ${filter}; then
    echo "[ERROR] ${func_name}: ワークロードアイデンティティプール '${pool_id}' のプロバイダー一覧取得に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "Workload Identity Pool Providerの一覧を取得できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: ワークロードアイデンティティプール '${pool_id}' のプロバイダー一覧を正常に取得しました。"
  send_discord_notification_about_gciam "一覧を取得したよ！" "Workload Identity Pool Providerの一覧を取得したよ！" "green"
  return 0
}

function describe_workload_identity_pool_provider() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "Workload Identity Pool Providerの詳細を取得するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <PROVIDER> <PROJECT_ID> <WORKLOAD_IDENTITY_POOL> [--location=LOCATION]"
    echo ""
    echo "引数:"
    echo "  PROVIDER                詳細を表示するプロバイダーの名前"
    echo "  PROJECT_ID              Google CloudプロジェクトのプロジェクトID"
    echo "  WORKLOAD_IDENTITY_POOL  プロバイダーが所属するワークロードアイデンティティプールの名前"
    echo "  --location              省略可能: ロケーション (デフォルト: global)"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-provider my-project-id my-pool"
    echo "  ${func_name} my-provider my-project-id my-pool --location=us-central1"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/providers/describe"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: PROVIDER が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$3" ]]; then
    echo "[ERROR] ${func_name}: WORKLOAD_IDENTITY_POOL が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local provider="$1"
  local project_id="$2"
  local pool_id="$3"
  local location="global"

  # オプションの解析
  shift 3
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --location=*)
        location="${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam workload-identity-pools providers describe ${provider} --project=${project_id} --workload-identity-pool=${pool_id} --location=${location}"

  # コマンド実行
  echo ""
  echo "======= Workload Identity Pool Providers ==================================================================="
  if ! gcloud iam workload-identity-pools providers describe "${provider}" \
       --project="${project_id}" \
       --workload-identity-pool="${pool_id}" \
       --location="${location}"; then
    echo "[ERROR] ${func_name}: プロバイダー '${provider}' の詳細取得に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "Workload Identity Pool Providerの詳細を取得できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: プロバイダー '${provider}' の詳細を正常に取得しました。"
  send_discord_notification_about_gciam "詳細を取得したよ！" "Workload Identity Pool Providerの詳細を取得したよ！" "green"
  return 0
}

function update_oidc_workload_identity_pool_provider() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "OIDC Workload Identity Pool Providerを更新するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <PROVIDER> <PROJECT_ID> <WORKLOAD_IDENTITY_POOL> [--location=LOCATION] [--allowed-audiences=ALLOWED_AUDIENCES,...] [--attribute-condition=ATTRIBUTE_CONDITION] [--attribute-mapping=KEY=VALUE,...] [--description=DESCRIPTION] [--disabled] [--display-name=DISPLAY_NAME] [--issuer-uri=ISSUER_URI] [--jwk-json-path=PATH_TO_FILE]"
    echo ""
    echo "引数:"
    echo "  PROVIDER                更新するプロバイダーの名前"
    echo "  PROJECT_ID              Google CloudプロジェクトのプロジェクトID"
    echo "  WORKLOAD_IDENTITY_POOL  プロバイダーが所属するワークロードアイデンティティプールの名前"
    echo "  --location              省略可能: ロケーション (デフォルト: global)"
    echo "  --allowed-audiences     省略可能: 許可されるオーディエンス (カンマ区切り)"
    echo "  --attribute-condition   省略可能: 属性条件"
    echo "  --attribute-mapping     省略可能: 属性マッピング (形式: KEY=VALUE,...)"
    echo "  --description           省略可能: プロバイダーの説明"
    echo "  --disabled              省略可能: プロバイダーを無効にする"
    echo "  --display-name          省略可能: 表示名"
    echo "  --issuer-uri            省略可能: OIDCプロバイダーの発行者URI"
    echo "  --jwk-json-path         省略可能: JWK JSONファイルへのパス"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-provider my-project-id my-pool"
    echo "  ${func_name} my-provider my-project-id my-pool --attribute-mapping=\"google.subject=assertion.sub\""
    echo "  ${func_name} my-provider my-project-id my-pool --disabled"
    echo "  ${func_name} my-provider my-project-id my-pool --issuer-uri=https://accounts.google.com"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/providers/update-oidc"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: PROVIDER が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$3" ]]; then
    echo "[ERROR] ${func_name}: WORKLOAD_IDENTITY_POOL が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local provider="$1"
  local project_id="$2"
  local pool_id="$3"
  local location="global"
  local allowed_audiences=""
  local attribute_condition=""
  local attribute_mapping=""
  local description=""
  local disabled=""
  local display_name=""
  local issuer_uri=""
  local jwk_json_path=""

  # オプションの解析
  shift 3
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --location=*)
        location="${1#*=}"
        shift
        ;;
      --allowed-audiences=*)
        allowed_audiences="--allowed-audiences=${1#*=}"
        shift
        ;;
      --attribute-condition=*)
        attribute_condition="--attribute-condition=${1#*=}"
        shift
        ;;
      --attribute-mapping=*)
        attribute_mapping="--attribute-mapping=${1#*=}"
        shift
        ;;
      --description=*)
        description="--description=${1#*=}"
        shift
        ;;
      --disabled)
        disabled="--disabled"
        shift
        ;;
      --display-name=*)
        display_name="--display-name=${1#*=}"
        shift
        ;;
      --issuer-uri=*)
        issuer_uri="--issuer-uri=${1#*=}"
        shift
        ;;
      --jwk-json-path=*)
        jwk_json_path="--jwk-json-path=${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam workload-identity-pools providers update-oidc ${provider} --project=${project_id} --workload-identity-pool=${pool_id} --location=${location} ${allowed_audiences} ${attribute_condition} ${attribute_mapping} ${description} ${disabled} ${display_name} ${issuer_uri} ${jwk_json_path}"

  # コマンド実行
  echo ""
  echo "======= Workload Identity Pool Providers ==================================================================="
  if ! gcloud iam workload-identity-pools providers update-oidc "${provider}" \
       --project="${project_id}" \
       --workload-identity-pool="${pool_id}" \
       --location="${location}" \
       ${allowed_audiences} \
       ${attribute_condition} \
       ${attribute_mapping} \
       ${description} \
       ${disabled} \
       ${display_name} \
       ${issuer_uri} \
       ${jwk_json_path}; then
    echo "[ERROR] ${func_name}: プロバイダー '${provider}' の更新に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "OIDC Workload Identity Pool Providerを更新できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: プロバイダー '${provider}' を正常に更新しました。"
  send_discord_notification_about_gciam "更新したよ！" "OIDC Workload Identity Pool Providerを更新したよ！" "green"
  return 0
}

function delete_workload_identity_pool_provider() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "Workload Identity Pool Providerを削除するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <PROVIDER> <PROJECT_ID> <WORKLOAD_IDENTITY_POOL> [--location=LOCATION]"
    echo ""
    echo "引数:"
    echo "  PROVIDER                削除するプロバイダーの名前"
    echo "  PROJECT_ID              Google CloudプロジェクトのプロジェクトID"
    echo "  WORKLOAD_IDENTITY_POOL  プロバイダーが所属するワークロードアイデンティティプールの名前"
    echo "  --location              省略可能: ロケーション (デフォルト: global)"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-provider my-project-id my-pool"
    echo "  ${func_name} my-provider my-project-id my-pool --location=us-central1"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/providers/delete"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: PROVIDER が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$3" ]]; then
    echo "[ERROR] ${func_name}: WORKLOAD_IDENTITY_POOL が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local provider="$1"
  local project_id="$2"
  local pool_id="$3"
  local location="global"

  # オプションの解析
  shift 3
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --location=*)
        location="${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # 削除の確認
  # read -p "[INFO] ${func_name}: プロバイダー '${provider}' を削除しますか？ (y/n): " confirm
  # if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
  #   echo "[INFO] ${func_name}: 削除をキャンセルしました。"
  #   return 0
  # fi

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam workload-identity-pools providers delete ${provider} --project=${project_id} --workload-identity-pool=${pool_id} --location=${location} --quiet"

  # コマンド実行
  echo ""
  echo "======= Workload Identity Pool Providers ==================================================================="
  if ! gcloud iam workload-identity-pools providers delete "${provider}" \
       --project="${project_id}" \
       --workload-identity-pool="${pool_id}" \
       --location="${location}" \
       --quiet; then
    echo "[ERROR] ${func_name}: プロバイダー '${provider}' の削除に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "Workload Identity Pool Providerを削除できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: プロバイダー '${provider}' を正常に削除しました。"
  send_discord_notification_about_gciam "削除したよ！" "Workload Identity Pool Providerを削除したよ！（復元したかったらundeleteしてね。）" "green"
  return 0
}

# ワークロードアイデンティティプールのプロバイダーを復元する関数
function undelete_workload_identity_pool_provider() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "OIDC Workload Identity Pool Providerを復元するよ！"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <PROVIDER> <PROJECT_ID> <WORKLOAD_IDENTITY_POOL> [--location=LOCATION]"
    echo ""
    echo "引数:"
    echo "  PROVIDER                復元するプロバイダーの名前"
    echo "  PROJECT_ID              Google CloudプロジェクトのプロジェクトID"
    echo "  WORKLOAD_IDENTITY_POOL  プロバイダーが所属するワークロードアイデンティティプールの名前"
    echo "  --location              省略可能: ロケーション (デフォルト: global)"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-provider my-project-id my-pool"
    echo "  ${func_name} my-provider my-project-id my-pool --location=us-central1"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/providers/undelete"
    return 0
  fi

  # パラメータのバリデーション
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: PROVIDER が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: PROJECT_ID が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  if [[ -z "$3" ]]; then
    echo "[ERROR] ${func_name}: WORKLOAD_IDENTITY_POOL が指定されていません。" >&2
    echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
    return 1
  fi

  local provider="$1"
  local project_id="$2"
  local pool_id="$3"
  local location="global"

  # オプションの解析
  shift 3
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --location=*)
        location="${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1" >&2
        echo "[ERROR] ${func_name}: 使用方法を確認するには --help を使用してください。" >&2
        return 1
        ;;
    esac
  done

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行するコマンド: gcloud iam workload-identity-pools providers undelete ${provider} --project=${project_id} --workload-identity-pool=${pool_id} --location=${location}"

  # コマンド実行
  echo ""
  echo "======= Workload Identity Pool Providers ==================================================================="
  if ! gcloud iam workload-identity-pools providers undelete "${provider}" \
       --project="${project_id}" \
       --workload-identity-pool="${pool_id}" \
       --location="${location}"; then
    echo "[ERROR] ${func_name}: プロバイダー '${provider}' の復元に失敗しました。" >&2
    send_discord_notification_about_gciam "失敗…" "OIDC Workload Identity Pool Providerを復元できなかったよ…" "red"
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${func_name}: プロバイダー '${provider}' を正常に復元しました。"
  send_discord_notification_about_gciam "復元したよ！" "OIDC Workload Identity Pool Providerを復元したよ！" "green"
  return 0
}

#==============================================================#
##     Workload Identity Federation Main Process              ##
#==============================================================#
# Google Cloud Workload Identity Federation セットアップ関数
function setup_workload_identity_federation() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <PROJECT_ID> <POOL_ID> <PROVIDER_ID> <SERVICE_ACCOUNT_ID> <REPO_OWNER> <REPO_NAME> [LOCATION] [POOL_DESCRIPTION]"
    echo ""
    echo "引数:"
    echo "  PROJECT_ID           Google CloudプロジェクトのプロジェクトID"
    echo "  POOL_ID              作成するWorkload Identity PoolのID"
    echo "  PROVIDER_ID          作成するOIDCプロバイダーのID"
    echo "  SERVICE_ACCOUNT_ID   作成するサービスアカウントのID"
    echo "  REPO_OWNER           GitHubリポジトリのオーナー名（組織名またはユーザー名）"
    echo "  REPO_NAME            GitHubリポジトリの名前"
    echo "  LOCATION             省略可能: ロケーション (デフォルト: global)"
    echo "  POOL_DESCRIPTION     省略可能: Workload Identity Poolの説明"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-project my-pool github-provider my-service-account my-org my-repo"
    echo "  ${func_name} my-project my-pool github-provider my-service-account my-org my-repo global \"GitHub Actions用プール\""
    echo ""
    echo "説明:"
    echo "  この関数は以下のリソースを作成します:"
    echo "  - Workload Identity Pool"
    echo "  - GitHub Actions用OIDCプロバイダー"
    echo "  - サービスアカウント"
    echo "  - IAMポリシーバインディング (monitoring.editor, run.viewer)"
    echo "  - Workload Identityバインディング"
    return 0
  fi

  # 引数の取得とローカル変数への代入
  local project_id="$1"
  local pool_id="$2"
  local provider_id="$3"
  local service_account_id="$4"
  local repo_owner="$5"
  local repo_name="$6"
  local location="${7:-global}"
  local pool_description="$8"

  # 引数の妥当性チェック
  if [[ -z "$project_id" || -z "$pool_id" || -z "$provider_id" || -z "$service_account_id" || -z "$repo_owner" || -z "$repo_name" ]]; then
      echo "エラー: 必須引数が不足しています" >&2
      echo "使用方法: setup_workload_identity_federation PROJECT_ID POOL_ID PROVIDER_ID SERVICE_ACCOUNT_ID REPO_OWNER REPO_NAME [LOCATION] [POOL_DESCRIPTION]" >&2
      echo "詳細な使用方法を確認するには --help を使用してください。" >&2
      return 1
  fi

  # エラー時に関数を終了
  set -e

  echo "=== Google Cloud Workload Identity Federation セットアップ開始 ==="
  echo "プロジェクト: $project_id"
  echo "リポジトリ: $repo_owner/$repo_name"
  echo "ロケーション: $location"
  echo

  # 1. Workload Identity Pool作成
  echo "1. Workload Identity Poolを作成中..."
  if [[ -n "$pool_description" ]]; then
      create_workload_identity_pool "$pool_id" "$project_id" --location="$location" --description="$pool_description"
  else
      create_workload_identity_pool "$pool_id" "$project_id" --location="$location"
  fi
  echo "✓ Workload Identity Pool作成完了"
  echo

  # 2. GitHub Actions用OIDCプロバイダー作成
  echo "2. GitHub Actions用OIDCプロバイダーを作成中..."
  create_oidc_workload_identity_pool_provider_for_github_actions "$provider_id" "$project_id" "$pool_id" "$repo_owner" --location="$location"
  echo "✓ OIDCプロバイダー作成完了"
  echo

  # 3. サービスアカウント作成
  echo "3. サービスアカウントを作成中..."
  create_gcloud_service_account "$service_account_id" "$project_id" "roles/monitoring.editor"
  echo "✓ サービスアカウント作成完了"
  echo

  # 4. IAMポリシーバインディング追加
  echo "4. IAMポリシーバインディングを追加中 (monitoring.editor)..."
  add_iam_policy_binding_to_project_on_gcloud "$project_id" "$service_account_id" "roles/monitoring.editor"
  echo "✓ monitoring.editor権限追加完了"

  echo "5. IAMポリシーバインディングを追加中 (run.viewer)..."
  add_iam_policy_binding_to_project_on_gcloud "$project_id" "$service_account_id" "roles/run.viewer"
  echo "✓ run.viewer権限追加完了"

  # 6. プロジェクト番号取得
  echo "6. プロジェクト番号を取得中..."
  local project_number
  project_number=$(gcloud projects describe "$project_id" --format="value(projectNumber)")
  echo "✓ プロジェクト番号: $project_number"
  echo

  # 7. Workload Identityバインディング追加
  echo "7. Workload Identityバインディングを追加中..."
  local service_account_email="${service_account_id}@${project_id}.iam.gserviceaccount.com"
  add_workload_identity_binding_to_service_account_on_gcloud "$service_account_email" "$project_number" "$pool_id" "$repo_owner" "$repo_name" --provider-id="$provider_id"
  echo "✓ Workload Identityバインディング追加完了"
  echo

  # セットアップ完了
  echo "=== Workload Identity Federationのセットアップが完了しました！ ==="
  echo

  # 秘匿情報なので一旦コメントアウトしておく。
  # echo "GitHub Secretsに以下の値を設定してください:"
  # echo "GCLOUD_PROJECT_NUMBER: $project_number"
  # echo "GCLOUD_POOL_ID: $pool_id"
  # echo "GCLOUD_PROVIDER_ID: $provider_id"
  # echo "GCLOUD_SERVICE_ACCOUNT_EMAIL: $service_account_email"
  # echo

  # エラーハンドリングを元に戻す
  set +e
}

# Google Cloud Workload Identity Federation リソース削除関数
function cleanup_workload_identity_federation() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <PROJECT_ID> <POOL_ID> <PROVIDER_ID> <SERVICE_ACCOUNT_ID> [LOCATION]"
    echo ""
    echo "引数:"
    echo "  PROJECT_ID           Google CloudプロジェクトのプロジェクトID"
    echo "  POOL_ID              削除するWorkload Identity PoolのID"
    echo "  PROVIDER_ID          削除するOIDCプロバイダーのID"
    echo "  SERVICE_ACCOUNT_ID   削除するサービスアカウントのID"
    echo "  LOCATION             省略可能: ロケーション (デフォルト: global)"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-project my-pool github-provider my-service-account"
    echo "  ${func_name} my-project my-pool github-provider my-service-account global"
    echo ""
    echo "説明:"
    echo "  この関数は以下のリソースを削除します:"
    echo "  - OIDC Provider"
    echo "  - Workload Identity Pool"
    echo "  - Service Account"
    echo "  - IAM Policy Bindings (自動削除)"
    echo ""
    echo "注意:"
    echo "  削除されたリソースは復元可能ですが、一定期間後に完全に削除されます。"
    echo "  削除前に確認プロンプトが表示されます。"
    return 0
  fi

  # 引数の取得とローカル変数への代入
  local project_id="$1"
  local pool_id="$2"
  local provider_id="$3"
  local service_account_id="$4"
  local location="${5:-global}"
  local service_account_email="${service_account_id}@${project_id}.iam.gserviceaccount.com"

  # 引数の妥当性チェック
  if [[ -z "$project_id" || -z "$pool_id" || -z "$provider_id" || -z "$service_account_id" ]]; then
      echo "エラー: 必須引数が不足しています" >&2
      echo "使用方法: cleanup_workload_identity_federation PROJECT_ID POOL_ID PROVIDER_ID SERVICE_ACCOUNT_ID [LOCATION]" >&2
      echo "詳細な使用方法を確認するには --help を使用してください。" >&2
      return 1
  fi

  echo "=== Google Cloud Workload Identity Federation リソース削除開始 ==="
  echo "プロジェクト: $project_id"
  echo "ロケーション: $location"
  echo
  echo "警告: 以下のリソースが削除されます:"
  echo "- Workload Identity Pool: $pool_id"
  echo "- OIDC Provider: $provider_id"
  echo "- Service Account: $service_account_email"
  echo "- IAM Policy Bindings (自動削除)"
  echo
  read -p "続行しますか？ (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "削除をキャンセルしました。"
      return 0
  fi
  echo

  # エラーが発生しても処理を継続
  set +e

  # 1. OIDCプロバイダー削除
  echo "1. OIDCプロバイダーを削除中..."
  delete_workload_identity_pool_provider "$provider_id" "$project_id" "$pool_id" --location="$location"
  echo "✓ OIDCプロバイダー削除処理完了"
  echo

  # 2. Workload Identity Pool削除
  echo "2. Workload Identity Poolを削除中..."
  delete_workload_identity_pool "$pool_id" "$project_id" --location="$location"
  echo "✓ Workload Identity Pool削除処理完了"
  echo

  # 3. サービスアカウント削除
  echo "3. サービスアカウントを削除中..."
  delete_gcloud_service_account "$service_account_email"
  echo "✓ サービスアカウント削除処理完了"
  echo

  # 削除完了
  echo "=== Workload Identity Federationリソースの削除が完了しました！ ==="
  echo "注意: 一部のリソースが削除できなかった場合は、手動で確認してください。"
  echo "IAMポリシーバインディングは自動的に削除されます。"
  echo

  # エラーハンドリングを元に戻す
  set -e
}
