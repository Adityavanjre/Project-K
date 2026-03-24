
import os
import json
import logging
import requests
import base64
from typing import Dict, Any, Optional

class AIService:
    """
    Service for interacting with Groq Cloud API.
    """
    
    def __init__(self, config: Dict[str, Any]):
        self.logger = logging.getLogger(__name__)
        self.api_key = os.getenv("GROQ_API_KEY")
        self.api_url = "https://api.groq.com/openai/v1/chat/completions"
        
        # Groq Models
        self.text_model = 'llama-3.3-70b-versatile' 
        self.vision_model = 'llama-3.2-11b-vision-preview'
        self.fallback_model = 'mixtral-8x7b-32768'
        
        if not self.api_key:
            self.logger.warning("GROQ_API_KEY not found. AI features will be limited.")
            self.is_connected = False
        else:
            self.is_connected = True
            self.logger.info(f"Connected to Groq Cloud. Main Model: {self.text_model}")

    def _extract_json(self, text: str) -> Dict[str, Any]:
        """
        Robustly extract JSON from a string, handling markdown blocks.
        """
        import json
        import re
        
        try:
            text = text.strip()
            
            # Remove Markdown code blocks
            if "```" in text:
                # Find the first opening brace after a code block start or just first brace
                # Simple regex to find json block
                match = re.search(r"```(?:json)?(.*?)```", text, re.DOTALL)
                if match:
                    text = match.group(1).strip()
            
            # Find start and end of JSON object
            start = text.find("{")
            end = text.rfind("}")
            
            if start != -1 and end != -1:
                text = text[start : end + 1]
            
            return json.loads(text)
        except Exception as e:
            self.logger.error(f"JSON extraction failed: {e}")
            self.logger.error(f"Raw Text: {text}")
            raise ValueError("Could not extract valid JSON from response")

    def is_available(self) -> bool:
        return self.is_connected

    def _generate_groq(self, messages: list, is_json: bool = False, temperature: float = 0.7):
        """Direct HTTP call to Groq."""
        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "model": "llama-3.3-70b-versatile",
                "messages": messages,
                "temperature": 0,
                "top_p": 0.1,
                "seed": 42,
                "max_tokens": 4096
            }
            
            if is_json:
                payload["response_format"] = {"type": "json_object"}

            resp = requests.post(self.api_url, headers=headers, json=payload, timeout=30)
            
            if resp.status_code == 200:
                content = resp.json()['choices'][0]['message']['content']
                if is_json:
                    import json
                    try:
                        return json.loads(content)
                    except:
                        return content # Fallback if model fails to output valid JSON
                return content
            else:
                self.logger.error(f"Groq Error {resp.status_code}: {resp.text}")
                return None

        except Exception as e:
            self.logger.error(f"Connection Error: {e}")
            return None

    def ask_question(self, question: str, context: str = "", temperature: float = 0.7) -> str:
        """Standard text query."""
        if not self.is_connected:
            # --- OFFLINE SIMULATION MODE ---
            self.logger.info("OFFLINE MODE: Generating simulated response.")
            
            # 1. Interconnectivity Check (Did we receive context?)
            if "Context:" in context or "Context:" in question:
                # Naive check to prove interconnectivity
                if "Sensor" in context or "Sensor" in question:
                   return "OFFLINE SIMULATION: I see you are asking about the Sensor from your project plan. In a live environment, I would explain its specific voltage properties."
                return "OFFLINE SIMULATION: I have received the project context. I can see the BOM and Roadmap you are working on."
            
            # 2. General Fallback
            return "⚠️ AI OFFLINE. (Groq API Key missing). Using Simulation Mode to verify system flow."

        messages = []
        sys_prompt = f"You are KALI, an advanced AI Assistant. Context: {context}"
        messages.append({"role": "system", "content": sys_prompt})
        messages.append({"role": "user", "content": question})

        return self._generate_groq(messages, temperature=temperature)

    def ask_json(self, system_prompt: str, user_prompt: str, temperature: float = 0.2) -> str:
        """Generate JSON structure (Strict Mode)."""
        if not self.is_connected:
             self.logger.info("OFFLINE MODE: Generating simulated JSON.")
             
             # Combine prompts to handle argument swapping issues robustly
             combined_prompt = f"{system_prompt} {user_prompt}"

             # --- SCENARIO 1: VISUAL EXPLAINER (3D) ---
             if "Visual Engine" in combined_prompt or "3D SCHEMATIC" in combined_prompt:
                 return json.dumps({
                     "steps": [
                        {
                            "text": "Phase 1: Component Placement. We start by positioning the Microcontroller.",
                            "audio_text": "First, we place the Arduino Uno as the central brain of our robot.",
                            "visual_code": """
                                // Arduino PCB (Teal)
                                const arduino = new THREE.Mesh(new THREE.BoxGeometry(2.5, 0.2, 3.5), new THREE.MeshStandardMaterial({color: 0x008080}));
                                arduino.position.y = 0;
                                scene.add(arduino);
                                
                                // USB Port (Silver)
                                const usb = new THREE.Mesh(new THREE.BoxGeometry(0.8, 0.4, 0.6), new THREE.MeshStandardMaterial({color: 0xC0C0C0}));
                                usb.position.set(-0.5, 0.3, -1.6);
                                scene.add(usb);
                                
                                // Chip (Black)
                                const chip = new THREE.Mesh(new THREE.BoxGeometry(0.6, 0.1, 2), new THREE.MeshStandardMaterial({color: 0x111111}));
                                chip.position.set(0, 0.2, 0);
                                scene.add(chip);

                                // LABEL: Arduino
                                const canvas1 = document.createElement('canvas');
                                const ctx1 = canvas1.getContext('2d');
                                ctx1.font = 'Bold 40px Arial';
                                ctx1.fillStyle = 'white';
                                ctx1.fillText('ARDUINO UNO', 0, 50);
                                const texture1 = new THREE.CanvasTexture(canvas1);
                                const spriteMat1 = new THREE.SpriteMaterial({ map: texture1 });
                                const sprite1 = new THREE.Sprite(spriteMat1);
                                sprite1.position.set(0, 2, 0);
                                sprite1.scale.set(3, 1.5, 1);
                                scene.add(sprite1);
                            """
                        },
                        {
                            "text": "Phase 2: Sensor Integration. Adding the Ultrasonic Sensor for distance measurement.",
                            "audio_text": "Next, we mount the Ultrasonic Sensor on the front chassis.",
                            "visual_code": """
                                // Sensor Body (Blue)
                                const sensor = new THREE.Mesh(new THREE.BoxGeometry(1.5, 0.5, 0.5), new THREE.MeshStandardMaterial({color: 0x0066cc}));
                                sensor.position.set(0, 1, 2);
                                scene.add(sensor);
                                
                                // Eyes (Silver Cylinders)
                                const eyeGeo = new THREE.CylinderGeometry(0.3, 0.3, 0.2, 32);
                                const eyeMat = new THREE.MeshStandardMaterial({color: 0xdddddd});
                                
                                const leftEye = new THREE.Mesh(eyeGeo, eyeMat);
                                leftEye.rotation.x = Math.PI / 2;
                                leftEye.position.set(-0.4, 1, 2.3);
                                scene.add(leftEye);
                                
                                const rightEye = new THREE.Mesh(eyeGeo, eyeMat);
                                rightEye.rotation.x = Math.PI / 2;
                                rightEye.position.set(0.4, 1, 2.3);
                                scene.add(rightEye);

                                // LABEL: Sensor
                                const canvas2 = document.createElement('canvas');
                                const ctx2 = canvas2.getContext('2d');
                                ctx2.font = 'Bold 40px Arial';
                                ctx2.fillStyle = 'yellow';
                                ctx2.fillText('ULTRASONIC SENSOR', 0, 50);
                                const texture2 = new THREE.CanvasTexture(canvas2);
                                const spriteMat2 = new THREE.SpriteMaterial({ map: texture2 });
                                const sprite2 = new THREE.Sprite(spriteMat2);
                                sprite2.position.set(0, 2.5, 2);
                                sprite2.scale.set(4, 2, 1);
                                scene.add(sprite2);
                            """
                        }
                    ]
                 })
                 
             # --- SCENARIO 2: PROJECT MENTOR (PLAN) ---
             if "Project Architect" in combined_prompt:
                 # DYNAMIC RESPONSE BASED ON INPUT KEYWORDS
                 p_lower = combined_prompt.lower()
                 
                 plan_data = {}
                 
                 if "rocket" in p_lower or "space" in p_lower:
                     plan_data = {
                        "project_name": "Model Rocket Flight Computer",
                        "summary": "Telemetry system for measuring altitude and acceleration.",
                        "bom": [
                            {"part": "Arduino Nano", "specs": "Small Form Factor", "estimated_cost": "$10", "reason": "Central Processing"},
                            {"part": "BMP280", "specs": "Barometric Pressure Sensor", "estimated_cost": "$5", "reason": "Altitude Tracking"},
                            {"part": "MPU6050", "specs": "Accelerometer/Gyro", "estimated_cost": "$4", "reason": "Orientation Data"}
                        ],
                        "mermaid_diagram": "graph TD; A[MPU6050] -->|I2C| B(Arduino Nano); C[BMP280] -->|I2C| B; B -->|SPI| D[SD Card Module];",
                        "roadmap": [
                             {"phase": "Phase 1: Sensor Test", "description": "Wire sensors to breadboard and scan I2C addresses.", "key_concept": "I2C Protocol"},
                             {"phase": "Phase 2: Data Logging", "description": "Implement SD card write logic for high-speed logging.", "key_concept": "Write Latency"}
                        ]
                     }
                 elif "home" in p_lower or "automation" in p_lower or "plant" in p_lower:
                     plan_data = {
                        "project_name": "Smart Home Hub",
                        "summary": "Central controller for home automation devices.",
                         "bom": [
                            {"part": "ESP32 Dev Module", "specs": "Wi-Fi + Bluetooth", "estimated_cost": "$8", "reason": "Wireless Connectivity"},
                            {"part": "Relay Module", "specs": "4-Channel 5V", "estimated_cost": "$5", "reason": "High Voltage Switching"},
                            {"part": "DHT11", "specs": "Temp/Humidity Sensor", "estimated_cost": "$2", "reason": "Environmental Monitoring"}
                        ],
                        "mermaid_diagram": "graph TD; A[DHT11] --> B(ESP32); B -->|WiFi| C[Cloud Dashboard]; B -->|GPIO| D[Relays];",
                        "roadmap": [
                             {"phase": "Phase 1: Network Setup", "description": "Configure ESP32 to connect to local WiFi.", "key_concept": "IoT Connectivity"},
                             {"phase": "Phase 2: Web Server", "description": "Host a simple control page on the ESP32.", "key_concept": "HTTP Request Handling"}
                        ]
                     }
                 else:
                     # Default (Car)
                     plan_data = {
                        "project_name": "Gesture Controlled Car",
                        "summary": "A robot car controlled by hand gestures via accelerometer.",
                        "bom": [
                            {"part": "Arduino Uno", "specs": "R3", "estimated_cost": "$25", "reason": "Logic Control"},
                            {"part": "L298N Motor Driver", "specs": "Dual H-Bridge", "estimated_cost": "$5", "reason": "Motor Control"},
                            {"part": "Ultrasonic Sensor", "specs": "HC-SR04", "estimated_cost": "$3", "reason": "Obstacle Avoidance"}
                        ],
                        "mermaid_diagram": "graph TD; A[Arduino] --> B[Motor Driver]; B --> C[Motors];",
                        "roadmap": [
                            {"phase": "Phase 1: Chassis Assembly", "description": "Mount motors to chassis.", "key_concept": "Mechanical Stability"},
                            {"phase": "Phase 2: Wiring", "description": "Connect Motor Driver to Arduino (Pins 9-11).", "key_concept": "PWM Control"}
                        ]
                     }
                 
                 # Common Fields
                 plan_data["difficulty"] = "Intermediate"
                 plan_data["code_snippet"] = "void setup() { Serial.begin(9600); } // Simulated Code"
                 plan_data["code_language"] = "cpp"
                 plan_data["tech_stack"] = ["C++", "Electronics", "System Design"]
                 plan_data["prerequisites"] = ["Basic Circuits", "Soldering"]
                 plan_data["calibration_guide"] = "Verify sensor readings on Serial Monitor."
                 
                 return json.dumps(plan_data)

             return json.dumps({"error": f"Unknown Offline Scenario. Prompt sample: {combined_prompt[:50]}..."})

            
        messages = [
            {"role": "system", "content": system_prompt + "\nIMPORTANT: Output valid JSON only."},
            {"role": "user", "content": user_prompt}
        ]
        
        return self._generate_groq(messages, is_json=True, temperature=temperature)

    def analyze_image(self, image_file, prompt: str = "Analyze this image.") -> str:
        if not self.is_connected:
             return "**OFFLINE SIMULATION**: I have analyzed the image. It appears to be a Circuit Diagram. (Vision API Unavailable)"
            
        try:
            # 1. Encode Image
            image_file.seek(0)
            base64_image = base64.b64encode(image_file.read()).decode('utf-8')
            
            # 2. Construct Vision Payload (OpenAI compatible)
            messages = [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ]
            
            # 3. Call Vision Model
            self.logger.info(f"Sending Image to {self.vision_model}...")
            
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
            payload = {
                "model": self.vision_model,
                "messages": messages,
                "max_tokens": 1024
            }
            
            response = requests.post(self.api_url, headers=headers, json=payload, timeout=60)
            if response.status_code == 200:
                return response.json()['choices'][0]['message']['content']
            else:
                return f"Vision Verification Failed: {response.text}"
            
        except Exception as e:
            return f"Vision Verification Failed: {e}"
            
    def _fallback_response(self, question: str) -> str:
         return "System Error. Neural Link Severed."

class ProgressiveExplainer:
    """
    Helper class for generating progressive explanations.
    Maintains compatibility with processor.py.
    """
    def __init__(self, ai_service: AIService):
        self.ai_service = ai_service
        self.logger = logging.getLogger(__name__)

    def explain_progressively(self, question: str, follow_up: bool = False) -> str:
        """
        Generate a concise, progressive explanation.
        """
        system_prompt = (
            "You are K.A.L.I., an advanced AI mentor."
            "Answer the user's question clearly and concisely."
            "Structure your answer with momentary 'steps' or logic if complex."
            "Do not be robotic. Be helpful and precise."
        )
        return self.ai_service.ask_question(question, system_prompt)
