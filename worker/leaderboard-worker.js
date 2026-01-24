// Cloudflare Worker for Gold Blood Leaderboard
// Deploy this to Cloudflare Workers (free tier)

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Content-Type': 'application/json'
};

export default {
  async fetch(request, env) {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    
    // GET - Fetch leaderboard
    if (request.method === 'GET') {
      const data = await env.LEADERBOARD.get('scores', 'json') || [];
      return new Response(JSON.stringify(data), { headers: CORS_HEADERS });
    }
    
    // POST - Add new score
    if (request.method === 'POST') {
      try {
        const entry = await request.json();
        
        // Validate entry
        if (!entry.name || typeof entry.kills !== 'number') {
          return new Response(JSON.stringify({ error: 'Invalid data' }), { 
            status: 400, headers: CORS_HEADERS 
          });
        }
        
        // Get current scores
        let scores = await env.LEADERBOARD.get('scores', 'json') || [];
        
        // Add new entry with timestamp
        entry.date = Date.now();
        scores.push(entry);
        
        // Sort by kills and keep top 100
        scores.sort((a, b) => b.kills - a.kills);
        if (scores.length > 100) scores = scores.slice(0, 100);
        
        // Save
        await env.LEADERBOARD.put('scores', JSON.stringify(scores));
        
        return new Response(JSON.stringify({ success: true, rank: scores.findIndex(s => s.date === entry.date) + 1 }), { 
          headers: CORS_HEADERS 
        });
      } catch (e) {
        return new Response(JSON.stringify({ error: e.message }), { 
          status: 500, headers: CORS_HEADERS 
        });
      }
    }
    
    return new Response('Not Found', { status: 404 });
  }
};
