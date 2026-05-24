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

### 必要資源

#### 1. Azure Database for PostgreSQL Flexible Server（或 Azure SQL）

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

#### 4. Managed Identity（User-assigned MI）

- **原因**：讓 App Service 以身份驗證方式存取 Azure 資源，取代密碼/金鑰。
- **需要授予的 RBAC 角色**：

  | 資源 | 角色 |
  |------|------|
  | Key Vault | `Key Vault Secrets User` |
  | Blob Storage | `Storage Blob Data Contributor` |

---

### 建議加上的資源

#### 5. Application Insights + Log Analytics Workspace

- **用途**：FastAPI request log、錯誤追蹤（exception）、效能監控（latency、throughput）。
- **整合方式**：在 App Service 設定 `APPLICATIONINSIGHTS_CONNECTION_STRING`，
  搭配 `opencensus-ext-azure` 或 `azure-monitor-opentelemetry` SDK。

---

#### 6. PostgreSQL Private Endpoint

- **PostgreSQL Private Endpoint**：DB 連線不走公網，走 VNet 內部。
- **Blob Storage**：使用公網端點 + SAS URL 存取（`container_access_type = "private"`），不使用 Private Endpoint。

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
    │   ├── pull image ──────────────────▶ GitHub Container Registry (GHCR)
    │   │
    │   ├── read secrets ────────────────▶ Azure Key Vault
    │   │                                   (via Managed Identity: KV Secrets User)
    │   │
    │   ├── store QR PNG ────────────────▶ Azure Blob Storage
    │   │                                   (public endpoint + SAS URL)
    │   │                                   (via Managed Identity: Blob Data Contributor)
    │   │
    │   └── read/write data ─────────────▶ Azure Database for PostgreSQL
    │                                       (via VNet Injection, private only)
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
| `azurerm_subnet` × 2 | `snet-appservice`（VNet Integration）<br>`snet-db`（PostgreSQL VNet Injection） |
| `azurerm_network_security_group` | NSG + inbound/outbound rules |

---

### Phase 2 — 身份與秘密管理

| Terraform 資源 | 說明 |
|----------------|------|
| `azurerm_user_assigned_identity` | App Service 使用的 User-assigned Managed Identity |
| `azurerm_key_vault` | Key Vault 主體 |
| `azurerm_key_vault_access_policy` × 2 | 一組給 MI（App Service 讀取），一組給 deployer（Terraform 寫入） |
| `azurerm_key_vault_secret` × 2 | `DATABASE_URL`、`AZURE_STORAGE_ACCOUNT_NAME` |

> **注意**：改用 User-assigned MI（`azurerm_user_assigned_identity`）而非 System-assigned，
> 好處是 identity 生命週期與 App Service 解耦，可提前建立再授予 RBAC，避免循環依賴。

---

### Phase 3 — 儲存與資料庫

| Terraform 資源 | 說明 |
|----------------|------|
| `azurerm_storage_account` | Blob Storage 主體（直接在 root module，無獨立 module） |
| `azurerm_storage_container` | 名稱 `qr-codes`，`container_access_type = "private"` |
| `azurerm_role_assignment` | MI → Storage `Storage Blob Data Contributor` 角色 |
| `azurerm_postgresql_flexible_server` | PostgreSQL Flexible Server |
| `azurerm_postgresql_flexible_server_database` | 應用資料庫 |

---

### Phase 4 — App Service

| Terraform 資源 | 說明 |
|----------------|------|
| `azurerm_service_plan` | Linux，B1 以上 |
| `azurerm_linux_web_app` | container mode，直接從 GHCR pull image，掛載 User-assigned MI |
| `azurerm_app_service_virtual_network_swift_connection` | App Service → `snet-appservice` VNet Integration |
| App settings（Key Vault references） | `@Microsoft.KeyVault(SecretUri=...)` 格式注入 secrets |

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
.
├── main.tf                  # provider、backend、resource group
├── variables.tf             # 全域變數
├── outputs.tf               # 輸出值（App Service URL 等）
├── app_service.tf           # App Service Plan、Web App、VNet Integration
├── storage.tf               # Storage Account、Container、Role Assignment
├── db.tf                    # PostgreSQL Flexible Server、DB
├── locals.tf                # 共用 tags、computed values
│
├── app.tfvars               # 跨環境共用變數（ghcr image 等）
├── dev.tfvars               # dev 環境變數
├── prod.tfvars              # prod 環境變數
│
├── backend/
│   ├── dev.hcl              # dev remote state backend config
│   └── prod.hcl             # prod remote state backend config
│
└── module/
    └── network/             # Phase 1：VNet、Subnet × 2（appservice / db）
```

---

## 環境變數與 Secrets 清單

### App Service 設定（非敏感，直接寫入）

| 變數名稱 | 範例值 | 說明 |
|----------|--------|------|
| `BASE_URL` | `https://app-qr-generator.azurewebsites.net` | API 對外 URL |
| `WEBSITES_PORT` | `8000` | uvicorn 監聽 port |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | `InstrumentationKey=...` | App Insights（Phase 6） |

### App Service 透過 Key Vault Reference 取值（敏感）

| 變數名稱 | Key Vault Secret | 說明 |
|----------|-----------------|------|
| `DATABASE_URL` | `DATABASE-URL` | PostgreSQL connection string |
| `AZURE_STORAGE_ACCOUNT_NAME` | `AZURE-STORAGE-ACCOUNT-NAME` | Blob Storage 帳戶名稱（搭配 MI 存取） |

---

## Resource Group 設計決策

本專案使用**兩個獨立的 Resource Group**：

| Resource Group | 用途 |
|----------------|------|
| `rg-qr-generator-{env}` | App Service、PostgreSQL、Blob Storage 等應用資源 |
| `rg-tfstate-qr` | Terraform remote state 的 Storage Account |

### 為什麼分開？

**安全隔離**：tfstate 是整個 infra 的命脈，記錄所有資源的當前狀態。若與應用資源放在同一個 RG，誤刪 RG（`az group delete`）會連 tfstate 一起刪掉，導致 Terraform 失去對所有資源的追蹤，難以復原。

**跨環境共用**：`rg-tfstate-qr` 同時服務 dev、prod 等多個環境（各自用不同的 blob key），不應該屬於任何單一環境的 RG。

**權限最小化**：GitHub Actions SP 對 `rg-qr-generator-dev` 有 `Reader`/`Contributor`，對 `rg-tfstate-qr` 只有 `Reader` + `Storage Blob Data Contributor`，做到最小權限原則。

---


## TODO

### Infrastructure

- [ ] Add Azure Cache for Redis (`azurerm_redis_cache`) + connect to App Service via app settings
- [ ] Move `db_password` to Azure Key Vault (`azurerm_key_vault_secret`) and have App Service read via Key Vault reference
- [ ] Replace Storage Account SAS URL with IAM-based access (Managed Identity + Storage Blob Data Reader role assignment)
- [ ] load test , test rate limit