# SmartConsent for Google Tag Manager

A Google Tag Manager tag template that adds the SmartConsent cookie banner to a site and drives Google Consent
Mode v2 from it. Fire it on the **Consent Initialization – All Pages** trigger. On every page it:

1. sets Consent Mode defaults first: every storage type denied except security storage, optionally different per
   region, with `wait_for_update` (500 ms by default);
2. gives the engine the site ID through `window.SmartConsentConfig.siteId`, turns off the engine's own Consent Mode
   calls (this template makes them instead, with `updateConsentState`), and registers `SmartConsentConfig.onConsent`,
   which the engine calls on every choice;
3. re-applies a returning visitor's stored choice if the engine would still accept it (same version, not expired);
4. loads the engine from `https://cdn.smartgenie.co.uk/v1/smartconsent.min.js`.

Category mapping: Analytics → `analytics_storage`; Marketing → `ad_storage`, `ad_user_data`, `ad_personalization`;
Functional → `functionality_storage`, `personalization_storage`; `security_storage` is always granted.

## Owner steps to list it in the Community Template Gallery

Do these in order, so the commit named in `metadata.yaml` holds the final file.

1. **Import and test.** In a GTM web container: Templates → Tag Templates → New → ⋮ → Import, and pick
   `template.tpl`. Open the Tests tab and run all tests; all must pass. Save.
2. **Preview.** Add a tag from the template with your site ID and the Consent Initialization – All Pages trigger.
   Add a Google tag (or GA4) on All Pages. Click Preview and, in Tag Assistant:
   - the Consent tab on the first event shows the defaults (all denied except security) set before any other tag;
   - click Accept on the banner: the next event shows analytics, ad and functionality types granted;
   - clear site data, reload, click Reject: they stay denied;
   - reload after a choice: the stored choice is applied on the first event.
   Also confirm no permission errors appear in the console. This step is the only check of the parts that could not
   be tested outside GTM (see below).
3. **Finish the Info tab.** Add the SmartGenie thumbnail (square PNG, JPEG or GIF, at least 64 px, under 50 kB) and
   tick the Community Template Gallery terms. Save, then ⋮ → Export. The exported file is the final `template.tpl`.
4. **Create the public repo.** A new public GitHub repo under SmartGenie (for example
   `smartgenie/smartconsent-gtm-template`). Commit, at its root, the exported `template.tpl`, `LICENSE` and this
   `README.md`.
5. **Pin the version.** Copy that commit's sha into `metadata.yaml` (`versions[0].sha`), set `homepage` and
   `documentation` if you want them to point elsewhere, and commit `metadata.yaml` to the root.
6. **Submit** the repo through the gallery's submission form
   (https://developers.google.com/tag-platform/tag-manager/templates/gallery).

For a later change, repeat steps 1 to 5 and add a new entry at the top of `versions` with its own sha and
`changeNotes`.

## Licence

Only the files in this folder are licensed under Apache 2.0 (`LICENSE`), as the gallery requires. The template
contains no engine code: it loads the SmartConsent engine from the SmartGenie CDN at run time, and the engine
keeps its own licence.

## Notes for site owners

- Install SmartConsent once. Do not also paste the SmartConsent snippet on pages that use this tag.
- If the page defines its own `window.SmartConsentConfig` (theme, texts, categories), it must be set before the GTM
  container snippet. The template keeps it, but sets `siteId`, `consentMode: false` and its own `onConsent`,
  replacing any `onConsent` the page set.
- The site ID field wins over any `siteId` in the page config.

## What was checked, and what was not

Checked in the SmartConsent repo (`tests/integrations/gtm-template.test.ts`): the file's sections and fields, the
permissions, the order of calls (defaults before the script loads), region rows, the callback mapping, the stored
choice rules including expiry, and success/failure reporting, by running the template's code with stand-ins for
GTM's APIs.

Not checked, because GTM itself could not be run: that GTM accepts the permission JSON as written, that
`setInWindow` sets nested keys such as `SmartConsentConfig.siteId`, and that the engine can call the template's
`onConsent` callback. Owner steps 1 and 2 confirm all three.
