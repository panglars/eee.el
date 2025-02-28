cat /tmp/ee-recentf-list.txt | \
  fzf \
  --reverse \
  --border \
  --exact \
  --ansi \
  --cycle \
  --no-sort \
  --color "border:#A15ABD" \
  --bind 'ctrl-f:page-down,ctrl-b:page-up' \
  --preview \
  "bash -c 'bat -n --color=always {}'"
