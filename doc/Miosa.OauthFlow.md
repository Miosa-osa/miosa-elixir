# `Miosa.OauthFlow`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.1.0/lib/miosa/oauth_flow.ex#L1)

A pending OAuth Connect flow.

Returned by `Miosa.Secrets.connect/3`. The caller is responsible for
surfacing `authorize_url` to the end user's browser — the SDK never
opens a browser tab automatically.

Once the user completes the OAuth grant, call
`wait_for_completion/2` to poll the server until the flow either
completes (returning the resulting secret payload) or fails.

## Fields

  * `:authorize_url` — URL the end user must visit to grant OAuth consent.
  * `:state` — Opaque server-issued token that identifies this flow.
  * `:provider` — Provider slug, e.g. `"github"` or `"slack"`.
  * `:client` — The `Miosa.Client` used to start the flow (retained for
    polling).
  * `:data` — Raw response payload from `POST /egress/oauth/start`.

## Example

    {:ok, flow} = Miosa.Secrets.connect(client, "github")
    IO.puts("Visit: " <> flow.authorize_url)
    {:ok, secret} = Miosa.OauthFlow.wait_for_completion(flow)

# `t`

```elixir
@type t() :: %Miosa.OauthFlow{
  authorize_url: String.t(),
  client: Miosa.Client.t(),
  data: map(),
  provider: String.t() | nil,
  state: String.t()
}
```

# `wait_for_completion`

```elixir
@spec wait_for_completion(
  t(),
  keyword()
) :: {:ok, map()} | {:error, term()}
```

Poll `GET /egress/oauth/status?state=<state>` until the OAuth flow
completes.

Returns `{:ok, payload}` where `payload` is the raw status map (which
typically includes `secret_id` and `status: "completed"`).

Returns `{:error, reason}` on failure or denial, and
`{:error, :timeout}` when `timeout_ms` elapses before completion.

## Options

  * `:timeout_ms` — milliseconds to wait before giving up. Defaults to
    `300_000` (5 minutes).
  * `:poll_interval_ms` — polling cadence in milliseconds. Defaults to
    `2_000`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
