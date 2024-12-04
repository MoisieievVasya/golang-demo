# Step 1: Use official Golang image as base
FROM golang:1.23-alpine

# Step 2: Set the working directory in the container
WORKDIR /app

# Step 3: Copy the Go module files and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Step 4: Copy the rest of the application code
COPY . .

# Step 5: Install `air` for hot-reloading (using Air for Go)
RUN go install github.com/cosmtrek/air@v1.40.4

# Step 6: Expose the application port
EXPOSE 8080

# Step 7: Run the application with Air for hot-reloading
CMD ["air"]
