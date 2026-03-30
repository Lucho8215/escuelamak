/*
  # Permitir a estudiantes actualizar sus propios quiz_assignments

  Cuando un estudiante completa un quiz, la app móvil necesita marcar
  is_completed = true en su assignment. Sin esta política RLS, el UPDATE
  falla silenciosamente.
*/

-- Política para que estudiantes actualicen sus propias asignaciones
CREATE POLICY "allow_students_update_own_assignments"
  ON quiz_assignments
  FOR UPDATE
  TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());
