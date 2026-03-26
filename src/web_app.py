#!/usr/bin/env python3
"""
Flask web application for KALI.
Provides a user-friendly web interface for asking questions and getting explanations.
"""

import os
import logging
from dotenv import load_dotenv
from flask import Flask, render_template, request, jsonify, session, send_from_directory, send_file
from flask_cors import CORS

# Load env variables immediately
load_dotenv()
from datetime import datetime

from core.processor import DoubtProcessor
from core.data_structures import DoubtContext
from core.auth import AuthService
from utils.helpers import load_config, setup_logging
from functools import wraps

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({"success": False, "error": "Unauthorized. Please sign in."}), 401
        return f(*args, **kwargs)
    return decorated_function

def create_app(config_path="config/config.json"):
    """Create and configure the Flask application."""
    app = Flask(__name__, static_folder="static")
    CORS(app) # Enable CORS for modern frontend development
    
    app.secret_key = os.environ.get("SECRET_KEY", "dev-secret-key-change-in-production")
    
    # Setup logging
    setup_logging(level=logging.INFO)
    logger = logging.getLogger(__name__)
    
    # Unified Initialization with Graceful Degradation
    try:
        # Load configuration
        config = load_config(config_path)
        logger.info("Configuration loaded successfully")
        
        # Initialize the doubt processor
        app.doubt_processor = DoubtProcessor(config)
        logger.info("Doubt processor initialized")

        # Safely initialize Auth Service
        try:
            client_id = os.getenv("GOOGLE_CLIENT_ID")
            if not client_id:
                logger.warning("GOOGLE_CLIENT_ID not found in env. Auth will fail.")
            app.auth_service = AuthService(client_id)
            logger.info("Auth Service initialized")
        except Exception as e:
            logger.error(f"Auth Service Warning: {e}. Authenticated features disabled.")
            app.auth_service = None
            
    except Exception as e:
        logger.error(f"CRITICAL: DoubtProcessor failed to init: {e}. Switching to LITE mode.")
        # Mock processor for basic UI rendering if core fails
        class LiteProcessor:
            def __init__(self):
                self.power_mode = "LITE (RECOVERY)"
                try:
                    from core.ai_service import AIService
                    self.ai_service = AIService()
                except:
                    self.ai_service = None
        app.doubt_processor = LiteProcessor()
        app.auth_service = None
        
    # Security: Ensure Auth Service is always present even if client_id is missing (for skeletal responses)
    if not hasattr(app, 'auth_service') or app.auth_service is None:
        app.auth_service = AuthService(None)
    
    @app.route("/")
    def index():
        """Main page with the doubt clearing interface."""
        return render_template("index.html")

    @app.route("/api/verify_token", methods=["POST"])
    def verify_token():
        """Verify Google ID Token and start session."""
        try:
            data = request.get_json()
            token = data.get("token")
            if not token:
                return jsonify({"success": False, "error": "No token provided"}), 400
            
            if not app.auth_service:
                return jsonify({"success": False, "error": "Auth Service not configured"}), 500

            user_info = app.auth_service.verify_token(token)
            
            # Create Session
            session['user_id'] = user_info['user_id']
            session['email'] = user_info['email']
            session['name'] = user_info['name']
            
            logger.info(f"User logged in: {user_info['email']}")
            
            return jsonify({
                "success": True, 
                "message": "Authenticated",
                "user": user_info
            })
        except Exception as e:
            logger.error(f"Auth Failed: {e}")
            return jsonify({"success": False, "error": str(e)}), 401

    @app.route("/api/logout", methods=["POST"])
    def logout():
        session.clear()
        return jsonify({"success": True, "message": "Logged out"})

    @app.route("/api/sync", methods=["POST"])
    def sync_cycle():
        """Phase 15: Perform the Sync Cycle to reconsolidate state."""
        try:
            success = app.doubt_processor.run_sync_cycle()
            return jsonify({
                "success": success, 
                "phase": getattr(app.doubt_processor, 'current_phase', 0),
                "message": "KALI Sync Cycle Complete." if success else "Sync Cycle Partially Failed."
            })
        except Exception as e:
            logger.error(f"Sync Cycle Error: {e}")
            return jsonify({"success": False, "error": str(e)}), 500
        return jsonify({"success": True, "message": "Logged out"})
        
    @app.route("/static/audio/<path:filename>")
    def serve_audio(filename):
        """Serve generated audio files."""
        audio_dir = os.path.join(os.path.dirname(__file__), "static", "audio")
        return send_from_directory(audio_dir, filename)
    
    @app.route("/ask", methods=["POST"])
    def ask_question():
        """Handle standard text question."""
        try:
            data = request.get_json()
            question = data.get("question", "").strip()
            
            if not question:
                return jsonify({"success": False, "error": "Please enter a question"}), 400
            
            logger.info(f"Processing question: {question[:50]}...")
            
            result = app.doubt_processor.process_doubt(question)
            
            # Handle both legacy string and new dict responses
            if isinstance(result, dict):
                response_text = result.get("text", "")
                can_build = result.get("can_build", False)
            else:
                response_text = str(result)
                can_build = False

            return jsonify({
                "success": True,
                "response": response_text,
                "can_build": can_build,
                "timestamp": datetime.now().isoformat()
            })
            
        except Exception as e:
            logger.error(f"Error processing question: {e}")
            return jsonify({"success": False, "error": str(e)}), 500

    @app.route("/api/presentation", methods=["POST"])
    def generate_presentation():
        """Generate a multimedia presentation (Steps + Audio + 3D Code)."""
        try:
            data = request.get_json()
            question = data.get("question", "").strip()
            
            result = app.doubt_processor.process_presentation_mode(question)
            return jsonify({"success": True, "data": result})
            
        except Exception as e:
            return jsonify({"success": False, "error": str(e)}), 500

    @app.route("/api/project_plan", methods=["POST"])
    def generate_project_plan():
        """Generate a project build plan (BOM + Roadmap)."""
        try:
            data = request.get_json()
            idea = data.get("idea", "").strip()
            
            result = app.doubt_processor.process_project_mentor(idea)
            return jsonify({"success": True, "data": result})
            
        except Exception as e:
            return jsonify({"success": False, "error": str(e)}), 500

    @app.route("/api/contextual_doubt", methods=["POST"])
    def contextual_doubt():
        """Handle a doubt asked during a step."""
        try:
            data = request.get_json()
            question = data.get("question", "")
            context = data.get("context", {}) # {current_step_text: ..., topic: ...}
            
            result = app.doubt_processor.process_contextual_doubt(question, context)
            return jsonify({"success": True, "data": result})
            
        except Exception as e:
            return jsonify({"success": False, "error": str(e)}), 500
    
    @app.route("/api/history", methods=["GET"])
    @login_required
    def get_history():
        """Get list of past sessions."""
        try:
            # Access memory service via processor
            sessions = app.doubt_processor.memory.get_sessions()
            return jsonify({"success": True, "data": sessions})
        except Exception as e:
            logger.error(f"Failed to fetch history: {e}")
            return jsonify({"success": False, "error": str(e)}), 500

    @app.route("/api/history/<session_id>", methods=["GET"])
    @login_required
    def get_session_history(session_id):
        """Get full content of a specific session."""
        try:
            content = app.doubt_processor.memory.get_session_content(session_id)
            return jsonify({"success": True, "data": content})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)}), 500

    @app.route("/api/agent", methods=["POST"])
    def run_agent():
        """KALI autonomously researches and executes a research goal."""
        try:
            data = request.get_json()
            goal = data.get("goal", "").strip()
            if not goal:
                return jsonify({"success": False, "error": "Mission parameters missing."}), 400
            
            res = app.doubt_processor.perform_mission(goal)
            return jsonify(res)
        except Exception as e:
            logger.error(f"Agent execution failed: {e}")
            return jsonify({"success": False, "error": str(e)}), 500

    @app.route("/api/status", methods=["GET"])
    def get_status():
        """Get real-time consciousness/status report."""
        try:
            processor = app.doubt_processor
            status = {
                "consciousness_level": min(100.0, 95.0 + (processor.message_count * 0.1)),
                "active_mission": processor.proactive_research.seeds[0] if processor.proactive_research.is_active else "Idle",
                "is_local": processor.use_local_ai,
                "uptime": "Optimal",
                "last_discovery": "Quantum Vedic Resonance",
                "heartbeat": {"status": "OFFLINE"} # Default
            }
            # Try to fetch actual heartbeat
            try:
                with open("data/trace_heartbeat.json", "r") as f:
                    import json
                    status["heartbeat"] = json.load(f)
            except: pass

            # Try to fetch actual last discovery
            try:
                with open("data/discoveries.jsonl", "r") as f:
                    lines = f.readlines()
                    if lines:
                        import json
                        last = json.loads(lines[-1])
                        status["last_discovery"] = last.get("problem", status["last_discovery"])
            except:
                pass
                
            return jsonify({"success": True, "status": status})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)}), 500

    @app.route('/api/export_report', methods=['POST'])
    def export_report():
        data = request.json
        title = data.get("title", "KALI Research Report")
        content = data.get("content", "")
        user_name = session.get("name", "Sir")
        
        path = app.doubt_processor.report_generator.generate_pdf_report(title, content, user_name)
        if path and os.path.exists(path):
            return send_file(path, as_attachment=True)
        return jsonify({"success": False, "error": "Generation failed"})

    @app.route('/api/analyze_image', methods=['POST'])
    def analyze_image():
        """Analyze uploaded image via DNA/CV engine."""
        try:
            if 'image' not in request.files:
                return jsonify({"success": False, "error": "No image data"}), 400
            
            f = request.files['image']
            upload_dir = "data/uploads/visions"
            os.makedirs(upload_dir, exist_ok=True)
            path = os.path.join(upload_dir, f.filename)
            f.save(path)
            
            # --- PHASE 34 ACTIVATION: Calling real Vision AI ---
            with open(path, "rb") as image_file:
                 analysis = app.doubt_processor.ai_service.analyze_image(
                     image_file, 
                     prompt="Perform a deep-core technical analysis of this hardware/circuit diagram. Identify specific components."
                 )
            
            return jsonify({"success": True, "analysis": analysis})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)}), 500

    @app.route('/api/ingest_document', methods=['POST'])
    def ingest_document():
        if 'file' in request.files:
            f = request.files['file']
            upload_dir = "data/uploads"
            os.makedirs(upload_dir, exist_ok=True)
            path = os.path.join(upload_dir, f.filename)
            f.save(path)
        else:
            path = request.json.get("path")
        
        if not path:
            return jsonify({"success": False, "error": "No file or path provided"})
            
        res = app.doubt_processor.ingestor.ingest_pdf(path)
        return jsonify(res)

    @app.route('/api/toggle_power', methods=['POST'])
    def toggle_power():
        new_mode = request.json.get("mode")
        if new_mode in ["ECO", "TURBO"]:
            app.doubt_processor.power_mode = new_mode
            return jsonify({"success": True, "mode": app.doubt_processor.power_mode})
        return jsonify({"success": False, "error": "Invalid mode"})

    @app.route('/api/feedback', methods=['POST'])
    def feedback():
        data = request.json
        res = app.doubt_processor.handle_feedback(data.get("q"), data.get("r"), data.get("c"))
        return jsonify(res)

    @app.route('/api/switch_user', methods=['POST'])
    def switch_user():
        uid = request.json.get("uid")
        app.doubt_processor.user_dna.switch_user(uid)
        return jsonify({"success": True, "user": uid})

    return app


def main():
    """Run the Flask development server."""
    app = create_app()
    config = load_config("config/config.json")
    api_config = config.get("api", {})
    
    host = api_config.get("host", "localhost")
    port = api_config.get("port", 8000)
    debug = api_config.get("debug", False)
    
    print(f"🚀 KALI Premium Interface Running on http://{host}:{port}")
    app.run(host=host, port=port, debug=debug)



if __name__ == "__main__":
    main()
