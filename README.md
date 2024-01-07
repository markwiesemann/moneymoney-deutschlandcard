# moneymoney-deutschlandcard

This is an extension for the MoneyMoney Mac app (https://moneymoney-app.com/). It allows to fetch the total number of points and the transactions of the last year for a DeutschlandCard account. Authentication is supported via card number and password (PIN) or via the combination of card number, birth date, and zip code.

# Changelog 
- Version 1.0, 2020-01-26: initial version
- Version 1.1, 2020-04-05: support for DeutschlandCard's reCAPTCHA added
  (MoneyMoney 2.3.25 (353) or newer is required)

# How To Use
## Authentication

The username is your card number.

The password is either your PIN or the combination of your birthdate and zip code. In the latter case, the passwords needs to be entered in the format ```YYYY-MM-DD|123456```. So if your birthdate is January 15th, 1990 and you're living in 10062 Berlin, you would need to enter ```1990-01-15|10062``` as the password.
