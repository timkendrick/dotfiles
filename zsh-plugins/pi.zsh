export PI_DE_CLAUDE_USE_DIFF_EDITOR=false

alias 'pi-sandbox'="sandbox --dir . $(jj_root=$(jj workspace root 2>/dev/null) && { echo --dir $jj_root; if [ -f $jj_root/.jj/repo ]; then echo --dir $(dirname $(dirname $(cat $jj_root/.jj/repo))); fi; } | tr "\n" " " || true) --dir ~/.pi --dir ~/.npm --dir ~/Library/pnpm --dir ~/.docker/buildx --dir ~/.plannotator -- pi"
