# Use an official base image
FROM ubuntu:20.04

# Set working directory
WORKDIR /app

# Copy files to the container
COPY . .

# Install dependencies (example)
RUN apt-get update && apt-get install -y curl

# Default command
CMD ["echo", "Hello, Docker!"]
