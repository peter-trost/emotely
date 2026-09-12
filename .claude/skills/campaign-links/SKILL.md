---
name: campaign-links
description: How to build a getemotely.com link for a LinkedIn post, a blog article, an ad or any other source so the waitlist sign-up carries its origin. Use whenever someone asks for a link to share, a tracked link, a UTM link, or where sign-ups came from.
---

# Campaign links for getemotely.com

The site is cookieless, so attribution lives in the link itself: the waitlist
form reads `utm_source`, `utm_medium` and `utm_campaign` from the visit's URL
and stores them as `source` = `utm_source/utm_medium/utm_campaign` on the
row (lowercased, `[a-z0-9._-]` only, 64 characters max). Without UTM the
referrer host is stored, without either the tag is `landing`.

## Build one

```
https://getemotely.com/?utm_source=<where>&utm_medium=<how>&utm_campaign=<what>
```

| Where you post | Link |
| --- | --- |
| LinkedIn post | `https://getemotely.com/?utm_source=linkedin&utm_medium=post&utm_campaign=<slug>` |
| LinkedIn profile / bio | `https://getemotely.com/?utm_source=linkedin&utm_medium=bio` |
| Blog article | `https://getemotely.com/?utm_source=blog&utm_medium=article&utm_campaign=<slug>` |
| Newsletter | `https://getemotely.com/?utm_source=newsletter&utm_medium=email&utm_campaign=<issue>` |
| Paid ad | `https://getemotely.com/?utm_source=<network>&utm_medium=cpc&utm_campaign=<slug>` |
| GitHub README | `https://getemotely.com/?utm_source=github&utm_medium=readme` |

`<slug>` is short and dated, e.g. `2026-09-launch`. Keep the three parts
stable across channels: `utm_source` is the site, `utm_medium` the format,
`utm_campaign` the piece. Everything else in the URL is ignored.

## Read the results

Sign-ups by source, with the linked Supabase CLI (schema access only, the
list is never readable through the API). `confirmed` is the number that
answered the double-opt-in mail; the rest are deleted after a week:

```bash
supabase db query --linked "select source, count(*) as signed_up, count(confirmed_at) as confirmed from public.waitlist group by 1 order by 2 desc"
```

PostHog (project emotely, EU) keeps all three tags: every event carries
`utm_source`, `utm_medium` and `utm_campaign` (and the referrer) as
properties, so Web analytics can break visits down by any of them, and the
`waitlist_joined` event carries the combined `source` string, the same one
the row stores. Everything is cookieless, so counts are per visit, not per
person over time. Paid
campaigns or experiments that need returning-visitor attribution mean
switching PostHog to `on_reject` with a consent banner — tracked in #70.
