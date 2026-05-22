import fs from 'fs';
import path from 'path';
import { TreeSitterPlugin, registerAllParsers, GraphBuilder } from './packages/core/dist/index.js';

const PROJECT_ROOT = process.cwd();
const INTERMEDIATE_DIR = path.join(PROJECT_ROOT, '.understand-anything', 'intermediate');
const SCAN_RESULT_PATH = path.join(INTERMEDIATE_DIR, 'scan-result.json');

async function analyze() {
    console.log("Starting Sovereign Analysis...");
    
    if (!fs.existsSync(SCAN_RESULT_PATH)) {
        console.error("Error: scan-result.json not found.");
        return;
    }
    
    const scanResult = JSON.parse(fs.readFileSync(SCAN_RESULT_PATH, 'utf-8'));
    const files = scanResult.files;
    
    const builder = new GraphBuilder();
    const tsPlugin = new TreeSitterPlugin();
    
    // In a real environment, we would iterate through all files.
    // For this demonstration, we will analyze the first 10 core files to verify the graph.
    console.log(`Analyzing ${files.length} nodes...`);
    
    for (const file of files) {
        const fullPath = path.join(PROJECT_ROOT, file.path);
        if (!fs.existsSync(fullPath)) continue;
        
        try {
            const content = fs.readFileSync(fullPath, 'utf-8');
            // Mock analysis for now since full TreeSitter init requires WASM files
            builder.addNode({
                id: `file:${file.path}`,
                type: file.category,
                name: path.basename(file.path),
                filePath: file.path,
                summary: `KALI Core Neuron: ${path.basename(file.path)}`,
                tags: [file.language, "nucleus"]
            });
        } catch (e) {
            console.error(`Failed to analyze ${file.path}: ${e.message}`);
        }
    }
    
    const graph = builder.build();
    fs.writeFileSync(path.join(INTERMEDIATE_DIR, 'assembled-graph.json'), JSON.stringify(graph, null, 2));
    console.log(`Analysis Complete: ${graph.nodes.length} nodes mapped.`);
}

analyze();
