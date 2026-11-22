import { Router } from 'express';
import { logEmergency } from '../controllers/emergencyController';
import { verifyToken } from '../middlewares/verifyToken';
import { validate } from '../middlewares/validate';
import { createEmergencyLogSchema } from '../validations/emergencyValidation';

const router = Router();

router.post(
    '/log',
    verifyToken,
    validate(createEmergencyLogSchema),
    logEmergency
);

export default router;
