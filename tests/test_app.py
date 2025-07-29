from app import ping


def test_ping():
    assert ping() == {"message": "pong"}
