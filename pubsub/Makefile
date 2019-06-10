shipvote: $(shell find . -name '*.go')
	go build

.PHONY: run
run: shipvote
	./shipvote

.PHONY: watch
watch:
	make watch-run
	while true; do \
		inotifywait -q -e modify,create,delete,move -r . && \
		echo "x" && \
		make watch-run; \
	done

.PHONY: watch-run
watch-run: 
	-killall shipvote
	make run &

