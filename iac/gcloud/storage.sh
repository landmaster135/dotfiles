#!/bin/sh
function upload_files_to_gcs() {
  local FUNC_NAME=${FUNCNAME[0]}
  send_discord_notification "ファイルをアップロードするよ！"

  # --helpパラメータが渡された場合は利用方法を表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: upload_to_gcs <local_directory> <gs_bucket_url>"
    echo "[INFO] ${FUNC_NAME}: Example: upload_to_gcs /path/to/local/directory gs://your-bucket-name/"
    echo "[INFO] ${func_name}: Detail of gsutil is here: https://cloud.google.com/storage/docs/gsutil/addlhelp/GlobalCommandLineOptions?hl=ja"
    return 0
  fi

  # 引数の数をチェック（ローカルディレクトリとバケットURLの2つが必要）
  if [[ "$#" -ne 2 ]]; then
    echo "[ERROR] ${FUNC_NAME}: Invalid number of parameters."
    echo "[INFO] ${FUNC_NAME}: Usage: upload_to_gcs <local_directory> <gs_bucket_url>"
    return 1
  fi

  local local_dir="$1"
  local bucket_url="$2"

  # ローカルディレクトリの存在をチェック
  if [[ ! -d "${local_dir}" ]]; then
    echo "[ERROR] ${FUNC_NAME}: Local directory '${local_dir}' does not exist."
    return 1
  fi

  # アップロード開始の情報メッセージ
  echo "[INFO] ${FUNC_NAME}: Starting upload from '${local_dir}' to '${bucket_url}'..."

  # gsutilコマンドを実行（-mオプションで並列実行、-rオプションで再帰的コピー）
  gsutil -m cp -r "${local_dir}" "${bucket_url}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gcs "失敗…" "ファイルのアップロードに失敗したよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Failed to upload files."
    return 1
  fi

  send_discord_notification_about_gcs "アップしたよ！" "ファイルをアップロードしたよ！" "green"
  echo "[INFO] ${FUNC_NAME}: Upload completed successfully."
  return 0
}

function download_from_gcs_files() {
  local FUNC_NAME=${FUNCNAME[0]}
  send_discord_notification "ファイルをダウンロードするよ！"

  # --helpパラメータが渡された場合は利用方法を表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: download_from_gcs_files <gs_file1> [<gs_file2> ...] <local_directory>"
    echo "[INFO] ${FUNC_NAME}: Example: download_from_gcs_files gs://your-bucket-name/file1 gs://your-bucket-name/file2 gs://your-bucket-name/file3 /path/to/local/directory"
    echo "[INFO] ${func_name}: Detail of gsutil is here: https://cloud.google.com/storage/docs/gsutil/addlhelp/GlobalCommandLineOptions?hl=ja"
    return 0
  fi

  # 引数が2つ以上あるかチェック（最低1つのgsファイルと1つのローカルディレクトリが必要）
  if [[ "$#" -lt 2 ]]; then
    echo "[ERROR] ${FUNC_NAME}: Invalid number of parameters."
    echo "[INFO] ${FUNC_NAME}: Usage: download_from_gcs_files <gs_file1> [<gs_file2> ...] <local_directory>"
    return 1
  fi

  # 最後の引数をローカルディレクトリとして取得し、残りをgsファイルのリストとする
  local dest_dir="${!#}"
  local sources=("${@:1:$(($#-1))}")

  # ローカルディレクトリの存在チェック
  if [[ ! -d "${dest_dir}" ]]; then
    echo "[ERROR] ${FUNC_NAME}: Destination directory '${dest_dir}' does not exist."
    return 1
  fi

  echo "[INFO] ${FUNC_NAME}: Starting download of ${#sources[@]} file(s) to '${dest_dir}'..."

  # gsutilコマンドを実行（-mオプションで並列実行）
  gsutil -m cp "${sources[@]}" "${dest_dir}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gcs "失敗…" "ファイルのダウンロードに失敗したよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Failed to download files."
    return 1
  fi

  send_discord_notification_about_gcs "ダウンロードしたよ！" "ファイルをダウンロードしたよ！" "green"
  echo "[INFO] ${FUNC_NAME}: Download completed successfully."
  return 0
}

function create_bucket_on_gcs() {
  local FUNC_NAME=${FUNCNAME[0]}
  send_discord_notification "バケットを作るよ！"

  # --helpパラメータが渡された場合は利用方法を表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: create_bucket <gs_bucket_url> <storage_class> <location>"
    echo "[INFO] ${FUNC_NAME}: Example: create_bucket gs://your-new-bucket-name/ STANDARD US"
    echo "[INFO] ${func_name}: Detail of gsutil is here: https://cloud.google.com/storage/docs/gsutil/addlhelp/GlobalCommandLineOptions?hl=ja"
    return 0
  fi

  # パラメータ数チェック（バケットURL、ストレージクラス、ロケーションの3つが必要）
  if [[ "$#" -ne 3 ]]; then
    echo "[ERROR] ${FUNC_NAME}: Invalid number of parameters."
    echo "[INFO] ${FUNC_NAME}: Usage: create_bucket <gs_bucket_url> <storage_class> <location>"
    return 1
  fi

  local bucket_url="$1"
  local storage_class="$2"
  local location="$3"

  echo "[INFO] ${FUNC_NAME}: Creating bucket '${bucket_url}' with storage class '${storage_class}' and location '${location}'..."

  # gsutil mbコマンドでバケット作成（-cでストレージクラス、-lでロケーション指定）
  gsutil mb -c "${storage_class}" -l "${location}" "${bucket_url}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gcs "失敗…" "バケットを作れなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Failed to create bucket '${bucket_url}'."
    return 1
  fi

  send_discord_notification_about_gcs "作ったよ！" "バケットを作ったよ！" "green"
  echo "[INFO] ${FUNC_NAME}: Bucket '${bucket_url}' created successfully."
  return 0
}

function list_contents_in_gcs() {
  local FUNC_NAME=${FUNCNAME[0]}
  send_discord_notification "バケットのリストかファイルの詳細を並べるよ！"

  # --helpパラメータが渡された場合は利用方法を表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: list_contents <target_path>"
    echo "[INFO] ${FUNC_NAME}: Example 1 (GCS bucket/folder): list_contents gs://your-bucket-name/"
    echo "[INFO] ${func_name}: Detail of gsutil is here: https://cloud.google.com/storage/docs/gsutil/addlhelp/GlobalCommandLineOptions?hl=ja"
    return 0
  fi

  # 引数が1つであることをチェック
  if [[ "$#" -ne 1 ]]; then
    echo "[ERROR] ${FUNC_NAME}: Invalid number of parameters."
    echo "[INFO] ${FUNC_NAME}: Usage: list_contents <target_path>"
    return 1
  fi

  local target="$1"

  echo "[INFO] ${FUNC_NAME}: Listing contents of '${target}'..."

  # 対象がGCSの場合はgsutil ls、それ以外はローカルのlsコマンドを使用
  if [[ "${target}" == gs://* ]]; then
    gsutil ls "${target}"
    if [[ "$?" -ne 0 ]]; then
      send_discord_notification_about_gcs "失敗…" "バケットとファイルを取れなかったよ…" "red"
      echo "[ERROR] ${FUNC_NAME}: Failed to list contents of '${target}'."
      return 1
    fi
  else
    ls "${target}"
    if [[ "$?" -ne 0 ]]; then
      send_discord_notification_about_gcs "失敗…" "バケットとファイルを取れなかったよ…" "red"
      echo "[ERROR] ${FUNC_NAME}: Failed to list contents of '${target}'."
      return 1
    fi
  fi

  send_discord_notification_about_gcs "並べたよ！" "バケットとファイルのリストを並べたよ！" "green"
  return 0
}

function show_detail_of_bucket_or_object_in_gcs() {
  local FUNC_NAME=${FUNCNAME[0]}
  send_discord_notification "バケットかオブジェクトの詳細を並べるよ！"

  # --helpパラメータが渡された場合は利用方法を表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: show_gcs_details <gs_path>"
    echo "[INFO] ${FUNC_NAME}: Example 1 (bucket details): show_gcs_details gs://your-bucket-name/"
    echo "[INFO] ${FUNC_NAME}: Example 2 (object details): show_gcs_details gs://your-bucket-name/path/to/object"
    echo "[INFO] ${func_name}: Detail of gsutil is here: https://cloud.google.com/storage/docs/gsutil/addlhelp/GlobalCommandLineOptions?hl=ja"
    return 0
  fi

  # 引数が1つであることをチェック
  if [[ "$#" -ne 1 ]]; then
    echo "[ERROR] ${FUNC_NAME}: Invalid number of parameters."
    echo "[INFO] ${FUNC_NAME}: Usage: show_gcs_details <gs_path>"
    return 1
  fi

  local target="$1"

  # 対象が Cloud Storage のパスかチェック
  if [[ "${target}" != gs://* ]]; then
    echo "[ERROR] ${FUNC_NAME}: The target must be a Cloud Storage path (gs://)."
    return 1
  fi

  echo "[INFO] ${FUNC_NAME}: Displaying details for '${target}'..."

  # バケットかどうかの判定（gs://の後にスラッシュが無い、または末尾がスラッシュのみの場合）
  if [[ "${target}" =~ ^gs://[^/]+/?$ ]]; then
    # バケットの場合は bucket metadata を表示
    echo "[INFO] ${FUNC_NAME}: '${target}' is a bucket."
    gsutil ls -Lb "${target}"
    if [[ "$?" -ne 0 ]]; then
      send_discord_notification_about_gcs "失敗…" "バケットとオブジェクトを取れなかったよ…" "red"
      echo "[ERROR] ${FUNC_NAME}: Failed to display bucket details for '${target}'."
      return 1
    fi
  else
    # オブジェクトやフォルダの場合はオブジェクト詳細を表示
    echo "[INFO] ${FUNC_NAME}: '${target}' is an object."
    gsutil ls -L "${target}"
    if [[ "$?" -ne 0 ]]; then
      send_discord_notification_about_gcs "失敗…" "バケットとオブジェクトを取れなかったよ…" "red"
      echo "[ERROR] ${FUNC_NAME}: Failed to display object details for '${target}'."
      return 1
    fi
  fi

  send_discord_notification_about_gcs "表示したよ！" "バケットかオブジェクトの詳細を表示したよ！" "green"
  return 0
}

function list_details_of_buckets_or_objects_in_gcs() {
  local FUNC_NAME=${FUNCNAME[0]}
  send_discord_notification "バケットかオブジェクトの詳細を並べるよ！"

  # --helpパラメータが渡された場合は利用方法を表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: show_gcs_details <gs_path>"
    echo "[INFO] ${FUNC_NAME}: Example 1 (bucket details): show_gcs_details gs://your-bucket-name/"
    echo "[INFO] ${FUNC_NAME}: Example 2 (object details): show_gcs_details gs://your-bucket-name/path/to/object"
    echo "[INFO] ${func_name}: Detail of gsutil is here: https://cloud.google.com/storage/docs/gsutil/addlhelp/GlobalCommandLineOptions?hl=ja"
    return 0
  fi

  # 引数が1つであることをチェック
  if [[ "$#" -ne 1 ]]; then
    echo "[ERROR] ${FUNC_NAME}: Invalid number of parameters."
    echo "[INFO] ${FUNC_NAME}: Usage: show_gcs_details <gs_path>"
    return 1
  fi

  local target="$1"

  # 対象が Cloud Storage のパスかチェック
  if [[ "${target}" != gs://* ]]; then
    echo "[ERROR] ${FUNC_NAME}: The target must be a Cloud Storage path (gs://)."
    return 1
  fi

  echo "[INFO] ${FUNC_NAME}: Displaying details for '${target}'..."

  # バケットかどうかの判定（gs://の後にスラッシュが無い、または末尾がスラッシュのみの場合）
  if [[ "${target}" =~ ^gs://[^/]+/?$ ]]; then
    # バケットの場合は bucket metadata を表示
    echo "[INFO] ${FUNC_NAME}: '${target}' is a bucket."
    gsutil ls "${target}"
    if [[ "$?" -ne 0 ]]; then
      send_discord_notification_about_gcs "失敗…" "バケットとオブジェクトを取れなかったよ…" "red"
      echo "[ERROR] ${FUNC_NAME}: Failed to display bucket details for '${target}'."
      return 1
    fi
  else
    # フォルダの場合は配下のオブジェクトの物理名の一覧を表示、オブジェクトの場合はそのオブジェクトの物理名だけを表示
    echo "[INFO] ${FUNC_NAME}: '${target}' is an object."
    gsutil ls "${target}"
    if [[ "$?" -ne 0 ]]; then
      send_discord_notification_about_gcs "失敗…" "バケットとオブジェクトを取れなかったよ…" "red"
      echo "[ERROR] ${FUNC_NAME}: Failed to display object details for '${target}'."
      return 1
    fi
  fi

  send_discord_notification_about_gcs "表示したよ！" "バケットかオブジェクトの詳細を表示したよ！" "green"
  return 0
}

function delete_objects_or_folders_in_gcs() {
  local FUNC_NAME=${FUNCNAME[0]}
  send_discord_notification "フォルダもしくはオブジェクトを削除するよ！"

  # --helpパラメータが渡された場合は利用方法を表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: delete_gcs_object <gs_object_path>"
    echo "[INFO] ${FUNC_NAME}: Example: delete_gcs_object gs://your-bucket-name/path/to/object"
    echo "[INFO] ${func_name}: Detail of gsutil is here: https://cloud.google.com/storage/docs/gsutil/addlhelp/GlobalCommandLineOptions?hl=ja"
    return 0
  fi

  # 引数の数をチェック（オブジェクトパスが1つ必要）
  if [[ "$#" -ne 1 ]]; then
    echo "[ERROR] ${FUNC_NAME}: Invalid number of parameters."
    echo "[INFO] ${FUNC_NAME}: Usage: delete_gcs_object <gs_object_path>"
    return 1
  fi

  local object_path="$1"

  # Cloud Storageのパスかチェック
  if [[ "${object_path}" != gs://* ]]; then
    send_discord_notification_about_gcs "失敗…" "フォルダもしくはオブジェクトを削除できなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: The target must be a Cloud Storage object path (gs://)."
    return 1
  fi

  echo "[INFO] ${FUNC_NAME}: Deleting object '${object_path}'..."

  # gsutil rmコマンドでオブジェクトを削除
  gsutil rm "${object_path}"
  if [[ "$?" -ne 0 ]]; then
    echo "[ERROR] ${FUNC_NAME}: Failed to delete object '${object_path}'."
    return 1
  fi

  send_discord_notification_about_gcs "削除したよ！" "フォルダもしくはオブジェクトを削除したよ！" "green"
  echo "[INFO] ${FUNC_NAME}: Object '${object_path}' deleted successfully."
  return 0
}

function get_gcs_acl() {
  local FUNC_NAME=${FUNCNAME[0]}
  send_discord_notification "ACLを確認するよ！"

  # --helpパラメータが渡された場合は利用方法を表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: **Notice**: 'gsutil acl get' cannot get legacy ACL for an object when uniform bucket-level access is enabled. More detail is here: https://cloud.google.com/storage/docs/uniform-bucket-level-access?hl=ja"
    echo "[INFO] ${FUNC_NAME}: Usage: get_gcs_acl <gs_path>"
    echo "[INFO] ${FUNC_NAME}: Example: get_gcs_acl gs://your-bucket-name/path/to/object"
    echo "[INFO] ${func_name}: Detail of gsutil is here: https://cloud.google.com/storage/docs/gsutil/addlhelp/GlobalCommandLineOptions?hl=ja"
    return 0
  fi

  # 引数が1つであることをチェック
  if [[ "$#" -ne 1 ]]; then
    echo "[ERROR] ${FUNC_NAME}: Invalid number of parameters."
    echo "[INFO] ${FUNC_NAME}: Usage: get_gcs_acl <gs_path>"
      return 1
  fi

  local target="$1"

  # 対象が Cloud Storage のパスかチェック
  if [[ "${target}" != gs://* ]]; then
    echo "[ERROR] ${FUNC_NAME}: The target must be a Cloud Storage path (gs://)."
    return 1
  fi

  echo "[INFO] ${FUNC_NAME}: Retrieving ACL for '${target}'..."

  # gsutil acl get コマンドで対象のACLを取得
  gsutil acl get "${target}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gcs "失敗…" "ACLを確認できなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Failed to retrieve ACL for '${target}'."
    return 1
  fi

  send_discord_notification_about_gcs "権限を取得したよ！" "ACLを確認したよ！" "green"
  echo "[INFO] ${FUNC_NAME}: ACL retrieved successfully."
  return 0
}

function set_gcs_acl() {
  local FUNC_NAME=${FUNCNAME[0]}
  send_discord_notification "ACLを設定するよ！"

  # --helpパラメータが渡された場合は利用方法を表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: set_gcs_acl <acl_file> <gs_path>"
    echo "[INFO] ${FUNC_NAME}: Example: set_gcs_acl myacl.xml gs://your-bucket-name/path/to/object"
    echo "[INFO] ${func_name}: Detail of gsutil is here: https://cloud.google.com/storage/docs/gsutil/addlhelp/GlobalCommandLineOptions?hl=ja"
    return 0
  fi

  # パラメータ数のチェック（ACLファイルとCloud Storageパスの2つが必要）
  if [[ "$#" -ne 2 ]]; then
    echo "[ERROR] ${FUNC_NAME}: Invalid number of parameters."
    echo "[INFO] ${FUNC_NAME}: Usage: set_gcs_acl <acl_file> <gs_path>"
    return 1
  fi

  local acl_file="$1"
  local target="$2"

  # ACLファイルの存在チェック
  if [[ ! -f "${acl_file}" ]]; then
    echo "[ERROR] ${FUNC_NAME}: ACL file '${acl_file}' does not exist."
    return 1
  fi

  # 対象がCloud Storageのパスかチェック
  if [[ "${target}" != gs://* ]]; then
    echo "[ERROR] ${FUNC_NAME}: The target must be a Cloud Storage path (gs://)."
    return 1
  fi

  echo "[INFO] ${FUNC_NAME}: Setting ACL from file '${acl_file}' for '${target}'..."

  # gsutil acl setコマンドでACLを設定
  gsutil acl set "${acl_file}" "${target}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gcs "失敗…" "ACLを設定できなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Failed to set ACL for '${target}'."
    return 1
  fi

  send_discord_notification_about_gcs "権限を設定したよ！" "ACLを設定したよ！" "green"
  echo "[INFO] ${FUNC_NAME}: ACL set successfully for '${target}'."
  return 0
}

function grant_read_authority_for_all_on_acl_of_gcs() {
  local FUNC_NAME=${FUNCNAME[0]}
  send_discord_notification "ACLを全てのユーザに付与するよ！"

  # --helpパラメータが渡された場合は利用方法を表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: grant_read_all <gs_path>"
    echo "[INFO] ${FUNC_NAME}: Example: grant_read_all gs://your-bucket-name/path/to/object"
    echo "[INFO] ${func_name}: Detail of gsutil is here: https://cloud.google.com/storage/docs/gsutil/addlhelp/GlobalCommandLineOptions?hl=ja"
    return 0
  fi

  # 引数の数をチェック（対象のCloud Storageパスが1つ必要）
  if [[ "$#" -ne 1 ]]; then
    echo "[ERROR] ${FUNC_NAME}: Invalid number of parameters."
    echo "[INFO] ${FUNC_NAME}: Usage: grant_read_all <gs_path>"
    return 1
  fi

  local target="$1"

  # 対象がCloud Storageのパスかチェック
  if [[ "${target}" != gs://* ]]; then
    echo "[ERROR] ${FUNC_NAME}: The target must be a Cloud Storage path (gs://)."
    return 1
  fi

  echo "[INFO] ${FUNC_NAME}: Granting READ access to all users for '${target}'..."

  # gsutil acl chコマンドで全てのユーザにREAD権限を付与
  gsutil acl ch -u AllUsers:R "${target}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gcs "失敗…" "ACLを全てのユーザに付与できなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Failed to grant READ access to all users for '${target}'."
    return 1
  fi

  send_discord_notification_about_gcs "権限を付与したよ！" "ACL(READ)を全てのユーザに付与したよ！" "green"
  echo "[INFO] ${FUNC_NAME}: READ access granted to all users for '${target}' successfully."
  return 0
}

function remove_all_authority_for_all_on_acl_of_gcs() {
  local FUNC_NAME=${FUNCNAME[0]}
  send_discord_notification "ACLを全てのユーザから剥奪するよ！"

  # --helpパラメータが渡された場合は利用方法を表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: remove_read_all <gs_path>"
    echo "[INFO] ${FUNC_NAME}: Example: remove_read_all gs://your-bucket-name/path/to/object"
    echo "[INFO] ${func_name}: Detail of gsutil is here: https://cloud.google.com/storage/docs/gsutil/addlhelp/GlobalCommandLineOptions?hl=ja"
    return 0
  fi

  # 引数の数をチェック（Cloud Storageパスが1つ必要）
  if [[ "$#" -ne 1 ]]; then
    echo "[ERROR] ${FUNC_NAME}: Invalid number of parameters."
    echo "[INFO] ${FUNC_NAME}: Usage: remove_read_all <gs_path>"
    return 1
  fi

  local target="$1"

  # 対象がCloud Storageのパスかチェック
  if [[ "${target}" != gs://* ]]; then
    echo "[ERROR] ${FUNC_NAME}: The target must be a Cloud Storage path (gs://)."
    return 1
  fi

  echo "[INFO] ${FUNC_NAME}: Removing READ access for all users from '${target}'..."

  # gsutil acl chコマンドで全てのユーザのREADアクセスを削除
  gsutil acl ch -d AllUsers "${target}"
  if [[ "$?" -ne 0 ]]; then
    send_discord_notification_about_gcs "失敗…" "ACLを全てのユーザから剥奪できなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Failed to remove READ access for all users from '${target}'."
    return 1
  fi

  send_discord_notification_about_gcs "権限を付与したよ！" "ACLを全てのユーザから剥奪したよ！" "green"
  echo "[INFO] ${FUNC_NAME}: READ access for all users removed successfully from '${target}'."
  return 0
}
