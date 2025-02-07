#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
WHITE='\033[1;37m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
# Additional Colors
MAGENTA='\033[0;35m'   # Magenta
LIGHT_RED='\033[1;31m'  # Light Red
LIGHT_GREEN='\033[1;32m' # Light Green
LIGHT_BLUE='\033[1;34m'  # Light Blue
LIGHT_CYAN='\033[1;36m'  # Light Cyan
WHITE='\033[1;37m'       # White
GRAY='\033[0;90m'        # Gray
NC='\033[0m' # No Color

# Function to draw a separator
separator() {
    echo -e "${blue}-------------------------------------------------${nc}"
}

date
# Function to check Docker daemon status
check_docker_status() {
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}🟢 Docker daemon is running${NC}"
        echo
    else
        echo -e "${RED}🔴 Docker daemon is stopped${NC}"
        echo
    fi
}

# Function to remove Docker container
remove_container() {
    read -p "Enter container ID to remove: " container_id
    if docker ps -aq | grep -q "^$container_id$"; then
        echo
        echo -e "${YELLOW}⚠️  WARNING: This will remove container $container_id. Are you sure? (y/N): ${NC}"
        read -p "" confirm
        echo

        if [[ "${confirm,,}" == "y" ]]; then
            docker rm "$container_id" 2>&1 | tee /tmp/docker_rm_output.log
            if docker ps -aq | grep -q "^$container_id$"; then
                echo -e "${RED}❌ Container removal failed.${NC}"
            else
                echo -e "${GREEN}✅ Container $container_id successfully removed.${NC}"
            fi
        else
            echo -e "${RED}❌ Operation canceled.${NC}"
        fi
    else
        echo -e "${RED}❌ Error: Container ID '$container_id' is invalid or does not exist.${NC}"
    fi
    echo
    docker ps -a
}

# Function to FORCE remove Docker container
force_remove_container() {
    read -p "Enter container ID to FORCE remove: " container_id
    if docker ps -aq | grep -q "^$container_id$"; then
        echo
        echo -e "${YELLOW}⚠️  WARNING: This will forcefully remove container $container_id. Are you sure? (y/N): ${NC}"
        read -p "" confirm
        echo

        if [[ "${confirm,,}" == "y" ]]; then
            docker rm -f "$container_id" 2>&1 | tee /tmp/docker_rm_output.log
            if docker ps -aq | grep -q "^$container_id$"; then
                echo -e "${RED}❌ Force removal failed.${NC}"
            else
                echo -e "${GREEN}✅ Container $container_id successfully removed.${NC}"
            fi
        else
            echo -e "${RED}❌ Operation canceled.${NC}"
        fi
    else
        echo -e "${RED}❌ Error: Container ID '$container_id' is invalid or does not exist.${NC}"
    fi
    echo
    docker ps -a
}

# Function to remove Docker image
remove_image() {
    read -p "Enter image ID to remove: " image_id
    if docker images -q | grep -q "^$image_id$"; then
        echo
        echo -e "${YELLOW}⚠️  WARNING: This will remove image $image_id. Are you sure? (y/N): ${NC}"
        read -p "" confirm
        echo

        if [[ "${confirm,,}" == "y" ]]; then
            docker rmi "$image_id" 2>&1 | tee /tmp/docker_rmi_output.log
            if docker images -q | grep -q "^$image_id$"; then
                echo -e "${RED}❌ Image removal failed.${NC}"
            else
                echo -e "${GREEN}✅ Image $image_id successfully removed.${NC}"
            fi
        else
            echo -e "${RED}❌ Operation canceled.${NC}"
        fi
    else
        echo -e "${RED}❌ Error: Image ID '$image_id' is invalid or does not exist.${NC}"
    fi
    echo
    docker images
}

force_remove_image() {
    read -p "Enter image ID to FORCE remove: " image_id

    # Check if the image exists
    if ! docker images -q | grep -q "^$image_id$"; then
        echo -e "${RED}❌ Error: Image ID '$image_id' is invalid or does not exist.${NC}"
        return 1
    fi

    echo
    echo -e "${YELLOW}⚠️  Checking for dependent child images...${NC}"

    # Find child images that depend on the given image
    child_images=$(docker images --filter "since=$image_id" --format "{{.Repository}}:{{.Tag}} {{.ID}}")

    if [[ -n "$child_images" ]]; then
        echo -e "${RED}❌ Error: The image $image_id has dependent child images.${NC}"
        echo -e "${YELLOW}⚠️  You must remove the following child images first:${NC}"
        echo "$child_images"
        echo

        read -p "Would you like to stop and remove containers using these child images first? (y/N): " remove_children

        if [[ "${remove_children,,}" == "y" ]]; then
            echo
            echo -e "${YELLOW}⚠️  Stopping containers using dependent child images...${NC}"

            # Get container IDs using child images
            for child_image in $(echo "$child_images" | awk '{print $NF}'); do
                child_containers=$(docker ps -aq --filter "ancestor=$child_image")
                
                if [[ -n "$child_containers" ]]; then
                    echo -e "${YELLOW}Stopping and removing containers using child image $child_image:${NC}"
                    echo "$child_containers"
                    docker stop $child_containers
                    docker rm $child_containers
                fi

                # Remove the child image
                echo -e "${YELLOW}⚠️  Removing child image $child_image...${NC}"
                docker rmi -f "$child_image"
            done

            echo -e "${GREEN}✅ All dependent child images and their containers removed.${NC}"
        else
            echo -e "${RED}❌ Operation canceled. You must remove child images first.${NC}"
            return 1
        fi
    fi

    # Stop containers using the main image
    echo -e "${YELLOW}⚠️  Checking for containers using image $image_id...${NC}"
    parent_containers=$(docker ps -aq --filter "ancestor=$image_id")

    if [[ -n "$parent_containers" ]]; then
        echo -e "${YELLOW}Stopping and removing containers using image $image_id:${NC}"
        echo "$parent_containers"
        docker stop $parent_containers
        docker rm $parent_containers
    fi

    # Final confirmation for force removal of parent image
    echo -e "${YELLOW}⚠️  WARNING: This will forcefully remove image $image_id. Are you sure? (y/N): ${NC}"
    read -p "" confirm
    echo

    if [[ "${confirm,,}" == "y" ]]; then
        docker rmi -f "$image_id" 2>&1 | tee /tmp/docker_rmi_output.log
        
        if docker images -q | grep -q "^$image_id$"; then
            echo -e "${RED}❌ Force removal failed.${NC}"
        else
            echo -e "${GREEN}✅ Image $image_id successfully removed.${NC}"
        fi
    else
        echo -e "${RED}❌ Operation canceled.${NC}"
    fi

    echo
    docker images
}

build_docker_image() {
	
	# Validate if Dockerfile exists
	if [[ ! -f "Dockerfile" ]]; then
		echo -e "${RED}❌ ERROR: No Dockerfile found in: $PWD${NC}"
		echo "Unable to build as there is no Dockerfile present."
		echo
		read -p "Press enter to return to main menu... " 
		main_program
	fi

	echo
	echo "✅ OK: Dockerfile found in: $PWD"
	echo

	# Ask user if they want to view the Dockerfile content
	read -p "⚠️ Read content of Dockerfile? (y/N): " confirm
	if [[ "${confirm,,}" =~ ^(y|yes)$ ]]; then
		echo
		echo -e "${GREEN}✅ OK. Reading confirmed.${NC}"
		echo
		echo "Dockerfile content starts below this line: "
		echo "################################################################################"
		cat "Dockerfile"
		echo "################################################################################"
		echo "Dockerfile content ends above this line"
		echo
	else
		echo -e "${RED}❌ ABORTED: Skipped reading content.${NC}"
		echo
	fi

	read -p "Press enter to continue... "

	# Get image and container names
	read -p "Enter name for the new Docker image: " img_name
	echo
	read -p "Enter a container name (leave empty for a random name): " container_name
	echo

	# Display confirmation details
	echo "Docker Image name: $img_name"
	if [[ -n "$container_name" ]]; then
		echo "Docker Container name: $container_name"
	else
		echo "Docker Container name: (random)"
	fi
	echo "Docker Build path: $PWD"
	echo

	# Confirm build process
	read -p "⚠️ WARNING: Confirm to build from Dockerfile now with above data? (y/N): " confirm
	if [[ ! "${confirm,,}" =~ ^(y|yes)$ ]]; then
		echo
		echo -e "${RED}❌ ABORTED: Building from Dockerfile was canceled.${NC}"
		echo
		read -p "Press enter to return to main menu... "
		main_program
	fi

	echo
	echo -e "${GREEN}✅ OK. Building confirmed.${NC}"
	echo

	# Build Docker image
	docker build -t "$img_name" -f "Dockerfile" .

	# Check if build was successful
	if [[ $? -ne 0 ]]; then
		echo -e "${RED}❌ ERROR: Docker build failed.${NC}"
		read -p "Press enter to return to main menu... "
		main_program
	fi

	# Run container with or without a specific name
	if [[ -z "$container_name" ]]; then
		docker run -it "$img_name"
	else
		docker run -it --name "$container_name" "$img_name"
	fi

	echo
	read -p "Press enter to proceed... "
	main_program
	
}	

build_docker_image_child_path() {
	
	# List directories containing a Dockerfile (at depth 2)
	find . -maxdepth 2 -mindepth 2 -name Dockerfile | cut -f1,2 -d/
	echo

	# Ask user for child path to the Dockerfile
	read -p "Provide only the child path where the Dockerfile is present (e.g., child_path/): " dockerfile_path

	# Validate provided path
	if [[ -f "$dockerfile_path/Dockerfile" ]]; then
		echo -e "\n✅ OK: Dockerfile found in: $dockerfile_path\n"
		echo
		read -p "⚠️ Read content of Dockerfile? (y/N): " confirm
		if [[ "${confirm,,}" == "y" ]]; then
			echo
			echo -e "${GREEN}✅ OK. Reading confirmed.${NC}"
			echo
			echo "Dockerfile content starts below this line: "
			echo "################################################################################"
			echo
			cat $dockerfile_path/Dockerfile
			echo
			echo "################################################################################"
			echo "Dockefile conten ends above this line"
			echo
			
		else
			echo
			echo -e "${RED}❌ ABORTED reading content from $dockerfile_path/Dockerfile .${NC}"
			echo

		fi
	else
		echo -e "\n❌ ERROR: No Dockerfile found in the provided path: $dockerfile_path\n"
		read -p "Press enter to return to main menu..." enter
		main_program
	fi

	# Get Docker image and container names
	read -p "Enter name for the new Docker image: " img_name
	read -p "Enter a container name (leave empty for a random name): " container_name

	# Display entered values
	echo -e "\nDocker Image name: $img_name"
	echo "Docker Container name: ${container_name:-[Random]}"
	echo "Docker Build path: $PWD"
	echo
	read -p "⚠️ WARNING: Confirm to build from $dockerfile_path/Dockerfile now? (y/N): " confirm

	if [[ ! "${confirm,,}" =~ ^(y|yes)$ ]]; then
		echo -e "\n❌ ABORTED Building from $dockerfile_path/Dockerfile.\n"
		read -p "Press enter to return to main menu: "
		main_program
	fi

	# Build the Docker image (only once)
	echo -e "\n🚀 Building Docker image: $img_name from $dockerfile_path/Dockerfile...\n"

	# Run the container
	if [[ -z "$container_name" ]]; then
		docker build -t "$img_name" -f "$dockerfile_path/Dockerfile" "$dockerfile_path"
		docker run -it "$img_name"
		echo 
		read -p "Press enter to proceed: "
		enter
		main_program
	else
		docker build -t "$img_name" -f "$dockerfile_path/Dockerfile" "$dockerfile_path"
		docker run -it --name "$container_name" "$img_name"
		echo
		read -p "Press enter to proceed: "
		enter
		main_program
	fi
}

remove_all_containers() {
	
	read -p "⚠️ WARNING: This will remove ALL unused images and containers. Are you sure? (y/N): " confirm
	if [[ "${confirm,,}" == "y" ]]; then
		echo
		docker system prune -a -f
		echo -e "${GREEN}✅ Pruning completed.${NC}"
		echo
		docker ps -a
	else
		echo
		echo -e "${RED}❌ Operation canceled.${NC}"
		echo
		docker ps -a
	fi	
}

# Function to display the menu
main_program() {
    echo
    echo -e "${CYAN}"
    echo "====================================="
    echo "       🐳 DOCKER MANAGEMENT CONSOLE      "
    echo "====================================="
    echo -e "${NC}"
    check_docker_status
    echo -e "${LIGHT_GREEN} === SHOW OPTIONS === ${nc}"
    echo -e "${WHITE}1. Show all Docker images${NC}"
    echo -e "${WHITE}2. Show running containers${NC}"
    echo -e "${WHITE}3. Show all containers (running + stopped)${NC}"
    separator
    echo -e "${LIGHT_GREEN} === CONTAINER AND IMAGE OPERATIONS === ${nc}"
    echo -e "${WHITE}4. Run a container interactively (Persistent)${NC}"
    echo -e "${WHITE}5. Attach to a running container${NC}"
    echo -e "${WHITE}6. Build Docker image from Dockerfile${NC}"
    echo -e "${WHITE}7. Build Docker image from child path Dockerfile${NC}"
    echo -e "${WHITE}8. Persist changes to container image${NC}"
    echo -e "${WHITE}9. Start a container${NC}"
    echo -e "${WHITE}10. Stop a container${NC}"
    echo -e "${WHITE}11. Restart a container${NC}"
    separator
    echo -e "${LIGHT_GREEN} === LOGS OPTIONS === ${nc}"
    echo -e "${WHITE}12. Show logs for a container${NC}"
    echo -e "${WHITE}13. Show Docker system logs${NC}"
    echo -e "${WHITE}14. Show detailed Docker info${NC}"
    separator
    echo -e "${LIGHT_GREEN} === DAEMONS OPERATIONS === ${nc}"
    echo -e "${WHITE}15. Start Docker daemon${NC}"
    echo -e "${WHITE}16. Stop Docker daemon${NC}"
    echo -e "${WHITE}17. Restart Docker daemon${NC}"
    separator
    echo -e "${LIGHT_GREEN} === REMOVAL OPERATIONS === ${nc}"
    echo -e "${WHITE}18. Remove a container${NC}"
    echo -e "${WHITE}19. FORCE Remove a container${NC}"
    echo -e "${WHITE}20. Remove a DOCKER image${NC}"
    echo -e "${WHITE}21. FORCE Remove a DOCKER image${NC}"
    echo -e "${WHITE}22. Prune unused images & containers${NC}"
    echo -e "${WHITE}23. Exit${NC}\n"


    read -p "Select an option: " choice
    echo -e "\n"

    case $choice in
        1) 
            echo -e "${CYAN}===== MODE ACCESSED: SHOW ALL DOCKER IMAGES =====${NC}"
            echo
            docker images 
            ;;

        2) 
            echo -e "${CYAN}===== MODE ACCESSED: SHOW RUNNING CONTAINERS =====${NC}"
            echo
            docker ps
            ;;
        3) 
            echo -e "${CYAN}===== MODE ACCESSED: SHOW ALL CONTAINERS =====${NC}"
            echo
            docker ps -a
            ;;
        4) 
            echo -e "${CYAN}===== MODE ACCESSED: RUN CONTAINER =====${NC}"
            echo
            docker ps -a
            echo
            read -p "Enter a container image name to run: " img
            container_id=$(docker run -dit $img)
            echo -e "${GREEN}Container started: $container_id${NC}"
            echo -e "${WHITE}Attaching to container $container_id... (Use Ctrl+P + Ctrl+Q to detach)${NC}"
            docker attach $container_id
            ;;

        5) 
            echo -e "${CYAN}===== MODE ACCESSED: ATTACH TO CONTAINER =====${NC}"
            echo
            docker ps -a
            echo
            read -p "Enter container ID/name: " cid
            docker attach $cid
            ;;
        6) 
            echo -e "${CYAN}===== MODE ACCESSED: BUILD DOCKER IMAGE =====${NC}"
			echo
			build_docker_image
            ;;
        
        7) 
			echo -e "${CYAN}===== MODE ACCESSED: BUILD DOCKER IMAGE FROM CHILD PATH =====${NC}"
			echo
			build_docker_image_child_path
            ;;
        8) 
            echo -e "${CYAN}===== MODE ACCESSED: PERSIST CHANGES TO CONTAINER IMAGE =====${NC}"
            echo
            docker ps -a
            echo
            read -p "Enter container ID to persist changes: " cid
            echo
            read -p "Enter new image name: " new_img
            echo
            docker commit $cid $new_img
            ;;
        9) 
            echo -e "${CYAN}===== MODE ACCESSED: START CONTAINER =====${NC}"
            echo
            docker ps -a
            echo
            read -p "Enter container ID/name: " cid
            echo
            echo "Attempting to start container $cid..."
            echo
            docker start $cid
            ;;
        10) 
            echo -e "${CYAN}===== MODE ACCESSED: STOP CONTAINER =====${NC}"
            echo
            docker ps -a
            echo
            read -p "Enter container ID/name: " cid
            echo
            echo "Attempting to stop container $cid..."
            echo
            docker stop $cid
            ;;
        11) 
            echo -e "${CYAN}===== MODE ACCESSED: RESTART CONTAINER =====${NC}"
            echo
            docker ps -a
            echo
            read -p "Enter container ID/name: " cid
            echo
            echo "Attempting to restart container $cid..."
            echo
            docker restart $cid
            ;;
        12) 
            echo -e "${CYAN}===== MODE ACCESSED: SHOW CONTAINER LOGS =====${NC}"
            echo
            docker ps -a
            echo
            read -p "Enter container ID/name: " cid
            docker logs $cid
            ;;
        13) 
            echo -e "${CYAN}===== MODE ACCESSED: SHOW DOCKER SYSTEM LOGS =====${NC}"
            echo
            journalctl -u docker --no-pager
            ;;
        14) 
            echo -e "${CYAN}===== MODE ACCESSED: SHOW DOCKER INFO =====${NC}"
            echo
            docker info
            ;;
        15) 
            echo -e "${CYAN}===== MODE ACCESSED: START DOCKER DAEMON =====${NC}"
            echo
            sudo systemctl start docker
            ;;
        16) 
            echo -e "${CYAN}===== MODE ACCESSED: STOP DOCKER DAEMON =====${NC}"
            echo
            sudo systemctl stop docker
            ;;
        17) 
            echo -e "${CYAN}===== MODE ACCESSED: RESTART DOCKER DAEMON =====${NC}"
            echo
            sudo systemctl restart docker
            ;;
        18) 
            echo -e "${CYAN}===== MODE ACCESSED: REMOVE CONTAINER =====${NC}"
            echo
            docker ps -a
            echo
			remove_container
            ;;   
        19) 
            echo -e "${CYAN}===== MODE ACCESSED: FORCE REMOVE A CONTAINER =====${NC}"
            echo
            docker ps -a
            echo
            force_remove_container
            ;;
            
        20) 
            echo -e "${CYAN}===== MODE ACCESSED: REMOVE DOCKER IMAGE =====${NC}"
            echo
            docker images
            echo
            remove_image
			
            ;;   
        21) 
            echo -e "${CYAN}===== MODE ACCESSED: FORCE REMOVE DOCKER IMAGE =====${NC}"
            echo
            docker images
            echo
            force_remove_image
            ;;
        22) 
            echo -e "${CYAN}===== MODE ACCESSED: PRUNE UNUSED IMAGES & CONTAINERS =====${NC}"
            echo
			remove_all_containers
            ;;
        23) 
            echo -e "${GREEN}Exiting...${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}Invalid option! Try again.${NC}"
            ;;
    esac

    echo -e "\nPress Enter to continue..."
    read
}

# Main loop
while true; do
    main_program
done
