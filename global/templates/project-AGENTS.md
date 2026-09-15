# AGENTS.md — <项目名>

> 复制本文件到新项目根目录，填写方括号内内容。
> 边界：本项目专属的规则放这里；不要把全局规则重复进来（全局在 `~/.codex/AGENTS.md`）。
> 更靠近当前目录的规则优先于更宽的规则，但任何规则都不覆盖安全红线。

## 项目目的
<这个项目解决什么问题、在长期方向中的位置，1-3 句>

## 技术栈与运行
- 语言/框架：<如 C++17 / Python 3.11 / ROS2 humble>
- 构建命令：<如 `mkdir -p build && cd build && cmake .. && make -j`>
- 测试命令：<如 `pytest tests/`、`ctest`、`make test`>
- 环境可复现：<Dockerfile / requirements.txt / pyproject.toml / 依赖版本锁>

## 工具链策略（本项目专属，按需保留）
- 格式化 / Lint：<clang-format / black + isort / 无>
- 编译告警：<是否 `-Werror` 与例外目录>
- 交叉编译 / 目标平台：<目标板、工具链、烧录流程>
- 关键路径约束：<如实时路径禁动态分配>
- 目录约定：<src / include / benchmark / docs>

## 完成标准与验证
- 声称完成前必须通过的：<构建、lint、测试命令>
- 可验证输出：<示例可运行 / benchmark 数据 / 报告>

## 约束与高危操作
- 本项目特有红线：<如真机急停、寄存器写、烧录>
- 需人工确认的操作清单：
  - <...>
