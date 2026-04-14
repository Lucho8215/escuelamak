/*
  # Ensure quiz assignments table exists for quiz management

  This migration is intentionally idempotent to heal environments where
  `20250310201100_quiz_system.sql` was not applied completely.
*/

CREATE TABLE IF NOT EXISTS quiz_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  assigned_by TEXT,
  due_date TIMESTAMPTZ,
  is_completed BOOLEAN DEFAULT false,
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  UNIQUE(quiz_id, student_id)
);

ALTER TABLE quiz_assignments ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'quiz_assignments'
      AND policyname = 'allow_students_view_own_assignments'
  ) THEN
    CREATE POLICY "allow_students_view_own_assignments"
      ON quiz_assignments
      FOR SELECT
      TO authenticated
      USING (student_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'quiz_assignments'
      AND policyname = 'allow_teachers_view_all_assignments'
  ) THEN
    CREATE POLICY "allow_teachers_view_all_assignments"
      ON quiz_assignments
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM app_users
          WHERE id = auth.uid()
          AND role IN ('admin', 'teacher', 'tutor')
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'quiz_assignments'
      AND policyname = 'allow_teachers_create_assignments'
  ) THEN
    CREATE POLICY "allow_teachers_create_assignments"
      ON quiz_assignments
      FOR INSERT
      TO authenticated
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM app_users
          WHERE id = auth.uid()
          AND role IN ('admin', 'teacher', 'tutor')
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'quiz_assignments'
      AND policyname = 'allow_teachers_delete_assignments'
  ) THEN
    CREATE POLICY "allow_teachers_delete_assignments"
      ON quiz_assignments
      FOR DELETE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM app_users
          WHERE id = auth.uid()
          AND role IN ('admin', 'teacher', 'tutor')
        )
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_quiz_assignments_quiz_id ON quiz_assignments(quiz_id);
CREATE INDEX IF NOT EXISTS idx_quiz_assignments_student_id ON quiz_assignments(student_id);