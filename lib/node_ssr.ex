defmodule NodeSsr do
  @moduledoc """
  NodeJS Server side rendering service manager for Elixir.

  Launches local http services for nodejs server side rendering, and provides a js module for easy extensibility.
  Processes are launched via [erlexec](https://hex.pm/packages/erlexec) with the hopes of being cleaned up nicely when exiting the VM
  """

  @spec check_render_service(non_neg_integer()) :: :error | :ok
  def check_render_service(port) do

    [host: "localhost", port: port]
    |> service_url()
    |> HTTPoison.get()
    |> case do
      {:ok, %{status_code: 200, body: "{\"message\":\"OK\"}"}} -> :ok
      _ -> :error
    end
  end

  @spec render(String.t(), map(), keyword()) :: {:ok, map()} | {:error, map()}
  def render(component, props \\ %{}, _opts \\ []) do
    # grab a random worker port
    port = random_worker_port()

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

  defp render_service_url(args) do
    service_url(args) <> "?" <> URI.encode_query(component: args[:component])
  end

  defp service_url(args), do: "http://#{args[:host] || "localhost"}:#{args[:port]}/"

  defp random_worker_port() do

    :persistent_term.get(:node_ssr_ports, nil)
    |> case do
      nil -> raise "No SSR worker ports configured."
      [port] -> port
      ports -> Enum.random(ports)
    end
  end

  defp handle_response({:ok, %{error: nil}} = resp), do: resp
  defp handle_response({:ok, %{error: error}}), do: {:error, error}
end
