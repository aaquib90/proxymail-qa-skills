# Proxy Mail QA skills

Agent skills for testing the emails your app sends: sign-up verification,
login codes, magic links, password resets and invites. They work in Claude
Code, Codex, Cursor, Qoder, OpenCode and other agents that read skills.

| Skill | What it does |
| --- | --- |
| [account-email-audit](skills/account-email-audit/SKILL.md) | Triggers every account email an app sends (verification, reset, sign-in, invite, email change), checks each one's sending setup, links, expiry and layout, and lists what to fix |
| [age-and-region-testing](skills/age-and-region-testing/SKILL.md) | Tests age gates, parental consent, age-restricted content and country rules with test accounts of exact ages and countries, tagged for the next run |
| [auth-regression-pack](skills/auth-regression-pack/SKILL.md) | Checks sign-up, password reset and invitation emails the same way every time, including reused and replaced links, and reports what changed since the last run |
| [email-delivery-troubleshooting](skills/email-delivery-troubleshooting/SKILL.md) | Finds out why an app's emails aren't arriving: email providers in sandbox mode (Amazon SES, Resend, Mailgun, Postmark, Supabase), suppression lists, rate limits and links that point at localhost |
| [email-e2e-tests](skills/email-e2e-tests/SKILL.md) | Writes Playwright, Cypress, Puppeteer and pytest tests that sign up, read the code or link, check the email and finish the flow, and runs them in CI with a report on the pull request |
| [marketing-email-testing](skills/marketing-email-testing/SKILL.md) | Tests welcome coupons and checkout, one offer per person, unsubscribing that sticks, consent rules by country, welcome series timing and spam risk, on staging with test payments only |
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
server, the main sign-up skill and the auth regression pack.

## Qoder

`scripts/package-qoder.sh` builds `dist/proxymail-qa-skills-qoder-<date>.zip`
for Qoder's batch skill upload, with one folder per skill at its root. Bump
`version` in a skill's frontmatter before uploading a new version of it.

## Licence

MIT
