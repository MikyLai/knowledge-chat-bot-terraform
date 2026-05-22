Step 1（推薦）
App Service → PostgreSQL private

先做：

App Service VNet Integration
+
PostgreSQL Private Access

這是最有代表性的 Azure networking。

架構會變：
Internet
   ↓
App Service (public ingress)
   ↓
VNet Integration
   ↓
Private PostgreSQL
PostgreSQL

現在你是：

public network access
firewall 0.0.0.0

之後改：

delegated subnet
private dns zone
public_network_access_enabled = false
這是 Azure 很重要的觀念

AWS：

RDS in subnet

Azure：

Flexible Server delegated subnet
Step 2

Storage private endpoint

現在：

blob.core.windows.net

公開。

之後：

Private Endpoint
Step 3

完全 private ingress

現在：

App Service public URL

之後：

Front Door / App Gateway
+
Private App Service

這比較進階。

你現在最值得學的是
Azure networking 跟 AWS 最大不同：

| AWS | Azure |
|---|---|
| Security Group | NSG |
| Route Table | Route Table |
| RDS subnet group | Delegated subnet |
| PrivateLink | Private Endpoint |
| IAM | Entra ID + RBAC |

如果是 SRE / Platform interview

做到：

App Service
→ VNet integration
→ PostgreSQL private networking

已經非常加分。

我建議你的下一步 roadmap
1
App Service VNet Integration
2
PostgreSQL private access
3
Private DNS Zone
4
Disable public DB access
之後再做
5
Key Vault

把：

DB password
Storage secrets

移出去。

6
Managed Identity + Storage IAM

讓 App Service 用 Managed Identity 存取 Storage，完全不用 connection string / secret。

步驟：
1. 啟用 App Service system-assigned identity
   ```hcl
   identity {
     type = "SystemAssigned"
   }
   ```
2. 指派 Storage Blob Data Contributor role
   ```hcl
   resource "azurerm_role_assignment" "app_storage" {
     scope                = azurerm_storage_account.app.id
     role_definition_name = "Storage Blob Data Contributor"
     principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
   }
   ```
3. App Service 改用 DefaultAzureCredential（不再需要 AZURE_STORAGE_CONNECTION_STRING）
4. 移除 app_settings 裡的 AZURE_STORAGE_CONNECTION_STRING

優點：
- 不用管 secret rotation
- 符合 zero-secret 原則
- Azure 推薦的 production 做法

這些就是：
真正 Azure production architecture

了。