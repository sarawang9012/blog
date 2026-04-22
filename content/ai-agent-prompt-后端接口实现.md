# AI Agent 提示词：实现支付宝小程序后端接口

## 任务目标

在 `loan-market-api` 项目中实现支付宝小程序所需的 4 个后端接口（1 个已存在无需开发），并同步修改前端项目的 API 调用代码。所有接口路径、请求参数、响应格式必须与参考项目 `zxw-loan-market-app` 完全一致。

---

## 参考文档

1. **接口实现文档**：`C:\Users\iamno\work\.SaveToNAS\web\支付宝小程序后端接口实现文档.md`
   - 包含所有接口的详细规范：请求参数、响应格式、核心业务逻辑、数据库表结构、现有代码状态
   - **必须首先阅读此文档，作为实现的主要依据**

2. **前后端交互文档**：`C:\Users\iamno\work\git\quartz\content\支付宝小程序前后端交互文档.md`
   - 前端调用流程、接口调用时序、参数传递链路

---

## 参考源码项目

实现时必须参考原始项目的代码逻辑，确保行为一致：

### 原始后端项目（接口实现的权威参考）

路径：`C:\Users\iamno\work\git\zxiaowei\zxw-loan-market-new\zxw-loan-market`

| 接口                               | 参考文件                                                                                    |
| -------------------------------- | --------------------------------------------------------------------------------------- |
| `/biz/channel/getPageCodeByIp`   | `zxw-loan-market-api/.../infostream/controller/ChannelController.java`（line 122）        |
| `/infostream/rt2`                | `zxw-loan-market-api/.../infostream/controller/InfoStreamController.java`（line 168）     |
| `/biz/tEventRecordNew/addRecord` | `zxw-loan-market-api/.../infostream/controller/TEventRecordNewController.java`（line 65） |
| 各接口 Service 层                    | `zxw-loan-market-common/.../biz/service/` 及 `impl/` 子目录                                 |
| 各接口 Entity/DAO                   | `zxw-loan-market-common/.../biz/entity/`、`biz/dao/`、`resources/mapper/biz/`             |

### 参考前端项目（接口调用方式的权威参考）

路径：`C:\Users\iamno\work\git\zxiaowei\2026\zxw-loan-market-app`

| 文件 | 说明 |
|------|------|
| `src/service/api/index.ts` | 所有 API 接口定义（路径、参数） |
| `src/utils/http.ts` | HTTP 请求封装、响应格式约定 |
| `src/utils/index.ts` | `handlePageShow()` — rt2 + addRecord + getPageCodeByIp 完整调用链路 |
| `src/pages/home/index.vue` | 启动分流页（IP获取 + getPageCodeByIp） |
| `src/pages/h5/index.vue` | WebView 容器（URL拼接 + alipayDecrypt 通信） |

---

## 实际要改造的项目

### 后端项目（主要开发目标）

| 项目                     | 路径                                                                 | 说明                                 |
| ---------------------- | ------------------------------------------------------------------ | ---------------------------------- |
| **loan-market-api**    | `C:\Users\iamno\work\.SaveToNAS\贷超\git\loan-market-api`            | 所有新接口在此实现                          |
| **loan-market-common** | `C:\Users\iamno\work\.SaveToNAS\贷超\loan-market\loan-market-common` | 共享的 Service/Entity/DAO 层（部分已存在可复用） |
| **loan-market-admin**  | `C:\Users\iamno\work\.SaveToNAS\贷超\loan-market\loan-market-admin`  | 仅参考，不在其中开发                         |

### 前端项目（需同步修改 API 调用）

| 项目                          | 路径                                                           | 说明         |
| --------------------------- | ------------------------------------------------------------ | ---------- |
| **car-loan-alipay-miniapp** | `C:\Users\iamno\work\.SaveToNAS\web\car-loan-alipay-miniapp` | 支付宝小程序（A面） |
| **car-loan-h5**             | `C:\Users\iamno\work\.SaveToNAS\web\car-loan-h5`             | B面 H5 独立项目 |

---

## 用户确认的实现决策

以下为用户已确认的实现方案，**不得更改**：

### 决策 1：留资提交接口 — 复用已有 /common/api/apply

不新增 `/api/lead/submit`，改为复用 `loan-market-api` 中已有的 `POST /common/api/apply` 接口。前端项目需修改 API 调用代码，将原来调用 `/api/lead/submit` 改为调用 `/common/api/apply`，并适配其参数格式。

需确认 `/common/api/apply` 的请求 DTO 结构，将前端的 name/phone/city/carModel/loanAmount/remark 映射到对应字段。

### 决策 2：/infostream/rt2 — 简化实现

当前前端只用 UUID，不需要查询页面配置。简化实现：
- 生成 UUID 返回即可
- 后续按需扩展 UrlMapping / PageConfig / PageElementConfig 查询

用户原话："这个接口主要用来获取h5页面，支持按渠道id配置，目前我们不需要，直接返回固定的url就可以。"

### 决策 3：所有新接口在 loan-market-api 中开发

不在 loan-market-admin 中开发。common 层的 Service/Entity/DAO 可复用。

### 决策 4：接口格式必须与参考项目一致

所有接口路径、请求参数名、响应格式（`APIResult` / `R`）、业务逻辑必须与参考项目 `zxw-loan-market-app` + `zxw-loan-market` 保持一致，不得自行发明。

### 决策 5：支付宝小程序环境限制

支付宝小程序 JS 运行时不支持浏览器 API（如 `URLSearchParams`），后端接口如有需要返回 URL 的场景，不要依赖前端解析复杂结构。

---

## 具体开发任务清单

### 任务 1：在 loan-market-api 新增 getPageCodeByIp 端点

- 文件：`loan-market-api` 中的 `ChannelController`（映射 `biz/channel`）
- 新增方法：`getPageCodeByIp(String channelId, HttpServletRequest request)`
- 逻辑：从请求头获取客户端 IP → 调用 `ChannelPageService.getCityInfoByIp()` → 返回页面编码
- 依赖：
  - `loan-market-common` 中的 `ChannelPageService` / `ChannelPageServiceImpl` 已存在
  - 纯真 IP 数据库文件 + 配置（`chunzhen.ip.path`、`chunzhen.ip.secret`）

### 任务 2：在 loan-market-api 新增 /rt2 端点

- 文件：`loan-market-api` 中的 `InfoStreamController`（映射 `infostream`）
- 新增方法：`rt2(@RequestParam String channelId)`
- 逻辑：生成 UUID → 返回 `{ UUID: "xxx" }`
- 简化版，暂不查询 UrlMapping / PageConfig

### 任务 3：在 loan-market-api 新增 TEventRecordNewController

- 新增文件：`loan-market-api` 中的 `TEventRecordNewController`（映射 `biz/tEventRecordNew`）
- 新增方法：`addRecord(@RequestBody TEventRecordNewForm form, HttpServletRequest request)`
- 逻辑：与原始项目 `TEventRecordNewController.addRecord()` 完全一致
- 依赖：
  - `loan-market-common` 中的 `TEventRecordNewService` / `TEventRecordNewServiceImpl` 已存在
  - `loan-market-common` 中的 `TEventRecordNewForm` / `TEventRecordNew` / `TEvent` Entity 已存在
- 注意：该接口使用 `R` 返回类型（`code=0` 表示成功），不是 `APIResult`

### 任务 4：确认 alipayDecrypt 配置

- 已实现，无需开发
- 确认 `CallBackController.alipayDecrypt()` 正常工作
- 确认各渠道的支付宝 AES 密钥在数据库中已配置

### 任务 5：前端适配 /common/api/apply

- 修改 `car-loan-alipay-miniapp/src/api/index.ts`：删除 `submitLead`（原 `/api/lead/submit`），改为调用 `/common/api/apply`
- 修改 `car-loan-h5/src/api/index.ts`：同上
- 修改前端表单提交代码，适配 `/common/api/apply` 的参数格式

### 任务 6：前端补充埋点调用逻辑

- 修改 `car-loan-alipay-miniapp/src/pages/h5/index.vue`：补充 `infostreamRt2` + `addRecord` 调用
- 修改 `car-loan-alipay-miniapp/src/pages/index/index.vue`：补充 `handlePageShow` 埋点逻辑
- 在 `src/api/index.ts` 中新增 `infostreamRt2` 和 `addRecord` 接口定义

---

## 实现注意事项

1. **先读文档再动手**：实现前务必先读 `支付宝小程序后端接口实现文档.md`，理解每个接口的完整规范

2. **对照原始项目**：每个接口的实现必须对照 `zxw-loan-market` 原始项目的 Controller 和 Service 代码，确保逻辑一致

3. **复用 common 层**：`loan-market-common` 中已有的 Service/Entity/DAO/Form 直接复用，不要重复创建

4. **响应格式**：
   - `getPageCodeByIp`、`rt2`、`alipayDecrypt` 使用 `APIResult`（`success`/`errCode`/`data`）
   - `addRecord` 使用 `R`（`code`/`msg`）
   - 与参考项目保持一致，不得混用

5. **编译验证**：每个接口实现后，确认 `loan-market-api` 项目能编译通过

6. **前端同步**：后端接口路径确定后，同步修改前端 `api/index.ts` 中的接口调用

7. 参考项目相关代码如果用到了com.fidaframe,com.fida,com.zxiaowei包下面的代码，记得要对相关代码进行改造。切记，我们不能引入这些依赖。

