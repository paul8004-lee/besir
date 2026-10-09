#!/bin/zsh
# t60 재현용 실행 래퍼 — t47 e2e/run-one.sh 레시피를 이 워크트리 사본으로 옮겼다.
# 차이: 메인 체크아웃 cd 금지(워크트리 안에서만), 로그·플로우가 .moai/reports/t60/e2e/ 아래에.
# 사용: run.sh <flow-name>   (flows/<name>.yaml 실행, 로그 .runs/<stamp>-<name>.log)
set -u
wt=/Users/iseongmin/Projects/besir/.claude/worktrees/t60
name=$1
flow=$wt/.moai/reports/t60/e2e/flows/${name}.yaml
runs=$wt/.moai/reports/t60/e2e/.runs
mkdir -p "$runs"
stamp=$(date +%Y%m%d-%H%M%S)
log=$runs/${stamp}-${name}.log
# 혹시 남은 이전 maestro 정리 — 동시 실행이 화면을 두고 싸우면 결과가 무의미해진다
pkill -f "maestro.cli.AppKt test" 2>/dev/null; sleep 1
perl -e 'alarm 300; exec @ARGV' env \
  MAESTRO_CLI_NO_ANALYTICS=1 ~/.maestro/bin/maestro test --no-reinstall-driver "$flow" > "$log" 2>&1
code=$?
pkill -f "maestro.cli.AppKt test" 2>/dev/null
echo "flow=${name} exit=${code} log=${log}"
tail -5 "$log"
exit $code
