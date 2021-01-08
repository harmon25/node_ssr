defmodule NodeSsrTest do
  use ExUnit.Case

  setup_all do
    Application.ensure_all_started(:node_ssr)
    :ok
  end

  setup do
    all_ports = NodeSsr.all_ports()
    [ports: all_ports]
  end

  test "app launches and exposes a single tcp port", %{ports: ports} do
    assert length(ports) == 1
  end

  test "responds to a GET", %{ports: ports} do
    [{port, _pid}] = ports
    assert NodeSsr.check_render_service(port) === :ok
  end

  test "responds to a POST", _ do
    props = %{some_prop: "a value"}
    {:ok, result} = NodeSsr.render("TEST", props)


    assert result.name === "TEST"
    assert result.markup === "TESTING"
    assert result.props === props
  end

  test "killing application terminates workers, and cleans up ports", %{ports: ports} do
    [{port, _pid}] = ports
    # stop application, and all children..
    Application.stop(:node_ssr)

    on_exit(fn ->
      Application.ensure_all_started(:node_ssr)
    end)

    assert NodeSsr.check_render_service(port) === :error
    assert NodeSsr.all_ports() == []
  end
end
