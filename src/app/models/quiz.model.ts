export interface Question {
  id: string;
  text: string;
  options: string[];
  correctAnswer: number;
  explanation?: string;
  points: number;
}

export interface Quiz {
  id: string;
  title: string;
  description: string;
  questions: Question[];
  isEnabled: boolean;
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
  category: string;
  difficulty: 'easy' | 'medium' | 'hard';
  timeLimit?: number; // en minutos
  passingScore: number;
}

export interface QuizAttempt {
  id: string;
  quizId: string;
  userId: string;
  answers: { questionId: string; selectedOption: number }[];
  score: number;
  startedAt: Date;
  completedAt?: Date;
  status: 'in-progress' | 'completed' | 'abandoned';
}