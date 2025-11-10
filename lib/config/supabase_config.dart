import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Configuration
/// Single source of truth for Supabase credentials
///
/// IMPORTANT: Keep these credentials secure
/// For production, consider using environment variables
const supabaseUrl = 'https://hitqjenhkhumvdbsolsv.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpdHFqZW5oa2h1bXZkYnNvbHN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4MDM2MzQsImV4cCI6MjA3NTM3OTYzNH0.YwTpP8oXmin6mbVfHRMI5H815_IQVN9sZLioFaeV_KI';

/// Supabase client instance
/// Access anywhere in the app using: supabase
final supabase = Supabase.instance.client;