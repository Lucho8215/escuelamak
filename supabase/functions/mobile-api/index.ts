/**
 * ====================================================================
 * ESCUELAMAK - API PARA APP MÓVIL
 * ====================================================================
 * Este archivo contiene los endpoints necesarios para la aplicación
 * móvil de la Escuela Mak. 
 * 
 * IMPORTANTE: Esta API está diseñada para la estructura de base de datos
 * real que incluye: app_users, courses, classes, course_enrollments, 
 * class_enrollments
 * 
 * @author Escuela Mak
 * @version 2.0 - Actualizado para esquema real
 * ====================================================================
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ============================================================
// CORS HEADERS - Configuración de CORS para permitir acceso
// ============================================================
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, PUT, DELETE, OPTIONS"
};

/**
 * Función principal que maneja todas las solicitudes
 * Distribuye las acciones según el parámetro 'action' enviado
 */
serve(async (req) => {
  // Manejar preflight CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Obtener el cuerpo de la solicitud
    const body = req.method === "GET" 
      ? Object.fromEntries(new URL(req.url).searchParams)
      : await req.json();
    
    const { action } = body;

    // Crear cliente de Supabase con clave de servicio
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Validar que existan las variables de entorno necesarias
    if (!Deno.env.get("SUPABASE_URL") || !Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")) {
      return errorResponse("Faltan configuración de Supabase en el servidor");
    }

    // ============================================================
    // ENDPOINT: Obtener módulos/permisos del usuario
    // ============================================================
    /**
     * GET /mobile-api - action: "get-modules"
     * 
     * Devuelve los módulos disponibles para el usuario según su rol.
     * La app móvil muestra diferentes módulos según el rol del usuario.
     * 
     * Parámetros:
     * - user_id: ID del usuario en app_users
     */
    if (action === "get-modules") {
      const { user_id } = body;

      if (!user_id) {
        return errorResponse("Se requiere el parámetro user_id");
      }

      // Obtener información del usuario
      const { data: user, error: userError } = await supabase
        .from("app_users")
        .select("id, name, email, role, cedula")
        .eq("id", user_id)
        .single();

      if (userError || !user) {
        return errorResponse("Usuario no encontrado");
      }

      // Definir módulos según el rol del usuario
      const modules = getModulesByRole(user.role);

      return successResponse({
        modules: modules,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          cedula: user.cedula
        }
      });
    }

    // ============================================================
    // ENDPOINT: Obtener cursos disponibles para el usuario
    // ============================================================
    /**
     * GET /mobile-api - action: "get-courses"
     * 
     * Devuelve los cursos según el rol del usuario.
     * - Estudiante: cursos donde está matriculado
     * - Profesor: cursos que imparte
     * - Admin/Tutor: todos los cursos
     */
    if (action === "get-courses") {
      const { user_id, status } = body;

      if (!user_id) {
        return errorResponse("Se requiere el parámetro user_id");
      }

      // Obtener datos del usuario
      const { data: user } = await supabase
        .from("app_users")
        .select("id, role")
        .eq("id", user_id)
        .single();

      let courses;

      if (user?.role === "admin" || user?.role === "tutor") {
        // Admin y tutor ven todos los cursos
        const { data } = await supabase
          .from("courses")
          .select("*")
          .eq("is_active", true)
          .order("created_at", { ascending: false });
        courses = data ?? [];
      } else if (user?.role === "teacher") {
        // Profesores ven sus cursos
        const { data } = await supabase
          .from("courses")
          .select("*")
          .eq("teacher_id", user_id)
          .eq("is_active", true)
          .order("created_at", { ascending: false });
        courses = data ?? [];
      } else {
        // Estudiantes ven cursos donde están matriculados
        const { data: enrollments } = await supabase
          .from("course_enrollments")
          .select("course_id, status, enrolled_at")
          .eq("user_id", user_id);

        if (!enrollments || enrollments.length === 0) {
          return successResponse({ courses: [] });
        }

        const courseIds = enrollments.map(e => e.course_id);
        
        let query = supabase
          .from("courses")
          .select("*")
          .in("id", courseIds)
          .eq("is_active", true);

        const { data } = await query.order("created_at", { ascending: false });
        
        courses = data?.map(c => {
          const enrollment = enrollments.find(e => e.course_id === c.id);
          return { ...c, enrollment_status: enrollment?.status };
        }) ?? [];
      }

      return successResponse({ courses });
    }

    // ============================================================
    // ENDPOINT: Obtener detalle de un curso
    // ============================================================
    if (action === "get-course-detail") {
      const { course_id, user_id } = body;

      if (!course_id || !user_id) {
        return errorResponse("Se requieren course_id y user_id");
      }

      // Obtener curso
      const { data: course, error: courseError } = await supabase
        .from("courses")
        .select("*")
        .eq("id", course_id)
        .single();

      if (courseError || !course) {
        return errorResponse("Curso no encontrado");
      }

      // Obtener clases del curso
      const { data: classes } = await supabase
        .from("classes")
        .select("*")
        .eq("course_id", course_id)
        .eq("is_active", true)
        .order("class_number", { ascending: true });

      // Obtener progreso del usuario en las clases
      const classIds = classes?.map(c => c.id) ?? [];
      let userProgress: Record<string, any> = {};
      
      if (classIds.length > 0) {
        const { data: progress } = await supabase
          .from("student_lesson_assignments")
          .select("*")
          .eq("user_id", user_id)
          .in("lesson_id", classIds);
        
        progress?.forEach(p => {
          userProgress[p.lesson_id] = p;
        });
      }

      // Verificar si está matriculado
      const { data: enrollment } = await supabase
        .from("course_enrollments")
        .select("status, enrolled_at")
        .eq("course_id", course_id)
        .eq("user_id", user_id)
        .single();

      return successResponse({
        course,
        classes: classes ?? [],
        enrollment: enrollment,
        userProgress
      });
    }

    // ============================================================
    // ENDPOINT: Obtener detalle de una clase
    // ============================================================
    if (action === "get-class") {
      const { class_id, user_id } = body;

      if (!class_id || !user_id) {
        return errorResponse("Se requieren class_id y user_id");
      }

      // Obtener clase
      const { data: classData, error: classError } = await supabase
        .from("classes")
        .select("*")
        .eq("id", class_id)
        .single();

      if (classError || !classData) {
        return errorResponse("Clase no encontrada");
      }

      // Obtener progreso del usuario en esta clase
      const { data: progress } = await supabase
        .from("student_lesson_assignments")
        .select("*")
        .eq("lesson_id", class_id)
        .eq("student_id", user_id)
        .single();

      // Obtener información del curso
      const { data: course } = await supabase
        .from("courses")
        .select("id, title")
        .eq("id", classData.course_id)
        .single();

      return successResponse({
        class: classData,
        course: course,
        progress: progress
      });
    }

    // ============================================================
    // ENDPOINT: Obtener clases del usuario (mis clases)
    // ============================================================
    if (action === "get-my-classes") {
      const { user_id } = body;

      if (!user_id) {
        return errorResponse("Se requiere user_id");
      }

      // Obtener clases del usuario desde class_enrollments
      const { data: classEnrollments } = await supabase
        .from("class_enrollments")
        .select("class_id, status, enrolled_at")
        .eq("user_id", user_id);

      if (!classEnrollments || classEnrollments.length === 0) {
        return successResponse({ classes: [] });
      }

      const classIds = classEnrollments.map(e => e.class_id);

      // Obtener las clases con información del curso
      const { data: classes } = await supabase
        .from("classes")
        .select(`
          *,
          course:courses(id, title, category, image_url)
        `)
        .in("id", classIds)
        .eq("is_active", true)
        .order("start_date", { ascending: false });

      const classesWithEnrollment = classes?.map(c => {
        const enrollment = classEnrollments.find(e => e.class_id === c.id);
        return {
          ...c,
          enrollment_status: enrollment?.status,
          enrolled_at: enrollment?.enrolled_at
        };
      }) ?? [];

      return successResponse({ classes: classesWithEnrollment });
    }

    // ============================================================
    // ENDPOINT: Inscribirse en una clase
    // ============================================================
    if (action === "enroll-class") {
      const { user_id, class_id } = body;

      if (!user_id || !class_id) {
        return errorResponse("Se requieren user_id y class_id");
      }

      // Verificar que la clase existe
      const { data: classData } = await supabase
        .from("classes")
        .select("id, max_students, enrolled_students")
        .eq("id", class_id)
        .single();

      if (!classData) {
        return errorResponse("Clase no encontrada");
      }

      // Verificar si ya está inscrito
      const { data: existing } = await supabase
        .from("class_enrollments")
        .select("id")
        .eq("user_id", user_id)
        .eq("class_id", class_id)
        .single();

      if (existing) {
        return errorResponse("Ya estás inscrito en esta clase");
      }

      // Inscribir al usuario
      const { error } = await supabase
        .from("class_enrollments")
        .insert({
          user_id,
          class_id,
          status: "active"
        });

      if (error) {
        return errorResponse("Error al inscribirse: " + error.message);
      }

      return successResponse({ 
        message: "Inscripción exitosa",
        class_id 
      });
    }

    // ============================================================
    // ENDPOINT: Completar una clase (reportar progreso)
    // ============================================================
    if (action === "complete-class") {
      const { user_id, class_id, progress_pct, completed } = body;

      if (!user_id || !class_id) {
        return errorResponse("Se requieren user_id y class_id");
      }

      // Upsert progreso del estudiante
      const { data, error } = await supabase
        .from("student_lesson_assignments")
        .upsert({
          student_id: user_id,
          lesson_id: class_id,
          progress_pct: progress_pct ?? 100,
          completed: completed ?? true,
          updated_at: new Date().toISOString()
        }, {
          onConflict: "student_id,lesson_id"
        })
        .select()
        .single();

      if (error) {
        return errorResponse("Error al guardar progreso: " + error.message);
      }

      return successResponse({ 
        message: "Progreso guardado",
        progress: data 
      });
    }

    // ============================================================
    // ENDPOINT: Reportar estado de clase (desde app móvil)
    // ============================================================
    if (action === "report-class-status") {
      const { user_id, class_id, status, progress_pct, last_position } = body;

      if (!user_id || !class_id || !status) {
        return errorResponse("Se requieren user_id, class_id y status");
      }

      const completed = status === "completed";
      const pct = Math.min(100, Math.max(0, progress_pct ?? (completed ? 100 : 0)));

      // Guardar progreso
      const { data, error } = await supabase
        .from("student_lesson_assignments")
        .upsert({
          student_id: user_id,
          lesson_id: class_id,
          status: status,
          progress_pct: pct,
          completed: completed,
          last_position: last_position ?? 0,
          updated_at: new Date().toISOString()
        }, {
          onConflict: "student_id,lesson_id"
        })
        .select()
        .single();

      if (error) {
        return errorResponse("Error al reportar estado: " + error.message);
      }

      return successResponse({
        message: `Estado reportado: ${status}`,
        progress: data
      });
    }

    // ============================================================
    // ENDPOINT: Editar una clase (profesor/admin)
    // ============================================================
    if (action === "update-class") {
      const { user_id, class_id, title, description, content, resource_link, resource_file_url } = body;

      if (!user_id || !class_id) {
        return errorResponse("Se requieren user_id y class_id");
      }

      // Verificar permisos
      const { data: classData } = await supabase
        .from("classes")
        .select("teacher_id")
        .eq("id", class_id)
        .single();

      const { data: user } = await supabase
        .from("app_users")
        .select("role")
        .eq("id", user_id)
        .single();

      const isOwner = classData?.teacher_id === user_id;
      const isAdmin = user?.role === "admin";

      if (!isOwner && !isAdmin) {
        return errorResponse("No tienes permiso para editar esta clase", 403);
      }

      // Preparar datos de actualización
      const updateData: Record<string, unknown> = {};
      if (title !== undefined) updateData.title = title;
      if (description !== undefined) updateData.description = description;
      if (content !== undefined) updateData.content = content;
      if (resource_link !== undefined) updateData.resource_link = resource_link;
      if (resource_file_url !== undefined) updateData.resource_file_url = resource_file_url;
      updateData.updated_at = new Date().toISOString();

      // Actualizar clase
      const { data, error } = await supabase
        .from("classes")
        .update(updateData)
        .eq("id", class_id)
        .select()
        .single();

      if (error) {
        return errorResponse("Error al actualizar la clase: " + error.message);
      }

      return successResponse({ 
        message: "Clase actualizada correctamente",
        class: data 
      });
    }

    // ============================================================
    // ENDPOINT: Obtener progreso del usuario
    // ============================================================
    if (action === "get-user-progress") {
      const { user_id } = body;

      if (!user_id) {
        return errorResponse("Se requiere user_id");
      }

      // Obtener inscripciones en cursos
      const { data: courseEnrollments } = await supabase
        .from("course_enrollments")
        .select("course_id, status")
        .eq("user_id", user_id);

      // Obtener inscripciones en clases
      const { data: classEnrollments } = await supabase
        .from("class_enrollments")
        .select("class_id, status")
        .eq("user_id", user_id);

      // Obtener progreso en clases
      const { data: progress } = await supabase
        .from("student_lesson_assignments")
        .select("*")
        .eq("student_id", user_id)
        .eq("completed", true);

      return successResponse({
        courses_enrolled: courseEnrollments?.length ?? 0,
        classes_enrolled: classEnrollments?.length ?? 0,
        classes_completed: progress?.length ?? 0,
        progress_list: progress ?? []
      });
    }

    // ============================================================
    // ENDPOINT: Obtener información del perfil
    // ============================================================
    if (action === "get-profile") {
      const { user_id } = body;

      if (!user_id) {
        return errorResponse("Se requiere user_id");
      }

      const { data: user, error } = await supabase
        .from("app_users")
        .select("*")
        .eq("id", user_id)
        .single();

      if (error || !user) {
        return errorResponse("Usuario no encontrado");
      }

      return successResponse({ user });
    }

    // ============================================================
    // ENDPOINT: Actualizar perfil
    // ============================================================
    if (action === "update-profile") {
      const { user_id, name, cedula } = body;

      if (!user_id) {
        return errorResponse("Se requiere user_id");
      }

      const updateData: Record<string, unknown> = {};
      if (name !== undefined) updateData.name = name;
      if (cedula !== undefined) updateData.cedula = cedula;

      const { data, error } = await supabase
        .from("app_users")
        .update(updateData)
        .eq("id", user_id)
        .select()
        .single();

      if (error) {
        return errorResponse("Error al actualizar perfil: " + error.message);
      }

      return successResponse({ 
        message: "Perfil actualizado",
        user: data 
      });
    }

    // Si no coincide ninguna acción, devolver error
    return errorResponse(`Acción desconocida: ${action}`);

  } catch (error) {
    const message = error instanceof Error ? error.message : "Error desconocido";
    return errorResponse(message, 500);
  }
});

// ============================================================
// FUNCIONES AUXILIARES
// ============================================================

/**
 * Obtiene los módulos disponibles según el rol del usuario
 */
function getModulesByRole(role: string): Array<{
  key: string;
  name: string;
  description: string;
  icon: string;
  route: string;
  is_granted: boolean;
}> {
  // Módulos base para todos los usuarios
  const baseModules = [
    {
      key: "home",
      name: "Inicio",
      description: "Página principal",
      icon: "home",
      route: "/home",
      is_granted: true
    },
    {
      key: "my_classes",
      name: "Mis Clases",
      description: "Clases inscritas",
      icon: "class",
      route: "/my-classes",
      is_granted: true
    },
    {
      key: "profile",
      name: "Perfil",
      description: "Mi perfil de usuario",
      icon: "person",
      route: "/profile",
      is_granted: true
    }
  ];

  // Módulos adicionales para estudiantes
  const studentModules = [
    {
      key: "courses",
      name: "Cursos",
      description: "Explorar cursos disponibles",
      icon: "school",
      route: "/courses",
      is_granted: true
    },
    {
      key: "tasks",
      name: "Tareas",
      description: "Mis tareas y entregas",
      icon: "assignment",
      route: "/tasks",
      is_granted: true
    },
    {
      key: "progress",
      name: "Mi Progreso",
      description: "Ver mi avance",
      icon: "trending_up",
      route: "/progress",
      is_granted: true
    }
  ];

  // Módulos adicionales para profesores
  const teacherModules = [
    {
      key: "my_courses",
      name: "Mis Cursos",
      description: "Gestionar mis cursos",
      icon: "class",
      route: "/my-courses",
      is_granted: true
    },
    {
      key: "create_course",
      name: "Crear Curso",
      description: "Crear nuevo curso",
      icon: "add_circle",
      route: "/create-course",
      is_granted: true
    },
    {
      key: "students",
      name: "Estudiantes",
      description: "Ver mis estudiantes",
      icon: "people",
      route: "/students",
      is_granted: true
    }
  ];

  // Módulos para admin
  const adminModules = [
    {
      key: "admin_panel",
      name: "Administración",
      description: "Panel de administración",
      icon: "admin_panel_settings",
      route: "/admin",
      is_granted: true
    },
    {
      key: "all_users",
      name: "Usuarios",
      description: "Gestionar usuarios",
      icon: "supervised_user_circle",
      route: "/admin/users",
      is_granted: true
    }
  ];

  // Combinar módulos según el rol
  let modules = [...baseModules];

  if (role === "student") {
    modules = [...modules, ...studentModules];
  } else if (role === "teacher") {
    modules = [...modules, ...teacherModules, ...studentModules];
  } else if (role === "admin") {
    modules = [...modules, ...adminModules, ...teacherModules, ...studentModules];
  } else if (role === "tutor") {
    modules = [...modules, ...adminModules];
  }

  return modules;
}

// ============================================================
// RESPUESTAS HTTP
// ============================================================

/**
 * Genera una respuesta de éxito
 */
function successResponse(data: unknown): Response {
  return new Response(
    JSON.stringify({ success: true, data }),
    {
      status: 200,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    }
  );
}

/**
 * Genera una respuesta de error
 */
function errorResponse(message: string, status: number = 400): Response {
  return new Response(
    JSON.stringify({ success: false, error: message }),
    {
      status,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    }
  );
}
