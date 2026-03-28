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

    def __init__(self, config: Optional[Dict[str, Any]] = None, vector_memory=None):
        """Initialize the AI service."""
        self.config = config or {}
        self.logger = logging.getLogger(__name__)
        self.memory = vector_memory  # For semantic caching

        # Phase 51: Sovereign Hardware-Locked Node
        self.sovereign_url = os.getenv("KALI_SOVEREIGN_URL")
        self.api_url = (
            self.sovereign_url
            if self.sovereign_url
            else "https://api.groq.com/openai/v1/chat/completions"
        )

        self.nv_url = "https://integrate.api.nvidia.com/v1/chat/completions"

        # Phase 4.85: Multi-Key Rotation Support
        raw_key = os.getenv("GROQ_API_KEY", "")
        self.api_keys = [k.strip() for k in raw_key.split(",") if k.strip()]
        self.current_key_index = 0
        self.api_key = self.api_keys[0] if self.api_keys else None

        # NVIDIA Specific Keys
        self.nv_keys = {
            "google/gemma-7b": os.getenv("NV_GEMMA_KEY"),
            "nvidia/usdcode-llama-3.1-70b-instruct": os.getenv("NV_USDCODE_KEY"),
            "microsoft/phi-3-medium-128k-instruct": os.getenv("NV_PHI3_KEY"),
            "deepseek-ai/deepseek-v3.2": os.getenv("NV_DEEPSEEK_KEY"),
            "moonshotai/kimi-k2-instruct": os.getenv("NV_KIMI_KEY"),
            "mistralai/mistral-large-3-675b-instruct-2512": os.getenv("NV_MISTRAL_KEY"),
        }

        self.text_model = "llama-3.3-70b-versatile"
        self.fallback_model = "llama-3.1-8b-instant"
        self.vision_model = "llama-3.2-11b-vision-preview"
        self.is_connected = self._check_connection()

        if self.is_connected or any(self.nv_keys.values()):
            keys_found = len(self.api_keys)
            self.logger.info(
                f"KALI AI Service Online. Active Keys: {keys_found}. Primary: {self.text_model}"
            )
        else:
            self.logger.warning("KALI AI Service Offline (Simulation Mode Active).")

    def _rotate_key(self):
        """Rotate to the next available API key if multiple are provided."""
        if len(self.api_keys) > 1:
            self.current_key_index = (self.current_key_index + 1) % len(self.api_keys)
            self.api_key = self.api_keys[self.current_key_index]
            self.logger.info(
                f"[*] KALI: Rotating to next API key (Pool Index: {self.current_key_index})."
            )
            return True
        return False

    def _check_connection(self) -> bool:
        """Check if sovereign node or any API keys are present."""
        return (
            bool(self.sovereign_url) or bool(self.api_key) or any(self.nv_keys.values())
        )

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

    def _generate_groq(
        self,
        messages: list,
        is_json: bool = False,
        temperature: float = 0.7,
        use_fallback: bool = False,
        **kwargs,
    ):
        """Direct HTTP call to Groq."""
        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "ngrok-skip-browser-warning": "true", # Phase 51: Bypass Tunnel Warnings
            }

            target_model = self.fallback_model if use_fallback else self.text_model

            payload = {
                "model": target_model,
                "messages": messages,
                "temperature": temperature if not is_json else 0,  # Strict for JSON
                "top_p": 0.1,
                "seed": 42,
                "max_tokens": 4096,
            }

            if is_json:
                payload["response_format"] = {"type": "json_object"}

            resp = requests.post(
                self.api_url, headers=headers, json=payload, timeout=30
            )

            if resp.status_code == 200:
                content = resp.json()["choices"][0]["message"]["content"]

                # Cache the result if semantic memory is available
                if not is_json and self.memory and len(messages) > 1:
                    self.memory.cache_answer(messages[-1]["content"], content)

                if is_json:
                    import json

                    try:
                        return json.loads(content)
                    except:
                        return content  # Fallback if model fails to output valid JSON
                return content
            elif resp.status_code == 429:
                self.logger.warning(f"KALI: Rate Limit (429) hit for {target_model}.")

                # Phase 4.85: Immediate Rotation if available
                if self._rotate_key():
                    return self._generate_groq(
                        messages, is_json, temperature, use_fallback, **kwargs
                    )

                # Phase 4.24: Exponential Backoff if no rotation possible
                import time
                import random

                retry_count = kwargs.get("retry_count", 0)
                if retry_count < 3:
                    wait_time = (2**retry_count) + random.random()
                    self.logger.info(
                        f"[*] Cooling neural circuits: Backoff {wait_time:.2f}s (Retry {retry_count + 1}/3)..."
                    )
                    time.sleep(wait_time)
                    kwargs["retry_count"] = retry_count + 1
                    return self._generate_groq(
                        messages, is_json, temperature, use_fallback, **kwargs
                    )

                if not use_fallback:
                    self.logger.warning(
                        "Scaling to fallback node after backoff exhaustion."
                    )
                    return self._generate_groq(
                        messages, is_json, temperature, use_fallback=True
                    )
                return "RATE_LIMIT_CRITICAL: All neural nodes congested. Sir, please standby for cooling."
            else:
                self.logger.error(
                    f"Groq Error {resp.status_code} ({target_model}): {resp.text}"
                )
                # Simple recursive fallback if main model fails
                if not use_fallback:
                    self.logger.warning(
                        f"KALI switching to fallback node: {self.fallback_model}"
                    )
                    return self._generate_groq(
                        messages, is_json, temperature, use_fallback=True
                    )
                return {} if is_json else ""

        except requests.exceptions.RequestException as e:
            self.logger.error(f"Groq Connection Error: {e}")
            if not use_fallback:
                return self._generate_groq(
                    messages, is_json, temperature, use_fallback=True
                )
            return f"CONNECTION_ERROR: {e}"
        except Exception as e:
            self.logger.error(f"Groq Unexpected Error: {e}")
            return f"UNEXPECTED_ERROR: {e}"

    def ask_question(
        self,
        question: str,
        context: str = "",
        temperature: float = 0.7,
        use_fallback: bool = False,
        query_model: str = "llama-3.3-70b-versatile",
        bypass_cache: bool = False,
    ) -> str:
        """Standard text query."""
        if not self.is_connected and not any(self.nv_keys.values()):
            # --- OFFLINE SIMULATION MODE ---
            self.logger.info("OFFLINE MODE: Generating simulated response.")

            # 1. Interconnectivity Check (Did we receive context?)
            if "Context:" in context or "Context:" in question:
                # Naive check to prove interconnectivity
                if "Sensor" in context or "Sensor" in question:
                    return "OFFLINE SIMULATION: I see you are asking about the Sensor from your project plan. In a live environment, I would explain its specific voltage properties."
                return "OFFLINE SIMULATION: I have received the project context. I can see the BOM and Roadmap you are working on."

            # 2. General Fallback
            return "AI OFFLINE. (Groq API Key missing). Using Simulation Mode to verify system flow."

        # Phase 4.17: Semantic Cache Check — skipped during training to force fresh API responses
        if self.memory and not bypass_cache:
            cached = self.memory.get_cached_answer(question)
            if cached:
                self.logger.info("KALI: Cache Hit! (Neural Bypass Active)")
                return cached

        messages = []
        sys_prompt = (
            "You are KALI, an advanced Sovereign AI Engineering Mentor. "
            "Your personality is precise, authoritative, and helpful. "
            "CORE PROTOCOLS:\n"
            "   1. REASONING: Apply recursive chain-of-thought before finalizing answers. If a project context is provided, align your logic with the existing architecture.\n"
            "   2. OUTPUT: Provide high-fidelity technical explanations. Use Markdown for clarity.\n"
            "   3. SOVEREIGNTY: Do not use emojis. Maintain a professional, engineering-first tone.\n"
            "   4. MULTI-MODAL: Mention project manifests, DNA updates, and visual schematics whenever relevant.\n"
            f"CONTEXT: {context}"
        )
        messages.append({"role": "system", "content": sys_prompt})
        messages.append({"role": "user", "content": question})

        # Routing based on model name
        if "/" in query_model or query_model in self.nv_keys:
            return self._generate_nvidia(
                messages, model=query_model, temperature=temperature
            )

        return self._generate_groq(
            messages, temperature=temperature, use_fallback=use_fallback
        )

    def _generate_nvidia(self, messages: list, model: str, temperature: float = 0.7):
        """Call NVIDIA NIM API."""
        try:
            key = self.nv_keys.get(model)
            if not key:
                self.logger.info(f"NIM Route: {model} [Sovereign]")
                return self.ask_question(messages[-1]["content"], use_fallback=True)

            headers = {
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            }

            payload: Dict[str, Any] = {
                "model": model,
                "messages": messages,
                "temperature": temperature,
                "top_p": 0.7,
                "max_tokens": 4096,
                "stream": False,
            }

            # Specialized parameters for NIM models
            if "deepseek" in model:
                payload["extra_body"] = {"chat_template_kwargs": {"thinking": True}}
            elif "usdcode" in model:
                payload["extra_body"] = {"expert_type": "auto"}

            resp = requests.post(self.nv_url, headers=headers, json=payload, timeout=60)

            if resp.status_code == 200:
                data = resp.json()
                choice = data["choices"][0]["message"]

                content = choice.get("content", "")
                reasoning = choice.get("reasoning_content")

                if reasoning:
                    return f"> [THINKING]: {reasoning}\n\n{content}"
                return content
            else:
                self.logger.error(
                    f"NVIDIA NIM Error {resp.status_code} ({model}): {resp.text}"
                )
                return self.ask_question(messages[-1]["content"], use_fallback=True)

        except requests.exceptions.RequestException as e:
            self.logger.error(f"NVIDIA Connection Error: {e}")
            return self.ask_question(messages[-1]["content"], use_fallback=True)
        except Exception as e:
            self.logger.error(f"NVIDIA Unexpected Error: {e}")
            return f"NVIDIA Link Error: {e}"

    def ask_json(
        self, system_prompt: str, user_prompt: str, temperature: float = 0.2
    ) -> Dict[str, Any]:
        """Generate JSON structure (Strict Mode)."""
        if not self.is_connected:
            self.logger.info("OFFLINE MODE: Generating simulated JSON.")

            # Combine prompts to handle argument swapping issues robustly
            combined_prompt = f"{system_prompt} {user_prompt}"

            # --- SCENARIO 1: VISUAL EXPLAINER (3D) ---
            if "Visual Engine" in combined_prompt or "3D SCHEMATIC" in combined_prompt:
                return {
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
                            """,
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
                            """,
                        },
                    ]
                }

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
                            {
                                "part": "Arduino Nano",
                                "specs": "Small Form Factor",
                                "estimated_cost": "$10",
                                "reason": "Central Processing",
                            },
                            {
                                "part": "BMP280",
                                "specs": "Barometric Pressure Sensor",
                                "estimated_cost": "$5",
                                "reason": "Altitude Tracking",
                            },
                            {
                                "part": "MPU6050",
                                "specs": "Accelerometer/Gyro",
                                "estimated_cost": "$4",
                                "reason": "Orientation Data",
                            },
                        ],
                        "mermaid_diagram": "graph TD; A[MPU6050] -->|I2C| B(Arduino Nano); C[BMP280] -->|I2C| B; B -->|SPI| D[SD Card Module];",
                        "roadmap": [
                            {
                                "phase": "Phase 1: Sensor Test",
                                "description": "Wire sensors to breadboard and scan I2C addresses.",
                                "key_concept": "I2C Protocol",
                            },
                            {
                                "phase": "Phase 2: Data Logging",
                                "description": "Implement SD card write logic for high-speed logging.",
                                "key_concept": "Write Latency",
                            },
                        ],
                    }
                elif "home" in p_lower or "automation" in p_lower or "plant" in p_lower:
                    plan_data = {
                        "project_name": "Smart Home Hub",
                        "summary": "Central controller for home automation devices.",
                        "bom": [
                            {
                                "part": "ESP32 Dev Module",
                                "specs": "Wi-Fi + Bluetooth",
                                "estimated_cost": "$8",
                                "reason": "Wireless Connectivity",
                            },
                            {
                                "part": "Relay Module",
                                "specs": "4-Channel 5V",
                                "estimated_cost": "$5",
                                "reason": "High Voltage Switching",
                            },
                            {
                                "part": "DHT11",
                                "specs": "Temp/Humidity Sensor",
                                "estimated_cost": "$2",
                                "reason": "Environmental Monitoring",
                            },
                        ],
                        "mermaid_diagram": "graph TD; A[DHT11] --> B(ESP32); B -->|WiFi| C[Cloud Dashboard]; B -->|GPIO| D[Relays];",
                        "roadmap": [
                            {
                                "phase": "Phase 1: Network Setup",
                                "description": "Configure ESP32 to connect to local WiFi.",
                                "key_concept": "IoT Connectivity",
                            },
                            {
                                "phase": "Phase 2: Web Server",
                                "description": "Host a simple control page on the ESP32.",
                                "key_concept": "HTTP Request Handling",
                            },
                        ],
                    }
                else:
                    # Default (Car)
                    plan_data = {
                        "project_name": "Gesture Controlled Car",
                        "summary": "A robot car controlled by hand gestures via accelerometer.",
                        "bom": [
                            {
                                "part": "Arduino Uno",
                                "specs": "R3",
                                "estimated_cost": "$25",
                                "reason": "Logic Control",
                            },
                            {
                                "part": "L298N Motor Driver",
                                "specs": "Dual H-Bridge",
                                "estimated_cost": "$5",
                                "reason": "Motor Control",
                            },
                            {
                                "part": "Ultrasonic Sensor",
                                "specs": "HC-SR04",
                                "estimated_cost": "$3",
                                "reason": "Obstacle Avoidance",
                            },
                        ],
                        "mermaid_diagram": "graph TD; A[Arduino] --> B[Motor Driver]; B --> C[Motors];",
                        "roadmap": [
                            {
                                "phase": "Phase 1: Chassis Assembly",
                                "description": "Mount motors to chassis.",
                                "key_concept": "Mechanical Stability",
                            },
                            {
                                "phase": "Phase 2: Wiring",
                                "description": "Connect Motor Driver to Arduino (Pins 9-11).",
                                "key_concept": "PWM Control",
                            },
                        ],
                    }

                # Common Fields
                plan_data["difficulty"] = "Intermediate"
                plan_data["code_snippet"] = (
                    "void setup() { Serial.begin(9600); } // Simulated Code"
                )
                plan_data["code_language"] = "cpp"
                plan_data["tech_stack"] = ["C++", "Electronics", "System Design"]
                plan_data["prerequisites"] = ["Basic Circuits", "Soldering"]
                plan_data["calibration_guide"] = (
                    "Verify sensor readings on Serial Monitor."
                )

                # Title and response for verification scripts
                title = plan_data.get("project_name", "KALI Fabrication Project")
                plan_data["response"] = f"# Title: {title}\n\n" + plan_data.get(
                    "summary", "Analysis complete."
                )

                return plan_data

            return {
                "error": f"Unknown Offline Scenario. Prompt sample: {combined_prompt.splitlines()[0]}..."
            }

        messages = [
            {
                "role": "system",
                "content": system_prompt + "\nIMPORTANT: Output valid JSON only.",
            },
            {"role": "user", "content": user_prompt},
        ]

        return self._generate_groq(messages, is_json=True, temperature=temperature)

    def analyze_image(self, image_file, prompt: str = "Analyze this image.") -> str:
        if not self.is_connected:
            return "**OFFLINE SIMULATION**: I have analyzed the image. It appears to be a Circuit Diagram. (Vision API Unavailable)"

        try:
            # 1. Determine Model & Endpoint
            use_nim = any(self.nv_keys.values())
            target_model = self.vision_model
            endpoint = self.api_url  # Default Groq
            auth_key = self.api_key  # Default Groq

            if use_nim:
                # Prioritize USDCode or standard NIM vision if available
                target_model = "nvidia/llama-3.2-11b-vision-instruct"
                endpoint = self.nv_url
                # Try to find a valid NIM key
                for k, v in self.nv_keys.items():
                    if v:
                        auth_key = v
                        break

            if not auth_key:
                return "Vision Error: No active API keys found."

            # 2. Encode Image
            image_file.seek(0)
            base64_image = base64.b64encode(image_file.read()).decode("utf-8")

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
                            },
                        },
                    ],
                }
            ]

            # 3. Call Vision Model
            self.logger.info(f"Sending Image to {target_model}...")

            headers = {
                "Authorization": f"Bearer {auth_key}",
                "Content-Type": "application/json",
            }
            payload = {"model": target_model, "messages": messages, "max_tokens": 1024}

            response = requests.post(
                endpoint, headers=headers, json=payload, timeout=60
            )
            if response.status_code == 200:
                res_data = response.json()
                if "choices" in res_data:
                    return res_data["choices"][0]["message"]["content"]
                return "Vision analysis complete (JSON mismatch)."
            else:
                self.logger.error(
                    f"Vision API Error {response.status_code}: {response.text}"
                )
                return f"Vision Verification Failed: {response.status_code}"

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
        context = (
            "You are K.A.L.I., an advanced AI mentor. "
            "Answer the user's question clearly and concisely. "
            "Structure your answer with momentary 'steps' or logic if complex. "
            "Do not be robotic. Be helpful and precise."
        )
        return self.ai_service.ask_question(question, context=context)
