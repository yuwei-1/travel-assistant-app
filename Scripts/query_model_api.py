from flask import Flask, jsonify, request
from query_gemini_public import QueryGeminiModel

app = Flask(__name__)

with app.app_context():
    model = QueryGeminiModel()

@app.route('/api/data', methods=['POST'])
def get_data():
    query = request.form.get('query')
    response = model.query(query).rstrip()
    return response

if __name__ == '__main__':
    app.run(port=5001)