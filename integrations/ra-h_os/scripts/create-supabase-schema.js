#!/usr/bin/env node

// Script to create Supabase database schema using the REST API
// This works around the issue with direct SQL execution via psql

const https = require('https');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables.');
  process.exit(1);
}

// SQL statements to execute
const sqlStatements = [
  // Create subscriptions table
  `CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    stripe_subscription_id TEXT UNIQUE,
    stripe_customer_id TEXT,
    tier TEXT NOT NULL CHECK (tier IN ('free', 'lite', 'pro', 'max')),
    status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'past_due', 'trialing', 'incomplete')),
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
  );`,
  
  // Create usage_events table
  `CREATE TABLE IF NOT EXISTS public.usage_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    model TEXT NOT NULL,
    tokens_prompt INTEGER NOT NULL DEFAULT 0,
    tokens_completion INTEGER NOT NULL DEFAULT 0,
    cost_usd DECIMAL(10,6) NOT NULL DEFAULT 0,
    endpoint TEXT NOT NULL,
    provider TEXT NOT NULL CHECK (provider IN ('openai', 'anthropic', 'tavily')),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
  );`,
  
  // Create indexes
  `CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);`,
  `CREATE INDEX IF NOT EXISTS idx_usage_events_user_id ON public.usage_events(user_id);`
];

function executeSQL(sql) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({ query: sql });
    
    const options = {
      hostname: new URL(SUPABASE_URL).hostname,
      port: 443,
      path: '/rest/v1/rpc/query',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(data);
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', (e) => {
      reject(e);
    });

    req.write(postData);
    req.end();
  });
}

async function createSchema() {
  console.log('Creating Supabase schema...');
  
  for (let i = 0; i < sqlStatements.length; i++) {
    const sql = sqlStatements[i];
    try {
      console.log(`Executing statement ${i + 1}/${sqlStatements.length}...`);
      const result = await executeSQL(sql);
      console.log('✓ Success');
    } catch (error) {
      console.error(`✗ Failed: ${error.message}`);
      // Don't exit on error, continue with next statement
    }
  }
  
  console.log('Schema creation complete!');
}

createSchema().catch(console.error);
