require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const storageBucket = process.env.SUPABASE_STORAGE_BUCKET || 'prescriptions';

let supabase = null;

if (supabaseUrl && supabaseServiceRoleKey) {
  supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
} else if (process.env.NODE_ENV !== 'test') {
  console.warn(
    '[WARN] SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not configured in .env. Database operations will fail until valid Supabase credentials are provided.'
  );
}

/**
 * Allows automated tests to inject an in-memory client
 */
function setSupabaseClientForTesting(client) {
  supabase = client;
}

module.exports = {
  get supabase() {
    return supabase;
  },
  set supabase(client) {
    supabase = client;
  },
  setSupabaseClientForTesting,
  storageBucket,
};
