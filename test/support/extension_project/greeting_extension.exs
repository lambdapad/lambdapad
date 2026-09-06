transform "greeting" do
  set(on: :config)

  set(
    run: fn config, _posts ->
      Map.put(config, "greeting", "hello from the extension")
    end
  )
end
