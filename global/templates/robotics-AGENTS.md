# AGENTS.md — <机器人/具身智能项目名>

> 适用：机械臂 / 灵巧手 / 具身智能 (LeRobot) / ROS2 / CAN 总线 / 嵌入式 C++ / 昇腾 NPU
> 复制本文件到机器人项目根目录，填写方括号内内容。
> 本模板继承全局规则 `~/.codex/AGENTS.md`，并在项目级强化物理安全与实时性标准。

---

## 1. 项目目的与架构分层

### 项目概述
<本项目解决什么问题，例如：双臂 7 轴机械臂与 5 指灵巧手基于 LeRobot + 昇腾 NPU 的视觉伺服与遥操作系统>

### 五层分层架构（严禁跨层调用）
```
┌────────────────────────────────────────────────────────┐
│ 5. AI / Policy Layer (LeRobot / Ascend NPU / PyTorch)  │
└───────────────────────────┬────────────────────────────┘
                            │ Observation / Action Chunk
┌───────────────────────────▼────────────────────────────┐
│ 4. ROS2 Ecosystem Layer (rclcpp / ros2_control / Nodes)│
└───────────────────────────┬────────────────────────────┘
                            │ Trajectory / State Interfaces
┌───────────────────────────▼────────────────────────────┐
│ 3. Control & Safety Layer (Kinematics, E-stop, Limits) │
└───────────────────────────┬────────────────────────────┘
                            │ Target Position / Velocity / Torque
┌───────────────────────────▼────────────────────────────┐
│ 2. Driver Layer (CAN Protocols, Encoders, Protocol DBC)│
└───────────────────────────┬────────────────────────────┘
                            │ Raw CAN Frames (ID, DLC, Payload)
┌───────────────────────────▼────────────────────────────┐
│ 1. Hardware / Bus Layer (SocketCAN, Serial, Firmware)  │
└────────────────────────────────────────────────────────┘
```

---

## 2. 硬件与嵌入式标准 (Robotics & Embedded Standards)

### 2.1 嵌入式 C/C++ 与 CAN 总线
- **绝对零动态分配**：高频控制循环（>100Hz）内部严禁 `malloc`、`new`、`std::vector::resize` 等可能引发堆抖动的操作。
- **协议完整性检查**：反序列化 CAN 报文前，强制校验 Frame ID、DLC（数据长度代码）以及 CRC/校验和；明确标注大小端序（Endianness）。
- **通信心跳看门狗**：通信超时超过 50ms 必须自动禁用电机力矩输出，进入安全阻尼/抱闸状态。

### 2.2 ROS2 与 ros2_control
- **无锁实时安全**：`ros2_control` 硬件接口的 `read()` 和 `write()` 方法必须是非阻塞的，禁止在控制线程加锁或同步等待。
- **生命周期状态机**：严格实现 `on_configure`、`on_activate`、`on_deactivate`、`on_cleanup`，默认未激活态必须处于安全力矩切断状态。
- **QoS 策略**：高频关节状态发布采用 `BestEffort` 传感器 QoS；轨迹目标与配置采用 `Reliable` + `TransientLocal`。

### 2.3 运动学与动力学控制
- **标准 SI 物理单位**：所有角度一律使用 **弧度 (rad)**，角速度使用 **rad/s**，力矩使用 **Nm**，力使用 **N**，位移使用 **m**。
- **双重软硬件限位**：所有目标位置、速度和电流指令在转为总线指令前必须经过硬饱和截断（Clamp）。
- **奇异点防护**：运动学逆解在接近奇异点时必须启用阻尼最小二乘（DLS）或零空间投影，防止关节角速度瞬时发散。

### 2.4 具身智能与 LeRobot (昇腾 Ascend NPU)
- **推理线程隔离**：AI 模型推理必须运行在独立异步工作线程/进程中，严禁神经网络计算延迟阻塞实时底层控制循环。
- **动作块平滑滤波 (Action Smoothing)**：对策略输出的 Action Chunks 应用低通滤波或三次样条插值，避免机械机构高频抖动受损。
- **安全包络拦截器 (Safety Envelope)**：AI 生成动作必须经过确定性工作空间范围与速度上限安全层后方可下发执行。

---

## 3. 硬件安全分级操作协议 (Mandatory Safety Ladder)

任何涉及物理硬件的操作，严格执行以下五步阶梯：
1. **虚拟总线测试**：优先在 `vcan0`（虚拟 CAN）环境跑通帧收发与编解码测试。
2. **闭环仿真验证**：在仿真器（Isaac Sim / Gazebo / MuJoCo）中验证闭环控制与轨迹收敛。
3. **断电空跑 (Dry Run)**：在电机主电源切断状态下运行控制节点，验证指令流与时序。
4. **低速单关节测试**：初次上电测试将速度和力矩限制在额定值的 5%~10% 以内。
5. **人工批准红线**：**Agent 绝不允许自主执行物理电机使能、写寄存器、刷写固件或触发动作！** 必须明确提示风险并等待用户显式确认。

---

## 4. 技术栈与环境命令

- **开发语言/环境**：<C++17 / Python 3.11 / ROS2 Humble / PyTorch (CANN)>
- **构建命令**：<例如 `colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release`>
- **测试命令**：<例如 `colcon test && colcon test-result --all`>
- **虚拟 CAN 启动**：`sudo ip link add dev vcan0 type vcan && sudo ip link set up vcan0`

---

## 5. 完成标准 (Definition of Done)

- [ ] 核心协议与算法具备单元测试（TDD 优先）。
- [ ] 控制热循环无动态内存分配，无内存泄漏与死锁隐患。
- [ ] 具备完整的超时看门狗与急停（E-Stop）响应机制。
- [ ] 针对关键架构与通信流提供了基于 `diagram-design` 的架构图或状态机图。
