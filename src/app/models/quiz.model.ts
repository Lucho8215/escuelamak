export interface Question {
  id: string;
  text: string;
  options: string[];
  correctAnswer: number;
  explanation?: string;
  points: number;
  orderNumber?: number;
}

export interface Quiz {
  id: string;
  title: string;
  description: string;
  questions: Question[];
  isEnabled: boolean;
  isVisible: boolean;
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
  category: string;
  difficulty: 'easy' | 'medium' | 'hard';
  timeLimit?: number;
  passingScore: number;
}

export interface QuizAttempt {
  id: string;
  quizId: string;
  userId: string;
  answers: { questionId: string; selectedOption: number }[];
  score: number;
  passed: boolean;
  startedAt: Date;
  completedAt?: Date;
  timeSpentSeconds?: number;
  status: 'in-progress' | 'completed' | 'abandoned';
}

export interface QuizAssignment {
  id: string;
  quizId: string;
  studentId: string;
  assignedBy?: string;
  dueDate?: Date;
  isCompleted: boolean;
  assignedAt: Date;
  completedAt?: Date;
  quiz?: Quiz;
  student?: {
    id: string;
    name: string;
    email: string;
  };
  bestScore?: number;
}

export interface StudentQuiz {
  id: string;
  quizId: string;
  title: string;
  description: string;
  category: string;
  difficulty: string;
  timeLimit: number;
  passingScore: number;
  questionsCount: number;
  assignedAt?: Date;
  dueDate?: Date;
  isCompleted: boolean;
  bestScore?: number;
  lastAttemptDate?: Date;
  attemptCount: number;
}
