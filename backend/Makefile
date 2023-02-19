.PHONY: run
run:
	docker compose up -d
	mix ecto.migrate
	mix phx.server
