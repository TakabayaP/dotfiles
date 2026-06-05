#!/usr/bin/env bash

set_label() {
  local id="$1"
  local name="$2"
  local languages="$3"
  local text="${id} ${name} ${languages}"

  case "$text" in
    *net.mtgto.inputmethod.macSKK.ascii*|*net.mtgto.inputmethod.macSKK.eisu*)
      sketchybar --set "$NAME" icon="A" label="EN"
      ;;
    *net.mtgto.inputmethod.macSKK.hiragana*)
      sketchybar --set "$NAME" icon="あ" label="JA"
      ;;
    *net.mtgto.inputmethod.macSKK.katakana*)
      sketchybar --set "$NAME" icon="ア" label="JA"
      ;;
    *net.mtgto.inputmethod.macSKK.hankaku*)
      sketchybar --set "$NAME" icon="ｶ" label="JA"
      ;;
    *ko*|*Korean*|*Hangul*|*韓国語*)
      sketchybar --set "$NAME" icon="한" label="KO"
      ;;
    *zh*|*Chinese*|*Pinyin*|*中国語*|*簡体*|*繁体*)
      sketchybar --set "$NAME" icon="中" label="ZH"
      ;;
    *ja*|*Japanese*|*Japan*|*Kotoeri*|*AquaSKK*|*macSKK*|*Hiragana*|*Katakana*|*ひらがな*|*カタカナ*|*日本語*)
      sketchybar --set "$NAME" icon="あ" label="JA"
      ;;
    *ABC*|*US*|*U.S.*|*en*|*English*)
      sketchybar --set "$NAME" icon="A" label="EN"
      ;;
    *)
      local fallback="${name:-${id##*.}}"
      fallback="${fallback%% *}"
      fallback="$(echo "$fallback" | tr '[:lower:]' '[:upper:]' | cut -c 1-3)"
      sketchybar --set "$NAME" icon="⌨" label="${fallback:-IME}"
      ;;
  esac
}

source_info="$(
  swift -e '
import Carbon

func value(_ source: TISInputSource, _ key: CFString) -> String {
  guard let pointer = TISGetInputSourceProperty(source, key) else { return "" }
  return Unmanaged<CFTypeRef>.fromOpaque(pointer).takeUnretainedValue() as? String ?? ""
}

func languages(_ source: TISInputSource) -> String {
  guard let pointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else { return "" }
  let value = Unmanaged<CFTypeRef>.fromOpaque(pointer).takeUnretainedValue()
  return (value as? [String] ?? []).joined(separator: ",")
}

let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
print(value(source, kTISPropertyInputSourceID))
print(value(source, kTISPropertyLocalizedName))
print(languages(source))
' 2>/dev/null
)"

if [ -n "$source_info" ]; then
  source_id="$(echo "$source_info" | sed -n '1p')"
  source_name="$(echo "$source_info" | sed -n '2p')"
  source_languages="$(echo "$source_info" | sed -n '3p')"
  set_label "$source_id" "$source_name" "$source_languages"
  exit 0
fi

selected_source="$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources 2>/dev/null)"
set_label "$selected_source" "$selected_source" ""
