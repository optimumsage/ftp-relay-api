# Overview - ftp-relay-api

## Introduction
The ftp-relay-api project is designed to forward FTP messages via API calls. It can be deployed on a machine with the necessary permissions to communicate with FTP servers. This is particularly useful when your application is running in a container or on a machine that lacks proper access for security reasons.

## Installation
To use the ftp-relay-api, you need to have Docker installed on your machine. Follow the steps below to install and run the Docker image:

1. Install Docker on your machine.
2. Pull the Docker image from the following location: [optimumsage/ftp-relay-api](https://hub.docker.com/r/optimumsage/ftp-relay-api)
   

   docker pull optimumsage/ftp-relay-api
   


3. Run the Docker image, mapping port 8000 of the container to port 8000 of your machine:
   

   docker run -p 8000:8000 optimumsage/ftp-relay-api
   


## Usage
Once the Docker image is running, you can access the ftp-relay-api using the following endpoint:

http://localhost:8000/relay


To send an FTP message, make a POST request to the above endpoint with the following parameters:

- `host`: The FTP server host.
- `port`: The FTP server port.
- `user`: The username for authentication.
- `password`: The password for authentication.
- `directory`: The directory on the FTP server where the message should be forwarded.
- `is_pasv`: A boolean value indicating whether to use passive mode.
- `file_name`: The name of the file to be created on the FTP server.
- `message`: The content of the message to be sent.

Example API call using cURL:

bash
curl -X POST -d "host=ftp.example.com&port=21&user=username&password=password&directory=/path/to/directory&is_pasv=true&file_name=message.txt&message=Hello, FTP server!" http://localhost:8000/relay

This will forward the provided `message` to the specified FTP server.

Note: Make sure to replace the values for `host`, `port`, `user`, `password`, `directory`, `is_pasv`, `file_name`, and `message` with your own values.

That's it! You have successfully installed and used the ftp-relay-api Docker image. Enjoy forwarding FTP messages via API calls!