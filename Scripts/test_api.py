from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route('/api/data', methods=['POST'])
def get_data():
    #data = {'message': 'Hello from Python backend!'}

    name = request.form.get('name')
    return f'Hello {name}, from Python backend!' #jsonify(data)

if __name__ == '__main__':
    app.run()