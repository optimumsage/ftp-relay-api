import io
import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from ftplib import FTP, error_perm
import pysftp

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
        with FTP() as ftp:
            # Connect and log in to the FTP server
            ftp.connect(host, port)
            ftp.login(user, password)
            ftp.set_pasv(is_pasv)
            # Change to the remote directory
            if directory:
                ftp.cwd(directory)
            ftp.storbinary(f'STOR {file_name_without_extension}.tmp', in_memory_file)
            ftp.rename(f'{file_name_without_extension}.tmp', f'{file_name_without_extension}{file_extension}')
    except Exception as e:
        error_msg = str(e) if str(e) else f"{type(e).__name__}: Connection error"
        return jsonify({
            "status": False,
            "message": "Message sending failed",
            "error": error_msg,
        })
    finally:
        # Close the in-memory file
        in_memory_file.close()

    return jsonify({
        "status": True,
        "message": "message has been relayed",
    })


@app.route("/sftp/relay", methods=['POST'])
def sftp_relay():
    if not hasattr(request, 'json_data'):
        host = request.form.get('host')
        port = int(request.form.get('port'))
        user = request.form.get('user')
        password = request.form.get('password')
        directory = request.form.get('directory')
        file_name = request.form.get('file_name')
        message = request.form.get('message')
        private_key = request.form.get('private_key')
        private_key_pass = request.form.get('private_key_pass')
    else:
        json_data = request.json_data
        host = json_data['host']
        port = int(json_data['port'])
        user = json_data['user']
        password = json_data['password']
        directory = json_data['directory']
        file_name = json_data['file_name']
        message = json_data['message']
        private_key = json_data.get('private_key')
        private_key_pass = json_data.get('private_key_pass')
    
    in_memory_file = io.BytesIO(message.encode('utf-8'))
    
    try:
        cnopts = pysftp.CnOpts()
        cnopts.hostkeys = None

        connection_args = {
            'host': host,
            'username': user,
            'port': port,
            'cnopts': cnopts
        }

        if private_key:
            private_key_file = io.StringIO(private_key)
            connection_args['private_key'] = private_key_file
            if private_key_pass:
                connection_args['private_key_pass'] = private_key_pass
        else:
            connection_args['password'] = password
        
        with pysftp.Connection(**connection_args) as sftp:
            if directory:
                sftp.cwd(directory)
            
            with sftp.open(f'{file_name}.tmp', 'wb') as f:
                f.write(in_memory_file.getvalue())
            sftp.rename(f'{file_name}.tmp', file_name)

    except Exception as e:
        return jsonify({
            "status": False,
            "message": "Message sending failed",
            "error": str(e),
        })
    finally:
        in_memory_file.close()

    return jsonify({
        "status": True,
        "message": "message has been relayed",
    })


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=8000)
