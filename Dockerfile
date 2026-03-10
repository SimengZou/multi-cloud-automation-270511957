# Use ECR Public mirror instead of Docker Hub to avoid pull rate limit errors
# in CodeBuild. public.ecr.aws has no rate limits for AWS services.
FROM public.ecr.aws/docker/library/node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Copy source files
COPY . .

# Expose the port your app runs on
EXPOSE 3000

# Command to run your app
CMD [ "node", "index.js" ]
