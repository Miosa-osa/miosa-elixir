# `Miosa.Computer.AutoStop`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/computer/auto_stop.ex#L1)

Read and update idle-timeout config for a computer.

Maps to `GET /computers/:id/auto-stop` and `PATCH /computers/:id/auto-stop`.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Return the current auto-stop configuration
(GET `/computers/:computer_id/auto-stop`).

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), non_neg_integer()) ::
  Miosa.Client.result(map())
```

Set the idle timeout in seconds (PATCH `/computers/:computer_id/auto-stop`).

Pass `0` to disable auto-stop entirely.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
