___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "SmartConsent - Cookie Consent (CMP)",
  "categories": [
    "TAG_MANAGEMENT",
    "UTILITY"
  ],
  "brand": {
    "id": "brand_dummy",
    "displayName": "SmartGenie",
    "thumbnail": ""
  },
  "description": "Adds the SmartConsent cookie banner and sets Google Consent Mode v2: everything denied by default, updated when the visitor chooses. Fire on Consent Initialization - All Pages.",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "siteId",
    "displayName": "Site ID",
    "simpleValueType": true,
    "alwaysInSummary": true,
    "help": "The site ID you were given when you registered your site with SmartConsent. Letters, digits, - and _, at most 64 characters.",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      },
      {
        "type": "REGEX",
        "args": [
          "^[A-Za-z0-9_-]{1,64}$"
        ],
        "errorMessage": "Use letters, digits, - and _ only, at most 64 characters."
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "waitForUpdate",
    "displayName": "Wait for update (milliseconds)",
    "simpleValueType": true,
    "defaultValue": 500,
    "help": "How long Google tags wait for the visitor's stored choice before using the defaults. 500 or more is recommended.",
    "valueValidators": [
      {
        "type": "POSITIVE_NUMBER"
      }
    ]
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "regionDefaults",
    "displayName": "Region-specific defaults (optional). Everywhere else everything is denied until the visitor chooses.",
    "newRowButtonText": "Add region",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Regions (comma-separated ISO 3166-2 country or subdivision codes, e.g. US-CA, GB)",
        "name": "region",
        "type": "TEXT"
      },
      {
        "defaultValue": "denied",
        "displayName": "Analytics",
        "name": "analytics",
        "type": "SELECT",
        "selectItems": [
          {
            "value": "denied",
            "displayValue": "Denied"
          },
          {
            "value": "granted",
            "displayValue": "Granted"
          }
        ]
      },
      {
        "defaultValue": "denied",
        "displayName": "Marketing",
        "name": "marketing",
        "type": "SELECT",
        "selectItems": [
          {
            "value": "denied",
            "displayValue": "Denied"
          },
          {
            "value": "granted",
            "displayValue": "Granted"
          }
        ]
      },
      {
        "defaultValue": "denied",
        "displayName": "Functional",
        "name": "functional",
        "type": "SELECT",
        "selectItems": [
          {
            "value": "denied",
            "displayValue": "Denied"
          },
          {
            "value": "granted",
            "displayValue": "Granted"
          }
        ]
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const setDefaultConsentState = require('setDefaultConsentState');
const updateConsentState = require('updateConsentState');
const injectScript = require('injectScript');
const setInWindow = require('setInWindow');
const copyFromWindow = require('copyFromWindow');
const localStorage = require('localStorage');
const JSON = require('JSON');
const getType = require('getType');
const makeNumber = require('makeNumber');
const getTimestampMillis = require('getTimestampMillis');

const SCRIPT_URL = 'https://cdn.smartgenie.co.uk/v1/smartconsent.min.js';
const STATE_KEY = 'smartconsent_state';

// SmartConsent categories -> Consent Mode v2 types (the same mapping as the engine's own Consent Mode support).
const toConsent = (analytics, marketing, functional) => {
  return {
    ad_storage: marketing,
    ad_user_data: marketing,
    ad_personalization: marketing,
    analytics_storage: analytics,
    functionality_storage: functional,
    personalization_storage: functional,
    security_storage: 'granted'
  };
};

const grantedIf = (on) => on === true ? 'granted' : 'denied';

const fromCategories = (categories) => {
  return toConsent(grantedIf(categories.analytics), grantedIf(categories.marketing), grantedIf(categories.functional));
};

const pick = (value) => value === 'granted' ? 'granted' : 'denied';

// An ISO 8601 UTC timestamp (YYYY-MM-DDTHH:MM:SS...Z, as the engine writes it) in milliseconds, without Date.
// Anything unparseable gives NaN, which is never later than now.
const isoToMillis = (iso) => {
  if (getType(iso) !== 'string' || iso.length < 19) return 0;
  const part = (from, to) => makeNumber(iso.substring(from, to));
  const month = part(5, 7);
  const year = month <= 2 ? part(0, 4) - 1 : part(0, 4);
  const era = (year - year % 400) / 400;
  const yearOfEra = year - era * 400;
  const shifted = (month + 9) % 12;
  const dayOfYear = (153 * shifted + 2 - (153 * shifted + 2) % 5) / 5 + part(8, 10) - 1;
  const dayOfEra = yearOfEra * 365 + (yearOfEra - yearOfEra % 4) / 4 - (yearOfEra - yearOfEra % 100) / 100 + dayOfYear;
  const days = era * 146097 + dayOfEra - 719468;
  return ((days * 24 + part(11, 13)) * 60 + part(14, 16)) * 60000 + part(17, 19) * 1000;
};

// 1. Consent Mode defaults, before anything else: everything denied except security storage.
const requestedWait = makeNumber(data.waitForUpdate);
const waitForUpdate = requestedWait > 0 ? requestedWait : 500;
const defaults = toConsent('denied', 'denied', 'denied');
defaults.wait_for_update = waitForUpdate;
setDefaultConsentState(defaults);

// 2. Optional region-specific defaults, one per table row.
const rows = data.regionDefaults || [];
for (let i = 0; i < rows.length; i++) {
  const row = rows[i];
  const regions = [];
  const codes = (row.region || '').split(',');
  for (let j = 0; j < codes.length; j++) {
    const code = codes[j].trim();
    if (code) regions.push(code);
  }
  if (regions.length > 0) {
    const regional = toConsent(pick(row.analytics), pick(row.marketing), pick(row.functional));
    regional.wait_for_update = waitForUpdate;
    regional.region = regions;
    setDefaultConsentState(regional);
  }
}

// 3. Page config for the engine: the site ID, Consent Mode left to this template, and a callback the engine
//    calls on every consent choice (straight after its smartconsent:update event).
const pageConfig = copyFromWindow('SmartConsentConfig');
const hasPageConfig = getType(pageConfig) === 'object';
if (!hasPageConfig) setInWindow('SmartConsentConfig', {version: 1}, true);
const version = hasPageConfig && getType(pageConfig.version) === 'number' ? pageConfig.version : 1;
setInWindow('SmartConsentConfig.siteId', data.siteId, true);
setInWindow('SmartConsentConfig.consentMode', false, true);
setInWindow('SmartConsentConfig.onConsent', (state) => {
  if (getType(state) === 'object' && getType(state.categories) === 'object') {
    updateConsentState(fromCategories(state.categories));
  }
}, true);

// 4. Returning visitor: re-apply a stored choice that the engine would still accept (same version, not expired).
const stored = JSON.parse(localStorage.getItem(STATE_KEY) || '');
if (getType(stored) === 'object' && getType(stored.categories) === 'object' &&
    stored.version === version && isoToMillis(stored.expiresAt) > getTimestampMillis()) {
  updateConsentState(fromCategories(stored.categories));
}

// 5. Load the shared SmartConsent engine.
injectScript(SCRIPT_URL, data.gtmOnSuccess, data.gtmOnFailure, 'smartconsent');


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "access_consent",
        "versionId": "1"
      },
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ad_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ad_user_data" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ad_personalization" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "analytics_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "functionality_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "personalization_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "security_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "inject_script",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              { "type": 1, "string": "https://cdn.smartgenie.co.uk/v1/smartconsent.min.js" }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "key" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" },
                  { "type": 1, "string": "execute" }
                ],
                "mapValue": [
                  { "type": 1, "string": "SmartConsentConfig" },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": false }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "key" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" },
                  { "type": 1, "string": "execute" }
                ],
                "mapValue": [
                  { "type": 1, "string": "SmartConsentConfig.siteId" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": false }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "key" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" },
                  { "type": 1, "string": "execute" }
                ],
                "mapValue": [
                  { "type": 1, "string": "SmartConsentConfig.consentMode" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": false }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "key" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" },
                  { "type": 1, "string": "execute" }
                ],
                "mapValue": [
                  { "type": 1, "string": "SmartConsentConfig.onConsent" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": false }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_local_storage",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "key" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "smartconsent_state" },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": false }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Sets consent defaults before loading SmartConsent
  code: |-
    const order = [];
    mock('setDefaultConsentState', (state) => { order.push('default'); });
    mock('injectScript', (url, onSuccess, onFailure, cacheToken) => {
      order.push('inject');
      assertThat(url).isEqualTo('https://cdn.smartgenie.co.uk/v1/smartconsent.min.js');
      onSuccess();
    });
    runCode(mockData);
    assertThat(order[0]).isEqualTo('default');
    assertThat(order[order.length - 1]).isEqualTo('inject');
    assertApi('gtmOnSuccess').wasCalled();
- name: Global default denies everything except security storage
  code: |-
    let first;
    mock('setDefaultConsentState', (state) => { if (!first) first = state; });
    mock('injectScript', (url, onSuccess) => { onSuccess(); });
    runCode(mockData);
    assertThat(first.analytics_storage).isEqualTo('denied');
    assertThat(first.ad_storage).isEqualTo('denied');
    assertThat(first.ad_user_data).isEqualTo('denied');
    assertThat(first.ad_personalization).isEqualTo('denied');
    assertThat(first.functionality_storage).isEqualTo('denied');
    assertThat(first.personalization_storage).isEqualTo('denied');
    assertThat(first.security_storage).isEqualTo('granted');
    assertThat(first.wait_for_update).isEqualTo(500);
- name: Region rows add region defaults
  code: |-
    let regional;
    mock('setDefaultConsentState', (state) => { if (state.region) regional = state; });
    mock('injectScript', (url, onSuccess) => { onSuccess(); });
    mockData.regionDefaults = [{region: 'GB, FR', analytics: 'granted', marketing: 'denied', functional: 'denied'}];
    runCode(mockData);
    assertThat(regional.region).isEqualTo(['GB', 'FR']);
    assertThat(regional.analytics_storage).isEqualTo('granted');
    assertThat(regional.ad_storage).isEqualTo('denied');
- name: Script load failure is reported to GTM
  code: |-
    mock('injectScript', (url, onSuccess, onFailure) => { onFailure(); });
    runCode(mockData);
    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();
setup: |-
  const mockData = {
    siteId: 'test-site',
    waitForUpdate: '500',
    regionDefaults: []
  };


___NOTES___

SmartConsent GTM template (CR-012, Slice 14.1). Loads the shared engine from the SmartGenie CDN; the engine is
not part of this template and is licensed separately.
