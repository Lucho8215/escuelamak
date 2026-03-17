import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/features/courses/data/courses_repository.dart';
import 'package:escuelamak/shared/models/course_model.dart';
import 'package:escuelamak/features/auth/presentation/login_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PANTALLA: Perfil completo del usuario
// ═══════════════════════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  final String nombre;
  final String rol;
  final Color color;

  const ProfileScreen({
    super.key,
    required this.nombre,
    required this.rol,
    required this.color,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repo = CoursesRepository();
  UserProfile? _profile;
  UserProgressInfo? _progress;
  bool _loading = true;
  bool _editing = false;

  final _nameController = TextEditingController();
  final _cedulaController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    // Buscar por auth_user_id
    final data = await Supabase.instance.client
        .from('app_users')
        .select()
        .eq('auth_user_id', userId)
        .maybeSingle();

    UserProfile? profile;
    UserProgressInfo? progress;

    if (data != null) {
      profile = UserProfile.fromJson(data);
      progress = await _repo.getUserProgress(profile.id);
    }

    if (mounted) {
      setState(() {
        _profile = profile;
        _progress = progress;
        _loading = false;
        if (profile != null) {
          _nameController.text = profile.name;
          _cedulaController.text = profile.cedula ?? '';
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    setState(() => _saving = true);

    final ok = await _repo.updateProfile(
      _profile!.id,
      name: _nameController.text.trim(),
      cedula: _cedulaController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _saving = false;
        if (ok) _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(ok ? Icons.check_circle : Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(ok ? 'Perfil actualizado' : 'Error al guardar'),
          ]),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      if (ok) _loadProfile();
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir de la app?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_loading && _profile != null)
            IconButton(
              icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
              onPressed: () => setState(() => _editing = !_editing),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No se pudo cargar el perfil'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadProfile, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final profile = _profile!;
    final progress = _progress;
    final initial = profile.name.isNotEmpty
        ? profile.name.split(' ').first[0].toUpperCase()
        : 'U';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header con avatar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, widget.color.withOpacity(0.8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.25),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _roleLabel(profile.role),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Estadísticas de progreso (solo estudiantes)
          if (progress != null && profile.role == 'student') ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatCard(
                    label: 'Cursos',
                    value: progress.coursesEnrolled.toString(),
                    icon: Icons.school_outlined,
                    color: widget.color,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Clases',
                    value: progress.classesEnrolled.toString(),
                    icon: Icons.class_outlined,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Completadas',
                    value: progress.classesCompleted.toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],

          // Datos del perfil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_editing) _buildEditForm() else _buildInfoCards(profile),
                const SizedBox(height: 24),

                // Botón cerrar sesión
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _InfoTile(
          icon: Icons.person_outline,
          label: 'Nombre completo',
          value: profile.name,
          color: widget.color,
        ),
        _InfoTile(
          icon: Icons.email_outlined,
          label: 'Correo electrónico',
          value: profile.email,
          color: widget.color,
        ),
        _InfoTile(
          icon: Icons.badge_outlined,
          label: 'Cédula / ID',
          value: profile.cedula?.isNotEmpty == true
              ? profile.cedula!
              : 'No registrada',
          color: widget.color,
        ),
        _InfoTile(
          icon: Icons.verified_user_outlined,
          label: 'Rol',
          value: _roleLabel(profile.role),
          color: widget.color,
        ),
        _InfoTile(
          icon: Icons.calendar_today_outlined,
          label: 'Miembro desde',
          value: _formatDate(profile.createdAt),
          color: widget.color,
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Editar información',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[800])),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nombre completo',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _cedulaController,
          decoration: InputDecoration(
            labelText: 'Cédula / ID',
            prefixIcon: const Icon(Icons.badge_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _saveProfile,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            label:
                Text(_saving ? 'Guardando...' : 'Guardar cambios',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return 'Administrador';
      case 'teacher': return 'Docente';
      case 'tutor': return 'Tutor';
      default: return 'Estudiante';
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: color)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
