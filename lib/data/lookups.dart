/// Small static reference lists used by the default seed and DQ rules.

const isoCountryCodes = <String>[
  'GB', 'US', 'DE', 'FR', 'IN', 'JP', 'AU', 'CA', 'BR', 'NG', 'SG', 'KR',
  'IT', 'ES', 'NL', 'SE', 'CH', 'AE', 'ZA', 'MX',
];

/// ISO 4217 currency codes (subset).
const currencyCodes = <String>[
  'USD', 'EUR', 'GBP', 'JPY', 'INR', 'AUD', 'CAD', 'CHF', 'CNY', 'SGD',
];

/// Generic status codes used by `CUSTOMERS.STATUS` and `ORDERS.STATUS`.
const statusCodes = <String>['ACTIVE', 'INACTIVE', 'PENDING', 'CLOSED'];

/// Simple email pattern used by `EMPLOYEES.EMAIL` and `CUSTOMERS.EMAIL`.
const emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
