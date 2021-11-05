defmodule Protobuf.Protoc.Generator.Service do
  @moduledoc false

  alias Protobuf.Protoc.Context
  alias Protobuf.Protoc.Generator.Util

  @spec generate_list(Context.t(), [Google.Protobuf.ServiceDescriptorProto.t()]) :: [String.t()]
  def generate_list(%Context{} = ctx, descs) when is_list(descs) do
    if Enum.member?(ctx.plugins, "grpc") do
      Enum.map(descs, fn desc -> generate(ctx, desc) end)
    else
      []
    end
  end

  @spec generate(Context.t(), Google.Protobuf.ServiceDescriptorProto.t()) :: String.t()
  def generate(%Context{} = ctx, %Google.Protobuf.ServiceDescriptorProto{} = desc) do
    # service can't be nested
    mod_name = Util.mod_name(ctx, [Macro.camelize(desc.name)])
    name = Util.attach_raw_pkg(desc.name, ctx.package)
    methods = Enum.map(desc.method, &generate_service_method(ctx, &1))
    generate_desc = if ctx.gen_descriptors?, do: desc, else: nil
    Protobuf.Protoc.Template.service(mod_name, name, methods, generate_desc)
  end

  defp generate_service_method(ctx, method) do
    input = service_arg(Util.type_from_type_name(ctx, method.input_type), method.client_streaming)
    output = service_arg(Util.type_from_type_name(ctx, method.output_type), method.server_streaming)
    ":#{method.name}, #{input}, #{output}"
  end

  defp service_arg(type, _streaming? = true), do: "stream(#{type})"
  defp service_arg(type, _streaming?), do: type
end
