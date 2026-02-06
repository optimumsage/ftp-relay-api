# Use the official Python image as the base image
FROM python:3.9-slim-buster

# Set working directory
WORKDIR /app

# Copy requirements file into the container
COPY requirements.txt /app/

# Install app dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY ./app /app/

# Expose the port that Gunicorn will listen on
EXPOSE 8000

# Command to run Gunicorn
CMD ["gunicorn", "-w", "5" , "--bind", "0.0.0.0:8000", "main:app"]