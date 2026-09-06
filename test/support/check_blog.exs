import Lambdapad

blog do
  config do
    set(format: :toml)
    set(from: "config.toml")
  end

  check "no broken links" do
    set(on: :finish)

    set(
      run: fn config ->
        Map.put(config, "checked", true)
      end
    )
  end
end
