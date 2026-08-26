// class SupabaseConfig {
//   // Masukkan URL dan Anon Key Supabase Anda di sini untuk menghubungkan aplikasi ke backend
//   static const String url = 'https://scjjsselrcynomyhdvyn.supabase.co';
//   static const String anonKey = 'sb_publishable_quE-cS4udgmoxFczxJOW9g_FaybcQjW';
// }

class SupabaseConfig {
  // Ganti dengan IP VM Proxmox dan ANON_KEY dari file .env Docker Proxmox
  static const String url = 'http://10.135.73.27:8000'; // IP VM Proxmox Anda
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE';
}