.PHONY: build clean deploy

bin/lambda: $(shell find lambda -type f)
	env GOOS=linux go build -ldflags="-d -s -w" -a -tags netgo -installsuffix netgo -o bin/lambda lambda/main.go

build: bin/lambda

clean:
	rm -rf ./bin

deploy: build
	npx sls deploy --verbose

run: deploy
	npx sls invoke --log --function assign
