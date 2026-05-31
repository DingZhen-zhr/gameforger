import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const DEEPSEEK_URL = 'https://api.deepseek.com/v1/chat/completions';
const OPENAI_URL = 'https://api.openai.com/v1/chat/completions';

// ---- CORS helpers ----
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    const body = await req.json();
    const { messages, temperature = 0.7, max_tokens = 4096, model = 'deepseek-chat' } = body;

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return new Response(
        JSON.stringify({ error: 'messages array is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ---- Optional auth validation ----
    const authHeader = req.headers.get('Authorization');
    if (authHeader) {
      try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
        const supabase = createClient(supabaseUrl, supabaseServiceKey);
        const { data: { user }, error: authError } = await supabase.auth.getUser(
          authHeader.replace('Bearer ', ''),
        );
        if (authError || !user) {
          return new Response(
            JSON.stringify({ error: 'Unauthorized' }),
            { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
          );
        }
      } catch (_) {
        // Auth validation failed — allow through for development
      }
    }

    // ---- Route to provider based on model name ----
    const isGpt = model.startsWith('gpt-');
    const providerUrl = isGpt ? OPENAI_URL : DEEPSEEK_URL;
    const apiKeyEnv = isGpt ? 'OPENAI_API_KEY' : 'DEEPSEEK_API_KEY';
    const apiKey = Deno.env.get(apiKeyEnv);

    if (!apiKey) {
      return new Response(
        JSON.stringify({
          error: `Server misconfigured: missing ${apiKeyEnv} environment variable`,
          hint: isGpt
            ? `Set OPENAI_API_KEY in your Supabase project dashboard: https://supabase.com/dashboard/project/_/settings/functions`
            : `Set DEEPSEEK_API_KEY in your Supabase project dashboard`,
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const providerResp = await fetch(providerUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages,
        temperature,
        max_tokens,
      }),
    });

    const data = await providerResp.json();

    return new Response(JSON.stringify(data), {
      status: providerResp.status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: 'Internal server error', detail: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
