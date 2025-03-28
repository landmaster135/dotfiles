#!/bin/sh
function list_deployments() {
    local FUNC_NAME="list_deployments"
    local PROJECT=""
    local FILTER=""
    local FORMAT="table(name,insertTime,operation.operationType,operation.status,description)"
    local LIMIT=""
    local SIMPLE=false
    local SHOW_COMMAND=false

    # ヘルプ表示
    if [[ "$1" == "--help" ]]; then
      echo "[INFO] ${FUNC_NAME}: GCP Deployment Managerのデプロイメント一覧を表示します"
      echo ""
      echo "使用方法:"
      echo "  ${FUNC_NAME} [オプション]"
      echo ""
      echo "オプション:"
      echo "  --project=<PROJECT_ID>   特定のプロジェクトのデプロイメントを表示します"
      echo "  --filter=<FILTER>        結果をフィルタリングします"
      echo "  --format=<FORMAT>        出力フォーマットを指定します"
      echo "  --limit=<NUM>            結果の最大表示数を設定します"
      echo "  --simple                 シンプルな出力フォーマットで表示します"
      echo "  --show-command           実行するコマンドを表示します"
      echo "  --help                   このヘルプメッセージを表示します"
      echo ""
      echo "使用例:"
      echo "  ${FUNC_NAME}"
      echo "  ${FUNC_NAME} --project=my-project"
      echo "  ${FUNC_NAME} --filter=\"name:my-deployment*\""
      echo "  ${FUNC_NAME} --simple --limit=5"
      return 0
    fi

    # パラメータ解析
    for i in "$@"; do
      case $i in
        --project=*)
          PROJECT="${i#*=}"
          ;;
        --filter=*)
          FILTER="${i#*=}"
          ;;
        --format=*)
          FORMAT="${i#*=}"
          ;;
        --limit=*)
          LIMIT="${i#*=}"
          ;;
        --simple)
          SIMPLE=true
          FORMAT="table(name,insertTime)"
          ;;
        --show-command)
          SHOW_COMMAND=true
          ;;
        --help)
          # すでに上で処理されているのでスキップ
          ;;
        *)
          echo "[ERROR] ${FUNC_NAME}: 不明なオプション: $i"
          echo "[INFO] ${FUNC_NAME}: 使用方法を表示するには --help を使用してください"
          return 1
          ;;
      esac
    done

    # gcloudコマンドの存在確認
    if ! command -v gcloud &> /dev/null; then
      echo "[ERROR] ${FUNC_NAME}: gcloudコマンドが見つかりません。Google Cloud SDKがインストールされているか確認してください"
      return 1
    fi

    # コマンド構築
    local CMD="gcloud deployment-manager deployments list"

    if [[ -n "$PROJECT" ]]; then
      CMD="$CMD --project=$PROJECT"
    fi

    if [[ -n "$FILTER" ]]; then
      CMD="$CMD --filter=\"$FILTER\""
    fi

    if [[ -n "$FORMAT" ]]; then
      CMD="$CMD --format=\"$FORMAT\""
    fi

    if [[ -n "$LIMIT" ]]; then
      CMD="$CMD --limit=$LIMIT"
    fi

    # コマンド表示（--show-commandオプションが指定された場合のみ）
    if [[ "$SHOW_COMMAND" == true ]]; then
      echo "[INFO] ${FUNC_NAME}: 実行コマンド: $CMD"
    fi

    # コマンド実行
    if [[ -n "$FILTER" || -n "$FORMAT" ]]; then
      # 引用符を含むオプションはevalを使用
      eval $CMD
    else
      # 単純なコマンドは直接実行
      $CMD
    fi

    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
      echo "[ERROR] ${FUNC_NAME}: デプロイメント一覧の取得に失敗しました (終了コード: $EXIT_CODE)"
      return 1
    fi

    echo "[INFO] ${FUNC_NAME}: デプロイメント一覧の取得が完了しました"
    return 0
}
