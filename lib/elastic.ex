env = Application.get_env(:requesters, :environment)
env = if env == "prod" do
  "production"
else
  env
end

Tirexs.DSL.define(fn() ->
  import Tirexs.Mapping

  index = [index: "timelines-#{env}", type: "Timeline"]

  mappings do
    indexes "name", type: "string"
    indexes "artist", type: "string"
    indexes "description", type: "string"
  end

  index
end)
