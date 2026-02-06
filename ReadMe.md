# Overview - ftp-relay-api

## Introduction
The ftp-relay-api project is designed to forward FTP and SFTP messages via API calls. It can be deployed on a machine with the necessary permissions to communicate with FTP/SFTP servers. This is particularly useful when your application is running in a container or on a machine that lacks proper access for security reasons.

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

```bash
curl -X POST -d "host=ftp.example.com&port=21&user=username&password=password&directory=/path/to/directory&is_pasv=true&file_name=message.txt&message=Hello, FTP server!" http://localhost:8000/relay
```

### SFTP Relay

To send an SFTP message, make a POST request to the `http://localhost:8000/sftp/relay` endpoint with the following parameters:

- `host`: The SFTP server host.
- `port`: The SFTP server port.
- `user`: The username for authentication.
- `password`: The password for authentication (optional if `private_key` is provided).
- `private_key`: The private SSH key for authentication (optional).
- `private_key_pass`: The passphrase for the private key (optional).
- `directory`: The directory on the SFTP server where the message should be forwarded.
- `file_name`: The name of the file to be created on the SFTP server.
- `message`: The content of the message to be sent.

Example API call using cURL:

```bash
curl -X POST -d "host=sftp.example.com&port=22&user=username&password=password&directory=/path/to/directory&file_name=message.txt&message=Hello, SFTP server!" http://localhost:8000/sftp/relay
```

Example with SSH key:
```bash
curl -X POST -d "host=sftp.example.com&port=22&user=username&private_key=$(cat ~/.ssh/id_rsa)&private_key_pass=my_passphrase&directory=/path/to/directory&file_name=message.txt&message=Hello, SFTP server!" http://localhost:8000/sftp/relay
```

This will forward the provided `message` to the specified FTP/SFTP server.

Note: Make sure to replace the values for `host`, `port`, `user`, `password`, `directory`, `is_pasv`, `file_name`, and `message` with your own values.

## Testing

To run the automated test suite, use the provided test script:

```bash
./test_relay.sh
```

The test script will:
- Test SFTP relay with successful uploads
- Verify files are created on the SFTP server
- Test error handling with incorrect credentials
- Test both form data and JSON payloads
- Test FTP relay error handling
- Verify the home endpoint

Note: FTP server tests may fail on Apple Silicon (ARM64) Macs due to Docker Rosetta emulation issues. This is expected and does not indicate a problem with the application code.

That's it! You have successfully installed and used the ftp-relay-api Docker image. Enjoy forwarding FTP and SFTP messages via API calls!
