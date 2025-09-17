-- Unofficial E*TRADE Extension for MoneyMoney
-- Fetches account balances and transactions from E*TRADE API
--
-- IMPORTANT: This is a prototype/educational implementation
--
-- LIMITATIONS:
-- 1. OAuth 1.0a signature generation is incomplete (needs HMAC-SHA1)
-- 2. Manual authorization step is not implemented
-- 3. Real E*TRADE API endpoints need to be mapped properly
-- 4. Token storage and renewal not fully implemented
-- 5. Error handling could be improved
--
-- REQUIRED FOR PRODUCTION:
-- 1. Implement proper HMAC-SHA1 signature generation
-- 2. Handle OAuth authorization callback/verification
-- 3. Use correct E*TRADE API endpoints
-- 4. Implement token renewal and storage
-- 5. Add comprehensive error handling
--
-- USAGE:
-- Username: Your E*TRADE username
-- Password: Consumer Key and Consumer Secret separated by "|"
--           Format: "CONSUMER_KEY|CONSUMER_SECRET"
--           Example: "abc123def456|xyz789secret123"
--
-- SETUP:
-- 1. Register for E*TRADE Developer account
-- 2. Create an application to get Consumer Key and Secret
-- 3. Configure callback URL if needed
-- 4. Use sandbox environment for testing
--
-- Copyright (c) 2025
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

WebBanking {
    version     = 1.0,
    url         = "https://apisb.etrade.com/", -- Using sandbox environment
    services    = { "E*TRADE Account" },
    description = "Fetches account balances and transactions from E*TRADE API"
}

-- Global variables for OAuth and session management
local consumerKey
local consumerSecret
local userAccount
local accessToken
local accessTokenSecret
local accountList

-- E*TRADE API Configuration
local apiVersion = "v1"
local baseUrl = "https://apisb.etrade.com" -- Sandbox URL
local oauthBaseUrl = "https://apisb.etrade.com"

-- OAuth URLs
local requestTokenUrl = "/oauth/request_token"
local authorizeUrl = "https://us.etrade.com/e/t/etws/authorize"
local accessTokenUrl = "/oauth/access_token"
local renewTokenUrl = "/oauth/renew_access_token"

function SupportsBank(protocol, bankCode)
    return protocol == ProtocolWebBanking and bankCode == "E*TRADE Account"
end

function InitializeSession(protocol, bankCode, username, reserved, password)
    -- Store username parameter in global variable for other functions to use
    userAccount = username

    -- Parse the password field which contains "CONSUMER_KEY|CONSUMER_SECRET"
    if not password or password == "" then
        error("Password field is required. Format: CONSUMER_KEY|CONSUMER_SECRET")
    end

    local separatorPos = string.find(password, "|")
    if not separatorPos then
        error("Invalid password format. Expected: CONSUMER_KEY|CONSUMER_SECRET (separated by |)")
    end

    consumerKey = string.sub(password, 1, separatorPos - 1)
    consumerSecret = string.sub(password, separatorPos + 1)

    LogDebugInfo("Initializing E*TRADE session for user: " .. tostring(userAccount))
    LogDebugInfo("Consumer Key: " .. string.sub(consumerKey, 1, 8) .. "..." .. string.sub(consumerKey, -4))

    -- Validate all required credentials
    ValidateCredentials()

    LogDebugInfo("Credentials validated, starting OAuth flow")

    -- Initialize OAuth flow
    AuthenticateWithETrade()

    LogDebugInfo("Session initialization completed")
end

function ListAccounts(knownAccounts)
    if not accessToken then
        error("Not authenticated. Please check your credentials.")
    end

    local accounts = {}

    -- Fetch account list from E*TRADE
    pcall(function()
        local accountListResponse = ETradeRequest("GET", "/v1/user/alerts")

        -- Parse the response and create account objects
        -- Note: This is simplified - real E*TRADE response would need proper parsing
        local responseData = accountListResponse:dictionary()

        if responseData and responseData.AlertsResponse then
            -- Create a general E*TRADE account for now
            local account = {
                name = "E*TRADE Account (" .. userAccount .. ")",
                accountNumber = userAccount,
                type = AccountTypeGiro,
                currency = "USD"
            }
            table.insert(accounts, account)
        end
    end)

    -- If API call fails, still provide a default account for testing
    if #accounts == 0 then
        local account = {
            name = "E*TRADE Account (" .. userAccount .. ")",
            accountNumber = userAccount,
            type = AccountTypeGiro,
            currency = "USD"
        }
        table.insert(accounts, account)
    end

    return accounts
end

function RefreshAccount(account, since)
    if not accessToken then
        error("Not authenticated. Access token is missing.")
    end

    return {
        balances = GetAccountBalances(account),
        transactions = GetAccountTransactions(account, since)
    }
end

function EndSession()
    -- Revoke access token if we have one
    if accessToken then
        RevokeAccessToken()
    end

    -- Clear sensitive data
    accessToken = nil
    accessTokenSecret = nil
    consumerKey = nil
    consumerSecret = nil
    userAccount = nil
end

-- OAuth 1.0a Implementation
function AuthenticateWithETrade()
    -- Step 1: Get request token from E*TRADE
    LogDebugInfo("Starting OAuth 1.0a authentication flow...")

    local requestToken, requestTokenSecret = GetRequestToken()

    if not requestToken or not requestTokenSecret then
        error("Failed to obtain request token from E*TRADE. Check your Consumer Key/Secret.")
    end

    LogDebugInfo("Request token obtained: " .. string.sub(requestToken, 1, 16) .. "...")

    -- Step 2: Generate authorization URL for user
    local authUrl = authorizeUrl .. "?key=" .. consumerKey .. "&token=" .. requestToken

    -- Step 3: Manual authorization required (MoneyMoney limitation)
    -- In a real implementation, we would need to handle the verification code
    -- For now, we'll simulate having completed the authorization

    error("MANUAL AUTHORIZATION REQUIRED:\n\n" ..
        "1. Visit this URL in your browser:\n" .. authUrl .. "\n\n" ..
        "2. Log in to E*TRADE and authorize the application\n" ..
        "3. Copy the verification code shown\n" ..
        "4. This extension needs to be updated to accept the verification code\n\n" ..
        "Currently the OAuth flow cannot be completed automatically due to " ..
        "MoneyMoney's extension limitations with browser redirects.")

    -- TODO: Complete OAuth flow
    -- Step 4: Exchange request token + verification code for access token
    -- This would require:
    -- - User input mechanism for verification code
    -- - Call to GetAccessToken(requestToken, requestTokenSecret, verificationCode)
end

function GetRequestToken()
    local oauthParams = {
        oauth_consumer_key = consumerKey,
        oauth_nonce = GenerateNonce(),
        oauth_signature_method = "HMAC-SHA1",
        oauth_timestamp = tostring(os.time()),
        oauth_version = "1.0"
    }

    -- Generate signature
    local signature = GenerateOAuthSignature("GET", oauthBaseUrl .. requestTokenUrl, oauthParams, consumerSecret, "")
    oauthParams.oauth_signature = signature

    -- Build authorization header
    local authHeader = BuildOAuthHeader(oauthParams)

    -- Make request
    local connection = Connection()
    local headers = {
        ["Authorization"] = authHeader,
        ["Accept"] = "application/json"
    }

    local content, err = connection:request("GET", oauthBaseUrl .. requestTokenUrl, nil, nil, headers)

    if err then
        error("Request token request failed: " .. tostring(err))
    end

    -- Parse response (typically form-encoded)
    local requestToken, requestTokenSecret = ParseTokenResponse(content)

    return requestToken, requestTokenSecret
end

function ETradeRequest(method, endpoint, params)
    if not accessToken then
        error("No access token available")
    end

    local url = baseUrl .. endpoint
    local oauthParams = {
        oauth_consumer_key = consumerKey,
        oauth_token = accessToken,
        oauth_nonce = GenerateNonce(),
        oauth_signature_method = "HMAC-SHA1",
        oauth_timestamp = tostring(os.time()),
        oauth_version = "1.0"
    }

    -- Generate signature
    local signature = GenerateOAuthSignature(method, url, oauthParams, consumerSecret, accessTokenSecret)
    oauthParams.oauth_signature = signature

    -- Build authorization header
    local authHeader = BuildOAuthHeader(oauthParams)

    local connection = Connection()
    local headers = {
        ["Authorization"] = authHeader,
        ["Accept"] = "application/json"
    }

    local content, err = connection:request(method, url, nil, nil, headers)

    if err then
        error("E*TRADE API request failed: " .. tostring(err))
    end

    local json = JSON(content)
    local response = json:dictionary()

    if response.error then
        error("E*TRADE API error: " .. tostring(response.error.message or response.error))
    end

    return json
end

function GetAccountBalances(account)
    local balances = {}

    -- Try to fetch actual account balance from E*TRADE
    pcall(function()
        -- E*TRADE API endpoint for account balance would be something like:
        -- /v1/user/alerts or /v1/accounts/list for account information
        local balanceResponse = ETradeRequest("GET", "/v1/user/alerts")
        local responseData = balanceResponse:dictionary()

        -- Parse balance information from response
        -- Note: This is simplified - real E*TRADE API response structure would differ
        if responseData then
            local balance = {}
            balance[1] = 10000.00 -- Placeholder amount
            balance[2] = "USD"    -- Default currency
            table.insert(balances, balance)
        end
    end)

    -- Fallback to default balance if API call fails
    if #balances == 0 then
        local balance = {}
        balance[1] = 10000.00 -- Default amount for testing
        balance[2] = "USD"    -- Default currency
        table.insert(balances, balance)
    end

    return balances
end

function GetAccountTransactions(account, since)
    local transactions = {}

    -- Try to fetch actual transactions from E*TRADE
    pcall(function()
        -- E*TRADE API endpoint for transactions would be something like:
        -- /v1/accounts/{accountId}/transactions
        local transactionResponse = ETradeRequest("GET", "/v1/user/alerts")
        local responseData = transactionResponse:dictionary()

        -- Parse transaction data from response
        -- Note: This would need to be adapted to actual E*TRADE API response format
        if responseData then
            -- Add parsed transactions here
            local transaction = {
                bookingDate = os.time() - 86400, -- Yesterday
                valueDate = os.time() - 86400,
                purpose = "E*TRADE Transaction",
                name = "Stock Purchase",
                amount = -500.00, -- Purchase (negative)
                currency = "USD",
                booked = true
            }
            table.insert(transactions, transaction)

            -- Add another sample transaction
            local transaction2 = {
                bookingDate = os.time() - 172800, -- Two days ago
                valueDate = os.time() - 172800,
                purpose = "Dividend Payment",
                name = "AAPL Dividend",
                amount = 25.50, -- Income (positive)
                currency = "USD",
                booked = true
            }
            table.insert(transactions, transaction2)
        end
    end)

    -- Fallback to sample transactions if API call fails
    if #transactions == 0 then
        local transaction = {
            bookingDate = os.time() - 86400,
            valueDate = os.time() - 86400,
            purpose = "Sample E*TRADE Transaction",
            name = "Test Transaction",
            amount = 100.00,
            currency = "USD",
            booked = true
        }
        table.insert(transactions, transaction)
    end

    return transactions
end

-- OAuth Helper Functions
function GenerateNonce()
    -- Generate a cryptographically secure nonce using MoneyMoney's random function
    local randomBytes = MM.random(16)                      -- 16 bytes of random data
    local nonce = MM.base64(randomBytes):gsub("[^%w]", "") -- Remove non-alphanumeric chars

    -- Ensure we have a reasonable length nonce (OAuth spec recommends unique values)
    return string.sub(nonce, 1, 32) -- 32 character nonce
end

function GenerateOAuthSignature(method, url, params, consumerSecret, tokenSecret)
    -- Real OAuth 1.0a signature generation using MoneyMoney's built-in crypto functions

    -- Create normalized parameter string
    local paramString = ""
    local sortedKeys = {}

    -- Collect and sort all parameters
    for k, v in pairs(params) do
        table.insert(sortedKeys, k)
    end
    table.sort(sortedKeys)

    -- Build parameter string with proper URL encoding
    for i, key in ipairs(sortedKeys) do
        if paramString ~= "" then
            paramString = paramString .. "&"
        end
        paramString = paramString .. MM.urlencode(key) .. "=" .. MM.urlencode(tostring(params[key]))
    end

    -- Create signature base string (as per OAuth 1.0a spec)
    local baseString = MM.urlencode(method) .. "&" .. MM.urlencode(url) .. "&" .. MM.urlencode(paramString)

    -- Create signing key
    local signingKey = MM.urlencode(consumerSecret) .. "&" .. MM.urlencode(tokenSecret or "")

    -- Generate HMAC-SHA1 signature using MoneyMoney's built-in functions
    local hmacSignature = MM.hmac1(signingKey, baseString)

    -- Base64 encode the result
    local base64Signature = MM.base64(hmacSignature)

    LogDebugInfo("OAuth signature generated successfully")
    LogDebugInfo("Base string length: " .. string.len(baseString))
    LogDebugInfo("Signature: " .. string.sub(base64Signature, 1, 16) .. "...")

    return base64Signature
end

function BuildOAuthHeader(params)
    local header = "OAuth "
    local first = true

    for key, value in pairs(params) do
        if not first then
            header = header .. ", "
        end
        header = header .. key .. '="' .. MM.urlencode(tostring(value)) .. '"'
        first = false
    end

    return header
end

function ParseTokenResponse(response)
    -- Parse form-encoded response like: oauth_token=xxx&oauth_token_secret=yyy
    local token = response:match("oauth_token=([^&]+)")
    local tokenSecret = response:match("oauth_token_secret=([^&]+)")

    return token, tokenSecret
end

-- UrlEncode function removed - now using MM.urlencode() built-in function

function RevokeAccessToken()
    if not accessToken then
        return
    end

    -- Make revoke request
    pcall(function()
        ETradeRequest("GET", "/oauth/revoke_access_token")
        print("Access token revoked successfully")
    end)
end

-- Additional Helper Functions for E*TRADE API

function RenewAccessToken()
    -- E*TRADE tokens expire at midnight Eastern Time
    -- This function would renew the existing token without requiring re-authorization
    if not accessToken then
        print("No access token to renew")
        return false
    end

    pcall(function()
        local renewResponse = ETradeRequest("GET", "/oauth/renew_access_token")
        print("Access token renewed successfully")
        return true
    end)

    return false
end

function ValidateCredentials()
    -- Validate that we have all required credentials
    if not consumerKey or consumerKey == "" then
        error("Missing Consumer Key. Please check your password format: CONSUMER_KEY|CONSUMER_SECRET")
    end

    if not consumerSecret or consumerSecret == "" then
        error("Missing Consumer Secret. Please check your password format: CONSUMER_KEY|CONSUMER_SECRET")
    end

    if not userAccount or userAccount == "" then
        error("Missing Username. Please provide your E*TRADE username in the Username field.")
    end

    -- Additional validation
    if string.len(consumerKey) < 10 then
        error("Consumer Key seems too short. Please verify your credentials.")
    end

    if string.len(consumerSecret) < 10 then
        error("Consumer Secret seems too short. Please verify your credentials.")
    end

    return true
end

function LogDebugInfo(message)
    -- Helper function for debugging
    print("[E*TRADE DEBUG] " .. tostring(message))
end

--[[

USAGE GUIDE FOR E*TRADE MONEYMONEY EXTENSION
============================================

CURRENT STATUS:
This is a prototype/educational implementation that demonstrates the structure
of a MoneyMoney extension for E*TRADE. The OAuth 1.0a implementation is incomplete
and requires additional work for production use.

SETUP REQUIREMENTS:
1. E*TRADE Developer Account
   - Register at https://developer.etrade.com/
   - Create a new application
   - Note down Consumer Key and Consumer Secret

2. MoneyMoney Configuration
   - Place this file in MoneyMoney's Extensions directory
   - Add a new account with "E*TRADE Account" as the bank
   - Fill in the credential fields:
     * Username: Your E*TRADE username
     * Password: "CONSUMER_KEY|CONSUMER_SECRET"
       Example: "c5bb4dcb7bd6826c7c4340df3f791188|7d30246211192cda43ede3abd9b393b9"

LIMITATIONS:
- OAuth 1.0a signature generation is incomplete (placeholder implementation)
- Manual authorization step is not handled (requires user intervention)
- Uses sandbox endpoints (for testing only)
- Transaction and balance data is mostly simulated

TO MAKE THIS PRODUCTION-READY:
1. Implement proper HMAC-SHA1 signature generation for OAuth
2. Handle the OAuth authorization flow (browser redirect/callback)
3. Use correct E*TRADE API endpoints for accounts, balances, and transactions
4. Implement proper error handling for all API responses
5. Add token renewal functionality
6. Switch from sandbox to production URLs

TECHNICAL NOTES:
- Uses E*TRADE API v1 (sandbox environment)
- Follows MoneyMoney WebBanking API structure
- Implements required functions: SupportsBank, InitializeSession, ListAccounts, RefreshAccount, EndSession
- Includes helper functions for OAuth workflow

FOR DEVELOPERS:
If you want to complete this implementation, focus on:
1. OAuth signature generation (GenerateOAuthSignature function)
2. Real E*TRADE API endpoint integration
3. Authorization callback handling
4. Proper error handling and user feedback

This extension serves as a foundation and demonstrates the MoneyMoney extension
pattern that can be adapted for other OAuth-based financial APIs.

]]
