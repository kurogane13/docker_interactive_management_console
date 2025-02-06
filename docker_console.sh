#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Function to check Docker daemon status
check_docker_status() {
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}🟢 Docker daemon is running${NC}"
    else
        echo -e "${RED}🔴 Docker daemon is stopped${NC}"
    fi
}

# Function to display the menu
show_menu() {
    echo
    echo -e "${CYAN}"
    echo "====================================="
    echo "       🐳 Docker Management Console      "
    echo "====================================="
    echo -e "${NC}"
    check_docker_status
    echo -e "\n${YELLOW}1. Show all Docker images${NC}"
    echo -e "${YELLOW}2. Run a container interactively (Persistent)${NC}"
    echo -e "${YELLOW}3. Attach to a running container${NC}"
    echo -e "${YELLOW}4. Build Docker image from Dockerfile${NC}"
    echo -e "${YELLOW}5. Persist changes to container image${NC}"
    echo -e "${YELLOW}6. Start a container${NC}"
    echo -e "${YELLOW}7. Stop a container${NC}"
    echo -e "${YELLOW}8. Restart a container${NC}"
    echo -e "${YELLOW}9. Show logs for a container${NC}"
    echo -e "${YELLOW}10. Show Docker system logs${NC}"
    echo -e "${YELLOW}11. Show detailed Docker info${NC}"
    echo -e "${YELLOW}12. Start Docker daemon${NC}"
    echo -e "${YELLOW}13. Stop Docker daemon${NC}"
    echo -e "${YELLOW}14. Restart Docker daemon${NC}"
    echo -e "${YELLOW}15. Remove an image${NC}"
    echo -e "${YELLOW}16. Show running containers${NC}"
    echo -e "${YELLOW}17. Show all containers (running + stopped)${NC}"
    echo -e "${YELLOW}18. Prune unused images & containers${NC}"
    echo -e "${YELLOW}0. Exit${NC}\n"
}

# Function to handle user choice
handle_choice() {
    read -p "Select an option: " choice
    echo -e "\n"

    case $choice in
        1) 
            echo -e "${BLUE}Showing all Docker images...${NC}"
            docker images 
            ;;
        2) 
            read -p "Enter image name: " img
            echo -e "${BLUE}Starting container from image $img...${NC}"
            container_id=$(docker run -dit $img)
            echo -e "${GREEN}Container started: $container_id${NC}"
            echo -e "${YELLOW}Attaching to container $container_id... (Use Ctrl+P + Ctrl+Q to detach)${NC}"
            docker attach $container_id
            ;;
        3) 
            read -p "Enter container ID/name: " cid
            echo -e "${BLUE}Attaching to container $cid... (Use Ctrl+P + Ctrl+Q to detach)${NC}"
            docker attach $cid
            ;;
        4) 

			read -p "Enter name for the new Docker image: " img_name
			echo -e "${BLUE}Building Docker image $img_name from Dockerfile...${NC}"
			docker build -t "$img_name" .

			read -p "Enter a container name (leave empty for a random name): " CONTAINER_NAME

			if [[ -z "$CONTAINER_NAME" ]]; then
				docker run -it "$img_name"  # No name assigned, Docker will generate one
			else
				docker run -it --name "$CONTAINER_NAME" "$img_name"
			fi
            ;;
        5) 
            read -p "Enter container ID to persist changes: " cid
            read -p "Enter new image name: " new_img
            echo -e "${BLUE}Persisting changes from container $cid to new image $new_img...${NC}"
            docker commit $cid $new_img
            ;;
        6) 
            read -p "Enter container ID/name: " cid
            echo -e "${BLUE}Starting container $cid...${NC}"
            docker start $cid
            ;;
        7) 
            read -p "Enter container ID/name: " cid
            echo -e "${BLUE}Stopping container $cid...${NC}"
            docker stop $cid
            ;;
        8) 
            read -p "Enter container ID/name: " cid
            echo -e "${BLUE}Restarting container $cid...${NC}"
            docker restart $cid
            ;;
        9) 
            read -p "Enter container ID/name: " cid
            echo -e "${BLUE}Showing logs for container $cid...${NC}"
            docker logs $cid
            ;;
        10) 
            echo -e "${BLUE}Showing Docker system logs...${NC}"
            journalctl -u docker --no-pager
            ;;
        11) 
            echo -e "${BLUE}Showing detailed Docker info...${NC}"
            docker info
            ;;
        12) 
            echo -e "${GREEN}Starting Docker daemon...${NC}"
            sudo systemctl start docker
            ;;
        13) 
            echo -e "${RED}Stopping Docker daemon...${NC}"
            sudo systemctl stop docker
            ;;
        14) 
            echo -e "${YELLOW}Restarting Docker daemon...${NC}"
            sudo systemctl restart docker
            ;;
        15) 
            read -p "Enter image ID to remove: " img
            echo -e "${RED}Removing image $img...${NC}"
            docker rmi $img
            ;;
        16) 
            echo -e "${BLUE}Showing running containers...${NC}"
            docker ps
            ;;
        17) 
            echo -e "${BLUE}Showing all containers (running & stopped)...${NC}"
            docker ps -a
            ;;
        18) 
            echo -e "${YELLOW}Pruning unused images & containers...${NC}"
            docker system prune -a -f
            ;;
        0) 
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
    show_menu
    handle_choice
done
