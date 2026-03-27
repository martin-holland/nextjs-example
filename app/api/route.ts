// Example of an api route
// import { NextResponse } from "next/server";

// export async function GET() {
//   return NextResponse.json({ message: "Hello, world!" });
// }

// API call to supabase using REST API

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

// Direct API call to supabase using fetch
const response = await fetch(`${supabaseUrl}/rest/v1/products`, {
  headers: {
    Authorization: `Bearer ${supabaseAnonKey}`,
    apikey: supabaseAnonKey,
    "Content-Type": "application/json",
  },
});

const data = await response.json();

export async function GET() {
  return Response.json(data);
}
