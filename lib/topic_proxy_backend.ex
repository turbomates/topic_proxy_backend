defmodule TopicProxyBackend do
  @moduledoc false

  use GenEvent

  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  def handle_call({:configure, opts}, state) do
    {:ok, :ok, configure(state.name, opts)}
  end

  def handle_event({level, _gl, {Logger, _msg, _ts, md}} = event, state) do
    if level?(level, state.level) and topic?(state.name, md[:topic]) do
      log_event(event, state)
    end
    {:ok, state}
  end


  defp log_event(event, %{proxy: proxy}) do
    GenEvent.notify(proxy, event)
  end

  defp level?(_, nil),     do: true
  defp level?(level, min), do: Logger.compare_levels(level, min) != :lt

  defp topic?(name, topic), do: name == topic

  defp configure(name, opts) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    level = Keyword.get(opts, :level)
    {module, opts} = Keyword.get(opts, :backend)

    {:ok, proxy} = configure_backend(module, name, opts)

    %{name: name, level: level, proxy: proxy}
  end

  defp configure_backend(module, name, opts) do
    {:ok, proxy} = GenEvent.start_link

    if module == :console do
      GenEvent.add_handler(proxy, Logger.Backends.Console, :console)
      unless is_nil(opts), do: GenEvent.call(proxy, Logger.Backends.Console, {:configure, opts})
    else
      GenEvent.add_handler(proxy, module, {module, name})
      unless is_nil(opts), do: GenEvent.call(proxy, module, {:configure, opts})
    end

    {:ok, proxy}
  end
end
