import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Configuration
/// Single source of truth for Supabase credentials
///
/// IMPORTANT: Keep these credentials secure
/// For production, consider using environment variables
const supabaseUrl = 'https://hitqjenhkhumvdbsolsv.supabase.co';
const supabaseAnonKey = 'sb_publishable_dio3QJ5R9_5i_4U4rXoxnQ_tzI629-c';

/// Supabase client instance
/// Access anywhere in the app using: supabase
final supabase = Supabase.instance.client;