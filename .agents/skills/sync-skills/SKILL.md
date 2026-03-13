---
name: sync-skills
description: 同步技能目录。当新建、删除或移动技能后，运行此技能将 .agents/skills/ 中的所有技能同步到 skills/ 和 .codebuddy/skills/ 目录。通过软链接保持三个目录一致。触发词包括"同步技能"、"sync skills"、"技能不同步"、"缺少软链接"。
---

# Sync Skills

将 `.agents/skills/` 中的所有技能同步到 `skills/` 和 `.codebuddy/skills/` 目录，确保三处始终保持一致。

## 架构

```
.agents/skills/          ← 唯一实体存放处 (Single Source of Truth)
├── skill-a/
├── skill-b/
└── ...

skills/                  ← 软链接 (项目级技能注册)
├── skill-a -> ../.agents/skills/skill-a
├── skill-b -> ../.agents/skills/skill-b
└── ...

.codebuddy/skills/       ← 软链接 (CodeBuddy 技能注册)
├── skill-a -> ../../.agents/skills/skill-a
├── skill-b -> ../../.agents/skills/skill-b
└── ...
```

## 使用方式

### 预览变更（不实际修改）

```bash
bash .agents/sync-skills.sh --dry-run
```

### 执行同步

```bash
bash .agents/sync-skills.sh
```

## 脚本功能

同步脚本 `.agents/sync-skills.sh` 执行以下操作：

1. **补齐软链接**：扫描 `.agents/skills/` 中所有技能，在 `skills/` 和 `.codebuddy/skills/` 中创建缺失的软链接
2. **修复链接**：如果软链接指向错误路径，自动修正
3. **清理失效链接**：如果 `.agents/skills/` 中某个技能被删除，自动清理其他目录中对应的失效软链接

## 何时运行

- 新建技能后
- 删除技能后
- 移动技能后
- 发现 `skills/` 或 `.codebuddy/skills/` 中技能缺失时

## 注意事项

- 所有技能实体**必须**存放在 `.agents/skills/` 中
- `skills/` 和 `.codebuddy/skills/` 中**只能**存在软链接，不能存在实体目录
- 如果发现实体目录，脚本会发出警告并跳过，需要手动处理
