import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://hlgnackuzfhkhloemtey.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsZ25hY2t1emZoa2hsb2VtdGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MjUyNzIsImV4cCI6MjA4NjIwMTI3Mn0.8jq8Anq419bzO94DqCrCcNAJSOsiqGQ8UiFsEO6ibH4'
  );

  try {
    final res = await supabase.from('modalidades_vitrine').select('*').limit(5);
    print(res);
  } catch (e) {
    print("Error: ");
    print(e);
  }
}
