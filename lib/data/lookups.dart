/// Small static reference lists used by SAP-mirror data and DQ rules.

const isoCountryCodes = <String>[
  'GB', 'US', 'DE', 'FR', 'IN', 'JP', 'AU', 'CA', 'BR', 'NG', 'SG', 'KR',
  'IT', 'ES', 'NL', 'SE', 'CH', 'AE', 'ZA', 'MX',
];

/// Common SAP units of measure (subset).
const sapUoms = <String>[
  'EA', 'PC', 'KG', 'G', 'L', 'ML', 'M', 'MM', 'CM', 'BOX', 'PAL', 'TO',
];

/// SAP customer account groups (KTOKD).
const customerAccountGroups = <String>['0001', '0002', 'CPDA', 'KUNA', 'YB01'];

/// SAP material types (MTART).
const materialTypes = <String>['FERT', 'HALB', 'ROH', 'HAWA', 'DIEN', 'NLAG'];

/// SAP pricing condition types (KSCHL).
const conditionTypes = <String>['PR00', 'ZD01', 'K007', 'MWST', 'PB00'];

/// SAP sales organisations (VKORG).
const salesOrgs = <String>['1000', '2000', '3000'];

/// SAP plants (WERKS).
const plants = <String>['1000', '2000', '3000'];

/// ISO 4217 currency codes (subset).
const currencyCodes = <String>[
  'USD', 'EUR', 'GBP', 'JPY', 'INR', 'AUD', 'CAD', 'CHF', 'CNY', 'SGD',
];
