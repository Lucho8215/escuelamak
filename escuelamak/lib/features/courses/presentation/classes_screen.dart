import 'package:flutter/material.dart';
import 'package:escuelamak/core/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PANTALLA DE CLASES - Con skeleton loaders estilo Google Classroom
// ═══════════════════════════════════════════════════════════════════════════

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simular carga de datos
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Clases'),
        backgroundColor: AppTheme.teacherColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading ? _buildSkeletonLoading() : _buildContent(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SKELETON LOADING - Estado de carga
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FadeSlideIn(
            delay: Duration(milliseconds: 100 * index),
            child: const _ClassCardSkeleton(),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENIDO - Cuando los datos están cargados
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildContent() {
    // Datos de ejemplo
    final classes = [
      _ClassData(
        title: 'Matemáticas Avanzadas',
        subtitle: 'Álgebra y Cálculo',
        teacher: 'Prof. Juan García',
        color: Colors.blue,
        icon: Icons.functions,
        students: 28,
      ),
      _ClassData(
        title: 'Física y Química',
        subtitle: 'Mecánica Cuántica',
        teacher: 'Prof. María López',
        color: Colors.green,
        icon: Icons.science,
        students: 22,
      ),
      _ClassData(
        title: 'Programación Web',
        subtitle: 'Frontend y Backend',
        teacher: 'Prof. Carlos Ruiz',
        color: Colors.orange,
        icon: Icons.code,
        students: 35,
      ),
      _ClassData(
        title: 'Historia Universal',
        subtitle: 'Edad Contemporánea',
        teacher: 'Prof. Ana Martínez',
        color: Colors.purple,
        icon: Icons.history_edu,
        students: 25,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FadeSlideIn(
            delay: Duration(milliseconds: 100 * index),
            child: _ClassCard(
              classData: classes[index],
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Abriendo ${classes[index].title}...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA DE CLASE (CARGADA)
// ═══════════════════════════════════════════════════════════════════════════

class _ClassData {
  final String title;
  final String subtitle;
  final String teacher;
  final Color color;
  final IconData icon;
  final int students;

  _ClassData({
    required this.title,
    required this.subtitle,
    required this.teacher,
    required this.color,
    required this.icon,
    required this.students,
  });
}

class _ClassCard extends StatelessWidget {
  final _ClassData classData;
  final VoidCallback onTap;

  const _ClassCard({
    required this.classData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Color lateral
            Container(
              width: 6,
              height: 100,
              decoration: BoxDecoration(
                color: classData.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icono
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: classData.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        classData.icon,
                        color: classData.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Texto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classData.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            classData.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                classData.teacher,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.people_outline,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${classData.students}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Flecha
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SKELETON DE TARJETA DE CLASE
// ═══════════════════════════════════════════════════════════════════════════

class _ClassCardSkeleton extends StatelessWidget {
  const _ClassCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Color lateral esqueleto
          Container(
            width: 6,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),

          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icono esqueleto
                  SkeletonBox(
                    width: 56,
                    height: 56,
                    borderRadius: 14,
                  ),
                  const SizedBox(width: 16),

                  // Texto esqueleto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 160, height: 16),
                        const SizedBox(height: 8),
                        SkeletonBox(width: 120, height: 12),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SkeletonBox(width: 100, height: 12),
                            const SizedBox(width: 16),
                            SkeletonBox(width: 30, height: 12),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
