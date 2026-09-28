import { Router } from 'express';
import ExerciseController from '../controllers/ExerciseController.js';

const router = Router();

// GET /exercises (pagination, filtering, search)
router.get('/', ExerciseController.listExercises);

// GET /exercises/:id (single exercise details)
router.get('/:id', ExerciseController.getExerciseById);

export default router;
