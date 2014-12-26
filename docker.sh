#!/bin/bash

DIR=$(pwd)
VOLUMES=$DIR/volumes

#image
_metamaps_img=metamaps

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

	if [[ "$1" == "all" ]]; then
		return $db && $mm
	fi

	return 1
}


# Build containers from Dockerfiles
build () {	
	[[ ! -d src ]] && \
		git clone https://github.com/metamaps/metamaps_gen002 src
	[[ ! -f src/Dockerfile ]] && \
		cp config/Dockerfile src/Dockerfile
	[[ ! -f src/config/database.yml ]] && \
		cp config/database.yml src/config/database.yml

	verify_context
	docker build -t $_metamaps_img src/
}

# Start
start () {
	has_target db && docker start $_postgres
	has_target mm && docker start $_metamaps
}

# Run and link the containers
run () {
	has_target db && \
		docker run -d \
			-v $VOLUMES/data:/data \
			-e POSTGRES_USER=$POSTGRES_USER \
			-e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
			--name $_postgres postgres

	has_target mm || return 0;
	serve
}

# get our containers by 
containers () {	
	if has_target all; then
		regex="$_postgres|$_metamaps"
	else
		has_target mm && regex="$_metamaps"
		has_target db && regex="$_postgres"			
	fi

	docker ps -a | grep -E $regex | cut -d' ' -f1-1
}

# Stop and remove postgres or metamaps containers
stop () {	
	for container in $(containers); do
		docker stop $container
	done;
}

# Stop and remove postgres or metamaps containers
clean () {
	for container in $(containers); do
		docker stop $container
		docker rm $container
	done;
}

# seed the linked postgres container
seed () {
	docker exec -t $_metamaps bundle exec rake db:create
	docker exec -t $_metamaps bundle exec rake db:schema:load
	docker exec -t $_metamaps bundle exec rake db:fixtures:load
}

# run rails
serve () {
	docker run -d -p 8080:3000 \
		--link $_postgres:db \
		-e POSTGRES_USER=$POSTGRES_USER \
		-e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
		--name $_metamaps $_metamaps_img
}


CMD=$1; shift
set_target $1; shift

case $CMD in
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

	"serve")
		serve "$@"
		exit $? ;;

esac

graceful_exit -e "Usage: ./dev.sh <command>" \
	"\n\n\tAvailable Commands:" \
	"\n\n\tbuild:  \n\t    build command" \
	"\n\n\tstart:  \n\t    start command" \
	"\n\n\trun:  \n\t    run command" \
	"\n\n\tstop:  \n\t    stop command" \
	"\n\n\tclean:  \n\t    clean command" \
	"\n\n\tgems:  \n\t    metamaps_init_gems command" \
	"\n\n\tseed:  \n\t    metamaps_seed_db command" \
	"\n\n\tserve:  \n\t    metamaps_ser command" 