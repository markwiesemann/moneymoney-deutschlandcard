-- MoneyMoney extension for DeutschlandCard
--
--
-- MIT License
--
-- Copyright (c) 2020 Mark Wiesemann
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
  version = 1.1,
  country = "de",
  url = "https://www.deutschlandcard.de/",
  services = {"DeutschlandCard-Punkte"},
  description = "Deutschlandcard-Punkte"
}

-- global variables (used in various functions)
local cardNumber
local pin
local connection
local headersWithToken


local function GetTransactions(url, transactions)
  content, _, _, _, headers = connection:request("GET", url, "", "application/json", headersWithToken)
  if (headers["Content-Length"] == "0") then
    error("API returned an error")
  end
  fields = JSON(content):dictionary()
  for key, monthData in ipairs(fields["result"]) do
    for key, monthlyTransaction in ipairs(monthData["bookings"]) do
      _, _, year, month, day = string.find(monthlyTransaction["transactionDate"], "(%d+)-(%d+)-(%d+)")
      local singleTransaction = {
        name = monthlyTransaction["partner"],
        amount = monthlyTransaction["amount"] / 100,
        purpose = monthlyTransaction["bookingText"],
        bookingDate = os.time{year = year, month = month, day = day, hour = 0}
      }
      table.insert(transactions, singleTransaction)
    end
  end
  return fields["hasMoreResults"], fields["nextSearchParams"]
end


function SupportsBank(protocol, bankCode)
  return bankCode == "DeutschlandCard-Punkte" and protocol == ProtocolWebBanking
end


function InitializeSession2(protocol, bankCode, step, credentials, interactive)
  if step == 1 then

    -- Cache card number and PIN for step 2.
    cardNumber = credentials[1]
    pin = credentials[2]

    -- Load reCAPTCHA v3.
    return {challenge="https://www.recaptcha.net/recaptcha/api.js?render=6Le2S9AUAAAAAD4SMzwje15-swuVJtwV9O1HyL9T"}

  elseif step == 2 then

    -- Create HTTPS connection object.
    connection = Connection()
    connection.language = "de-de"

    -- Prepare HTTP headers.
    headers = {}
    headers["Accept"] = "application/json"
    headers["x-recaptcha-v3"] = credentials[1]

    -- Submit login form.
    print("Submitting login form.")
    local postContent = JSON():set{grant_type="password",response_type="id_token token",scope="deutschlandcardapi offline_access",audience="deutschlandcardapi",username=cardNumber,password=pin}:json()
    local json = JSON(connection:request("POST", url .. "api/v1/auth/connect/token", postContent, "application/json", headers)):dictionary()

    -- Check for login error.
    local message = json["data"] and json["data"]["error_description"]
    if message then
      print("Response:", message)
      if message == "invalid credential" then
        return LoginFailed
      end
    end

    -- Extract access token.
    if not json["access_token"] then
      return "Der Server von DeutschlandCard hat kein Access-Token übermittelt. Bitte versuchen Sie es später noch einmal."
    else
      headersWithToken = {}
      headersWithToken["Accept"] = "application/json"
      headersWithToken["Authorization"] = "Bearer " .. json["access_token"]
    end
  end
end


function EndSession()
  -- nothing to be done due to the token-based approach (=> the token will expire after an hour)
end

function ListAccounts(knownAccounts)
  url = "https://www.deutschlandcard.de/api/v1/profile/memberinfo"
  content, _, _, _, headers = connection:request("GET", url, "", "application/json", headersWithToken)
  if (headers["Content-Length"] == "0") then
    error("API returned an error")
  end
  fields = JSON(content):dictionary()
  return {
    {
      name = "DeutschlandCard",
      owner = fields["firstname"] .. " " .. fields["lastname"],
      accountNumber = cardNumber,
      currency = "EUR",
      type = AccountTypeOther
    }
  }
end

function RefreshAccount(account, since)
  url = "https://www.deutschlandcard.de/api/v1/profile/memberpoints"
  content, _, _, _, headers = connection:request("GET", url, "", "application/json", headersWithToken)
  if (headers["Content-Length"] == "0") then
    error("API returned an error")
  end
  fields = JSON(content):dictionary()

  balance = fields["balance"] / 100

  local transactions = {}
  local offset = 1
  local limit = 1

  repeat
    url = "https://www.deutschlandcard.de/api/v1/profile/bookings?offset=" .. offset .. "&limit=" .. limit
    hasMoreResults, nextSearchParams = GetTransactions(url, transactions)

    if (hasMoreResults) then
      offset = nextSearchParams["offset"]
      limit = nextSearchParams["limit"]
    end
  until (hasMoreResults == false)

  return {balance=balance, transactions=transactions}
end
