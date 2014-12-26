#!/bin/bash

DIR=$(pwd)
VOLUMES=$DIR/volumes

#image
_metamaps_img="metamaps"

#containers
_metamaps="mm-server"
_postgres="mm-postgres"

# Environment Vars for Postgres Container and database-docker.yml
POSTGRES_HOST=$_postgres
POSTGRES_PORT=5432

POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# Exit with message and error status
graceful_exit () {
	echo "$@"
	exit 1
}

# Validate directory
verify_context () {	
	[[ ! -d src ]] && graceful_exit "./src directory not found"
	[[ ! -f src/Dockerfile ]] && graceful_exit "./src/Dockerfile not found"
	[[ ! -f src/config/database.yml ]] && graceful_exit "./src/config/database.yml not found"
}

# selection
mm=1
db=1

# remember if we ran with ./dev <command> all|db|mm
set_target () {
	if [[ "$1" == "all" ]]; then
		mm=0
		db=0
	elif [[ "$1" == "db" ]]; then
		db=0
	elif [[ "$1" == "mm" ]]; then
		mm=0
	fi	
}

# test if we are targetting mm|db|all
has_target () {
	if [[ "$1" == "mm" ]]; then
		return $mm
	fi

	if [[ "$1" == "db" ]]; then
		return $db
	fi

	return 1
}


prepare () {
	[[ ! -d src ]] && \
		git clone https://github.com/metamaps/metamaps_gen002 src
	cp -v config/Dockerfile src/Dockerfile
	cp -v config/database.yml src/config/database.yml
}

# Build containers from Dockerfiles
build () {	
	verify_context
	docker build -t $_metamaps_img src/
}

# Run and link the containers
run () {	
	has_target db && run_db && exit $?;
	has_target mm && run_mm && exit $?;
}

run_db () {
	echo "Running Postgres Database"
	docker run -d \
		-v $VOLUMES/data:/data \
		-e POSTGRES_USER=$POSTGRES_USER \
		-e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
		--name $_postgres postgres
}

# run rails
run_mm () {

	echo "[docker.sh] Verifying DB Container"
	_db=$(docker ps | grep -E "\s+$_postgres" | cut -d' ' -f1-1)
	[[ $_db ]] || graceful_exit "Postgres DB is not running";
	echo "Found" $_db
	

	echo "[docker.sh] Cleaning Any MM Containers"
	for container in $(mm_containers); do		
		echo "Stopping" $(docker stop $container)
		echo "Removing" $(docker rm $container)
	done;

	echo "[docker.sh] Running MM"
	docker run -d -p 8080:3000 \
		--link $_postgres:$POSTGRES_HOST \
		-e POSTGRES_HOST=$POSTGRES_HOST \
		-e POSTGRES_PORT=$POSTGRES_PORT \
		-e POSTGRES_USER=$POSTGRES_USER \
		-e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
		--name $_metamaps $_metamaps_img "$@"
}

mm_containers () {
	docker ps -a | grep -E "\s+$_metamaps" | cut -d' ' -f1-1	
}

db_containers () {
	docker ps -a | grep -E "\s+$_postgres" | cut -d' ' -f1-1
}

# get our containers by 
containers () {	
	has_target mm && mm_containers
	has_target db && db_containers
}


# Start containers
start () {
	has_target db && docker start $_postgres
	has_target mm && docker start $_metamaps
}

# Stop containers
stop () {	
	for container in $(containers); do
		echo "Stopping" $(docker stop $container)
	done;
}

# Stop and remove postgres or metamaps containers
clean () {
	for container in $(containers); do		
		echo "Stopping" $(docker stop $container)
		echo "Removing" $(docker rm $container)
	done;
}

# seed the linked postgres container
seed () {
	docker exec -t $_metamaps bundle exec rake db:create
	docker exec -t $_metamaps bundle exec rake db:schema:load
	docker exec -t $_metamaps bundle exec rake db:fixtures:load
}


CMD=$1; shift
set_target $1; shift

case $CMD in
	"prepare")
		prepare "$@"
		exit $? ;;

	"build")
		build "$@"
		exit $? ;;

	"start")
		start "$@"
		exit $? ;;

	"run")
		run "$@"
		exit $? ;;

	"stop")
		stop "$@"
		exit $? ;;

	"clean")
		clean "$@"
		exit $? ;;

	"seed")
		seed "$@"
		exit $? ;;

esac

graceful_exit -e "Usage: ./docker.sh COMMAND [OPTIONS]" \
	"\n    Basic Commands" \
	"\n    prepare  downloads git repository into src and applies configuration." \
	"\n    build    build the metamaps docker image" \
	"\n    run db   runs metamaps postgres" \
	"\n    run mm   runs metamaps server" \
	"\n    seed     seeds the postgres database" \
	"\n" \
	"\n    Lifecycle Commands -- [mm|db|all]" \
	"\n    start all   starts stopped containers" \
	"\n    stop all    stop containers" \
	"\n    clean all   stops and removes containers" \