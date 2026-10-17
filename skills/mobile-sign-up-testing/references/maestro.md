# Maestro: sign-up with a Proxy Mail QA code or link

One script works for native iOS and Android, React Native and Flutter apps, because Maestro drives the app from outside. Save it next to the flows as `proxymail.js`:

```js
// Proxy Mail QA for Maestro flows. Guide: https://proxymail.qa/docs/maestro
//
//   - runScript: { file: proxymail.js, env: { ACTION: create } }
//       output.address, output.password, output.since
//   - runScript: { file: proxymail.js, env: { ACTION: code } }   (or link)
//       output.code (or output.link), for mail received since output.since
//     Add APP_LINK: true for the link that opens the app (myapp://…) when
//     the email also has a web one.
//
// The API key comes from the run: maestro test -e PROXYMAIL_QA_API_KEY=$PROXYMAIL_QA_API_KEY flow.yaml
const API = 'https://api.proxymail.qa/v1';
const headers = { Authorization: 'Bearer ' + PROXYMAIL_QA_API_KEY, 'Content-Type': 'application/json' };

if (ACTION === 'create') {
  const response = http.post(API + '/addresses', { headers: headers, body: JSON.stringify({ password: true, persona: true }) });
  if (!response.ok) throw new Error('Proxy Mail QA: ' + response.body);
  const created = json(response.body);
  output.address = created.address;
  output.password = created.password;
  output.since = new Date().toISOString();
} else {
  // Each request waits up to 10 seconds; four tries cover the email taking up to 40.
  const kind = ACTION === 'link' ? 'link' : 'code';
  const app = kind === 'link' && typeof APP_LINK !== 'undefined' && String(APP_LINK) === 'true' ? '&app=true' : '';
  const url = API + '/addresses/' + encodeURIComponent(output.address) + '/' + kind + '?timeout=10&since=' + encodeURIComponent(output.since) + app;
  let found = null;
  let last = null;
  for (let i = 0; i < 4 && !found; i++) {
    last = http.get(url, { headers: headers });
    if (last.ok) found = json(last.body).value;
  }
  // When nothing arrives, the hint says why (an email provider in sandbox mode, say).
  if (!found) throw new Error('Proxy Mail QA: no ' + kind + ' arrived. ' + (json(last.body).hint || ''));
  output[kind] = found;
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
