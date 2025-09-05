#!/usr/bin/env python3
"""
Flask web application for Project-K.
Provides a user-friendly web interface for asking questions and getting explanations.
"""

import os
import logging
from flask import Flask, render_template, request, jsonify, session
from datetime import datetime

from core.processor import DoubtProcessor
from core.data_structures import DoubtContext
from utils.helpers import load_config, setup_logging


def create_app(config_path="config/config.json"):
    """Create and configure the Flask application."""
    app = Flask(__name__)
    app.secret_key = os.environ.get("SECRET_KEY", "dev-secret-key-change-in-production")
    
    # Setup logging
    setup_logging(level=logging.INFO)
    logger = logging.getLogger(__name__)
    
    try:
        # Load configuration
        config = load_config(config_path)
        logger.info("Configuration loaded successfully")
        
        # Initialize the doubt processor
        app.doubt_processor = DoubtProcessor(config)
        logger.info("Doubt processor initialized")
        
    except Exception as e:
        logger.error(f"Failed to initialize application: {e}")
        raise
    
    @app.route("/")
    def index():
        """Main page with the doubt clearing interface."""
        return render_template("index.html")
    
    @app.route("/ask", methods=["POST"])
    def ask_question():
        """Handle question submission and return response."""
        try:
            data = request.get_json()
            question = data.get("question", "").strip()
            user_level = data.get("user_level", "intermediate")
            
            if not question:
                return jsonify({
                    "success": False,
                    "error": "Please enter a question"
                }), 400
            
            logger.info(f"Processing question: {question[:50]}...")
            
            # Create context with user preferences
            context = DoubtContext(
                question=question,
                user_level=user_level,
                conversation_history=session.get("conversation_history", [])
            )
            
            # Process the doubt
            response = app.doubt_processor.process_doubt(question, context)
            
            # Update session conversation history
            if "conversation_history" not in session:
                session["conversation_history"] = []
            
            session["conversation_history"].append({
                "question": question,
                "response": response,
                "timestamp": datetime.now().isoformat(),
                "user_level": user_level
            })
            
            # Keep only last 10 conversations
            if len(session["conversation_history"]) > 10:
                session["conversation_history"] = session["conversation_history"][-10:]
            
            return jsonify({
                "success": True,
                "response": response,
                "timestamp": datetime.now().isoformat(),
                "conversation_count": len(session["conversation_history"])
            })
            
        except Exception as e:
            logger.error(f"Error processing question: {e}")
            return jsonify({
                "success": False,
                "error": "Sorry, I encountered an error while processing your question. Please try again."
            }), 500
    
    @app.route("/history")
    def get_history():
        """Get conversation history for the current session."""
        history = session.get("conversation_history", [])
        return jsonify({
            "success": True,
            "history": history,
            "count": len(history)
        })
    
    @app.route("/clear", methods=["POST"])
    def clear_history():
        """Clear conversation history."""
        session.pop("conversation_history", None)
        # Also clear the processor's history
        app.doubt_processor.clear_history()
        
        return jsonify({
            "success": True,
            "message": "Conversation history cleared"
        })
    
    @app.route("/health")
    def health_check():
        """Health check endpoint."""
        return jsonify({
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "version": "0.1.0"
        })
    
    @app.errorhandler(404)
    def not_found(error):
        """Handle 404 errors."""
        return render_template("error.html", 
                             error_code=404, 
                             error_message="Page not found"), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        """Handle 500 errors."""
        logger.error(f"Internal server error: {error}")
        return render_template("error.html",
                             error_code=500,
                             error_message="Internal server error"), 500
    
    return app


def main():
    """Run the Flask development server."""
    app = create_app()
    
    # Get configuration from config file
    config = load_config("config/config.json")
    api_config = config.get("api", {})
    
    host = api_config.get("host", "localhost")
    port = api_config.get("port", 8000)
    debug = api_config.get("debug", False)
    
    print(f"🚀 Starting Project-K Web Interface...")
    print(f"📍 Access the application at: http://{host}:{port}")
    print(f"🛠️  Debug mode: {'ON' if debug else 'OFF'}")
    print(f"❓ Project-K is ready to help!")
    
    app.run(host=host, port=port, debug=debug)


if __name__ == "__main__":
    main()
