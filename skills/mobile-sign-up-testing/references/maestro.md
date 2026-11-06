# Maestro: sign-up with a Proxy Mail QA code or link

One script works for native iOS and Android, React Native and Flutter apps, because Maestro drives the app from outside. Save it next to the flows as `proxymail.js`:

```js
// Proxy Mail QA for Maestro flows: works for native iOS and Android, React
// Native and Flutter apps. Guide: https://proxymail.qa/docs/maestro
//
//   - runScript: { file: proxymail.js, env: { ACTION: create } }
//       output.address, output.password, output.since, and the persona for
//       forms that ask: output.firstName, output.lastName, output.username,
//       output.dateOfBirth (such as 2009-06-24) and output.country. Add
//       ENVIRONMENT (staging), AGE (adult, under18…) or COUNTRY (GB) to set them.
//   - runScript: { file: proxymail.js, env: { ACTION: code } }   (or link)
//       output.code (or output.link), for mail received since output.since.
//     Add APP_LINK: true for the link that opens the app (myapp://…) when
//     the email also has a web one, UNUSED: true to skip a used code, and
//     TYPE: coupon for a coupon or promo code (any for either), or for a
//     link, TYPE: unsubscribe for the email's unsubscribe link.
//   - runScript: { file: proxymail.js, env: { ACTION: count } }
//       output.count, the emails received since output.since
//   - runScript: { file: proxymail.js, env: { ACTION: check, EXPECT_HOST: links.example.com } }
//       fails the flow if the newest email fails a check (SPF, DKIM, DMARC,
//       local or http links, where its link goes…); output.failed lists them
//   - runScript: { file: proxymail.js, env: { ACTION: none } }
//       fails the flow if an email arrives within 30 seconds (TIMEOUT);
//       CATEGORY: marketing watches only for offers and newsletters
//   - runScript: { file: proxymail.js, env: { ACTION: signin, TAGS: verified } }
//       output.address and output.password of a saved test account, and its
//       persona, with the username and names to sign in with (a custom
//       field's, when one set them); needs a key allowed to read saved passwords
//   - runScript: { file: proxymail.js, env: { ACTION: checkout, TAGS: verified } }
//       borrows an account no other test has: output.address, output.password,
//       output.token. ACTION: return gives it back (ADD_TAGS, REMOVE_TAGS).
//   - runScript: { file: proxymail.js, env: { ACTION: coupon_result, RESULT: accepted } }
//       after applying the coupon at checkout (the store's sandbox, never a
//       real card): RESULT is accepted, rejected or error; add MESSAGE (what
//       the app said), CODE and ONE_TIME: true. output.verdict; fails the
//       flow if the coupon_result check fails.
//   - runScript: { file: proxymail.js, env: { ACTION: consent, MARKETING: declined } }
//       records what the account agreed to at sign-up: MARKETING opted_in or
//       declined; add PRECHECKED: true when the box started ticked and
//       DOUBLE_OPT_IN: pending or confirmed.
//
// The API key comes from the run: maestro test -e PROXYMAIL_QA_API_KEY=... flow.yaml
// Add -e PROXYMAIL_QA_RUN=$PROXYMAIL_QA_RUN to add the calls to a run (the
// GitHub Action sets it), and TEST: a name, in env, to name the step.
const API = 'https://api.proxymail.qa/v1';
const headers = { Authorization: 'Bearer ' + PROXYMAIL_QA_API_KEY, 'Content-Type': 'application/json' };
if (typeof PROXYMAIL_QA_RUN !== 'undefined' && PROXYMAIL_QA_RUN) {
  headers['Proxy-Mail-QA-Run'] = PROXYMAIL_QA_RUN;
  // Percent-encoded: a test's name can hold characters headers can't.
  if (typeof TEST !== 'undefined' && TEST) headers['Proxy-Mail-QA-Test'] = encodeURIComponent(TEST);
}

function call(method, path, body, extra) {
  const options = { headers: extra || headers };
  if (body) options.body = JSON.stringify(body);
  const response = method === 'POST' ? http.post(API + path, options) : method === 'PUT' ? http.put(API + path, options) : http.get(API + path, options);
  return { ok: response.ok, status: response.status, body: response.body ? json(response.body) : {} };
}

function fail(response) {
  // When nothing arrives, the hint says why (an email provider in sandbox mode, say).
  throw new Error('Proxy Mail QA: ' + (response.body.message || response.status) + ' ' + (response.body.hint || ''));
}

function tags(value) {
  return String(value).split(',').map(function (tag) { return tag.trim(); }).filter(function (tag) { return tag; });
}

function account(body) {
  output.address = body.address;
  output.password = body.password;
  output.since = new Date().toISOString();
  // The persona; on signin, the username and names to sign in with.
  const persona = body.persona || {};
  const name = body.identity || persona;
  output.firstName = name.first_name;
  output.lastName = name.last_name;
  output.username = name.username;
  output.dateOfBirth = persona.date_of_birth;
  output.country = persona.country;
}

const at = typeof output.address === 'undefined' ? '' : '/addresses/' + encodeURIComponent(output.address) + '/';
const since = '?since=' + encodeURIComponent(output.since);

if (ACTION === 'create') {
  const body = { password: true, persona: true };
  if (typeof ENVIRONMENT !== 'undefined') body.environment = ENVIRONMENT;
  if (typeof AGE !== 'undefined') body.age = AGE;
  if (typeof COUNTRY !== 'undefined') body.country = COUNTRY;
  const created = call('POST', '/addresses', body);
  if (!created.ok) fail(created);
  account(created.body);
} else if (ACTION === 'count') {
  const counted = call('GET', at + 'count' + since);
  if (!counted.ok) fail(counted);
  output.count = counted.body.count;
} else if (ACTION === 'check') {
  const host = typeof EXPECT_HOST !== 'undefined' ? '&expect_host=' + encodeURIComponent(EXPECT_HOST) : '';
  const checked = call('GET', at + 'checks' + since + host);
  if (!checked.ok) fail(checked);
  output.failed = checked.body.failed.join(', ');
  const failures = checked.body.checks.filter(function (c) { return c.status === 'fail'; }).map(function (c) { return c.check + ': ' + c.detail; });
  if (failures.length) throw new Error('Proxy Mail QA: the email failed ' + failures.join(' '));
} else if (ACTION === 'none') {
  const timeout = typeof TIMEOUT !== 'undefined' ? TIMEOUT : 30;
  const category = typeof CATEGORY !== 'undefined' ? '&category=' + encodeURIComponent(CATEGORY) : '';
  const watched = call('GET', at + 'none' + since + '&timeout=' + timeout + category);
  if (!watched.ok) fail(watched);
} else if (ACTION === 'signin') {
  const body = { tags: typeof TAGS !== 'undefined' ? tags(TAGS) : [] };
  if (typeof ENVIRONMENT !== 'undefined') body.environment = ENVIRONMENT;
  const found = call('POST', '/addresses/sign-in', body);
  if (!found.ok) fail(found);
  account(found.body);
} else if (ACTION === 'checkout') {
  const held = call('POST', '/addresses/checkout', { tags: tags(TAGS) });
  if (!held.ok) fail(held);
  // Its saved password, when the key may read it.
  const secret = call('GET', '/addresses/' + encodeURIComponent(held.body.address) + '/password');
  account({ address: held.body.address, password: secret.ok ? secret.body.secret : undefined });
  output.token = held.body.checkout.token;
} else if (ACTION === 'consent') {
  const body = { marketing: MARKETING };
  if (typeof PRECHECKED !== 'undefined') body.prechecked = String(PRECHECKED) === 'true';
  if (typeof DOUBLE_OPT_IN !== 'undefined') body.double_opt_in = DOUBLE_OPT_IN;
  const recorded = call('PUT', at + 'consent', body);
  if (!recorded.ok) fail(recorded);
} else if (ACTION === 'coupon_result') {
  const body = { result: RESULT, one_time: typeof ONE_TIME !== 'undefined' && String(ONE_TIME) === 'true' };
  if (typeof CODE !== 'undefined') body.code = CODE;
  if (typeof MESSAGE !== 'undefined') body.message = MESSAGE;
  const recorded = call('POST', at + 'coupon-result', body);
  if (!recorded.ok) fail(recorded);
  const check = recorded.body.check || { status: 'skip', detail: '' };
  output.verdict = check.status;
  if (check.status === 'fail') throw new Error('Proxy Mail QA: ' + check.detail);
} else if (ACTION === 'return') {
  const body = { token: output.token };
  if (typeof ADD_TAGS !== 'undefined') body.add_tags = tags(ADD_TAGS);
  if (typeof REMOVE_TAGS !== 'undefined') body.remove_tags = tags(REMOVE_TAGS);
  const returned = call('POST', at + 'return', body);
  if (!returned.ok) fail(returned);
} else {
  // Each request waits up to 10 seconds; four tries cover the email taking up to 40.
  const kind = ACTION === 'link' ? 'link' : 'code';
  const app = kind === 'link' && typeof APP_LINK !== 'undefined' && String(APP_LINK) === 'true' ? '&app=true' : '';
  const unused = typeof UNUSED !== 'undefined' && String(UNUSED) === 'true' ? '&unused=true' : '';
  const type = typeof TYPE !== 'undefined' && TYPE ? '&type=' + encodeURIComponent(TYPE) : '';
  let found = null;
  for (let i = 0; i < 4 && !found; i++) {
    // Only the last try's "nothing arrived" counts in a run's report.
    const retry = JSON.parse(JSON.stringify(headers));
    if (i < 3) retry['Proxy-Mail-QA-Run-Retry'] = 'true';
    found = call('GET', at + kind + since + '&timeout=10' + app + unused + type, null, retry);
    if (!found.ok && i < 3) found = null;
  }
  if (!found.ok) throw new Error('Proxy Mail QA: no ' + kind + ' arrived. ' + (found.body.hint || ''));
  output[kind] = found.body.value;
}
```

A flow that signs up and enters the code. Change `appId`, the labels and the button text to match the app:

```yaml
appId: com.example.app
---
- launchApp
- runScript:
    file: proxymail.js
    env:
      ACTION: create
- tapOn: "Email"
- inputText: ${output.address}
- tapOn: "Password"
- inputText: ${output.password}
- tapOn: "Sign up"
- runScript:
    file: proxymail.js
    env:
      ACTION: code
- inputText: ${output.code}
```

Run it with the key from the environment:

```bash
maestro test -e PROXYMAIL_QA_API_KEY=$PROXYMAIL_QA_API_KEY signup.yaml
```

For a link instead of a code, use `ACTION: link`, then `- openLink: ${output.link}`, which opens it in the app. Add `APP_LINK: true` to the script's `env` for the app's own link when the email also has a web one.

`output.since` is set when the address is created, so the wait only finds mail from this run.

On `ACTION: create`, `ENVIRONMENT: staging` records which environment the account is for, and `AGE: under18` or `COUNTRY: GB` give its persona a date of birth or a country. For forms that ask, the script sets the persona's `output.firstName`, `output.lastName`, `output.username`, `output.dateOfBirth` (year-month-day, such as `2009-06-24`) and `output.country`.

## Check the email, sign in, borrow an account

- `ACTION: count` sets `output.count`; follow it with `- assertTrue: ${output.count == 1}` to catch a duplicate email.
- `ACTION: check` with `EXPECT_HOST` set to the domain the app's links open fails the flow when the newest email fails a check (SPF, DKIM, DMARC, local or http links, where its link goes).
- `ACTION: none` fails the flow if an email arrives within 30 seconds.
- `ACTION: signin` with `TAGS: verified` sets `output.address` and `output.password` to a saved test account's, and `output.username` to the username to sign in with: a custom field's, when one set it, otherwise the persona's. `ACTION: checkout` lends one no other flow has, and `ACTION: return` gives it back. Both need a key allowed to read saved passwords.
- In CI with the Proxy Mail QA GitHub Action, add `-e PROXYMAIL_QA_RUN=$PROXYMAIL_QA_RUN` to `maestro test`, and `TEST` to each script's `env` to name the step in the pull request's report.
