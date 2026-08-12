#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

KARABINER_SRC="${DOTFILES_KARABINER_RULES_DIR:-$DOTFILES/karabiner}"
KARABINER_CONFIG="${DOTFILES_KARABINER_CONFIG_FILE:-$HOME/.config/karabiner/karabiner.json}"

# complex_modifications のアセットは、有効化時に karabiner.json へコピーされる。
# そのため、アセットを更新しただけでは反映されない。有効化済みの同名ルールだけを
# description をキーとして同期し、未有効のルールやその他の設定は変更しない。
[[ -f "$KARABINER_CONFIG" ]] || exit 0

if ! command -v jq >/dev/null 2>&1; then
  printf 'Karabinerルールの同期には jq が必要です。\n' >&2
  exit 1
fi

shopt -s nullglob
rule_files=("$KARABINER_SRC"/*.json)
shopt -u nullglob
(( ${#rule_files[@]} > 0 )) || exit 0

managed_rules_file="$(mktemp "${TMPDIR:-/tmp}/dotfiles-karabiner-rules.XXXXXX")"
updated_config_file=''

cleanup() {
  [[ -z "${managed_rules_file:-}" ]] || rm -f "$managed_rules_file"
  [[ -z "${updated_config_file:-}" ]] || rm -f "$updated_config_file"
}
trap cleanup EXIT HUP INT TERM

# description は同期キーなので、重複していたら曖昧な更新をせずに停止する。
jq -s '
  [.[].rules[]] as $rules
  | ($rules
      | group_by(.description)
      | map(select(length > 1) | .[0].description)) as $duplicates
  | if ($duplicates | length) > 0 then
      error("duplicate rule descriptions: \($duplicates | join(", "))")
    else
      $rules
    end
' "${rule_files[@]}" > "$managed_rules_file"

changed_rule_count="$(
  jq --slurpfile managed_rules "$managed_rules_file" '
    ($managed_rules[0]
      | map({key: .description, value: .})
      | from_entries) as $managed_by_description
    | [
        .profiles[]?.complex_modifications.rules[]?
        | . as $enabled_rule
        | select($managed_by_description[$enabled_rule.description] != null)
        | select($enabled_rule != $managed_by_description[$enabled_rule.description])
      ]
    | length
  ' "$KARABINER_CONFIG"
)"

(( changed_rule_count > 0 )) || exit 0

updated_config_file="$(mktemp "${KARABINER_CONFIG}.tmp.XXXXXX")"

jq --slurpfile managed_rules "$managed_rules_file" '
  ($managed_rules[0]
    | map({key: .description, value: .})
    | from_entries) as $managed_by_description
  | .profiles |= map(
      if (.complex_modifications.rules? | type) == "array" then
        .complex_modifications.rules |= map(
          . as $enabled_rule
          | ($managed_by_description[$enabled_rule.description] // $enabled_rule)
        )
      else
        .
      end
    )
' "$KARABINER_CONFIG" > "$updated_config_file"

config_mode="$(stat -f '%Lp' "$KARABINER_CONFIG")"
chmod "$config_mode" "$updated_config_file"
mv -f "$updated_config_file" "$KARABINER_CONFIG"
updated_config_file=''

printf 'Karabinerの有効ルールを同期しました（%d件）。\n' "$changed_rule_count"
