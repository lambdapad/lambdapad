defmodule Lambdapad.ConfigTest do
  use ExUnit.Case
  alias Lambdapad.Config

  @workdir Path.join(__DIR__, "../support/config")

  describe "init/2" do
    test "reads a single config block and namespaces it under var_name" do
      config = %{format: :toml, from: "blog.toml", var_name: "blog"}

      assert {:ok, %{"blog" => data}} = Config.init(config, @workdir)
      assert data["title"] == "My Blog"
      assert data["url"] == "http://example.com"
      assert data["workdir"] == @workdir
      assert %{"name" => "Lambdapad"} = data["lambdapad"]
    end

    test "reads a config block without var_name at the top level" do
      config = %{format: :toml, from: "blog.toml"}

      assert {:ok, data} = Config.init(config, @workdir)
      assert data["title"] == "My Blog"
    end

    test "applies the transform function before merging metainfo" do
      config = %{
        format: :toml,
        from: "blog.toml",
        var_name: "blog",
        transform: fn data -> Map.put(data, "title", "Overridden") end
      }

      assert {:ok, %{"blog" => data}} = Config.init(config, @workdir)
      assert data["title"] == "Overridden"
    end

    test "merges a list of config blocks" do
      configs = [
        %{format: :toml, from: "blog.toml", var_name: "blog"},
        %{format: :eterm, from: "blog.config", var_name: "extra"}
      ]

      assert {:ok, %{"blog" => blog_data, "extra" => extra_data}} = Config.init(configs, @workdir)
      assert blog_data["title"] == "My Blog"
      assert extra_data["title"] == "My Blog"
    end

    test "halts when the config file cannot be read" do
      config = %{format: :toml, from: "missing.toml"}
      assert catch_throw(Config.init(config, @workdir)) == {:halt, 1}
    end

    test "halts when the config data is not a map" do
      config = %{format: :eterm, from: "not_a_map.config"}
      assert catch_throw(Config.init(config, @workdir)) == {:halt, 1}
    end
  end

  describe "to_proplist/1" do
    test "converts a Date to a day/month/year proplist with zero-padded values" do
      assert Config.to_proplist(~D[2026-01-05]) == [
               {"day", "05"},
               {"month", "01"},
               {"year", "2026"}
             ]
    end

    test "converts a map to a list of pairs, recursing into nested maps and lists" do
      assert Config.to_proplist(%{"a" => %{"b" => 1}, "c" => [1, 2]}) == [
               {"a", [{"b", 1}]},
               {"c", [1, 2]}
             ]
    end

    test "passes through anything else unchanged" do
      assert Config.to_proplist("plain string") == "plain string"
      assert Config.to_proplist(42) == 42
    end
  end

  test "valid_configs/0 lists the available config backend names" do
    assert :toml in Config.valid_configs()
    assert :eterm in Config.valid_configs()
  end

  test "lambdapad_metainfo/0 reports the current project version" do
    assert %{"lambdapad" => %{"name" => "Lambdapad", "vsn" => vsn}} = Config.lambdapad_metainfo()
    assert is_binary(vsn)
  end
end
