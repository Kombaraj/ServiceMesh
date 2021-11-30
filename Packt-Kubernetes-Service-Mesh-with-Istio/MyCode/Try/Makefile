NAME = go-app:1.0.1

default: run

image:
        docker build -t $(NAME) .

push:
        docker tag $(NAME) kombaraj/$(NAME)
        docker push kombaraj/$(NAME)

run:
        go run main.go
