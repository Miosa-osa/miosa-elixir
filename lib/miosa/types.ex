defmodule Miosa.Types do
  @moduledoc """
  Typed structs representing all MIOSA API response objects.

  All structs use atom keys and provide a `from_map/1` constructor that
  accepts the raw string-keyed maps returned by the API.
  """

  # ---------------------------------------------------------------------------
  # Computer
  # ---------------------------------------------------------------------------

  defmodule Computer do
    @moduledoc "Represents a MIOSA computer (VM workspace)."

    @enforce_keys [:id, :name, :status]
    defstruct [
      :id,
      :name,
      :status,
      :template_type,
      :size,
      :ip_address,
      :vnc_url,
      :created_at,
      :updated_at,
      :metadata
    ]

    @type status :: :creating | :starting | :running | :stopping | :stopped | :error | :destroying

    @type t :: %__MODULE__{
            id: String.t(),
            name: String.t(),
            status: status(),
            template_type: String.t() | nil,
            size: String.t() | nil,
            ip_address: String.t() | nil,
            vnc_url: String.t() | nil,
            created_at: String.t() | nil,
            updated_at: String.t() | nil,
            metadata: map() | nil
          }

    @doc "Builds a `Computer` struct from a raw API response map."
    @spec from_map(map()) :: t()
    def from_map(map) when is_map(map) do
      %__MODULE__{
        id: map["id"],
        name: map["name"],
        status: parse_status(map["status"]),
        template_type: map["template_type"],
        size: map["size"],
        ip_address: map["ip_address"],
        vnc_url: map["vnc_url"],
        created_at: map["created_at"],
        updated_at: map["updated_at"],
        metadata: map["metadata"]
      }
    end

    defp parse_status(s) when is_binary(s), do: String.to_existing_atom(s)
    defp parse_status(_), do: :error
  end

  # ---------------------------------------------------------------------------
  # Desktop types
  # ---------------------------------------------------------------------------

  defmodule Window do
    @moduledoc "Represents an open window on the computer desktop."

    @enforce_keys [:id, :title]
    defstruct [:id, :title, :x, :y, :width, :height, :focused]

    @type t :: %__MODULE__{
            id: integer(),
            title: String.t(),
            x: integer() | nil,
            y: integer() | nil,
            width: integer() | nil,
            height: integer() | nil,
            focused: boolean() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) do
      %__MODULE__{
        id: map["id"],
        title: map["title"],
        x: map["x"],
        y: map["y"],
        width: map["width"],
        height: map["height"],
        focused: map["focused"]
      }
    end
  end

  defmodule CursorPosition do
    @moduledoc "Current mouse cursor position on the desktop."

    @enforce_keys [:x, :y]
    defstruct [:x, :y]

    @type t :: %__MODULE__{x: integer(), y: integer()}

    @spec from_map(map()) :: t()
    def from_map(%{"x" => x, "y" => y}), do: %__MODULE__{x: x, y: y}
    def from_map(map), do: %__MODULE__{x: map["x"] || 0, y: map["y"] || 0}
  end

  # ---------------------------------------------------------------------------
  # Exec
  # ---------------------------------------------------------------------------

  defmodule ExecResult do
    @moduledoc "Result of a command executed inside a computer."

    @enforce_keys [:exit_code]
    defstruct [:output, :stdout, :stderr, :exit_code]

    @type t :: %__MODULE__{
            output: String.t() | nil,
            stdout: String.t() | nil,
            stderr: String.t() | nil,
            exit_code: integer()
          }

    @spec from_map(map()) :: t()
    def from_map(map) do
      %__MODULE__{
        output: map["output"],
        stdout: map["stdout"],
        stderr: map["stderr"],
        exit_code: map["exit_code"] || 0
      }
    end
  end

  # ---------------------------------------------------------------------------
  # Files
  # ---------------------------------------------------------------------------

  defmodule FileEntry do
    @moduledoc "A file or directory entry in a computer's filesystem."

    @enforce_keys [:name, :path, :type]
    defstruct [:name, :path, :type, :size, :modified_at, :permissions]

    @type file_type :: :file | :directory | :symlink

    @type t :: %__MODULE__{
            name: String.t(),
            path: String.t(),
            type: file_type(),
            size: integer() | nil,
            modified_at: String.t() | nil,
            permissions: String.t() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) do
      %__MODULE__{
        name: map["name"],
        path: map["path"],
        type: parse_type(map["type"]),
        size: map["size"],
        modified_at: map["modified_at"],
        permissions: map["permissions"]
      }
    end

    defp parse_type("directory"), do: :directory
    defp parse_type("symlink"), do: :symlink
    defp parse_type(_), do: :file
  end

  defmodule ExportResult do
    @moduledoc "Result of a file export operation."

    @enforce_keys [:url]
    defstruct [:url, :expires_at]

    @type t :: %__MODULE__{url: String.t(), expires_at: String.t() | nil}

    @spec from_map(map()) :: t()
    def from_map(map), do: %__MODULE__{url: map["url"], expires_at: map["expires_at"]}
  end

  # ---------------------------------------------------------------------------
  # Agent / CUA
  # ---------------------------------------------------------------------------

  defmodule AgentSession do
    @moduledoc "A CUA (Computer-Use Agent) session running on a computer."

    @enforce_keys [:id, :computer_id, :status]
    defstruct [:id, :computer_id, :status, :goal, :created_at, :updated_at, :result, :error]

    @type status :: :pending | :running | :completed | :failed | :cancelled

    @type t :: %__MODULE__{
            id: String.t(),
            computer_id: String.t(),
            status: status(),
            goal: String.t() | nil,
            created_at: String.t() | nil,
            updated_at: String.t() | nil,
            result: String.t() | nil,
            error: String.t() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) do
      %__MODULE__{
        id: map["id"],
        computer_id: map["computer_id"],
        status: parse_status(map["status"]),
        goal: map["goal"],
        created_at: map["created_at"],
        updated_at: map["updated_at"],
        result: map["result"],
        error: map["error"]
      }
    end

    defp parse_status(s) when is_binary(s) do
      case s do
        "pending" -> :pending
        "running" -> :running
        "completed" -> :completed
        "failed" -> :failed
        "cancelled" -> :cancelled
        _ -> :pending
      end
    end

    defp parse_status(_), do: :pending
  end

  defmodule AgentEvent do
    @moduledoc "A server-sent event from a running agent session."

    @enforce_keys [:type]
    defstruct [:type, :data, :timestamp]

    @type event_type ::
            :thinking
            | :action
            | :screenshot
            | :result
            | :error
            | :done
            | :token
            | :raw

    @type t :: %__MODULE__{
            type: event_type(),
            data: map() | String.t() | nil,
            timestamp: String.t() | nil
          }

    @spec from_sse(String.t(), String.t()) :: t()
    def from_sse(event_type, data_string) do
      parsed_data =
        case Jason.decode(data_string) do
          {:ok, decoded} -> decoded
          _ -> data_string
        end

      %__MODULE__{
        type: parse_event_type(event_type),
        data: parsed_data,
        timestamp: extract_timestamp(parsed_data)
      }
    end

    defp parse_event_type("thinking"), do: :thinking
    defp parse_event_type("action"), do: :action
    defp parse_event_type("screenshot"), do: :screenshot
    defp parse_event_type("result"), do: :result
    defp parse_event_type("error"), do: :error
    defp parse_event_type("done"), do: :done
    defp parse_event_type("streaming_token"), do: :token
    defp parse_event_type("agent_response"), do: :result
    defp parse_event_type(_), do: :raw

    defp extract_timestamp(%{"timestamp" => ts}), do: ts
    defp extract_timestamp(_), do: nil
  end

  # ---------------------------------------------------------------------------
  # Workspace
  # ---------------------------------------------------------------------------

  defmodule Workspace do
    @moduledoc "Represents a MIOSA workspace — a named group of computers."

    @enforce_keys [:id, :name]
    defstruct [:id, :name, :metadata, :created_at, :updated_at]

    @type t :: %__MODULE__{
            id: String.t(),
            name: String.t(),
            metadata: map() | nil,
            created_at: String.t() | nil,
            updated_at: String.t() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) when is_map(map) do
      %__MODULE__{
        id: map["id"],
        name: map["name"],
        metadata: map["metadata"],
        created_at: map["created_at"],
        updated_at: map["updated_at"]
      }
    end
  end

  # ---------------------------------------------------------------------------
  # Snapshot / Checkpoint
  # ---------------------------------------------------------------------------

  defmodule Snapshot do
    @moduledoc "Represents a disk checkpoint (snapshot) of a MIOSA computer."

    @enforce_keys [:id, :computer_id, :status]
    defstruct [:id, :computer_id, :name, :description, :status, :size_bytes, :created_at]

    @type status :: :creating | :ready | :failed | :deleting

    @type t :: %__MODULE__{
            id: String.t(),
            computer_id: String.t(),
            name: String.t() | nil,
            description: String.t() | nil,
            status: status(),
            size_bytes: integer() | nil,
            created_at: String.t() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) when is_map(map) do
      %__MODULE__{
        id: map["id"],
        computer_id: map["computer_id"],
        name: map["name"],
        description: map["description"],
        status: parse_status(map["status"]),
        size_bytes: map["size_bytes"],
        created_at: map["created_at"]
      }
    end

    defp parse_status("creating"), do: :creating
    defp parse_status("ready"), do: :ready
    defp parse_status("failed"), do: :failed
    defp parse_status("deleting"), do: :deleting
    defp parse_status(_), do: :ready
  end

  # ---------------------------------------------------------------------------
  # Service
  # ---------------------------------------------------------------------------

  defmodule Service do
    @moduledoc "Represents a managed background service running inside a computer."

    @enforce_keys [:id, :computer_id, :name, :status]
    defstruct [
      :id,
      :computer_id,
      :name,
      :command,
      :working_dir,
      :env,
      :status,
      :auto_restart,
      :pid,
      :created_at,
      :updated_at
    ]

    @type status :: :stopped | :starting | :running | :stopping | :error

    @type t :: %__MODULE__{
            id: String.t(),
            computer_id: String.t(),
            name: String.t(),
            command: String.t() | nil,
            working_dir: String.t() | nil,
            env: map() | nil,
            status: status(),
            auto_restart: boolean() | nil,
            pid: integer() | nil,
            created_at: String.t() | nil,
            updated_at: String.t() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) when is_map(map) do
      %__MODULE__{
        id: map["id"],
        computer_id: map["computer_id"],
        name: map["name"],
        command: map["command"],
        working_dir: map["working_dir"],
        env: map["env"],
        status: parse_status(map["status"]),
        auto_restart: map["auto_restart"],
        pid: map["pid"],
        created_at: map["created_at"],
        updated_at: map["updated_at"]
      }
    end

    defp parse_status("stopped"), do: :stopped
    defp parse_status("starting"), do: :starting
    defp parse_status("running"), do: :running
    defp parse_status("stopping"), do: :stopping
    defp parse_status("error"), do: :error
    defp parse_status(_), do: :stopped
  end

  defmodule ServiceLogEvent do
    @moduledoc "A single log line emitted by a background service."

    @enforce_keys [:line]
    defstruct [:line, :stream, :timestamp, :service_id]

    @type t :: %__MODULE__{
            line: String.t(),
            stream: String.t() | nil,
            timestamp: String.t() | nil,
            service_id: String.t() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) when is_map(map) do
      %__MODULE__{
        line: map["line"] || map["message"] || "",
        stream: map["stream"] || "stdout",
        timestamp: map["timestamp"],
        service_id: map["service_id"]
      }
    end
  end

  # ---------------------------------------------------------------------------
  # Custom Domain
  # ---------------------------------------------------------------------------

  defmodule CustomDomain do
    @moduledoc "Represents a custom domain registered for a MIOSA computer."

    @enforce_keys [:id, :domain, :status]
    defstruct [
      :id,
      :computer_id,
      :domain,
      :port,
      :tls,
      :status,
      :dns_instructions,
      :created_at
    ]

    @type status :: :pending | :verifying | :active | :failed

    @type t :: %__MODULE__{
            id: String.t(),
            computer_id: String.t() | nil,
            domain: String.t(),
            port: pos_integer() | nil,
            tls: boolean() | nil,
            status: status(),
            dns_instructions: map() | nil,
            created_at: String.t() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) when is_map(map) do
      %__MODULE__{
        id: map["id"],
        computer_id: map["computer_id"],
        domain: map["domain"],
        port: map["port"],
        tls: map["tls"],
        status: parse_status(map["status"]),
        dns_instructions: map["dns_instructions"],
        created_at: map["created_at"]
      }
    end

    defp parse_status("pending"), do: :pending
    defp parse_status("verifying"), do: :verifying
    defp parse_status("active"), do: :active
    defp parse_status("failed"), do: :failed
    defp parse_status(_), do: :pending
  end

  # ---------------------------------------------------------------------------
  # Network Policy
  # ---------------------------------------------------------------------------

  defmodule NetworkPolicyRule do
    @moduledoc "A single network firewall rule (allow or deny)."

    @enforce_keys [:direction, :action]
    defstruct [:direction, :action, :host, :port, :protocol]

    @type direction :: :ingress | :egress
    @type action :: :allow | :deny

    @type t :: %__MODULE__{
            direction: direction(),
            action: action(),
            host: String.t() | nil,
            port: String.t() | pos_integer() | nil,
            protocol: String.t() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) when is_map(map) do
      %__MODULE__{
        direction: parse_atom(map["direction"]),
        action: parse_atom(map["action"]),
        host: map["host"],
        port: map["port"],
        protocol: map["protocol"]
      }
    end

    defp parse_atom("allow"), do: :allow
    defp parse_atom("deny"), do: :deny
    defp parse_atom("ingress"), do: :ingress
    defp parse_atom("egress"), do: :egress
    defp parse_atom(_), do: :allow
  end

  defmodule NetworkPolicy do
    @moduledoc "The full network policy for a computer, expressed as an ordered list of rules."

    @enforce_keys [:computer_id]
    defstruct [:computer_id, :rules, :updated_at]

    @type t :: %__MODULE__{
            computer_id: String.t(),
            rules: [NetworkPolicyRule.t()],
            updated_at: String.t() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) when is_map(map) do
      rules =
        map["rules"]
        |> List.wrap()
        |> Enum.map(&NetworkPolicyRule.from_map/1)

      %__MODULE__{
        computer_id: map["computer_id"],
        rules: rules,
        updated_at: map["updated_at"]
      }
    end
  end

  # ---------------------------------------------------------------------------
  # File System helpers
  # ---------------------------------------------------------------------------

  defmodule FileStat do
    @moduledoc "Detailed stat information for a single filesystem path."

    @enforce_keys [:path, :type]
    defstruct [:path, :name, :type, :size, :mode, :modified_at, :created_at, :is_symlink]

    @type t :: %__MODULE__{
            path: String.t(),
            name: String.t() | nil,
            type: :file | :directory | :symlink,
            size: integer() | nil,
            mode: String.t() | nil,
            modified_at: String.t() | nil,
            created_at: String.t() | nil,
            is_symlink: boolean() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) when is_map(map) do
      %__MODULE__{
        path: map["path"],
        name: map["name"],
        type: parse_type(map["type"]),
        size: map["size"],
        mode: map["mode"],
        modified_at: map["modified_at"],
        created_at: map["created_at"],
        is_symlink: map["is_symlink"]
      }
    end

    defp parse_type("directory"), do: :directory
    defp parse_type("symlink"), do: :symlink
    defp parse_type(_), do: :file
  end

  defmodule DirEntry do
    @moduledoc "A single entry returned by a directory listing."

    @enforce_keys [:name, :path, :type]
    defstruct [:name, :path, :type, :size, :modified_at]

    @type t :: %__MODULE__{
            name: String.t(),
            path: String.t(),
            type: :file | :directory | :symlink,
            size: integer() | nil,
            modified_at: String.t() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) when is_map(map) do
      %__MODULE__{
        name: map["name"],
        path: map["path"],
        type: parse_type(map["type"]),
        size: map["size"],
        modified_at: map["modified_at"]
      }
    end

    defp parse_type("directory"), do: :directory
    defp parse_type("symlink"), do: :symlink
    defp parse_type(_), do: :file
  end

  # ---------------------------------------------------------------------------
  # Computer Events
  # ---------------------------------------------------------------------------

  defmodule ComputerEvent do
    @moduledoc "A real-time lifecycle event emitted by a MIOSA computer."

    @enforce_keys [:type]
    defstruct [:type, :data, :computer_id, :timestamp]

    @type event_type ::
            :status_changed
            | :started
            | :stopped
            | :error
            | :checkpoint_created
            | :raw

    @type t :: %__MODULE__{
            type: event_type(),
            data: map() | String.t() | nil,
            computer_id: String.t() | nil,
            timestamp: String.t() | nil
          }

    @spec from_sse(String.t(), String.t()) :: t()
    def from_sse(event_type, data_string) do
      parsed_data =
        case Jason.decode(data_string) do
          {:ok, decoded} -> decoded
          _ -> data_string
        end

      computer_id =
        case parsed_data do
          %{"computer_id" => cid} -> cid
          _ -> nil
        end

      %__MODULE__{
        type: parse_event_type(event_type),
        data: parsed_data,
        computer_id: computer_id,
        timestamp: extract_timestamp(parsed_data)
      }
    end

    defp parse_event_type("status_changed"), do: :status_changed
    defp parse_event_type("started"), do: :started
    defp parse_event_type("stopped"), do: :stopped
    defp parse_event_type("error"), do: :error
    defp parse_event_type("checkpoint_created"), do: :checkpoint_created
    defp parse_event_type(_), do: :raw

    defp extract_timestamp(%{"timestamp" => ts}), do: ts
    defp extract_timestamp(_), do: nil
  end

  # ---------------------------------------------------------------------------
  # Computer visibility
  # ---------------------------------------------------------------------------

  @typedoc "Controls who can access a computer's HTTP endpoints."
  @type visibility :: :public | :tenant | :key

  # ---------------------------------------------------------------------------
  # Credits
  # ---------------------------------------------------------------------------

  defmodule CreditBalance do
    @moduledoc "Current credit balance for the authenticated tenant."

    @enforce_keys [:balance]
    defstruct [:balance, :plan, :expires_at]

    @type t :: %__MODULE__{
            balance: integer(),
            plan: String.t() | nil,
            expires_at: String.t() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) do
      %__MODULE__{
        balance: map["balance"] || 0,
        plan: map["plan"],
        expires_at: map["expires_at"]
      }
    end
  end

  defmodule CreditTransaction do
    @moduledoc "A single credit debit or credit event."

    @enforce_keys [:id, :amount, :type]
    defstruct [:id, :amount, :type, :description, :created_at]

    @type t :: %__MODULE__{
            id: String.t(),
            amount: integer(),
            type: String.t(),
            description: String.t() | nil,
            created_at: String.t() | nil
          }

    @spec from_map(map()) :: t()
    def from_map(map) do
      %__MODULE__{
        id: map["id"],
        amount: map["amount"] || 0,
        type: map["type"] || "unknown",
        description: map["description"],
        created_at: map["created_at"]
      }
    end
  end
end
