# E*TRADE Extension for MoneyMoney

An unofficial MoneyMoney extension that connects to E*TRADE's API to fetch account balances and transactions.

## ⚠️ Current Status: **Prototype/Educational**

This extension is currently a **working prototype** that demonstrates the MoneyMoney WebBanking API integration with OAuth-based financial APIs. 

### What Works ✅
- ✅ MoneyMoney extension structure and API compliance
- ✅ E*TRADE sandbox credential parsing and validation
- ✅ OAuth 1.0a workflow framework
- ✅ Placeholder account and transaction data display
- ✅ Comprehensive error handling and debug logging

### What's Missing ❌
- ✅ **OAuth 1.0a HMAC-SHA1 signature generation** (IMPLEMENTED!)
- ❌ OAuth authorization callback handling (manual intervention required)
- ❌ Real E*TRADE API endpoint integration
- ❌ Production environment support

## 📋 Prerequisites

### 1. E*TRADE Developer Account
- Register at [E*TRADE Developer Portal](https://developer.etrade.com/)
- Create a new application to obtain:
  - **Consumer Key** (e.g., `c5bb4dcb7bd6826c7c4340df3f791188`)
  - **Consumer Secret** (e.g., `7d30246211192cda43ede3abd9b393b9`)

### 2. MoneyMoney App
- [MoneyMoney for macOS](https://moneymoney-app.com/) (version 2.3 or later)
- Valid MoneyMoney license for using extensions

## 🚀 Installation

### Step 1: Download the Extension
```bash
# Clone this repository
git clone https://github.com/your-username/etrade-moneymoney.git
cd etrade-moneymoney
```

### Step 2: Install in MoneyMoney
```bash
# Copy the extension to MoneyMoney's Extensions directory
cp ETrade.lua ~/Library/Containers/com.moneymoney-app.retail/Data/Library/Application\ Support/MoneyMoney/Extensions/
```

### Step 3: Restart MoneyMoney
- Quit and restart MoneyMoney to load the new extension

## ⚙️ Configuration

### Step 1: Add E*TRADE Account
1. Open MoneyMoney
2. Go to **Account → Add Account**
3. Select **"E*TRADE Account"** from the list

### Step 2: Enter Credentials
MoneyMoney will prompt for two fields:

**Username:** `your_etrade_username`  
**Password:** `CONSUMER_KEY|CONSUMER_SECRET`

**Example:**
- **Username:** `john_doe`
- **Password:** `c5bb4dcb7bd6826c7c4340df3f791188|7d30246211192cda43ede3abd9b393b9`

### Step 3: Save Account
- Click **Add** to save the account configuration
- MoneyMoney will attempt to connect using the provided credentials

## 📊 Expected Behavior

### Current Prototype Functionality
- **Account Creation:** Successfully adds E*TRADE account to MoneyMoney
- **Balance Display:** Shows placeholder balance of $10,000 USD
- **Transaction History:** Displays sample transactions:
  - Stock purchase (-$500.00)
  - Dividend payment (+$25.50)
- **Debug Logging:** Comprehensive logging in MoneyMoney's console

### Debug Output Example
```
[E*TRADE DEBUG] Initializing E*TRADE session for user: john_doe
[E*TRADE DEBUG] Consumer Key: c5bb4dcb...f188
[E*TRADE DEBUG] Credentials validated, starting OAuth flow
[E*TRADE DEBUG] WARNING: Using placeholder authentication...
```

## 🛠️ Troubleshooting

### Common Issues

#### "Invalid password format" Error
- **Cause:** Missing `|` separator in password field
- **Solution:** Ensure password format is `CONSUMER_KEY|CONSUMER_SECRET`

#### "Consumer Key seems too short" Error
- **Cause:** Invalid or incomplete E*TRADE credentials
- **Solution:** Verify Consumer Key and Secret from E*TRADE Developer Portal

#### No Account Data Showing
- **Expected:** Current version shows placeholder data only
- **Check:** Look for debug messages in MoneyMoney's console

### Viewing Debug Logs
1. In MoneyMoney: **Window → Show Console**
2. Look for `[E*TRADE DEBUG]` messages
3. Check for error messages during account sync

## 🔧 Development Status

### For Production Use, Implement:

#### 1. OAuth Authorization Flow ⭐ **NOW HIGHEST PRIORITY**
**GOOD NEWS:** OAuth signature generation is now implemented using MoneyMoney's built-in crypto functions!

**REMAINING:** Handle user authorization manually:
```lua
-- Current status: Shows authorization URL to user
error("MANUAL AUTHORIZATION REQUIRED:\n" ..
      "Visit: " .. authUrl .. "\n" ..
      "Get verification code and update extension")
```

#### 2. Real E*TRADE API Endpoints
- Replace `/v1/user/alerts` with actual account endpoints:
  - `/v1/user/alerts` → `/v1/account/list`
  - Add `/v1/account/{accountIdKey}/balance`
  - Add `/v1/account/{accountIdKey}/transactions`

#### 3. OAuth Authorization Flow  
- ✅ **HMAC-SHA1 signature generation** (implemented with MM.hmac1)
- ❌ User authorization callback mechanism  
- ❌ Verification code processing
- ❌ Proper token storage and renewal

#### 4. Production Environment
- Switch from sandbox (`apisb.etrade.com`) to production (`api.etrade.com`)
- Add environment selection option

## 🏗️ Technical Architecture

### MoneyMoney Integration
- **Language:** Lua 5.3
- **API:** MoneyMoney WebBanking API
- **Functions:** `SupportsBank`, `InitializeSession`, `ListAccounts`, `RefreshAccount`, `EndSession`

### E*TRADE API Integration
- **Authentication:** OAuth 1.0a with HMAC-SHA1 signatures
- **Crypto Functions:** MoneyMoney built-ins (`MM.hmac1`, `MM.base64`, `MM.urlencode`)
- **Environment:** Sandbox (apisb.etrade.com)
- **Format:** JSON responses
- **Version:** API v1

### File Structure
```
etrade-moneymoney/
├── ETrade.lua          # Main extension file
├── README.md           # This documentation
└── LICENSE             # MIT License
```

## 🤝 Contributing

### How to Help

#### For Crypto/Security Developers
- **Priority 1:** Implement proper HMAC-SHA1 signature generation
- **Skills needed:** Lua, cryptography, OAuth 1.0a specification

#### For API Integration Developers  
- **Priority 2:** Map E*TRADE API endpoints to MoneyMoney data structures
- **Skills needed:** REST APIs, JSON parsing, financial data modeling

#### For UX Developers
- **Priority 3:** Improve authorization flow and error handling
- **Skills needed:** User experience design, error messaging

### Development Setup
```bash
# Clone repository
git clone https://github.com/your-username/etrade-moneymoney.git

# Install in MoneyMoney (development)
ln -s $(pwd)/ETrade.lua ~/Library/Containers/com.moneymoney-app.retail/Data/Library/Application\ Support/MoneyMoney/Extensions/

# Test with sandbox credentials
# (See Configuration section above)
```

### Testing
1. **Sandbox Testing:** Use E*TRADE sandbox credentials
2. **Debug Logging:** Enable verbose logging in MoneyMoney
3. **Error Scenarios:** Test invalid credentials, network failures
4. **Data Validation:** Verify account and transaction data parsing

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

- **Unofficial:** Not affiliated with E*TRADE or MoneyMoney
- **Educational:** Primarily for learning MoneyMoney extension development
- **No Warranty:** Use at your own risk
- **No Real Trading:** Currently uses sandbox environment only

## 🔗 Resources

- [E*TRADE Developer Portal](https://developer.etrade.com/)
- [E*TRADE API Documentation](https://apisb.etrade.com/docs/api/account/api-account-v1.html)
- [MoneyMoney WebBanking API](https://moneymoney.app/api/webbanking/)
- [OAuth 1.0a Specification](https://tools.ietf.org/html/rfc5849)

## 📞 Support

For issues related to:
- **Extension bugs:** Open an issue on GitHub
- **E*TRADE API:** Consult E*TRADE Developer documentation
- **MoneyMoney:** Contact MoneyMoney support

---

**Happy Banking! 🏦**
