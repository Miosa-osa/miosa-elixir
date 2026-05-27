# `Miosa.Email`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/email.ex#L1)

Admin email surface with sub-modules for campaigns, templates, and inbox.

Routes live under `/api/v1/admin/email-{campaigns,templates,inbox}/`
and require an admin credential (`msk_a_*` / `msk_p_*` or admin JWT).

## Sub-modules

  * `Miosa.Email.Campaigns` — Bulk email send-out lifecycle
  * `Miosa.Email.Templates` — Reusable templates keyed by name
  * `Miosa.Email.Inbox` — Inbound and outbound direct messages

---

*Consult [api-reference.md](api-reference.md) for complete listing*
