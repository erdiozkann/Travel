/**
 * Admin User Creation Script
 * Uses the Supabase admin API to bypass email confirmation and rate limits.
 */

require('dotenv').config({ path: '../app/.env' });
require('dotenv').config({ path: '.env' });

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    console.error('Missing env vars.');
    process.exit(1);
}

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
        autoRefreshToken: false,
        persistSession: false
    }
});

async function main() {
    console.log('Creating demo user...');

    const { data, error } = await supabaseAdmin.auth.admin.createUser({
        email: 'demo@travel.com',
        password: 'password123',
        email_confirm: true,
        user_metadata: { display_name: 'Demo User' }
    });

    if (error) {
        if (error.message.includes('already exists')) {
            console.log('✅ User already exists. You can log in with demo@travel.com / password123');
            return;
        }
        console.error('❌ Error:', error.message);
        process.exit(1);
    }

    console.log('✅ Success! Test user created.');
    console.log('Email: demo@travel.com');
    console.log('Password: password123');
}

main();
