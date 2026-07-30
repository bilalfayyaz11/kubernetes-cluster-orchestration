from flask import Flask, jsonify, request
import os
import redis

app = Flask(__name__)

redis_client = redis.Redis(
    host=os.getenv("REDIS_HOST", "redis"),
    port=6379,
    decode_responses=True,
)


@app.get("/api/health")
def health():
    try:
        redis_client.ping()
        return jsonify(status="healthy", redis="connected"), 200
    except redis.RedisError as exc:
        return jsonify(status="unhealthy", error=str(exc)), 503


@app.get("/api/visits")
def get_visits():
    visits = redis_client.incr("visits")
    return jsonify(visits=visits)


@app.post("/api/message")
def set_message():
    payload = request.get_json(silent=True) or {}
    message = payload.get("message")

    if not isinstance(message, str) or not message.strip():
        return jsonify(error="A non-empty message is required"), 400

    redis_client.set("message", message.strip())
    return jsonify(status="saved", message=message.strip()), 201


@app.get("/api/message")
def get_message():
    message = redis_client.get("message")

    if message is None:
        return jsonify(message=None, status="not set"), 404

    return jsonify(message=message)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
