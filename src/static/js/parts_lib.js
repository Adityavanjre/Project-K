/**
 * KALI PROTOTYPING & FABRICATION LIBRARY
 * Provides Three.js abstractions for hardware components.
 */

class PartsLibrary {
    constructor(scene, THREE) {
        this.scene = scene;
        this.THREE = THREE;
    }

    /**
     * Adds a standard breadboard to the scene.
     */
    addBreadboard(x = 0, y = 0, z = 0) {
        const group = new this.THREE.Group();
        
        // Main Body
        const geometry = new this.THREE.BoxGeometry(4.5, 0.2, 1.6);
        const material = new this.THREE.MeshPhongMaterial({ color: 0xeeeeee });
        const body = new this.THREE.Mesh(geometry, material);
        group.add(body);

        // Holes (Decorative grid)
        const holeGeo = new this.THREE.PlaneGeometry(0.04, 0.04);
        const holeMat = new this.THREE.MeshBasicMaterial({ color: 0x333333 });
        
        for (let r = -0.6; r <= 0.6; r += 0.2) {
            for (let c = -2.1; c <= 2.1; c += 0.1) {
                const hole = new this.THREE.Mesh(holeGeo, holeMat);
                hole.rotation.x = -Math.PI / 2;
                hole.position.set(c, 0.11, r);
                group.add(hole);
            }
        }

        group.position.set(x, y, z);
        this.scene.add(group);
        return group;
    }

    /**
     * Adds a generic microcontroller (Arduino-like).
     */
    addMicrocontroller(x = 0, y = 0, z = 0) {
        const group = new this.THREE.Group();

        // PCB
        const pcbGeo = new this.THREE.BoxGeometry(1.4, 0.1, 1);
        const pcbMat = new this.THREE.MeshPhongMaterial({ color: 0x004411 }); // Forest Green
        const pcb = new this.THREE.Mesh(pcbGeo, pcbMat);
        group.add(pcb);

        // Main Chip
        const chipGeo = new this.THREE.BoxGeometry(0.4, 0.1, 0.4);
        const chipMat = new this.THREE.MeshPhongMaterial({ color: 0x222222 });
        const chip = new this.THREE.Mesh(chipGeo, chipMat);
        chip.position.set(0, 0.08, 0);
        group.add(chip);

        // USB Port
        const usbGeo = new this.THREE.BoxGeometry(0.3, 0.2, 0.2);
        const usbMat = new this.THREE.MeshPhongMaterial({ color: 0x999999 });
        const usb = new this.THREE.Mesh(usbGeo, usbMat);
        usb.position.set(-0.6, 0.1, 0);
        group.add(usb);

        group.position.set(x, y, z);
        this.scene.add(group);
        return group;
    }

    /**
     * Adds a standard Servo motor.
     */
    addServo(x = 0, y = 0, z = 0) {
        const group = new this.THREE.Group();

        // Body
        const bodyGeo = new this.THREE.BoxGeometry(0.5, 0.8, 0.4);
        const bodyMat = new this.THREE.MeshPhongMaterial({ color: 0x111111 });
        const body = new this.THREE.Mesh(bodyGeo, bodyMat);
        group.add(body);

        // Gear Head
        const gearGeo = new this.THREE.CylinderGeometry(0.15, 0.15, 0.1, 16);
        const gearMat = new this.THREE.MeshPhongMaterial({ color: 0xffffff });
        const gear = new this.THREE.Mesh(gearGeo, gearMat);
        gear.position.set(0, 0.45, 0);
        group.add(gear);

        // Horn
        const hornGeo = new this.THREE.BoxGeometry(0.8, 0.05, 0.1);
        const hornMat = new this.THREE.MeshPhongMaterial({ color: 0xffffff });
        const horn = new this.THREE.Mesh(hornGeo, hornMat);
        horn.position.set(0, 0.52, 0);
        group.add(horn);

        group.position.set(x, y, z);
        this.scene.add(group);
        return group;
    }

    /**
     * Adds an LED.
     */
    addLED(color = 0xff0000, x = 0, y = 0, z = 0) {
        const group = new this.THREE.Group();
        
        // Lens
        const lensGeo = new this.THREE.CylinderGeometry(0.1, 0.1, 0.2, 16);
        const lensMat = new this.THREE.MeshPhongMaterial({ color: color, transparent: true, opacity: 0.8 });
        const lens = new this.THREE.Mesh(lensGeo, lensMat);
        lens.position.y = 0.2;
        group.add(lens);

        const capGeo = new this.THREE.SphereGeometry(0.1, 16, 8, 0, Math.PI * 2, 0, Math.PI / 2);
        const cap = new this.THREE.Mesh(capGeo, lensMat);
        cap.position.y = 0.3;
        group.add(cap);

        // Legs
        const legGeo = new this.THREE.CylinderGeometry(0.01, 0.01, 0.4);
        const legMat = new this.THREE.MeshPhongMaterial({ color: 0x999999 });
        
        const leg1 = new this.THREE.Mesh(legGeo, legMat);
        leg1.position.set(-0.04, 0, 0);
        group.add(leg1);

        const leg2 = new this.THREE.Mesh(legGeo, legMat);
        leg2.position.set(0.04, -0.05, 0); // Slightly shorter
        group.add(leg2);

        group.position.set(x, y, z);
        this.scene.add(group);
        return group;
    }

    /**
     * Adds a Resistor.
     */
    addResistor(x = 0, y = 0, z = 0) {
        const group = new this.THREE.Group();

        // Body
        const bodyGeo = new this.THREE.CylinderGeometry(0.06, 0.06, 0.3, 16);
        const bodyMat = new this.THREE.MeshPhongMaterial({ color: 0x88bbcc });
        const body = new this.THREE.Mesh(bodyGeo, bodyMat);
        body.rotation.z = Math.PI / 2;
        group.add(body);

        // Legs
        const legGeo = new this.THREE.CylinderGeometry(0.01, 0.01, 0.8);
        const legMat = new this.THREE.MeshPhongMaterial({ color: 0x999999 });
        const legs = new this.THREE.Mesh(legGeo, legMat);
        legs.rotation.z = Math.PI / 2;
        group.add(legs);

        group.position.set(x, y, z);
        this.scene.add(group);
        return group;
    }

    /**
     * Smoothly animate a component to a new position.
     */
    animateTo(mesh, targetPos, duration = 1000) {
        const startPos = mesh.position.clone();
        const startTime = Date.now();

        const update = () => {
            const now = Date.now();
            const progress = Math.min(1, (now - startTime) / duration);
            
            // Easing
            const t = progress * (2 - progress);

            mesh.position.lerpVectors(startPos, targetPos, t);

            if (progress < 1) {
                requestAnimationFrame(update);
            }
        };
        update();
    }
}

// Global Export
window.PartsLibrary = PartsLibrary;
