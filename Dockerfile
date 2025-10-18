# Builder stage starting with a minimal image of python 12 slim stable debian 12
FROM python:3.12-slim-bookworm AS builder

# Copy the file containing libraries to be installed
COPY requirements.txt .

# Create a Python virtual environment to manage libraries in a dedicated folder
RUN python -m venv /opt/venv

# Add the venv's bin directory to the PATH
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip & then install libraries without caching
RUN pip install --upgrade pip & pip install --no-cache-dir -r requirements.txt

# --- Final Stage ---
# Start with the same minimal base
FROM python:3.12-slim-bookworm

# Copy the venv folder containing libraries from the builder stage
COPY --from=builder /opt/venv /opt/venv

# Add the venv's bin directory to the PATH
ENV PATH="/opt/venv/bin:$PATH"

# Expose the application's listening port
EXPOSE 8000

# Copy the entrypoint script into the root folder
COPY ./entrypoint.sh /

# Set the copied script as the entrypoint when the container runs
ENTRYPOINT ["/entrypoint.sh"]
