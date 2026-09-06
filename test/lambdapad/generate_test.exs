defmodule Lambdapad.GenerateTest do
  use ExUnit.Case
  alias Lambdapad.{Blog, Generate}

  setup_all do
    file = Path.join(__DIR__, "../support/blog_extended.exs")
    assert {:ok, mod} = Blog.Exs.compile(file)
    {:ok, mod: mod}
  end

  describe "resolve_uri/5" do
    test "raises when the entry has no :uri key" do
      assert_raise RuntimeError, ~r/needs a valid :uri key/, fn ->
        Generate.resolve_uri(%{}, "some page", nil, [])
      end
    end

    test "calls the function with the index and the vars when uri is a function" do
      uri = fn index, vars -> "computed/#{index}/#{vars[:slug]}" end
      assert Generate.resolve_uri(%{}, "name", uri, [slug: "hello"], 3) == "computed/3/hello"
    end

    test "renders uri as an ErlyDTL template and joins it with the blog url" do
      config = %{"blog" => %{"url" => "http://example.com"}}
      vars = [{"post", [{"id", "my-post"}]}]

      assert Generate.resolve_uri(config, "posts", "/posts/{{ post.id }}.html", vars) ==
               "http://example.com/posts/my-post.html"
    end
  end

  describe "build_file_abspath/3" do
    setup do
      dir =
        Path.join(
          System.tmp_dir!(),
          "lambdapad_generate_test_#{System.unique_integer([:positive])}"
        )

      on_exit(fn -> File.rm_rf!(dir) end)
      {:ok, dir: dir}
    end

    test "creates the directory and appends index.html for :dir", %{dir: dir} do
      path = Generate.build_file_abspath(dir, "/about/", :dir)
      assert path == Path.absname(Path.join(dir, "about/index.html"))
      assert File.dir?(Path.join(dir, "about"))
    end

    test "creates the parent directory and uses the exact path for :file", %{dir: dir} do
      path = Generate.build_file_abspath(dir, "/feed/atom.xml", :file)
      assert path == Path.absname(Path.join(dir, "feed/atom.xml"))
      assert File.dir?(Path.join(dir, "feed"))
    end

    test "raises when uri_type is nil", %{dir: dir} do
      assert_raise RuntimeError, ~r/must set a valid valid: :dir or :file/, fn ->
        Generate.build_file_abspath(dir, "/about/", nil)
      end
    end
  end

  describe "process_vars/3" do
    test "wraps the data under var_name when no index is given" do
      assert Generate.process_vars(%{var_name: "post"}, %{"a" => 1}) == [{"post", [{"a", 1}]}]
    end

    test "returns a flat proplist for :plain with no index" do
      assert Generate.process_vars(%{var_name: :plain}, %{"a" => 1}) == [{"a", 1}]
    end

    test "raises when var_name is neither :plain nor a binary" do
      assert_raise RuntimeError, ~r/var_name must be specified/, fn ->
        Generate.process_vars(%{}, %{"a" => 1})
      end
    end

    test "includes the index alongside var_name when an index is given" do
      assert Generate.process_vars(%{var_name: "post"}, %{"a" => 1}, 2) ==
               [{"index", 2}, {"post", [{"a", 1}]}]
    end

    test "includes the index for :plain too" do
      assert Generate.process_vars(%{var_name: :plain}, %{"a" => 1}, 2) ==
               [{"index", 2}, {"a", 1}]
    end
  end

  describe "resolve_transforms_on_item/2, _on_page/2 and _on_config/2" do
    test "return nil when the corresponding key is absent", %{mod: mod} do
      assert Generate.resolve_transforms_on_item(mod, %{}) == nil
      assert Generate.resolve_transforms_on_page(mod, %{}) == nil
      assert Generate.resolve_transforms_on_config(mod, %{}) == nil
    end

    test "return the function unchanged when it is already a function", %{mod: mod} do
      fun = fn posts, _config -> posts end
      assert Generate.resolve_transforms_on_item(mod, %{transform_on_item: fun}) == fun
      assert Generate.resolve_transforms_on_page(mod, %{transform_on_page: fun}) == fun
    end

    test "resolves a bound transform name to the real function via chain_function/4", %{mod: mod} do
      transform =
        Generate.resolve_transforms_on_config(mod, %{transform_on_config: "last_update"})

      posts = [%{"date" => "2026-01-01"}, %{"date" => "2026-03-01"}]
      assert transform.(%{}, posts) == %{"last_update" => "2026-03-01"}
    end
  end

  describe "resolve_transforms_to_persist/2" do
    test "returns an empty map when the key is absent", %{mod: mod} do
      assert Generate.resolve_transforms_to_persist(mod, %{}) == nil
    end
  end
end
