# moneymoney-deutschlandcard

This is an extension for the MoneyMoney Mac app (https://moneymoney-app.com/). It allows to fetch the total number of points and the transactions of the last year for a DeutschlandCard account. Authentication is supported via card number and password (but not via card number, birth date, and zip code).

# Changelog 
- Version 1.0, 2020-01-26: initial version
- Version 1.1, 2020-04-05: support for DeutschlandCard's reCAPTCHA added
  (MoneyMoney 2.3.25 (353) or newer is required)

# How To Use
## Login-credentials

The username ist your card number.

The password is either your PIN or a combination of your birthdate and postal code, depending on which credentials you use for logging in on the website. When using birthdate and postal code, it needs to be entered in the format ```YYYY-MM-DD|123456```. So if your birthdate is on the 01. January 1990 and you're living in 10062 Berlin, you'd need to enter ```1990-01-01|10062``` as your password.
