import io
import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from ftplib import FTP, error_perm

app = Flask(__name__)
CORS(app, origins=[
    "*"
])


@app.before_request
def before_request():
    if request.method == 'POST' and request.headers.get('Content-Type') == 'application/json':
        request.json_data = request.get_json()


@app.route("/")
def home():
    return jsonify({
        "status": "It's working",
        "usage": "http[s]:your-domain.com[:port]/relay"
    })


@app.route("/relay", methods=['POST'])
def relay():
    if not hasattr(request, 'json_data'):
        host = request.form.get('host')
        port = int(request.form.get('port'))
        user = request.form.get('user')
        password = request.form.get('password')
        directory = request.form.get('directory')
        is_pasv = True if request.form.get('is_pasv').strip() == "true" else False
        file_name = request.form.get('file_name')
        message = request.form.get('message')
    else:
        json_data = request.json_data
        host = json_data['host']
        port = int(json_data['port'])
        user = json_data['user']
        password = json_data['password']
        directory = json_data['directory']
        is_pasv = bool(json_data['is_pasv'])
        file_name = json_data['file_name']
        message = json_data['message']
    in_memory_file = io.BytesIO(message.encode('utf-8'))
    file_name_without_extension, file_extension = os.path.splitext(file_name)
    try:
        with FTP(host) as ftp:
            # Log in to the FTP server
            ftp.connect(host, port)
            ftp.login(user, password)
            ftp.set_pasv(is_pasv)
            # Change to the remote directory
            if not directory:
                ftp.cwd(directory)
            ftp.storbinary(f'STOR {file_name_without_extension}.tmp', in_memory_file)
            ftp.rename(f'{file_name_without_extension}.tmp', f'{file_name_without_extension}{file_extension}')
    except error_perm as e:
        return jsonify({
            "status": False,
            "message": "Message sending failed",
            "error": str(e),
        })
    # Close the in-memory file
    in_memory_file.close()

    return jsonify({
        "status": True,
        "message": "message has been relayed",
    })


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=8000)
