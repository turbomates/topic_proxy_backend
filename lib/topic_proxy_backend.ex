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
      {:ok, new_backend_state} = log_event(event, state)
      {:ok, %{state | backend_state: new_backend_state}}
    else
      {:ok, state}
    end
  end


  defp log_event(event, %{module: module, backend_state: backend_state}) do
    module.handle_event(event, backend_state)
  end

  defp level?(_, nil),     do: true
  defp level?(level, min), do: Logger.compare_levels(level, min) != :lt

  defp topic?(name, topic), do: name == topic

  defp configure(name, opts) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    level = Keyword.get(opts, :level)
    {module, backend_opts} = Keyword.get(opts, :backend)
    Application.put_env(:logger, :"_proxy_#{name}", backend_opts)

    {:ok, backend_state} = module.init({module, :"_proxy_#{name}"})

    %{name: name, level: level, module: module, backend_state: backend_state}
  end
end
