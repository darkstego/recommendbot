# Use a slim version of the official Ruby image
FROM ruby:3-slim

# Install system dependencies
# build-essential is often required for gems with native C extensions
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /app

# Copy the Gemfile and Gemfile.lock first
# This allows Docker to cache the 'bundle install' layer
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy the rest of the application code
COPY . .

# Run the application
CMD ["ruby", "recommend.rb"]
