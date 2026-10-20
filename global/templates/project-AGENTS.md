# AGENTS.md — <项目名>

> 复制本文件到新项目根目录，填写方括号内内容。
> 边界：本项目专属的规则放这里；不要把全局规则重复进来（全局在 `~/.codex/AGENTS.md`）。
> 更靠近当前目录的规则优先于更宽的规则，但任何规则都不覆盖安全红线。

## 项目目的
<这个项目解决什么问题、在长期方向中的位置，1-3 句>

## 技术栈与运行
- 语言/框架：<如 C++17 / Python 3.11 / ROS2 humble>
- 编码与测试基准规范（全局继承）：
  - Python: [PEP 8 规范](https://pep8.org/)，单元测试使用 [pytest](http://www.pytest.org/en/latest/)
  - C++: [Google C++ 编程规范](http://google.github.io/styleguide/cppguide.html)，单元测试使用 [Googletest](https://github.com/google/googletest/blob/master/googletest/docs/primer.md)
  - 其余语言（C/Shell/TypeScript/Go等）: 遵循各自对应的 [Google 编程规范](https://github.com/zh-google-styleguide/zh-google-styleguide)
- 构建命令：<如 `mkdir -p build && cd build && cmake .. && make -j`>
- 测试命令：<如 `pytest tests/`、`ctest --output-on-failure`、`make test`>
- 环境可复现：<Dockerfile / requirements.txt / pyproject.toml / 依赖版本锁>

## 工具链策略（本项目专属，按需保留）
- 格式化 / Lint：<Python: ruff / black + isort / flake8; C++: clang-format (BasedOnStyle: Google)>
- 编译告警：<是否 `-Werror` 与例外目录>
- 交叉编译 / 目标平台：<目标板、工具链、烧录流程>
- 关键路径约束：<如实时路径禁动态分配>
- 目录约定：<src / include / tests / benchmark / docs>

## 完成标准与验证
- 声称完成前必须通过的：<构建、lint、测试命令（长输出务必通过管道截断或关键行过滤，执行防爆安全带）>
- 可验证输出：<示例可运行 / benchmark 数据 / 报告>

## 约束与高危操作
- 本项目特有红线：<如真机急停、寄存器写、烧录>
- 需人工确认的操作清单：
  - <...>
