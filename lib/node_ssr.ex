defmodule NodeSsr do
  @moduledoc """
  NodeJS Server side rendering service manager for Elixir.

  Launches local http services for nodejs server side rendering, and provides a js module for easy extensibility.
  Processes are launched via [erlexec](https://hex.pm/packages/erlexec) with the hopes of being cleaned up nicely when exiting the VM
  """

  @spec check_render_service() :: :error | :ok
  def check_render_service() do
    get_port()
    |> do_check_service()
  end

  defp do_check_service(port, host \\ "localhost")

  defp do_check_service(nil, _host) do
    :error
  end

  defp do_check_service({tcp_port, _}, host) when is_integer(tcp_port) do
    [host: host, port: tcp_port]
    |> service_url()
    |> HTTPoison.get()
    |> case do
      {:ok, %{status_code: 200, body: "{\"result\":\"OK\",\"error\":null}"}} -> :ok
      _ -> :error
    end
  end

  defp do_check_service(_, _) do
    :error
  end

  @spec render(String.t(), map(), keyword()) :: {:ok, map()} | {:error, map()}
  def render(component, props \\ %{}, _opts \\ []) do
    # grab a random worker port
    port = get_port(:port)

    [host: "localhost", port: port, component: component]
    |> render_service_url()
    |> HTTPoison.post(Jason.encode!(props))
    |> case do
      {:ok, %{status_code: 200, body: json_encoded_body}} ->
        Jason.decode(json_encoded_body, keys: :atoms)
        |> handle_response()

      _ ->
        # not a very recoverable error...if running during compilation this should just crash
        raise "Error reaching js component server at localhost:#{port}"
    end
  end

  @spec set_port(any) :: :ok
  def set_port(new_port) do
    # using persistent term for shared state to track all the opened tcp ports - is only ever written here
    :persistent_term.put(:node_ssr_port, new_port)
  end

  @spec clear_port :: boolean
  def clear_port() do
    :persistent_term.erase(:node_ssr_port)
  end

  @spec get_port :: Integer.t()
  def get_port() do
    :persistent_term.get(:node_ssr_port, nil)
  end

  @spec get_port(:pid | :port) :: pid() | integer()
  def get_port(:port) do
    get_port() |> elem(0)
  end

  def get_port(:pid) do
    get_port() |> elem(1)
  end

  defp render_service_url(args) do
    service_url(args) <> "?" <> URI.encode_query(component: args[:component])
  end

  defp service_url(args), do: "http://#{args[:host] || "localhost"}:#{args[:port]}/"

  defp handle_response({:ok, %{error: nil}} = resp), do: resp
  defp handle_response({:ok, %{error: error}}), do: {:error, error}
end
