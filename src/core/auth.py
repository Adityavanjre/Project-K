from google.oauth2 import id_token
from google.auth.transport import requests
import os

class AuthService:
    def __init__(self, client_id):
        self.client_id = client_id

    def verify_token(self, token):
        """
        Interrogates Google's Identity Servers to validate the user's token.
        Returns user dictionary if valid, raises Exception if not.
        """
        try:
            # Specify the CLIENT_ID of the app that accesses the backend:
            id_info = id_token.verify_oauth2_token(token, requests.Request(), self.client_id)

            # ID token is valid. Get the user's Google Account ID from the decoded token.
            user_id = id_info['sub']
            
            return {
                "success": True,
                "user_id": user_id,
                "email": id_info.get('email'),
                "name": id_info.get('name'),
                "picture": id_info.get('picture'),
                "exp": id_info.get('exp')
            }
        except ValueError as e:
            # Invalid token
            raise Exception(f"Token verification failed: {str(e)}")
        except Exception as e:
             raise Exception(f"Auth Service Error: {str(e)}")
