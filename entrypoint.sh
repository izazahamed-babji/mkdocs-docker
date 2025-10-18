#!/bin/bash

# ENV for mount path and filename produced from produce function
MOUNT_PATH="/mnt"
TAR_GZ_FILE_NAME="mkdocs_site.tar.gz"

# Function to build the MkDocs site folder from the input server and create a tar.gz file
do_produce() {

    while true; do
        # Prompt user for sever folder and if CTRL+D, EOF etc are received, exit
        if ! read -r -p "Enter the server folder name (e.g., mkdocs_server) located in ${MOUNT_PATH}/: " SERVER_FOLDER; then
            echo "Operation cancelled by user."
            exit 1
        fi

        # Try again if the folder is empty or an enter button is pressed without any input
        if [ -z "${SERVER_FOLDER}" ]; then
            echo "Error: Folder name cannot be empty..."
            continue
        fi


        SERVER_PATH="${MOUNT_PATH}/${SERVER_FOLDER}"

        # Check for directory in the mount path
        # Else list available files with format suffix
        # ( / for directory, * for files, @ for Symlinks etc...)
        if [ -d "${SERVER_PATH}" ]; then
            echo "Found directory at: ${SERVER_PATH}"
            echo "${SERVER_PATH}"
            break
        else
            echo "Error: Directory ${SERVER_PATH} not found..."
            echo "Available folders in ${MOUNT_PATH}:"
            ls -F "${MOUNT_PATH}"
            echo "Please try again..."
        fi
    done

    if [ -z "${SERVER_PATH}" ]; then
        echo "Exiting due to server folder selection failure..."
        exit 1
    fi

    # Build the site folder from the input server folder
    mkdocs build -f "${SERVER_PATH}/mkdocs.yml" -d "${MOUNT_PATH}/site"

    BUILD_STATUS=$?
    # Check build status and exit if non-zero is received
    if [ ${BUILD_STATUS} -ne 0 ]; then
        echo "ERROR: MkDocs build failed. Exiting..."
        exit 1
    fi

    # Remove any existing .tar.gz files with the same name
    if [ -f "${MOUNT_PATH}/${TAR_GZ_FILE_NAME}" ]; then
        echo "Removing previous tar.gz file: ${TAR_GZ_FILE_NAME}"
        rm -f "${MOUNT_PATH}/${TAR_GZ_FILE_NAME}"
    fi

    # Create the tar.gz file from the site folder making sure index.html is in the root
    tar -C "${MOUNT_PATH}/site/" -cvzf "${MOUNT_PATH}/${TAR_GZ_FILE_NAME}" .

    # Clean up the temporary site folder
    rm -rf "${MOUNT_PATH}/site"

    echo "SUCCESS: Tar GZ file saved to "${MOUNT_PATH}/${TAR_GZ_FILE_NAME}
    echo "The file is now available in the root folder: ${TAR_GZ_FILE_NAME}"
}

# Function to server the input .tar.gz file containing site and serve the content with a Python web server
do_serve() {

    while true; do
        # Prompt user for sever folder and if CTRL+D, EOF etc are received, exit
        if ! read -r -p "Enter the .tar.gz filename (e.g., ${TAR_GZ_FILE_NAME} ) located in ${MOUNT_PATH}/: " INPUT_TAR_FILENAME; then
            echo "Operation cancelled by user."
            exit 1
        fi

        # Try again if the folder is empty or an enter button is pressed without any input
        if [ -z "${INPUT_TAR_FILENAME}" ]; then
            echo "Error: Filename cannot be empty." 
            continue
        fi

        INPUT_FILE_PATH="${MOUNT_PATH}/${INPUT_TAR_FILENAME}"

        # Check for .tar.gz suffix, else try again listing available .tar.gz files
        if [[ -f "${INPUT_FILE_PATH}" ]] && [[ "${INPUT_FILE_PATH}" == *.tar.gz ]]; then
            echo "Found tar file at: ${INPUT_FILE_PATH}"
            break
        else
            echo "Error: Archive file ${INPUT_FILE_PATH} not found."
            echo "Available files in ${MOUNT_PATH}:"
            for file in "${MOUNT_PATH}"/*.tar.gz; do
                if [ -f "${file}" ]; then
                  basename "${file}"
                fi
            done
            echo "Please try again."
        fi
    done

    echo "Extracting ${INPUT_FILE_PATH} to ${EXTRACT_DIR}..."

    # Prepare extraction directory
    rm -rf /mnt/site/
    mkdir -p /mnt/site

    # Extract the file contents
    tar -xzf "${INPUT_FILE_PATH}" -C /mnt/site/

    # Check extraction status
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to extract archive. Exiting." 
        exit 1
    fi

    echo "Extraction complete." 

    echo "Starting Static Web Server from /mnt/site..."

    # Start the Python simple HTTP server
    cd  /mnt/site && exec python3 -m http.server 8000 --bind 0.0.0.0
}

exit_with_tooltip() {
    echo "Usage: docker run <args> <image> {produce|serve}"
    echo "  produce: Builds the MkDocs project and saves the .tar.gz file"
    echo "  serve: Accepts a .tar.gz file, extracts and starts a web server on port 8000."
    exit 1
}

####### Script Execution starts from here.....

#Listen for CTRL+C and exit
trap 'echo "Operation cancelled by user."; exit 1' INT

# Exit if executed without interactive terminal
if [ ! -t 0 ]; then
    echo "Error: Command requires interactive mode (-it flags)." >&2
    exit 1
fi

# Exit if no parameters are passed
if [ $# -eq 0 ]; then
    echo "Error: Missing parameters..." 
    exit_with_tooltip

# Exit if 2 or more parameters are passed
elif [ $# -gt 1 ]; then
    echo "Error: 2 or more parameters passed. Only one allowed" 
    exit_with_tooltip
fi

COMMAND=$1

# Select appropriate functions as per the parameter received
case "${COMMAND}" in
    "produce")
        do_produce
        ;;
    "serve")
        do_serve
        ;;
    *)
        exit_with_tooltip
        ;;
esac

exit 0
