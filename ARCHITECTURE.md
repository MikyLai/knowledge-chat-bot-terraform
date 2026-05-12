# QR Code Generator — Azure 架構計畫

## 目錄

1. [專案概述](#專案概述)
2. [已確認使用的服務](#已確認使用的服務)
3. [缺少的關鍵資源](#缺少的關鍵資源)
4. [架構圖](#架構圖)
5. [Terraform 模組規劃](#terraform-模組規劃)
6. [環境變數與 Secrets 清單](#環境變數與-secrets-清單)
7. [待辦事項](#待辦事項)

---

## 專案概述

以 FastAPI + uvicorn 為後端，透過 Docker container 部署在 Azure App Service，
提供 QR Code 生成 API，並將產生的 PNG 圖片存放於 Azure Blob Storage。

---

## 已確認使用的服務

| 服務 | 用途 | 程式碼依據 |
|------|------|------------|
| **Azure App Service** | 執行 Docker container（FastAPI + uvicorn） | `Dockerfile` |
| **Azure Blob Storage** | 儲存 QR Code PNG 圖片 | `blob_storage.py` |
| **Azure Virtual Network (VNet)** | 網路隔離，讓 App Service、DB、Storage 在私有網路內互通 | 架構設計 |
| **Azure Load Balancer / Application Gateway** | 流量入口、SSL termination、WAF（可選） | 架構設計 |

---

## 缺少的關鍵資源

### 必要資源

#### 1. Azure Container Registry (ACR)

- **原因**：`Dockerfile` 已寫好，需要一個 registry 推送 image，App Service 才能 pull。
- **App Service 相依設定**：
  ```
  DOCKER_REGISTRY_SERVER_URL  = https://<acr-name>.azurecr.io
  DOCKER_REGISTRY_SERVER_USERNAME = <acr-admin-or-mi>
  DOCKER_REGISTRY_SERVER_PASSWORD = <acr-password-or-mi>
  ```
- **建議**：搭配 Managed Identity 讓 App Service 直接 pull，不需明文密碼。

---

#### 2. Azure Database for PostgreSQL Flexible Server（或 Azure SQL）

- **原因**：`database.py` 目前預設使用 SQLite，App Service 沒有持久磁碟，容器重啟資料即消失。
- **需要的變更**：
  - 將 `DATABASE_URL` 環境變數改為 PostgreSQL connection string：
    ```
    postgresql+asyncpg://<user>:<password>@<host>:5432/<dbname>?sslmode=require
    ```
  - 建議透過 Key Vault reference 注入，不明文寫在 App Service 設定中。
- **網路**：掛載 Private Endpoint 到 VNet，不對公網開放。

---

#### 3. Azure Key Vault

- **原因**：管理所有敏感設定，避免 secrets 明文出現在 App Service 環境變數或程式碼中。
- **需要存放的 secrets**：

  | Secret 名稱 | 內容 |
  |-------------|------|
  | `AZURE-STORAGE-CONNECTION-STRING` | Blob Storage 連線字串（或改用 MI） |
  | `DATABASE-URL` | PostgreSQL connection string |
  | `BASE-URL` | API 對外的 base URL |

- **App Service 取值方式**（Key Vault reference）：
  ```
  @Microsoft.KeyVault(SecretUri=https://<kv-name>.vault.azure.net/secrets/<secret-name>/)
  ```

---

#### 4. Managed Identity（系統指派 System-assigned MI）

- **原因**：讓 App Service 以身份驗證方式存取 Azure 資源，取代密碼/金鑰。
- **需要授予的 RBAC 角色**：

  | 資源 | 角色 |
  |------|------|
  | ACR | `AcrPull` |
  | Key Vault | `Key Vault Secrets User` |
  | Blob Storage | `Storage Blob Data Contributor`（建議取代 connection string） |

---

### 建議加上的資源

#### 5. Application Insights + Log Analytics Workspace

- **用途**：FastAPI request log、錯誤追蹤（exception）、效能監控（latency、throughput）。
- **整合方式**：在 App Service 設定 `APPLICATIONINSIGHTS_CONNECTION_STRING`，
  搭配 `opencensus-ext-azure` 或 `azure-monitor-opentelemetry` SDK。

---

#### 6. Private Endpoints + NSG

- **Blob Storage Private Endpoint**：Storage 流量不走公網，走 VNet 內部。
- **PostgreSQL Private Endpoint**：DB 連線不走公網，走 VNet 內部。
- **NSG（Network Security Group）**：限制 VNet 子網路的進出規則，只允許必要的 port 與來源 IP。

---

## 架構圖

```
Internet
    │
    ▼
Application Gateway (SSL termination, WAF)
    │
    ▼
App Service (Docker container: FastAPI + uvicorn)
    │   ├── pull image ──────────────────▶ Azure Container Registry (ACR)
    │   │                                   (via Managed Identity: AcrPull)
    │   │
    │   ├── read secrets ────────────────▶ Azure Key Vault
    │   │                                   (via Managed Identity: KV Secrets User)
    │   │
    │   ├── store QR PNG ────────────────▶ Azure Blob Storage
    │   │                                   (via Private Endpoint in VNet)
    │   │                                   (via Managed Identity: Blob Data Contributor)
    │   │
    │   └── read/write data ─────────────▶ Azure Database for PostgreSQL
    │                                       (via Private Endpoint in VNet)
    │
    └── logs / metrics ──────────────────▶ Application Insights
                                            └── Log Analytics Workspace
```

---

## Terraform 資源清單（依 Phase）

### Phase 1 — 基礎網路

| Terraform 資源 | 說明 |
|----------------|------|
| `azurerm_resource_group` | 所有資源的容器 |
| `azurerm_virtual_network` | VNet 主體 |
| `azurerm_subnet` × 4 | `subnet-appservice`（VNet Integration）<br>`subnet-db`（PostgreSQL）<br>`subnet-storage`（Blob Storage）<br>`subnet-private-endpoint`（Private Endpoints） |
| `azurerm_network_security_group` | NSG + inbound/outbound rules |

---

### Phase 2 — 身份與秘密管理

| Terraform 資源 | 說明 |
|----------------|------|
| `azurerm_user_assigned_identity` | App Service 使用的 User-assigned Managed Identity |
| `azurerm_key_vault` | Key Vault 主體 |
| `azurerm_key_vault_access_policy` × 2 | 一組給 MI（App Service 讀取），一組給 deployer（Terraform 寫入） |
| `azurerm_key_vault_secret` × 3 | `DATABASE_URL`、`AZURE_STORAGE_CONNECTION_STRING`、`BASE_URL` |

> **注意**：改用 User-assigned MI（`azurerm_user_assigned_identity`）而非 System-assigned，
> 好處是 identity 生命週期與 App Service 解耦，可提前建立再授予 RBAC，避免循環依賴。

---

### Phase 3 — 儲存與資料庫

| Terraform 資源 | 說明 |
|----------------|------|
| `azurerm_storage_account` | Blob Storage 主體 |
| `azurerm_storage_container` | 名稱 `qr-codes`，`public_access = blob` |
| `azurerm_postgresql_flexible_server` | PostgreSQL Flexible Server |
| `azurerm_postgresql_flexible_server_database` | 應用資料庫 |
| `azurerm_private_endpoint` × 2 | Storage Private Endpoint + PostgreSQL Private Endpoint |

---

### Phase 4 — Container Registry & App Service

| Terraform 資源 | 說明 |
|----------------|------|
| `azurerm_container_registry` | ACR，SKU: Basic（dev）/ Standard（prod） |
| `azurerm_service_plan` | Linux，B1 以上 |
| `azurerm_linux_web_app` | container mode，掛載 User-assigned MI |
| `azurerm_role_assignment` | MI → ACR `AcrPull` 角色 |
| App settings（Key Vault references） | `@Microsoft.KeyVault(SecretUri=...)` 格式注入 secrets |
| VNet Integration | App Service → `subnet-appservice` |

---

### Phase 5 — 流量入口

| Terraform 資源 | 說明 |
|----------------|------|
| `azurerm_public_ip` | static，供 Application Gateway 使用 |
| `azurerm_application_gateway` | Frontend → public IP；Backend pool → App Service |
| Listener rule | HTTP → HTTPS redirect |
| SSL 憑證 | `azurerm_key_vault_certificate` 或 App Gateway managed cert |

---

### Phase 6 — 監控

| Terraform 資源 | 說明 |
|----------------|------|
| `azurerm_log_analytics_workspace` | 集中儲存 log |
| `azurerm_application_insights` | 連結至 Log Analytics Workspace，注入 App Service |

---

## Terraform 模組規劃

```
terraform/
├── main.tf                  # provider、backend 設定
├── variables.tf             # 全域變數
├── outputs.tf               # 輸出值（ACR URL、App Service URL 等）
│
├── modules/
│   ├── networking/          # Phase 1：VNet、Subnet × 4、NSG
│   ├── identity/            # Phase 2：User-assigned MI
│   ├── key_vault/           # Phase 2：Key Vault、access policy × 2、secrets × 3
│   ├── storage/             # Phase 3：Storage Account、Container、Private Endpoint
│   ├── database/            # Phase 3：PostgreSQL Flexible Server、Private Endpoint
│   ├── acr/                 # Phase 4：Azure Container Registry
│   ├── app_service/         # Phase 4：App Service Plan、Web App、VNet Integration
│   ├── app_gateway/         # Phase 5：Application Gateway、public IP、SSL
│   └── monitoring/          # Phase 6：Application Insights、Log Analytics Workspace
│
└── envs/
    ├── dev/
    │   ├── main.tf
    │   └── terraform.tfvars
    └── prod/
        ├── main.tf
        └── terraform.tfvars
```

---

## 環境變數與 Secrets 清單

### App Service 應用程式設定（非敏感）

| 變數名稱 | 範例值 | 說明 |
|----------|--------|------|
| `DOCKER_REGISTRY_SERVER_URL` | `https://<acr>.azurecr.io` | ACR 位址 |
| `WEBSITES_PORT` | `8000` | uvicorn 監聽 port |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | `InstrumentationKey=...` | App Insights |

### App Service 透過 Key Vault Reference 取值（敏感）

| 變數名稱 | Key Vault Secret | 說明 |
|----------|-----------------|------|
| `DATABASE_URL` | `DATABASE-URL` | PostgreSQL connection string |
| `AZURE_STORAGE_CONNECTION_STRING` | `AZURE-STORAGE-CONNECTION-STRING` | Blob Storage（若未改用 MI） |
| `BASE_URL` | `BASE-URL` | API 對外 URL |

---

## 待辦事項

### Phase 1 — 基礎網路
- [ ] `modules/networking` — VNet、Subnet × 4（appservice / db / storage / private-endpoint）、NSG rules

### Phase 2 — 身份與秘密管理
- [ ] `modules/identity` — User-assigned Managed Identity
- [ ] `modules/key_vault` — Key Vault、access policy × 2（MI + deployer）、secrets × 3

### Phase 3 — 儲存與資料庫
- [ ] `modules/storage` — Storage Account、Container `qr-codes`、Private Endpoint
- [ ] `modules/database` — PostgreSQL Flexible Server、DB、Private Endpoint
- [ ] 修改應用程式 `database.py` — 支援 PostgreSQL（`DATABASE_URL` 環境變數）

### Phase 4 — Container Registry & App Service
- [ ] `modules/acr` — ACR（SKU: Basic/Standard）
- [ ] `modules/app_service` — App Service Plan（Linux B1+）、Web App（container mode）、VNet Integration、MI 掛載、Key Vault references、`azurerm_role_assignment`（AcrPull）

### Phase 5 — 流量入口
- [ ] `modules/app_gateway` — Public IP（static）、Application Gateway、HTTP→HTTPS redirect、SSL 憑證

### Phase 6 — 監控
- [ ] `modules/monitoring` — Log Analytics Workspace、Application Insights

### 其他
- [ ] CI/CD pipeline — build image → push ACR → deploy App Service
