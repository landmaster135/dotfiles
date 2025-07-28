#!/bin/sh
#==============================================================#
##         Document AI                                        ##
#==============================================================#

# NOT usable
function undeploy_processor_version_on_gcloud() {
  local func_name="${FUNCNAME[0]}"
  local region=""
  local project_number=""
  local processor_id=""
  local deploy_version_id=""
  local help=false

  # ヘルプメッセージ表示関数
  function display_help() {
    echo "[INFO] ${func_name}: 使用方法:"
    echo "  ${func_name} --region <REGION> --project-number <PROJECT_NUMBER> --processor-id <PROCESSOR_ID> --version-id <DEPLOY_VERSION_ID>"
    echo ""
    echo "パラメータ:"
    echo "  --region          : Document AIのリージョン (例: us-central1)"
    echo "  --project-number  : Google Cloudプロジェクト番号"
    echo "  --processor-id    : Document AIプロセッサID"
    echo "  --version-id      : アンデプロイするプロセッサのバージョンID"
    echo "  --help            : このヘルプメッセージを表示"
    echo ""
    echo "使用例:"
    echo "  ${func_name} --region us-central1 --project-number 123456789 --processor-id abc123def456 --version-id 123456789"
    echo ""
  }

  # パラメータがない場合はヘルプを表示
  if [ $# -eq 0 ]; then
    display_help
    return 1
  fi

  # パラメータの解析
  while [ $# -gt 0 ]; do
    case "$1" in
      --region)
        region="$2"
        shift 2
        ;;
      --project-number)
        project_number="$2"
        shift 2
        ;;
      --processor-id)
        processor_id="$2"
        shift 2
        ;;
      --version-id)
        deploy_version_id="$2"
        shift 2
        ;;
      --help)
        help=true
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ: $1"
        display_help
        return 1
        ;;
    esac
  done

  # ヘルプフラグが立っている場合はヘルプを表示して終了
  if [ "$help" = true ]; then
    display_help
    return 0
  fi

  # 必須パラメータのチェック
  if [ -z "$region" ]; then
    echo "[ERROR] ${func_name}: リージョンが指定されていません"
    display_help
    return 1
  fi

  if [ -z "$project_number" ]; then
    echo "[ERROR] ${func_name}: プロジェクト番号が指定されていません"
    display_help
    return 1
  fi

  if [ -z "$processor_id" ]; then
    echo "[ERROR] ${func_name}: プロセッサIDが指定されていません"
    display_help
    return 1
  fi

  if [ -z "$deploy_version_id" ]; then
    echo "[ERROR] ${func_name}: バージョンIDが指定されていません"
    display_help
    return 1
  fi

  # APIエンドポイントの構築
  local endpoint="https://${region}-documentai.googleapis.com/v1beta3/${project_number}/locations/${region}/processors/${processor_id}/processorVersions/${deploy_version_id}:undeploy"

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行コマンド: curl -X POST -H \"Authorization: Bearer \$(gcloud auth print-access-token)\" -H \"Content-Type: application/json\" \"${endpoint}\""

  # APIリクエストの実行
  local response
  response=$(curl -s -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    "${endpoint}" 2>&1)

  local status_code=$?

  # curlコマンドの実行結果を確認
  if [ $status_code -ne 0 ]; then
    echo "[ERROR] ${func_name}: APIリクエストの実行に失敗しました: ${response}"
    return $status_code
  fi

  # HTTPレスポンスにエラーがあるか確認
  if echo "$response" | grep -q "error"; then
    echo "[ERROR] ${func_name}: APIがエラーを返しました: ${response}"
    return 1
  fi

  echo "[INFO] ${func_name}: プロセッサバージョンのアンデプロイが開始されました"
  echo "[INFO] ${func_name}: レスポンス: ${response}"
  return 0
}
