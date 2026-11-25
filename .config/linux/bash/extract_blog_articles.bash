#!/bin/bash

#==============================================================#
##         Commands to extract                                ##
#==============================================================#
function find_content_files() {
  local func_name="find_content_files"

  # 改行を含むパターンを正しく定義
  # Perl正規表現モード(-P)では \n が改行を表す
  local search_pattern="# Content\\n\\n## はじまり\\n"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <ディレクトリ> [拡張子]"
    echo ""
    echo "説明:"
    echo "  指定されたディレクトリ内で、特定のコンテンツパターンを含むファイルを検索します。"
    echo "  検索対象は「# Content」の後に3つの改行、その後に「## はじまり」が続くパターンです。"
    echo ""
    echo "パラメータ:"
    echo "  <ディレクトリ>  検索対象のディレクトリパス（必須）"
    echo "  [拡張子]      検索対象のファイル拡張子（省略時は .md）"
    echo ""
    echo "使用例:"
    echo "  ${func_name} ~/documents"
    echo "  ${func_name} ~/projects .txt"
    return 0
  fi

  # 引数チェック
  if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "[ERROR] ${func_name}: 引数の数が不正です"
    echo "[INFO] ${func_name}: 使用法を確認するには「${func_name} --help」を実行してください"
    return 1
  fi

  local dir_path="$1"
  local extension=".md"  # デフォルト拡張子

  # 拡張子が指定されている場合は上書き
  if [ $# -eq 2 ]; then
    extension="$2"
    # 拡張子の先頭にドットがなければ追加
    if [[ ! $extension =~ ^\. ]]; then
      extension=".$extension"
    fi
  fi

  # ディレクトリの存在確認
  if [ ! -d "$dir_path" ]; then
    echo "[ERROR] ${func_name}: ディレクトリ '$dir_path' が存在しません"
    return 1
  fi

  echo "[INFO] ${func_name}: '$dir_path' ディレクトリ内の '$extension' ファイルを検索中..."

  # 結果を格納する変数
  local found_files=0

  # ディレクトリ内のファイルを検索
  for file in "$dir_path"/*"$extension"; do
    # ファイルが存在しない場合のエラー処理
    if [ ! -f "$file" ]; then
      echo "[INFO] ${func_name}: '$extension' 拡張子のファイルが見つかりません"
      return 0
    fi

    # ファイル内容を検索
    if grep -Pzq "$search_pattern" "$file" 2>/dev/null; then
      echo "$file"
      ((found_files++))
    fi
  done

  # 結果の表示
  if [ $found_files -eq 0 ]; then
    echo "[INFO] ${func_name}: パターンに一致するファイルが見つかりませんでした"
  else
    echo "[INFO] ${func_name}: パターンに一致するファイルが $found_files 件見つかりました"
  fi

  return 0
}

function write_matched_content_files() {
  local func_name="write_matched_content_files"

  # 改行を含むパターンを正しく定義
  # Perl正規表現モード(-P)では \n が改行を表す
  local search_pattern="# Content\\n\\n## はじまり\\n"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <ディレクトリ> <出力ファイル> [拡張子]"
    echo ""
    echo "説明:"
    echo "  指定されたディレクトリ内で、特定のコンテンツパターンを含むファイルを検索し、結果を出力ファイルに書き込みます。"
    echo ""
    echo "パラメータ:"
    echo "  <ディレクトリ>  検索対象のディレクトリパス（必須）"
    echo "  <出力ファイル>  結果を書き込むファイルパス（必須）"
    echo "  [拡張子]       検索対象のファイル拡張子（省略時は .md）"
    echo ""
    echo "使用例:"
    echo "  ${func_name} 'pattern' output.txt"
    echo "  ${func_name} 'pattern' output.txt .txt"
    return 0
  fi

  # 引数チェック
  if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "[ERROR] ${func_name}: 引数の数が不正です"
    echo "[INFO] ${func_name}: 使用法を確認するには「${func_name} --help」を実行してください"
    return 1
  fi

  # local search_pattern="$1"
  local dir_path="$1"
  local output_file="$2"
  local extension=".md"  # デフォルト拡張子

  # 拡張子が指定されている場合は上書き
  if [ $# -eq 3 ]; then
    extension="$3"
    # 拡張子の先頭にドットがなければ追加
    if [[ ! $extension =~ ^\. ]]; then
      extension=".$extension"
    fi
  fi

  # ディレクトリの存在確認
  if [ ! -d "$dir_path" ]; then
    echo "[ERROR] ${func_name}: ディレクトリ '$dir_path' が存在しません"
    return 1
  fi

  echo "[INFO] ${func_name}: 現在のディレクトリ内の '$extension' ファイルを検索中..."

  # 結果を格納する変数
  local found_files=0

  # 一時ファイルを作成
  local temp_file=$(mktemp)

  # ディレクトリ内のファイルを検索
  for file in "$dir_path"/*"$extension"; do
    # ファイルが存在しない場合のエラー処理
    if [ ! -f "$file" ]; then
      echo "[INFO] ${func_name}: '$extension' 拡張子のファイルが見つかりません"
      return 0
    fi

    # ファイル内容を検索
    if grep -Pzq "$search_pattern" "$file" 2>/dev/null; then
    # if grep -q "$search_pattern" "$file" 2>/dev/null; then
      echo "$file" >> "$temp_file"
      echo "$file"
      ((found_files++))
    fi
  done

  # 結果の表示と出力ファイルへの書き込み
  if [ $found_files -eq 0 ]; then
    echo "[INFO] ${func_name}: パターンに一致するファイルが見つかりませんでした"
    echo "" > "$output_file"  # 空ファイルを作成
  else
    mv "$temp_file" "$output_file"
    echo "[INFO] ${func_name}: パターンに一致するファイルが $found_files 件見つかり、'$output_file' に書き込みました"
  fi

  rm -f "$temp_file"  # 一時ファイルを削除
  return 0
}

function move_files_from_list() {
  local func_name="move_files_from_list"

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} <ファイルリスト> <移動先ディレクトリ> [デフォルト拡張子]"
    echo ""
    echo "説明:"
    echo "  指定されたファイルリストに記載されているファイルを移動先ディレクトリに移動します。"
    echo "  ファイル名に拡張子がない場合は、指定されたデフォルト拡張子が追加されます。"
    echo ""
    echo "パラメータ:"
    echo "  <ファイルリスト>      移動対象ファイル名が記載されたテキストファイル（必須）"
    echo "  <移動先ディレクトリ>  ファイルの移動先ディレクトリ（必須）"
    echo "  [デフォルト拡張子]    拡張子のないファイル名に追加する拡張子（省略時は .md）"
    echo ""
    echo "使用例:"
    echo "  ${func_name} ファイルリスト.txt /path/to/destination"
    echo "  ${func_name} ファイルリスト.txt /path/to/destination .txt"
    return 0
  fi

  # 引数チェック
  if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "[ERROR] ${func_name}: 引数の数が不正です"
    echo "[INFO] ${func_name}: 使用法を確認するには「${func_name} --help」を実行してください"
    return 1
  fi

  local file_list=$1
  local dest_dir=$2
  local default_ext=".md"  # デフォルトの拡張子は.md
  local moved_count=0      # 移動したファイル数をカウント

  # 引数で拡張子が指定されている場合は上書き
  if [ $# -eq 3 ]; then
    default_ext=$3
    # 拡張子の先頭にドットがなければ追加
    if [[ ! $default_ext =~ ^\. ]]; then
      default_ext=".$default_ext"
    fi
  fi

  # 移動先ディレクトリの存在確認
  if [ ! -d "$dest_dir" ]; then
    echo "[ERROR] ${func_name}: 移動先ディレクトリ '$dest_dir' が存在しません"
    return 1
  fi

  # ファイルリストの存在確認
  if [ ! -f "$file_list" ]; then
    echo "[ERROR] ${func_name}: ファイルリスト '$file_list' が見つかりません"
    return 1
  fi

  echo "[INFO] ${func_name}: ファイルの移動を開始します..."

  # ファイルリストを読み込んで移動
  while IFS= read -r filename || [ -n "$filename" ]; do
    # 空行をスキップ
    if [ -z "$filename" ]; then
      continue
    fi

    # 拡張子の確認と追加
    local actual_filename="$filename"
    if [[ ! "$filename" =~ \.[^./]+$ ]]; then
      actual_filename="${filename}${default_ext}"
      echo "[INFO] ${func_name}: 拡張子なしファイル '$filename' に '$default_ext' を追加しました: '$actual_filename'"
    fi

    # ファイルの存在確認
    if [ -f "$actual_filename" ]; then
      mv "$actual_filename" "$dest_dir"
      echo "[INFO] ${func_name}: '$actual_filename' を '$dest_dir' に移動しました"
      ((moved_count++))
    else
      echo "[ERROR] ${func_name}: '$actual_filename' が見つからないためスキップします"
    fi
  done < "$file_list"

  # 移動したファイル数を表示
  if [ $moved_count -eq 0 ]; then
    echo "[INFO] ${func_name}: 移動したファイルはありません"
  else
    echo "[INFO] ${func_name}: 移動処理が完了しました - 合計 $moved_count 個のファイルを移動しました"
  fi

  return 0
}

function extract_content_files() {
  # 関数名をローカル変数に格納
  local funcName="${FUNCNAME[0]}"

  # --helpパラメータの確認
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${funcName}: 利用方法:"
    echo "  ${funcName} <対象ディレクトリ> [抽出ファイル出力ディレクトリ] [拡張子]"
    echo "    <対象ディレクトリ>            : 処理対象のディレクトリ"
    echo "    [抽出ファイル出力ディレクトリ] : 抽出したファイルを出力するためのディレクトリ"
    echo "    [拡張子]                     : ファイルの拡張子（省略時は \".md\"）"
    echo ""
    echo "[INFO] ${funcName}: 使用例:"
    echo "  ${funcName} /path/to/directory .md"
    return 0
  fi

  # パラメータ数のチェック
  if [ $# -lt 1 ]; then
    echo "[ERROR] ${funcName}: 対象ディレクトリが指定されていません。--help を参照してください。" >&2
    return 1
  fi

  local target_dir="$1"
  local dir_to_output_extracted_markdowns="${2:-extracted_contents}"
  local ext="${3:-.md}"

  # 対象ディレクトリが存在するかチェック
  if [ ! -d "$target_dir" ]; then
    echo "[ERROR] ${funcName}: 指定されたディレクトリ '$target_dir' が存在しません。" >&2
    return 1
  fi

  local output_dir="${target_dir}/${dir_to_output_extracted_markdowns}"
  mkdir -p "$output_dir"
  if [ $? -ne 0 ]; then
    echo "[ERROR] ${funcName}: '$output_dir' の作成に失敗しました。" >&2
    return 1
  fi
  echo "[INFO] ${funcName}: '$output_dir' を作成しました。"

  # 対象ディレクトリ内の拡張子が一致する各ファイルに対して処理を実施
  for file in "${target_dir}"/*"${ext}"; do
    # 通常のファイルのみ処理
    if [ ! -f "$file" ]; then
      continue
    fi

    # ファイル内からマーカー以降の内容を取得
    # マーカーは以下のように記載されているとする:
    # # Content
    #
    # ## はじまり
    # 以降すべてのテキストを抽出（マーカーも含む）
    local content
    content=$(perl -0777 -ne 'if(/(# Content\s*\n\s*\n## はじまり\s*\n.*)/s){print $1}' "$file")
    if [ -z "$content" ]; then
      echo "[ERROR] ${funcName}: ファイル '$file' 内に指定マーカーが見つかりませんでした。" >&2
      continue
    fi

    local basefile
    basefile=$(basename "$file")
    local output_file="${output_dir}/${basefile}"

    # 抽出した内容を新規ファイルに出力
    echo "$content" > "$output_file"
    if [ $? -ne 0 ]; then
      echo "[ERROR] ${funcName}: '$output_file' への出力に失敗しました。" >&2
    else
      echo "[INFO] ${funcName}: '$file' を処理し、'$output_file' に出力しました。"
    fi
  done
}

function find_content_files_to_extract() {
  # 関数名をローカル変数に格納
  local funcName="${FUNCNAME[0]}"

  # --helpパラメータの確認
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${funcName}: 使用方法"
    echo "  ${funcName} <対象ディレクトリ> <保存先ディレクトリ> <マークダウンリストファイル>"
    echo ""
    echo "説明:"
    echo "  指定されたディレクトリ内のコンテンツファイルを検索し、抽出して保存します。"
    echo "  以下の処理を順番に実行します："
    echo "    1. コンテンツファイルの検索"
    echo "    2. 一時ディレクトリの作成"
    echo "    3. マッチしたファイルの移動"
    echo "    4. コンテンツの抽出"
    echo ""
    echo "パラメータ:"
    echo "  <対象ディレクトリ>         検索対象のディレクトリパス（必須）"
    echo "  <保存先ディレクトリ>       抽出したファイルの保存先ディレクトリ（必須）"
    echo "  <マークダウンリストファイル> マッチしたファイルのリストを保存するファイル（必須）"
    echo ""
    echo "使用例:"
    echo "  ${funcName} ./ ./target_dir markdown_list.txt"
    return 0
  fi

  # 引数チェック
  if [ $# -ne 3 ]; then
    echo "[ERROR] ${funcName}: 引数の数が不正です"
    echo "[INFO] ${funcName}: 使用法を確認するには「${funcName} --help」を実行してください"
    return 1
  fi

  local dir_for_matching="$1"
  local dir_to_store_files="$2"
  local output_file_to_list_markdowns="$3"

  # ディレクトリの存在確認
  if [ ! -d "$dir_for_matching" ]; then
    echo "[ERROR] ${funcName}: 対象ディレクトリ '$dir_for_matching' が存在しません"
    return 1
  fi

  # 保存先ディレクトリを作成
  mkdir -p "$dir_to_store_files"
  if [ $? -ne 0 ]; then
    echo "[ERROR] ${funcName}: ディレクトリ '$dir_to_store_files' の作成に失敗しました"
    return 1
  fi

  # コンテンツファイルの検索と一覧作成
  write_matched_content_files "$dir_for_matching" "$dir_for_matching/$dir_to_store_files/$output_file_to_list_markdowns"
  if [ $? -ne 0 ]; then
    return 1
  fi

  # マッチしたファイルを移動
  move_files_from_list "$dir_for_matching/$dir_to_store_files/$output_file_to_list_markdowns" "$dir_for_matching/$dir_to_store_files"
  if [ $? -ne 0 ]; then
    return 1
  fi

  # コンテンツの抽出
  extract_content_files "$dir_to_store_files" "extracted_contents"
  return $?
}
