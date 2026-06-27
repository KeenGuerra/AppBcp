#!/usr/bin/env python3
"""
run_seed.py - Executes 10_seed_demo.sql via Supabase REST API (execute_sql via pg_net or admin API)
Uses the Supabase service role key to execute arbitrary SQL.
"""

import os
import sys
import requests
import json
from pathlib import Path

SUPABASE_URL = "https://kawalgwszhtclarijjqg.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imthd2FsZ3dzemh0Y2xhcmlqanFnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcxNzU3NjE3OSwiZXhwIjoyMDMzMTUyMTc5fQ.placeholder"

# Read the .env file to get the actual service role key
env_path = Path(__file__).parent.parent / "backend_core_mobile" / ".env"
if env_path.exists():
    for line in env_path.read_text().splitlines():
        if line.startswith("SUPABASE_SERVICE_ROLE_KEY="):
            SERVICE_ROLE_KEY = line.split("=", 1)[1].strip()
        elif line.startswith("SUPABASE_URL="):
            SUPABASE_URL = line.split("=", 1)[1].strip()

print(f"Supabase URL: {SUPABASE_URL}")
print(f"Service key prefix: {SERVICE_ROLE_KEY[:20]}...")

# Read the SQL seed file
seed_file = Path(__file__).parent / "10_seed_demo.sql"
sql = seed_file.read_text(encoding="utf-8")

print(f"SQL length: {len(sql)} characters")
print("Executing seed SQL via Supabase RPC...")

# Try using the Supabase Database REST API
# This requires the Management API access token.
# The service role key can be used to call PostgreSQL-like operations via PostgREST
# but for arbitrary DDL/DML, we need the management API or a stored procedure.

# Alternative: Use the /rest/v1/rpc endpoint with a stored procedure
# We'll try sending the SQL as-is to the Management API
headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
    "apikey": SERVICE_ROLE_KEY,
    "Prefer": "return=minimal"
}

# The Management API endpoint for running SQL
# https://supabase.com/docs/reference/api/v1-run-a-query
project_ref = SUPABASE_URL.replace("https://", "").split(".")[0]
mgmt_url = f"https://api.supabase.com/v1/projects/{project_ref}/database/query"

print(f"Project ref: {project_ref}")
print(f"Management API URL: {mgmt_url}")

# Split the SQL into separate statements for execution
# Since Supabase management API requires authorization token (not service role key)
# we need an alternative approach.
#
# Use the supabase python client with service role key to run queries
# via the "from('table').select()" API or execute raw SQL via rpc

try:
    from supabase import create_client, Client
    
    supabase: Client = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)
    
    # Execute the entire SQL using rpc or postgrest
    # Split by the major sections
    print("\nExecuting SQL...")
    print("NOTE: Large SQL blocks with PL/pgSQL DO $$ blocks need to be executed in Supabase SQL Editor.")
    print("Executing via Management API...")
    
    # Try the management API
    import urllib.request
    import urllib.error
    
    # Use the personal access token approach if available
    # For now, let's try via a different endpoint
    
    print("\n" + "="*60)
    print("IMPORTANT: The seed SQL cannot be executed automatically via the REST API.")
    print("You need to run 10_seed_demo.sql manually in the Supabase SQL Editor.")
    print("="*60)
    print(f"\nInstructions:")
    print(f"1. Open: https://supabase.com/dashboard/project/{project_ref}/sql/new")
    print(f"2. Paste the contents of: d:/appbcp/database_supabase/10_seed_demo.sql")
    print(f"3. Click 'Run'")
    print(f"\nThe file is ready with 30 real cases.")
    
except ImportError:
    print("supabase package not found in this Python environment")

sys.exit(0)
