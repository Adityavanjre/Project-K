import os
import base64
import logging
from email.mime.text import MIMEText
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from google.auth.transport.requests import Request

logger = logging.getLogger("GMAIL_TOOL")

class GmailTool:
    """
    KALI Sovereign Gmail Integration.
    Handles checking inbox telemetry, parsing bounty notifications, and sending reports.
    """
    def __init__(self, token_path="token.json", credentials_path="credentials.json"):
        self.token_path = token_path
        self.credentials_path = credentials_path
        self.scopes = [
            'https://www.googleapis.com/auth/gmail.readonly',
            'https://www.googleapis.com/auth/gmail.send'
        ]
        self._service = None

    def _get_service(self):
        """Lazy-loads the Google API client service using token.json."""
        if self._service:
            return self._service

        if not os.path.exists(self.token_path):
            logger.error(f"GmailTool: {self.token_path} not found! Run authenticate_gmail.py first.")
            return None

        try:
            creds = Credentials.from_authorized_user_file(self.token_path, self.scopes)
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
                with open(self.token_path, 'w') as token:
                    token.write(creds.to_json())
            
            self._service = build('gmail', 'v1', credentials=creds)
            return self._service
        except Exception as e:
            logger.error(f"GmailTool: Failed to build Gmail service: {e}")
            return None

    def list_messages(self, query=None, max_results=10):
        """List messages in the inbox matching a optional query."""
        service = self._get_service()
        if not service:
            return {"success": False, "error": "Gmail service not initialized."}

        try:
            results = service.users().messages().list(
                userId='me', q=query, maxResults=max_results
            ).execute()
            messages = results.get('messages', [])
            
            output = []
            for msg in messages:
                detail = service.users().messages().get(userId='me', id=msg['id'], format='minimal').execute()
                output.append({
                    "id": msg['id'],
                    "threadId": msg['threadId'],
                    "snippet": detail.get("snippet", "")
                })
            return {"success": True, "messages": output}
        except Exception as e:
            logger.error(f"GmailTool: list_messages failed: {e}")
            return {"success": False, "error": str(e)}

    def get_message(self, message_id):
        """Retrieve full details of a specific message by ID."""
        service = self._get_service()
        if not service:
            return {"success": False, "error": "Gmail service not initialized."}

        try:
            message = service.users().messages().get(userId='me', id=message_id, format='full').execute()
            headers = message.get('payload', {}).get('headers', [])
            
            subject = "No Subject"
            sender = "Unknown Sender"
            date = "Unknown Date"
            for h in headers:
                if h['name'].lower() == 'subject':
                    subject = h['value']
                elif h['name'].lower() == 'from':
                    sender = h['value']
                elif h['name'].lower() == 'date':
                    date = h['value']

            # Extract body
            body = ""
            parts = message.get('payload', {}).get('parts', [])
            if not parts:
                body_data = message.get('payload', {}).get('body', {}).get('data', '')
                if body_data:
                    body = base64.urlsafe_b64decode(body_data.encode('UTF-8')).decode('UTF-8', errors='ignore')
            else:
                for part in parts:
                    if part.get('mimeType') == 'text/plain':
                        body_data = part.get('body', {}).get('data', '')
                        if body_data:
                            body = base64.urlsafe_b64decode(body_data.encode('UTF-8')).decode('UTF-8', errors='ignore')
                            break

            return {
                "success": True,
                "id": message_id,
                "subject": subject,
                "sender": sender,
                "date": date,
                "snippet": message.get("snippet", ""),
                "body": body
            }
        except Exception as e:
            logger.error(f"GmailTool: get_message failed: {e}")
            return {"success": False, "error": str(e)}

    def send_message(self, to, subject, body):
        """Send a plain text email message."""
        service = self._get_service()
        if not service:
            return {"success": False, "error": "Gmail service not initialized."}

        try:
            message = MIMEText(body)
            message['to'] = to
            message['subject'] = subject
            raw_message = base64.urlsafe_b64encode(message.as_bytes()).decode('utf-8')
            
            sent_msg = service.users().messages().send(
                userId='me', body={'raw': raw_message}
            ).execute()
            
            logger.info(f"GmailTool: Email sent successfully to {to}. ID: {sent_msg.get('id')}")
            return {"success": True, "id": sent_msg.get('id')}
        except Exception as e:
            logger.error(f"GmailTool: send_message failed: {e}")
            return {"success": False, "error": str(e)}

    def check_bounty_emails(self):
        """Checks the inbox specifically for bounty award notifications."""
        # Query specifically for hackerone, bugcrowd, or general bounty award phrases
        query = "bounty awarded OR hackerone OR bugcrowd"
        res = self.list_messages(query=query, max_results=5)
        if not res.get("success"):
            return []

        bounty_emails = []
        for msg in res.get("messages", []):
            detail = self.get_message(msg["id"])
            if detail.get("success"):
                bounty_emails.append(detail)
        return bounty_emails
