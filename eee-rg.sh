#!/usr/bin/env bash

export TEMP=$(mktemp -u)
export TEMP_FLAGS=$(mktemp -u)
trap 'rm -f "$TEMP"' EXIT
trap 'rm -f "$TEMP_FLAGS"' EXIT


CURR_DIR=$(dirname $(readlink -f $0))
. ${CURR_DIR}/eee-common.sh
EE_REGEX=${CURR_DIR}/eee-rich-regex.sh

check_tools fzf bat rg

# Switch between Ripgrep mode and fzf filtering mode (CTRL-T)
rm -f /tmp/rg-fzf-{r,f}

INITIAL_QUERY="$1"

export QUERY_PATH="${2:-.}"

function rg_align(){
	while IFS= read -r line; do
  prefix=$(printf '%s' "$line" | cut -d: -f1-3)
  rest=$(printf '%s' "$line" | cut -d: -f4-)
  printf '%-80s' "$prefix"
  [[ -n $rest ]] && printf ':%s\n' "$rest" || printf '\n'
done

}



TRANSFORMER='
  rg_pat={q:1}      # The first word is passed to ripgrep
  fzf_pat={q:2..}   # The rest are passed to fzf
  flags=$(cat ${TEMP_FLAGS})

  if ! [[ -r "$TEMP" ]] || [[ $rg_pat != $(cat "$TEMP") ]] || [[ $TEMP_FLAGS -nt $TEMP ]]; then
    echo "$rg_pat" > "$TEMP"
    printf "reload:sleep 0.01; '"$RG"' --hidden --column --line-number --with-filename --no-heading --color=always --smart-case %q -e %q %q  || true" "$flags" "$rg_pat" ${QUERY_PATH}
  fi
  echo "+search:$fzf_pat"
'

# if TEMP_FLAGS contains --word-regexp, remove it, else add it
function toggle_word_rexp(){
    if grep -q -- '--word-regexp' "$TEMP_FLAGS"; then
        sed -i '/--word-regexp/d' "$TEMP_FLAGS"
    else
        echo -n "--word-regexp" >> "$TEMP_FLAGS"
    fi
    logger "Flags: $(cat $TEMP_FLAGS)"
}

export -f toggle_word_rexp




$FZF --ansi --disabled --query "$INITIAL_QUERY" \
    --delimiter : --nth 3.. \
    --border \
    --reverse \
    --exact \
    --cycle \
    --with-shell 'bash -c' \
    --bind "start:transform:$TRANSFORMER" \
    --bind "change:transform:$TRANSFORMER" \
    --color "hl:-1:underline,hl+:-1:underline:reverse,border:#A15ABD" \
    --delimiter : \
    --preview "$BAT"' --color=always {1} --highlight-line {2}' \
    --preview-window 'up,70%,+{2}+3/3,~3' \
    --bind "alt-w:execute-silent(toggle_word_rexp)+transform:$TRANSFORMER" \
    --bind 'ctrl-f:page-down,ctrl-b:page-up' |
    xargs -0 -I{} echo $(pwd)/{}

