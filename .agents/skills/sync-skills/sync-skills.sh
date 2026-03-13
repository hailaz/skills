#!/usr/bin/env bash
# sync-skills.sh
# 将 .agents/skills/ 中的所有技能同步到 skills/ 和 .codebuddy/skills/
# 实体统一存放在 .agents/skills/，其余两个目录通过软链接引用。
#
# 用法: bash .agents/skills/sync-skills/sync-skills.sh [--dry-run]

set -euo pipefail

# 获取项目根目录（脚本位于 .agents/skills/sync-skills/ 下，回退三层）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

SOURCE_DIR="$PROJECT_ROOT/.agents/skills"
TARGET_DIRS=(
    "$PROJECT_ROOT/skills"
    "$PROJECT_ROOT/.codebuddy/skills"
)

# 从各目标目录到 SOURCE_DIR 的相对路径
declare -A REL_PATHS
REL_PATHS["$PROJECT_ROOT/skills"]="../.agents/skills"
REL_PATHS["$PROJECT_ROOT/.codebuddy/skills"]="../../.agents/skills"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "[dry-run] 仅显示将要执行的操作，不实际修改"
    echo ""
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "错误: 源目录 $SOURCE_DIR 不存在" >&2
    exit 1
fi

changes=0

for target_dir in "${TARGET_DIRS[@]}"; do
    # 确保目标目录存在
    if [[ ! -d "$target_dir" ]]; then
        if $DRY_RUN; then
            echo "[dry-run] mkdir -p $target_dir"
        else
            mkdir -p "$target_dir"
        fi
    fi

    rel_base="${REL_PATHS[$target_dir]}"

    # 1. 为 .agents/skills/ 中的每个技能创建软链接（如果不存在）
    for skill_path in "$SOURCE_DIR"/*/; do
        [[ -d "$skill_path" ]] || continue
        skill_name="$(basename "$skill_path")"
        link_path="$target_dir/$skill_name"
        expected_target="$rel_base/$skill_name"

        if [[ -L "$link_path" ]]; then
            current_target="$(readlink "$link_path")"
            if [[ "$current_target" == "$expected_target" ]]; then
                continue  # 已存在且正确
            else
                echo "修复: $link_path (当前 -> $current_target, 期望 -> $expected_target)"
                if ! $DRY_RUN; then
                    rm "$link_path"
                    ln -s "$expected_target" "$link_path"
                fi
                changes=$((changes + 1))
            fi
        elif [[ -e "$link_path" ]]; then
            echo "警告: $link_path 是实体目录/文件，跳过（请手动处理）"
        else
            echo "创建: $link_path -> $expected_target"
            if ! $DRY_RUN; then
                ln -s "$expected_target" "$link_path"
            fi
            changes=$((changes + 1))
        fi
    done

    # 2. 清理目标目录中指向 .agents/skills/ 下已不存在技能的失效软链接
    for link_path in "$target_dir"/*/; do
        [[ -L "${link_path%/}" ]] || continue
        link_path="${link_path%/}"
        skill_name="$(basename "$link_path")"
        current_target="$(readlink "$link_path")"

        # 只处理指向 .agents/skills 的链接
        if [[ "$current_target" == *".agents/skills/"* ]]; then
            if [[ ! -d "$SOURCE_DIR/$skill_name" ]]; then
                echo "清理: $link_path (目标技能已不存在)"
                if ! $DRY_RUN; then
                    rm "$link_path"
                fi
                changes=$((changes + 1))
            fi
        fi
    done
done

if [[ $changes -eq 0 ]]; then
    echo "✅ 所有技能已同步，无需变更。"
else
    if $DRY_RUN; then
        echo ""
        echo "共 $changes 处需要变更（dry-run 模式未实际执行）"
    else
        echo ""
        echo "✅ 同步完成，共 $changes 处变更。"
    fi
fi
