from app import app


def test_ping():
    with app.test_client() as client:
        response = client.get("/api/ping")
        assert response.status_code == 200
        data = response.get_json()
        assert data["message"] == "pong"
        assert "hostname" in data
