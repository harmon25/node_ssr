defmodule NodeSsrTest do
  use ExUnit.Case

  setup_all do
    Application.ensure_all_started(:node_ssr)
    :ok
  end

  setup do
    port = NodeSsr.get_port()
    [port: port]
  end

  test "app launches and exposes a single tcp port", %{port: port} do
    assert port != nil
  end

  test "responds to a GET", _ do
    assert NodeSsr.check_render_service() === :ok
  end

  test "responds to a POST", _ do
    props = %{some_prop: "a value"}
    {:ok, result} = NodeSsr.render("TEST", props)


    assert result.name === "TEST"
    assert result.markup === "TESTING"
    assert result.props === props
  end

  test "killing application terminates workers, and cleans up ports", _ do

    on_exit(fn ->
      Application.ensure_all_started(:node_ssr)
    end)

    # stop application, and all children..
    Application.stop(:node_ssr)
    assert NodeSsr.check_render_service() === :error
    assert NodeSsr.get_port() == nil
  end
end
