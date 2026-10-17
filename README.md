# Proxy Mail QA skills

Agent skills for testing the emails your app sends: sign-up verification,
login codes, magic links, password resets and invites. They work in Claude
Code, Codex, Cursor, Qoder, OpenCode and other agents that read skills.

| Skill | What it does |
| --- | --- |
| [email-delivery-troubleshooting](skills/email-delivery-troubleshooting/SKILL.md) | Finds out why an app's emails aren't arriving: email providers in sandbox mode (Amazon SES, Resend, Mailgun, Postmark, Supabase), suppression lists, rate limits and links that point at localhost |
| [email-e2e-tests](skills/email-e2e-tests/SKILL.md) | Writes Playwright, Cypress, Puppeteer and pytest tests that sign up, read the code or link, and finish the flow, and runs them in CI |
| [mobile-sign-up-testing](skills/mobile-sign-up-testing/SKILL.md) | Tests sign-up in iOS, Android, React Native, Expo and Flutter apps, by driving a simulator or with Maestro, XCUITest, Espresso, Detox or Appium |
| [signup-form-email-validation](skills/signup-form-email-validation/SKILL.md) | Checks a form accepts valid but unusual addresses (plus tags, apostrophes, capitals) and rejects invalid ones |

## Install

```
npx skills add aaquib90/proxymail-qa-skills
```

Or copy a folder from `skills/` into your agent's skills folder.

The skills use [Proxy Mail QA](https://proxymail.qa) for disposable test
inboxes, and the free plan is enough. Agents connect to its MCP server at
`https://api.proxymail.qa/mcp`, which signs in through the browser
([setup](https://proxymail.qa/docs/api#agent-setup)). Test code uses an API key
in `PROXYMAIL_QA_API_KEY` ([API keys](https://proxymail.qa/docs/api-keys)).
The troubleshooting skill is useful without an account.

For Claude Code, Cursor and Qoder there's also a
[plugin](https://github.com/aaquib90/proxymail-qa-plugin) that adds the MCP
server and the main sign-up skill.

## Qoder

`scripts/package-qoder.sh` builds `dist/proxymail-qa-skills-qoder-<date>.zip`
for Qoder's batch skill upload, with one folder per skill at its root. Bump
`version` in a skill's frontmatter before uploading a new version of it.

## Licence

MIT
